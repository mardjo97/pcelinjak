import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';

class AutorotationTile extends StatelessWidget {
  const AutorotationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.screen_rotation),
          title: Text(l10n.settingsAutorotation),
          subtitle: Text(l10n.settingsAutorotationSubtitle),
          value: controller.autorotation,
          onChanged: controller.setAutorotation,
        );
      },
    );
  }
}
