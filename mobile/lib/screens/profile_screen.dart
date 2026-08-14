import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../services/auto_sync_service.dart';
import '../services/beekeeper_prefs.dart';
import '../utils/password_rules.dart';
import '../utils/system_insets.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/home_fab.dart';
import '../widgets/password_field.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hidCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _loggedIn = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _hidCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await widget.api.session();
    final loggedIn = await widget.api.isLoggedIn();
    final hid = await BeekeeperPrefs.hid();
    var first = session['firstName']?.trim() ?? '';
    var last = session['lastName']?.trim() ?? '';
    final name = session['name']?.trim() ?? '';
    if (first.isEmpty && last.isEmpty && name.isNotEmpty) {
      final i = name.indexOf(' ');
      if (i < 0) {
        first = name;
      } else {
        first = name.substring(0, i).trim();
        last = name.substring(i + 1).trim();
      }
    }
    if (first.isEmpty && last.isEmpty) {
      final report = await BeekeeperPrefs.reportName();
      if (report.isNotEmpty) {
        final i = report.indexOf(' ');
        if (i < 0) {
          first = report;
        } else {
          first = report.substring(0, i).trim();
          last = report.substring(i + 1).trim();
        }
      }
    }
    if (loggedIn) {
      try {
        final me = await widget.api.get('/me') as Map<String, dynamic>;
        first = (me['firstName'] as String?)?.trim() ?? first;
        last = (me['lastName'] as String?)?.trim() ?? last;
        _phoneCtrl.text = (me['phone'] as String?) ?? session['phone'] ?? '';
        _email = (me['email'] as String?) ?? session['email'] ?? '';
      } catch (_) {
        _phoneCtrl.text = session['phone'] ?? '';
        _email = session['email'] ?? '';
      }
    } else {
      _phoneCtrl.text = session['phone'] ?? '';
      _email = session['email'] ?? '';
    }
    if (!mounted) return;
    setState(() {
      _firstCtrl.text = first;
      _lastCtrl.text = last;
      _hidCtrl.text = hid;
      _loggedIn = loggedIn;
      _loading = false;
    });
  }

  bool _validPhone(String phone) {
    final t = phone.trim();
    if (t.isEmpty) return true;
    return RegExp(r'^\+?[0-9][0-9\s().-]{5,19}$').hasMatch(t);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nameRequired)));
      return;
    }
    if (!_validPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhone)));
      return;
    }
    setState(() => _saving = true);
    try {
      await BeekeeperPrefs.setHid(_hidCtrl.text);
      if (_loggedIn) {
        await AuthService(widget.api).updateProfile(
          firstName: first,
          lastName: last,
          phone: phone.isEmpty ? null : phone,
        );
      }
      await BeekeeperPrefs.setReportName('$first $last'.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaved)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(l10n: l10n),
    );
    if (result == null || !mounted) return;
    try {
      await AuthService(widget.api).changePassword(
        currentPassword: result.$1,
        newPassword: result.$2,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
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
      appBar: AppBar(title: Text(l10n.profile)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, settingsScrollBottom(context)),
              children: [
                Text(l10n.profileIntro, style: Theme.of(context).textTheme.bodyMedium),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_email, style: Theme.of(context).textTheme.titleSmall),
                ],
                _sectionTitle(l10n.profileAccount),
                FormSpacedColumn(
                  children: [
                    TextField(
                      controller: _firstCtrl,
                      decoration: InputDecoration(labelText: l10n.firstName),
                      textCapitalization: TextCapitalization.words,
                    ),
                    TextField(
                      controller: _lastCtrl,
                      decoration: InputDecoration(labelText: l10n.lastName),
                      textCapitalization: TextCapitalization.words,
                    ),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l10n.phone),
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
                if (_loggedIn) ...[
                  _sectionTitle(l10n.settingsDanger),
                  OutlinedButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: Text(l10n.changePassword),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
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
          PasswordField(
            controller: _passwordCtrl,
            label: l10n.password,
            autofocus: true,
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = widget.l10n;
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (current.isEmpty || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordRequired)));
      return;
    }
    final passwordError = PasswordRules.errorMessage(l10n, next);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordMismatch)));
      return;
    }
    Navigator.pop(context, (current, next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.changePassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(
              controller: _currentCtrl,
              label: l10n.currentPassword,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _newCtrl,
              label: l10n.newPassword,
              helperText: l10n.passwordHint,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _confirmCtrl,
              label: l10n.confirmPassword,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
