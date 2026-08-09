import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../services/auto_sync_service.dart';
import '../services/beekeeper_prefs.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/home_fab.dart';
import '../widgets/language_picker.dart';
import '../widgets/theme_picker.dart';
import 'auth_screen.dart';
import 'feedback_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _hidCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hidCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await widget.api.session();
    final loggedIn = await widget.api.isLoggedIn();
    final name = await BeekeeperPrefs.reportName(fallback: session['name']);
    final hid = await BeekeeperPrefs.hid();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = name;
      _hidCtrl.text = hid;
      _loggedIn = loggedIn;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await BeekeeperPrefs.setReportName(_nameCtrl.text);
      await BeekeeperPrefs.setHid(_hidCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => _DeleteAccountPasswordDialog(l10n: l10n),
    );
    if (password == null || !mounted) return;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordRequired)));
      return;
    }
    try {
      await AuthService(widget.api).deleteAccount(password: password);
      AutoSyncService.instance.stop();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Text(l10n.settingsIntro, style: Theme.of(context).textTheme.bodyMedium),
                _sectionTitle(l10n.settingsAppearance),
                const LanguagePicker(),
                const SizedBox(height: 12),
                const ThemePicker(),
                _sectionTitle(l10n.settingsReports),
                FormSpacedColumn(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: l10n.beekeeperName),
                      textCapitalization: TextCapitalization.words,
                    ),
                    TextField(
                      controller: _hidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.hidLabel,
                        hintText: l10n.hidHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? l10n.saving : l10n.save),
                ),
                _sectionTitle(l10n.settingsSupport),
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
                if (_loggedIn) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
                    label: Text(l10n.deleteAccount, style: TextStyle(color: Colors.red.shade700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DeleteAccountPasswordDialog extends StatefulWidget {
  const _DeleteAccountPasswordDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_DeleteAccountPasswordDialog> createState() => _DeleteAccountPasswordDialogState();
}

class _DeleteAccountPasswordDialogState extends State<_DeleteAccountPasswordDialog> {
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.deleteAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.deleteAccountConfirm),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.password),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _passwordCtrl.text),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }
}
