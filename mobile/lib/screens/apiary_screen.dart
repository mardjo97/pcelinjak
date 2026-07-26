import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/apiary_edit_dialog.dart';
import '../widgets/barcode_scan.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/home_fab.dart';
import 'hive_screen.dart';

class ApiaryScreen extends StatefulWidget {
  const ApiaryScreen({super.key, required this.apiaryUuid});

  final String apiaryUuid;

  @override
  State<ApiaryScreen> createState() => _ApiaryScreenState();
}

class _ApiaryScreenState extends State<ApiaryScreen> {
  final db = AppDatabase.instance;
  final _searchCtrl = TextEditingController();
  Apiary? _apiary;
  List<Hive> _hives = [];
  final Map<String, Queen> _queens = {};
  /// ACTIVE | ARCHIVED | DEAD | ALL
  String _statusFilter = 'ACTIVE';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final a = await db.apiaryByUuid(widget.apiaryUuid);
    final h = await db.listHives(widget.apiaryUuid, activeOnly: false);
    final queens = <String, Queen>{};
    for (final hive in h) {
      final q = await db.activeQueen(hive.uuid);
      if (q != null) queens[hive.uuid] = q;
    }
    if (!mounted) return;
    setState(() {
      _apiary = a;
      _hives = h;
      _queens
        ..clear()
        ..addAll(queens);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ARCHIVED':
        return const Color(0xFF4A5568);
      case 'DEAD':
        return const Color(0xFFC53030);
      default:
        return AppColors.meadow;
    }
  }

