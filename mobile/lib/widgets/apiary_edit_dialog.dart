import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'form_spaced_column.dart';

/// Dijalog za kreiranje ili izmenu pčelinjaka. Vraća sačuvani zapis ili null.
Future<Apiary?> showApiaryEditor(
  BuildContext context, {
  Apiary? existing,
}) async {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final locCtrl = TextEditingController(text: existing?.location ?? '');
  final officialIdCtrl = TextEditingController(text: existing?.officialId ?? '');

  late Color selectedColor;
  if (existing != null) {
    selectedColor = _parseHex(existing.color) ?? AppColors.apiaryPalette.first;
  } else {
    final nextWork = await AppDatabase.instance.nextWorkNumber();
    selectedColor = AppColors.apiaryPalette[(nextWork - 1) % AppColors.apiaryPalette.length];
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(isEdit ? 'Izmena pčelinjaka' : 'Novi pčelinjak'),
          content: SingleChildScrollView(
            child: FormSpacedColumn(
              children: [
                if (isEdit)
                  Text(
                    'Radni broj: ${existing.workNumber}',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: selectedColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Naziv'),
                ),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Lokacija (opciono)'),
                ),
                TextField(
                  controller: officialIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID broj pčelinjaka (Prilog 4)',
                    hintText: 'npr. 12 cifara',
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Boja', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in AppColors.apiaryPalette)
                          InkWell(
                            onTap: () => setLocal(() => selectedColor = c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor.toARGB32() == c.toARGB32() ? AppColors.ink : Colors.white,
                                  width: selectedColor.toARGB32() == c.toARGB32() ? 3 : 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
            ),
          ],
        );
      },
    ),
  );

  if (ok != true || nameCtrl.text.trim().isEmpty) return null;

  final db = AppDatabase.instance;
  final hex = selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
  final location = locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim();
  final officialId = officialIdCtrl.text.replaceAll(RegExp(r'\D'), '');
  final officialIdValue = officialId.isEmpty ? null : officialId;

  if (isEdit) {
    existing.name = nameCtrl.text.trim();
    existing.location = location;
    existing.officialId = officialIdValue;
    existing.color = '#$hex';
    existing.touch();
    existing.dateSynched = null;
    await db.upsertApiary(existing);
    return existing;
  }

  final work = await db.nextWorkNumber();
  final a = Apiary(
    uuid: db.newUuid(),
    name: nameCtrl.text.trim(),
    location: location,
    workNumber: work,
    color: '#$hex',
    sortOrder: work,
    officialId: officialIdValue,
  );
  await db.upsertApiary(a);
  return a;
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  } catch (_) {
    return null;
  }
}
