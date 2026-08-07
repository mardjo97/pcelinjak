import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../services/auto_sync_service.dart';
import '../services/push_device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/language_picker.dart';
import 'home_screen.dart';
import 'privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _register = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final auth = AuthService(widget.api);
      if (_register) {
        await auth.register(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
        if (!mounted) return;
        setState(() => _register = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registerCheckEmailActivation), duration: const Duration(seconds: 6)),
        );
        return;
      }
      await auth.login(email: _email.text.trim(), password: _password.text);
      await AutoSyncService.instance.start();
      await PushDeviceService(widget.api).start();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _offline() async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.authGradient(context),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const Spacer(),
                  const LanguagePicker(compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.appName, style: AppTheme.brandTitle(context: context)),
              const SizedBox(height: 8),
              Text(
                _register ? l10n.authRegisterSubtitle : l10n.authLoginSubtitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 28),
              FormSpacedColumn(
                children: [
                  if (_register) ...[
                    TextField(controller: _name, decoration: InputDecoration(labelText: l10n.fullName)),
                    TextField(
                      controller: _phone,
                      decoration: InputDecoration(labelText: l10n.phone),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(labelText: l10n.email),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _password,
                    decoration: InputDecoration(labelText: l10n.password),
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? l10n.waiting : (_register ? l10n.signUp : l10n.signIn)),
              ),
              TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(_register ? l10n.haveAccount : l10n.createAccount),
              ),
              TextButton(onPressed: _offline, child: Text(l10n.continueOffline)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
                child: Text(l10n.privacyPolicy),
              ),
              const SizedBox(height: 12),
              Text(l10n.authDeviceNote, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
