import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/locale_service.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/home_fab.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  Future<void> _prefillEmail() async {
    final session = await widget.api.session();
    if (!mounted) return;
    _emailCtrl.text = session['email'] ?? '';
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedbackRequired)));
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.api.post('/api/feedback', {
        'message': message,
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'appVersion': '1.0.0',
        'locale': LocaleController.instance.locale.languageCode,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedbackThanks)));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedback)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(l10n.feedbackIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          FormSpacedColumn(
            children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              TextField(
                controller: _messageCtrl,
                minLines: 5,
                maxLines: 10,
                maxLength: 4000,
                decoration: InputDecoration(
                  labelText: l10n.feedbackMessage,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? l10n.sending : l10n.sendFeedback),
          ),
        ],
      ),
    );
  }
}
