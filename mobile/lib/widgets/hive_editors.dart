import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../services/reminder_notification_title.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import 'form_spaced_column.dart';

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String message,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Potvrdi'),
        ),
      ],
    ),
  );
  return ok == true;
}

String notePreviewLine(Note n) {
  final line = n.content
      .split(RegExp(r'\r?\n'))
      .firstWhere((s) => s.trim().isNotEmpty, orElse: () => n.content);
  return line.trim();
}

/// Sačuva napomenu. Vraća true ako je sačuvano.
Future<bool> editNoteDialog(
  BuildContext context, {
  required String hiveUuid,
  Note? existing,
}) async {
  final db = AppDatabase.instance;
  final ctrl = TextEditingController(text: existing?.content ?? '');
  DateTime? reminderAt = existing?.reminderAt;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(existing == null ? 'Nova napomena' : 'Izmeni napomenu'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: FormSpacedColumn(
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  minLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Upišite napomenu…',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Podsetnik (opciono)'),
                  subtitle: Text(
                    reminderAt == null
                        ? 'Nije postavljen'
                        : reminderAt!.toLocal().toString().split('.').first,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reminderAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setLocal(() => reminderAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                            initialDate:
                                reminderAt ??
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d == null) return;
                          if (!ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: reminderAt != null
                                ? TimeOfDay.fromDateTime(reminderAt!)
                                : const TimeOfDay(hour: 9, minute: 0),
                          );
                          final when = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t?.hour ?? 9,
                            t?.minute ?? 0,
                          );
                          setLocal(() => reminderAt = when);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || ctrl.text.trim().isEmpty) return false;

  final note =
      existing ??
      Note(uuid: db.newUuid(), hiveUuid: hiveUuid, content: ctrl.text.trim());
  note.content = ctrl.text.trim();
  note.reminderAt = reminderAt;
  note.touch();
  note.dateSynched = null;
  await db.upsertNote(note);
  await GroupSharedDataSync().syncFromNote(note);

  if (reminderAt != null) {
    final rem = Reminder(
      uuid: db.newUuid(),
      hiveUuid: hiveUuid,
      dueAt: reminderAt!,
      title: note.content,
    );
    await db.upsertReminder(rem);
    await ReminderService.instance.schedule(
      id: rem.uuid.hashCode & 0x7fffffff,
      title: await ReminderNotificationTitle.forHiveUuid(hiveUuid),
      body: note.content,
      when: reminderAt!,
      reminderUuid: rem.uuid,
    );
  }
  return true;
}

Future<bool> showNoteDetailsDialog(
  BuildContext context, {
  required Note note,
  required Future<void> Function() onEdit,
  required Future<void> Function() onDelete,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Napomena'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                [
                  note.dateCreated.toLocal().toString().split('.').first,
                  if (note.reminderAt != null)
                    'Podsetnik: ${note.reminderAt!.toLocal().toString().split('.').first}',
                ].join(' · '),
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted(ctx),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                softWrap: true,
                style: const TextStyle(height: 1.4, fontSize: 16),
              ),
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
            await onDelete();
          },
          child: Text('Obriši', style: TextStyle(color: Colors.red.shade700)),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await onEdit();
          },
          child: const Text('Izmeni'),
        ),
      ],
    ),
  );
  return true;
}

