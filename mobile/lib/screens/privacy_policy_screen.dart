import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../utils/system_insets.dart';
import '../widgets/home_fab.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _assetSr = 'assets/privacy_policy.md';
  static const _assetEn = 'assets/privacy_policy_en.md';

  static String assetForLocale(Locale locale) =>
      locale.languageCode == 'en' ? _assetEn : _assetSr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final assetPath = assetForLocale(Localizations.localeOf(context));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: FutureBuilder<String>(
        key: ValueKey(assetPath),
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                settingsScrollBottom(context),
              ),
              children: [
                Text(l10n.privacyTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.privacyUpdated, style: theme.textTheme.bodySmall),
                const SizedBox(height: 20),
                Text(
                  l10n.privacyBody,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(
            data: snapshot.data!,
            selectable: true,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              settingsScrollBottom(context),
            ),
            onTapLink: (text, href, title) {
              if (href == null) {
                return;
              }
              final uri = Uri.tryParse(href);
              if (uri != null) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            styleSheet: MarkdownStyleSheet(
              h1: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h2: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h3: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
