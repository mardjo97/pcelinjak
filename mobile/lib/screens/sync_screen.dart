import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../widgets/home_fab.dart';
import '../widgets/sync_warning_banner.dart';
import '../widgets/busy.dart';
import 'auth_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _loading = false;
  String? _message;
  int _unsynced = 0;

  @override
  void initState() {
    super.initState();
    _loadUnsynced();
  }

  Future<void> _loadUnsynced() async {
    final n = await AppDatabase.instance.unsyncedCount();
    if (!mounted) return;
    setState(() => _unsynced = n);
  }

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (!await widget.api.isLoggedIn()) {
        throw Exception('Niste prijavljeni. Vratite se na login.');
      }
      final msg = await SyncService(widget.api, AppDatabase.instance).fullSync();
      final left = await AppDatabase.instance.unsyncedCount();
      setState(() {
        _message = msg;
        _unsynced = left;
      });
    } on ApiException catch (e) {
      if (e.isDeviceMismatch) {
        await widget.api.clearSession();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deviceMismatch)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)),
          (_) => false,
        );
        return;
      }
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: BusyOverlay(
        busy: _loading,
        message: l10n.syncing,
        child: Column(
        children: [
          SyncWarningBanner(
            count: _unsynced,
            message: _unsynced > 0 ? l10n.unsyncedWaiting(_unsynced) : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.syncIntro),
                  if (_unsynced == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.syncAllDone,
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _sync,
                    child: BusyButtonChild(
                      busy: _loading,
                      label: l10n.sendToServer,
                      busyLabel: l10n.syncing,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(_message!),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
