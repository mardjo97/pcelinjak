import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../services/auto_sync_service.dart';
import '../utils/system_insets.dart';
import '../widgets/autorotation_tile.dart';
import '../widgets/home_fab.dart';
import '../widgets/language_picker.dart';
import '../widgets/text_scale_picker.dart';
import '../widgets/theme_picker.dart';
import 'auth_screen.dart';
import 'feedback_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    widget.api.isLoggedIn().then((v) {
      if (mounted) setState(() => _loggedIn = v);
    });
  }

  Future<void> _logout() async {
    AutoSyncService.instance.stop();
    await AuthService(widget.api).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
      (_) => false,
    );
  }

  void _goToLogin() async {
    final l10n = AppLocalizations.of(context);
    final hiveCount = await AppDatabase.instance.hiveCount();
    final apiaries = await AppDatabase.instance.listApiaries();
    final hasLocal = hiveCount > 0 || apiaries.isNotEmpty;
    if (!mounted) return;
    if (hasLocal) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.goToLogin),
          content: Text(l10n.loginReplaceDataConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.goToLogin),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
      (_) => false,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, settingsScrollBottom(context)),
        children: [
          Text(l10n.settingsIntro, style: Theme.of(context).textTheme.bodyMedium),
          _sectionTitle(l10n.settingsAppearance),
          const LanguagePicker(),
          const SizedBox(height: 12),
          const ThemePicker(),
          const SizedBox(height: 12),
          const TextScalePicker(),
          const SizedBox(height: 8),
          const AutorotationTile(),
          _sectionTitle(l10n.settingsSupport),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api)),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.feedback_outlined),
            title: Text(l10n.feedback),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FeedbackScreen(api: widget.api)),
              );
            },
          ),
          _sectionTitle(l10n.settingsDanger),
          OutlinedButton.icon(
            onPressed: _loggedIn ? _logout : _goToLogin,
            icon: Icon(_loggedIn ? Icons.logout : Icons.login),
            label: Text(_loggedIn ? l10n.logout : l10n.goToLogin),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
