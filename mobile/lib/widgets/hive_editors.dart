import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../services/reminder_notification_title.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import 'form_spaced_column.dart';

Future<bool> confirmDialog(BuildContext context, String title, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Potvrdi')),
      ],
    ),
  );
  return ok == true;
}

String notePreviewLine(Note n) {
  final line = n.content.split(RegExp(r'\r?\n')).firstWhere((s) => s.trim().isNotEmpty, orElse: () => n.content);
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
                  decoration: const InputDecoration(hintText: 'Upišite napomenu…'),
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
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                            initialDate: reminderAt ?? DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d == null) return;
                          if (!ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: reminderAt != null
                                ? TimeOfDay.fromDateTime(reminderAt!)
                                : const TimeOfDay(hour: 9, minute: 0),
                          );
                          final when = DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0);
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
        ],
      ),
    ),
  );
  if (ok != true || ctrl.text.trim().isEmpty) return false;

  final note = existing ??
      Note(
        uuid: db.newUuid(),
        hiveUuid: hiveUuid,
        content: ctrl.text.trim(),
      );
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
              Text(note.content, softWrap: true, style: const TextStyle(height: 1.4, fontSize: 16)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zatvori')),
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
  final amountCtrl = TextEditingController(text: existing != null ? '${existing.amountKg}' : '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(existing == null ? 'Dodaj prinos' : 'Izmeni prinos'),
        content: FormSpacedColumn(
          children: [
            DropdownButtonFormField<String>(
              initialValue: pastureType,
              items: pastureTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setLocal(() => pastureType = v ?? pastureType),
              decoration: const InputDecoration(labelText: 'Paša'),
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Količina (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
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
  if (ok != true) return false;
  final kg = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
  if (existing == null) {
    await db.upsertHarvest(Harvest(
      uuid: db.newUuid(),
      hiveUuid: hiveUuid,
      pastureType: pastureType,
      amountKg: kg,
      collectedAt: DateTime.now(),
      harvestYear: DateTime.now().year,
    ));
  } else {
    existing.pastureType = pastureType;
    existing.amountKg = kg;
    existing.touch();
    existing.dateSynched = null;
    await db.upsertHarvest(existing);
    await GroupSharedDataSync().syncFromHarvest(existing);
  }
  return true;
}
