import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hive_editors.dart';
import '../widgets/home_fab.dart';

class HiveInspectionsScreen extends StatefulWidget {
  const HiveInspectionsScreen({
    super.key,
    required this.hiveUuid,
    this.hiveLabel,
  });

  final String hiveUuid;
  final String? hiveLabel;

  @override
  State<HiveInspectionsScreen> createState() => _HiveInspectionsScreenState();
}

class _HiveInspectionsScreenState extends State<HiveInspectionsScreen> {
  final db = AppDatabase.instance;
  List<Inspection> _inspections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final inspections = await db.inspectionsForHive(widget.hiveUuid);
    if (!mounted) return;
    setState(() {
      _inspections = inspections;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({Inspection? existing}) async {
    final saved = await editInspectionDialog(
      context,
      hiveUuid: widget.hiveUuid,
      existing: existing,
    );
    if (saved) await _reload();
  }

  Future<void> _delete(Inspection inspection) async {
    if (!await confirmDialog(
      context,
      'Obriši kontrolu',
      'Obrisati ovu kontrolu košnice?',
    ))
      return;
    final reminder = await db.reminderByInspection(inspection.uuid);
    if (reminder != null) {
      reminder.dateDeleted = DateTime.now();
      reminder.touch();
      reminder.dateSynched = null;
      await db.upsertReminder(reminder);
      await ReminderService.instance.cancel(
        reminder.uuid.hashCode & 0x7fffffff,
      );
    }
    await db.softDelete('inspection', inspection.uuid);
    await _reload();
  }

  Future<void> _openDetails(Inspection inspection) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kontrola košnice'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inspection.inspectedAt.toLocal().toString().split('.').first,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow(
                  'Ishod',
                  inspectionValueLabel(
                    inspectionOutcomeStatuses,
                    inspection.outcomeStatus,
                  ),
                ),
                _detailRow(
                  'Matica',
                  inspectionValueLabel(
                    inspectionQueenStatuses,
                    inspection.queenStatus,
                  ),
                ),
                _detailRow(
                  'Leglo',
                  inspectionValueLabel(
                    inspectionChecklistStatuses,
                    inspection.broodStatus,
                  ),
                ),
                _detailRow(
                  'Jačina',
                  inspectionValueLabel(
                    inspectionStrengthStatuses,
                    inspection.strengthStatus,
                  ),
                ),
                _detailRow(
                  'Hrana',
                  inspectionValueLabel(
                    inspectionChecklistStatuses,
                    inspection.foodStatus,
                  ),
                ),
                _detailRow(
                  'Temperament',
                  inspectionValueLabel(
                    inspectionTemperStatuses,
                    normalizeInspectionTemperStatus(inspection.temperStatus),
                  ),
                ),
                _detailRow(
                  'Zdravlje',
                  inspectionValueLabel(
                    inspectionHealthStatuses,
                    inspection.healthStatus,
                  ),
                ),
                if (inspection.followUpAt != null)
                  _detailRow(
                    'Podsetnik',
                    inspection.followUpAt!
                        .toLocal()
                        .toString()
                        .split('.')
                        .first,
                  ),
                _detailRow('Izvor', inspectionSourceLabel(inspection)),
                if (inspection.summary != null &&
                    inspection.summary!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    inspection.summary!,
                    style: const TextStyle(height: 1.4, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zatvori'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _delete(inspection);
            },
            child: Text('Obriši', style: TextStyle(color: Colors.red.shade700)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addOrEdit(existing: inspection);
            },
            child: const Text('Izmeni'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hiveLabel == null
              ? 'Kontrole košnice'
              : 'Kontrole · ${widget.hiveLabel}',
        ),
      ),
      floatingActionButton: HomeFab.pair(
        primary: FloatingActionButton.extended(
          heroTag: 'add_inspection_fab',
          onPressed: () => _addOrEdit(),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _inspections.isEmpty
          ? const Center(child: Text('Nema kontrola.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _inspections.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final inspection = _inspections[i];
                return Material(
                  color: AppTheme.card(context),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.meadow,
                    ),
                    title: Text(
                      inspectionSummaryLine(inspection),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        inspection.inspectedAt
                            .toLocal()
                            .toString()
                            .split('.')
                            .first,
                        inspectionValueLabel(
                          inspectionOutcomeStatuses,
                          inspection.outcomeStatus,
                        ),
                        'Izvor: ${inspectionSourceLabel(inspection)}',
                      ].join(' · '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') await _addOrEdit(existing: inspection);
                        if (v == 'delete') await _delete(inspection);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                        PopupMenuItem(value: 'delete', child: Text('Obriši')),
                      ],
                    ),
                    onTap: () => _openDetails(inspection),
                  ),
                );
              },
            ),
    );
  }
}