Future<bool> editHarvestDialog(
  BuildContext context, {
  required String hiveUuid,
  Harvest? existing,
}) async {
  final db = AppDatabase.instance;
  String pastureType = existing?.pastureType ?? pastureTypes.first;
  if (!pastureTypes.contains(pastureType)) pastureType = pastureTypes.last;
  final amountCtrl = TextEditingController(
    text: existing != null ? '${existing.amountKg}' : '',
  );
  DateTime collectedAt = existing?.collectedAt ?? DateTime.now();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(existing == null ? 'Dodaj prinos' : 'Izmeni prinos'),
        content: FormSpacedColumn(
          children: [
            DropdownButtonFormField<String>(
              initialValue: pastureType,
              items: pastureTypes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setLocal(() => pastureType = v ?? pastureType),
              decoration: const InputDecoration(labelText: 'Paša'),
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Količina (kg)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Datum'),
              subtitle: Text(collectedAt.toLocal().toString().split(' ').first),
              trailing: IconButton(
                icon: const Icon(Icons.event),
                onPressed: () async {
                  final next = await showDatePicker(
                    context: ctx,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 3650),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: collectedAt,
                  );
                  if (next == null) return;
                  setLocal(
                    () => collectedAt = DateTime(
                      next.year,
                      next.month,
                      next.day,
                      collectedAt.hour,
                      collectedAt.minute,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  final kg = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
  if (existing == null) {
    await db.upsertHarvest(
      Harvest(
        uuid: db.newUuid(),
        hiveUuid: hiveUuid,
        pastureType: pastureType,
        amountKg: kg,
        collectedAt: collectedAt,
        harvestYear: collectedAt.year,
      ),
    );
  } else {
    existing.pastureType = pastureType;
    existing.amountKg = kg;
    existing.collectedAt = collectedAt;
    existing.harvestYear = collectedAt.year;
    existing.touch();
    existing.dateSynched = null;
    await db.upsertHarvest(existing);
    await GroupSharedDataSync().syncFromHarvest(existing);
  }
  return true;
}

String inspectionValueLabel(Map<String, String> labels, String value) =>
    labels[value] ?? value;

String inspectionSummaryLine(Inspection inspection) {
  final summary = inspection.summary?.trim();
  if (summary != null && summary.isNotEmpty) return summary;
  final parts = <String>[
    inspectionValueLabel(inspectionOutcomeStatuses, inspection.outcomeStatus),
    'matica ${inspectionValueLabel(inspectionQueenStatuses, inspection.queenStatus).toLowerCase()}',
  ];
  return parts.join(' · ');
}

String inspectionSourceLabel(Inspection inspection) {
  if (inspection.sourceType == null || inspection.sourceType!.isEmpty) {
    return 'Ručno';
  }
  return inspectionSourceTypes[inspection.sourceType!] ??
      inspection.sourceType!;
}

Future<bool> editInspectionDialog(
  BuildContext context, {
  required String hiveUuid,
  Inspection? existing,
  String? sourceType,
  String? sourceGroupHiveUuid,
  String? sourceReminderUuid,
  DateTime? initialInspectedAt,
  String? initialSummary,
}) async {
  final db = AppDatabase.instance;
  final summaryCtrl = TextEditingController(
    text: existing?.summary ?? initialSummary ?? '',
  );
  DateTime inspectedAt =
      existing?.inspectedAt ?? initialInspectedAt ?? DateTime.now();
  DateTime? followUpAt = existing?.followUpAt;
  String outcome = existing?.outcomeStatus ?? 'OK';
  String queenStatus = existing?.queenStatus ?? 'NOT_CHECKED';
  String broodStatus = existing?.broodStatus ?? 'NOT_CHECKED';
  String foodStatus = existing?.foodStatus ?? 'NOT_CHECKED';
  String temperStatus = normalizeInspectionTemperStatus(existing?.temperStatus);
  String healthStatus = existing?.healthStatus ?? 'NOT_CHECKED';
  String strengthStatus = existing?.strengthStatus ?? 'NOT_CHECKED';

  Future<DateTime?> pickDateTime(BuildContext ctx, DateTime initial) async {
    final d = await showDatePicker(
      context: ctx,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
    );
    if (d == null) return null;
    if (!ctx.mounted) return null;
    final t = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return DateTime(
      d.year,
      d.month,
      d.day,
      t?.hour ?? initial.hour,
      t?.minute ?? initial.minute,
    );
  }

  Widget dropdown({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.containsKey(value) ? value : options.keys.first,
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(
          existing == null
              ? 'Nova kontrola košnice'
              : 'Izmeni kontrolu košnice',
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: FormSpacedColumn(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final next = await pickDateTime(ctx, inspectedAt);
                      if (next != null) setLocal(() => inspectedAt = next);
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      'Kontrola: ${inspectedAt.toLocal().toString().split('.').first}',
                    ),
                  ),
                ),
                dropdown(
                  label: 'Ishod',
                  value: outcome,
                  options: inspectionOutcomeStatuses,
                  onChanged: (v) => setLocal(() => outcome = v),
                ),
                dropdown(
                  label: 'Matica',
                  value: queenStatus,
                  options: inspectionQueenStatuses,
                  onChanged: (v) => setLocal(() => queenStatus = v),
                ),
                dropdown(
                  label: 'Leglo',
                  value: broodStatus,
                  options: inspectionChecklistStatuses,
                  onChanged: (v) => setLocal(() => broodStatus = v),
                ),
                dropdown(
                  label: 'Jačina društva',
                  value: strengthStatus,
                  options: inspectionStrengthStatuses,
                  onChanged: (v) => setLocal(() => strengthStatus = v),
                ),
                dropdown(
                  label: 'Hrana',
                  value: foodStatus,
                  options: inspectionChecklistStatuses,
                  onChanged: (v) => setLocal(() => foodStatus = v),
                ),
                dropdown(
                  label: 'Temperament',
                  value: temperStatus,
                  options: inspectionTemperStatuses,
                  onChanged: (v) => setLocal(() => temperStatus = v),
                ),
                dropdown(
                  label: 'Zdravlje',
                  value: healthStatus,
                  options: inspectionHealthStatuses,
                  onChanged: (v) => setLocal(() => healthStatus = v),
                ),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Sažetak / napomena',
                    hintText: 'Upišite zapažanja sa pregleda...',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kontrolni podsetnik'),
                  subtitle: Text(
                    followUpAt == null
                        ? 'Nije postavljen'
                        : followUpAt!.toLocal().toString().split('.').first,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (followUpAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setLocal(() => followUpAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.alarm_add),
                        onPressed: () async {
                          final base =
                              followUpAt ??
                              inspectedAt.add(const Duration(days: 7));
                          final next = await pickDateTime(ctx, base);
                          if (next != null) setLocal(() => followUpAt = next);
                        },
                      ),
                    ],
                  ),
                ),
                if ((existing?.sourceType ?? sourceType) != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Izvor: ${inspectionSourceTypes[(existing?.sourceType ?? sourceType)!] ?? (existing?.sourceType ?? sourceType)!}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;

  final inspection =
      existing ??
      Inspection(
        uuid: db.newUuid(),
        hiveUuid: hiveUuid,
        inspectedAt: inspectedAt,
      );
  inspection.hiveUuid = hiveUuid;
  inspection.inspectedAt = inspectedAt;
  inspection.summary = summaryCtrl.text.trim().isEmpty
      ? null
      : summaryCtrl.text.trim();
  inspection.outcomeStatus = outcome;
  inspection.queenStatus = queenStatus;
  inspection.broodStatus = broodStatus;
  inspection.foodStatus = foodStatus;
  inspection.temperStatus = temperStatus;
  inspection.healthStatus = healthStatus;
  inspection.strengthStatus = strengthStatus;
  inspection.followUpAt = followUpAt;
  inspection.sourceType = existing?.sourceType ?? sourceType;
  inspection.sourceGroupHiveUuid =
      existing?.sourceGroupHiveUuid ?? sourceGroupHiveUuid;
  inspection.sourceReminderUuid =
      existing?.sourceReminderUuid ?? sourceReminderUuid;
  inspection.touch();
  inspection.dateSynched = null;
  await db.upsertInspection(inspection);

  final existingReminder = await db.reminderByInspection(inspection.uuid);
  if (followUpAt != null) {
    final reminder =
        existingReminder ??
        Reminder(
          uuid: db.newUuid(),
          hiveUuid: hiveUuid,
          inspectionUuid: inspection.uuid,
          dueAt: followUpAt!,
          title: inspection.summary ?? 'Kontrola košnice',
        );
    reminder.hiveUuid = hiveUuid;
    reminder.inspectionUuid = inspection.uuid;
    reminder.dueAt = followUpAt!;
    reminder.title = inspection.summary ?? 'Kontrola košnice';
    reminder.completed = false;
    reminder.touch();
    reminder.dateSynched = null;
    await db.upsertReminder(reminder);
    await ReminderService.instance.schedule(
      id: reminder.uuid.hashCode & 0x7fffffff,
      title: await ReminderNotificationTitle.forHiveUuid(hiveUuid),
      body: reminder.title,
      when: followUpAt!,
      reminderUuid: reminder.uuid,
    );
  } else if (existingReminder != null) {
    existingReminder.dateDeleted = DateTime.now();
    existingReminder.touch();
    existingReminder.dateSynched = null;
    await db.upsertReminder(existingReminder);
    await ReminderService.instance.cancel(
      existingReminder.uuid.hashCode & 0x7fffffff,
    );
  }
  return true;
}
