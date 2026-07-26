import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/hive_status_rules.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../theme/app_theme.dart';
import '../widgets/hive_editors.dart';
import '../widgets/home_fab.dart';

class HiveHarvestsScreen extends StatefulWidget {
  const HiveHarvestsScreen({super.key, required this.hiveUuid, this.hiveLabel});

  final String hiveUuid;
  final String? hiveLabel;

  @override
  State<HiveHarvestsScreen> createState() => _HiveHarvestsScreenState();
}

class _HiveHarvestsScreenState extends State<HiveHarvestsScreen> {
  final db = AppDatabase.instance;
  List<Harvest> _harvests = [];
  double _yearSum = 0;
  bool _loading = true;
  String? _pastureFilter;
  String _hiveStatus = 'ACTIVE';
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final hive = await db.findHiveByUuid(widget.hiveUuid);
    final harvests = await db.harvestsForHive(widget.hiveUuid, year: _year);
    final sum = await db.harvestSum(widget.hiveUuid, _year);
    if (!mounted) return;
    setState(() {
      _hiveStatus = HiveStatusRules.normalize(hive?.status);
      _harvests = harvests;
      _yearSum = sum;
      _loading = false;
    });
  }

  List<Harvest> get _visible {
    if (_pastureFilter == null) return _harvests;
    return _harvests.where((h) => h.pastureType == _pastureFilter).toList();
  }

  double get _visibleSum => _visible.fold<double>(0, (s, h) => s + h.amountKg);

  Future<void> _addOrEdit({Harvest? existing}) async {
    final blocked = HiveStatusRules.blockReasonHarvest(_hiveStatus);
    if (blocked != null && existing == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    if (blocked != null && existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final saved = await editHarvestDialog(context, hiveUuid: widget.hiveUuid, existing: existing);
    if (saved) await _reload();
  }

  Future<void> _delete(Harvest h) async {
    final linked = h.workGroupHiveUuid != null && h.workGroupHiveUuid!.isNotEmpty;
    if (!await confirmDialog(
      context,
      'Obriši prinos',
      linked
          ? 'Ovaj prinos je vezan za zapis u radnoj grupi. '
              'Brisanjem se briše i članstvo u grupi (bez istorije). Nastaviti?'
          : 'Obrisati ovaj unos prinosa?',
    )) {
      return;
    }
    await GroupSharedDataSync().deleteHarvest(h);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6CB0),
        foregroundColor: Colors.white,
        title: Text(widget.hiveLabel == null ? 'Prinosi $_year' : 'Prinosi · ${widget.hiveLabel}'),
      ),
      floatingActionButton: HomeFab.pair(
        primary: FloatingActionButton.extended(
          heroTag: 'add_harvest_fab',
          backgroundColor: const Color(0xFF2B6CB0),
          foregroundColor: Colors.white,
          onPressed: HiveStatusRules.canAddHarvest(_hiveStatus) ? () => _addOrEdit() : null,
          icon: const Icon(Icons.add),
          label: Text(HiveStatusRules.canAddHarvest(_hiveStatus) ? 'Dodaj' : 'Samo aktivna'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: const Color(0xFFEAF2FB),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Text(
                      'Ukupno $_year: ${_yearSum.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2B6CB0)),
                    ),
                  ),
                ),
                if (_harvests.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Sve (${_yearSum.toStringAsFixed(1)} kg)'),
                            selected: _pastureFilter == null,
                            selectedColor: const Color(0xFF2B6CB0),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _pastureFilter == null ? Colors.white : const Color(0xFF2B6CB0),
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) => setState(() => _pastureFilter = null),
                          ),
                        ),
                        for (final type in pastureTypes)
                          if (_harvests.any((h) => h.pastureType == type))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  '$type (${_harvests.where((h) => h.pastureType == type).fold<double>(0, (s, h) => s + h.amountKg).toStringAsFixed(1)} kg)',
                                ),
                                selected: _pastureFilter == type,
                                selectedColor: const Color(0xFF2B6CB0),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: _pastureFilter == type ? Colors.white : const Color(0xFF2B6CB0),
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) => setState(() => _pastureFilter = type),
                              ),
                            ),
                      ],
                    ),
                  ),
                if (_pastureFilter != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      '$_pastureFilter: ${_visibleSum.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                Expanded(
                  child: _harvests.isEmpty
                      ? const Center(child: Text('Još nema unosa prinosa ove godine.'))
                      : visible.isEmpty
                          ? const Center(child: Text('Nema prinosa za izabranu pašu.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: visible.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final h = visible[i];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    leading: const Icon(Icons.hive_outlined, color: Color(0xFF2B6CB0)),
                                    title: Text('${h.pastureType} · ${h.amountKg} kg', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text(h.collectedAt?.toLocal().toString().split('.').first ?? ''),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') await _addOrEdit(existing: h);
                                        if (v == 'delete') await _delete(h);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                                        PopupMenuItem(value: 'delete', child: Text('Obriši')),
                                      ],
                                    ),
                                    onTap: () => _addOrEdit(existing: h),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
