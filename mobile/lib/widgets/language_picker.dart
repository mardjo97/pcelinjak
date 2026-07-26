import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

/// Izbor jezika (sistem / sr / en / hr / bs / cnr).
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = LocaleController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.preference;
        if (compact) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.language, color: AppColors.meadowDark),
              items: [
                for (final code in const ['system', 'sr', 'en', 'hr', 'bs', 'cnr'])
                  DropdownMenuItem(
                    value: code,
                    child: Text(LocaleController.labelFor(l10n, code)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) controller.setPreference(v);
              },
            ),
          );
        }

        return DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          decoration: InputDecoration(
            labelText: l10n.language,
            prefixIcon: const Icon(Icons.language),
          ),
          items: [
            for (final code in const ['system', 'sr', 'en', 'hr', 'bs', 'cnr'])
              DropdownMenuItem(
                value: code,
                child: Text(LocaleController.labelFor(l10n, code)),
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
