import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';

class TextScalePicker extends StatelessWidget {
  const TextScalePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeController.instance;
    final options = <double, String>{
      ThemeController.textScaleSmall: l10n.settingsTextSmall,
      ThemeController.textScaleNormal: l10n.settingsTextNormal,
      ThemeController.textScaleLarge: l10n.settingsTextLarge,
      ThemeController.textScaleExtraLarge: l10n.settingsTextVeryLarge,
    };

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.textScaleFactor;
        final selected = options.keys.contains(value) ? value : ThemeController.textScaleNormal;
        return DropdownButtonFormField<double>(
          key: ValueKey(selected),
          initialValue: selected,
          decoration: InputDecoration(
            labelText: l10n.settingsTextSize,
            prefixIcon: const Icon(Icons.format_size),
          ),
          items: [
            for (final e in options.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) {
            if (v != null) controller.setTextScaleFactor(v);
          },
        );
      },
    );
  }
}