  List<Hive> get _filtered {
    Iterable<Hive> list = _hives;
    if (_statusFilter != 'ALL') {
      list = list.where((h) {
        final s = h.status.isEmpty ? 'ACTIVE' : h.status;
        return s == _statusFilter;
      });
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list.toList();

    final markedWanted = const ['markir', 'oznac', 'označ', 'marked', 'obelez', 'obelež']
        .any((k) => q.contains(k));
    final unmarkedWanted = const ['nemark', 'neoznac', 'neoznač', 'unmarked'].any((k) => q.contains(k));

    return list.where((h) {
      final queen = _queens[h.uuid];
      final hay = [
        h.barcode,
        '${h.orderNumber}',
        h.hiveType,
        h.description ?? '',
        h.status,
        hiveStatuses[h.status] ?? '',
        queen?.queenYear?.toString() ?? '',
        queen?.origin ?? '',
        if (queen?.marked == true) ...['markirana', 'označena', 'marked'],
        if (queen != null && !queen.marked) ...['nemarkirana', 'neoznačena'],
        if (queen == null) 'bez matice',
      ].join(' ').toLowerCase();

      if (hay.contains(q)) return true;
      if (markedWanted && queen?.marked == true) return true;
      if (unmarkedWanted && queen != null && !queen.marked) return true;
      return false;
    }).toList();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() {});
    });
  }

  void _setStatusFilter(String filter) {
    setState(() => _statusFilter = filter);
  }

  Future<void> _editApiary() async {
    final a = _apiary;
    if (a == null) return;
    final updated = await showApiaryEditor(context, existing: a);
    if (updated != null) await _reload();
  }

  Future<void> _addHive({String? presetBarcode}) async {
    final barcodeCtrl = TextEditingController(text: presetBarcode ?? '');
    String type = hiveTypes.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nova košnica'),
          content: FormSpacedColumn(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barcodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Barkod'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await scanBarcode(context);
                      if (code != null) barcodeCtrl.text = code;
                    },
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: hiveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setLocal(() => type = v ?? type),
                decoration: const InputDecoration(labelText: 'Tip košnice'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
          ],
        ),
      ),
    );
    if (ok != true || barcodeCtrl.text.trim().isEmpty) return;
    final existing = await db.findHiveByBarcode(barcodeCtrl.text.trim());
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barkod već postoji')));
      return;
    }
    final order = await db.nextHiveOrder(widget.apiaryUuid);
    final hive = Hive(
      uuid: db.newUuid(),
      barcode: barcodeCtrl.text.trim(),
      orderNumber: order,
      hiveType: type,
      apiaryUuid: widget.apiaryUuid,
      status: 'ACTIVE',
    );
    await db.upsertHive(hive);
    await _reload();
  }

  Future<void> _addManyHives() async {
    String type = hiveTypes.first;
    final typeOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Dodaj više košnica'),
          content: DropdownButtonFormField<String>(
            initialValue: type,
            items: hiveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setLocal(() => type = v ?? type),
            decoration: const InputDecoration(labelText: 'Tip za sve skenirane'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Skeniraj')),
          ],
        ),
      ),
    );
    if (typeOk != true || !mounted) return;

    final codes = await scanBarcodesContinuous(context, title: 'Skeniraj košnice · $type');
    if (codes == null || codes.isEmpty || !mounted) return;

    var created = 0;
    var skipped = 0;
    var order = await db.nextHiveOrder(widget.apiaryUuid);
    for (final code in codes) {
      final existing = await db.findHiveByBarcode(code);
      if (existing != null) {
        skipped++;
        continue;
      }
      await db.upsertHive(Hive(
        uuid: db.newUuid(),
        barcode: code,
        orderNumber: order,
        hiveType: type,
        apiaryUuid: widget.apiaryUuid,
        status: 'ACTIVE',
      ));
      order++;
      created++;
    }
    await _reload();
    if (!mounted) return;
    final msg = skipped == 0
        ? 'Dodato $created košnica ($type).'
        : 'Dodato $created · preskočeno $skipped (već postoje).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickAddHiveMode() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Jedna košnica'),
              onTap: () => Navigator.pop(ctx, 'one'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Više košnica (sken)'),
              subtitle: const Text('Kontinuirano skeniranje, isti tip'),
              onTap: () => Navigator.pop(ctx, 'many'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'one') await _addHive();
    if (choice == 'many') await _addManyHives();
  }

  @override
  Widget build(BuildContext context) {
    final a = _apiary;
    final visible = _filtered;
    final q = _searchCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(a == null ? 'Pčelinjak' : 'Pčelinjak ${a.workNumber} · ${a.name}'),
        actions: [
          IconButton(
            tooltip: 'Izmeni pčelinjak',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editApiary,
          ),
          IconButton(
            tooltip: 'Dodaj više skeniranjem',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _addManyHives,
          ),
        ],
      ),
      floatingActionButton: HomeFab.pair(
        primary: FloatingActionButton.extended(
          heroTag: 'add_hive_fab',
          onPressed: _pickAddHiveMode,
          icon: const Icon(Icons.add),
          label: const Text('Dodaj košnicu'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Material(
            color: AppTheme.tintedSurface(context, AppColors.mist),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'Aktivne',
                    selected: _statusFilter == 'ACTIVE',
                    color: _statusColor('ACTIVE'),
                    onTap: () => _setStatusFilter('ACTIVE'),
                  ),
                  _StatusChip(
                    label: 'Arhivirane',
                    selected: _statusFilter == 'ARCHIVED',
                    color: _statusColor('ARCHIVED'),
                    onTap: () => _setStatusFilter('ARCHIVED'),
                  ),
                  _StatusChip(
                    label: 'Ugašene',
                    selected: _statusFilter == 'DEAD',
                    color: _statusColor('DEAD'),
                    onTap: () => _setStatusFilter('DEAD'),
                  ),
                  _StatusChip(
                    label: 'Sve',
                    selected: _statusFilter == 'ALL',
                    color: AppColors.meadowDark,
                    onTap: () => _setStatusFilter('ALL'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Barkod, tip, RB, matica…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Obriši',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          if (q.isNotEmpty || _statusFilter != 'ALL')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${visible.length} košnica',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted(context)),
                ),
              ),
            ),
          Expanded(
            child: _hives.isEmpty
                ? const Center(
                    child: Text(
                      'Nema košnica. Skenirajte barkodove redom.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          q.isNotEmpty
                              ? 'Nema rezultata za „$q”.'
                              : 'Nema košnica za ovaj status.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        children: [
                          const Row(
                            children: [
                              Expanded(flex: 1, child: Text('RB', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('TIP', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text('KOD', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const Divider(),
                          ...visible.map((h) {
                            final status = h.status.isEmpty ? 'ACTIVE' : h.status;
                            final color = _statusColor(status);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Material(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => HiveScreen(hiveUuid: h.uuid)));
                                    _reload();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border(left: BorderSide(color: color, width: 7)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${h.orderNumber}',
                                            style: TextStyle(fontWeight: FontWeight.w800, color: color),
                                          ),
                                        ),
                                        Expanded(flex: 2, child: Text(h.hiveType)),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(h.barcode, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  hiveStatuses[status] ?? status,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: color),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: AppTheme.chipLabel(context, selected: selected, accent: color),
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: color),
      ),
    );
  }
}
