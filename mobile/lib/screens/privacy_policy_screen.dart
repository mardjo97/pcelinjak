import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/system_insets.dart';
import '../widgets/home_fab.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, settingsScrollBottom(context)),
        children: [
          Text(l10n.privacyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.privacyUpdated, style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Text(l10n.privacyBody, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
