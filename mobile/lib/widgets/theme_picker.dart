import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.preference;
        return DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          decoration: InputDecoration(
            labelText: l10n.theme,
            prefixIcon: const Icon(Icons.brightness_6_outlined),
          ),
          items: [
            for (final code in const ['system', 'light', 'dark'])
              DropdownMenuItem(
                value: code,
                child: Text(ThemeController.labelFor(l10n, code)),
              ),
          ],
          onChanged: (v) {
            if (v != null) controller.setPreference(v);
          },
        );
      },
    );
  }
}
