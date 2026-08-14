import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import 'api_client.dart';
import 'auth_sync.dart';

/// Automatski šalje lokalne izmene na server kada postoji veza.
/// Bez veze sve ostaje lokalno (offline-first).
class AutoSyncService with WidgetsBindingObserver, ChangeNotifier {
  AutoSyncService._();
  static final AutoSyncService instance = AutoSyncService._();

  ApiClient? _api;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounce;
  bool _started = false;
  bool _running = false;
  bool _fullRunning = false;
  bool _showBanner = false;
  bool _pendingAfterRun = false;
  bool _wantFull = false;
  bool _wantBanner = false;

  /// True while a full pull/push cycle is in progress.
  bool get isFullSyncing => _fullRunning;

  /// Banner only for explicit full sync (login / Sync screen), not connectivity or resume.
  bool get showSyncBanner => _showBanner;

  void attach(ApiClient api) {
    _api = api;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    AppDatabase.instance.onLocalChange = schedulePush;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (_hasNetwork(results)) {
        scheduleFullSync();
      }
    });
    final current = await Connectivity().checkConnectivity();
    if (_hasNetwork(current)) {
      scheduleFullSync();
    }
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _debounce?.cancel();
    if (AppDatabase.instance.onLocalChange == schedulePush) {
      AppDatabase.instance.onLocalChange = null;
    }
  }

  /// Posle lokalne izmene — pošalji dirty zapise (debounce).
  void schedulePush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_run());
    });
  }

  /// Povratak mreže / app resume — push + pull, without the home banner.
  void scheduleFullSync() {
    _wantFull = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_run());
    });
  }

  /// Odmah uradi full sync (npr. posle logina) i prikaži baner.
  Future<void> syncNow() async {
    _debounce?.cancel();
    _wantFull = true;
    _wantBanner = true;
    await _run();
  }

  Future<void> _run() async {
    if (_running) {
      _pendingAfterRun = true;
      return;
    }
    final api = _api;
    if (api == null) return;
    if (!await api.isLoggedIn()) return;

    final results = await Connectivity().checkConnectivity();
    if (!_hasNetwork(results)) return;

    final doFull = _wantFull;
    final showBanner = doFull && _wantBanner;
    _wantFull = false;
    _wantBanner = false;
    _running = true;
    _fullRunning = doFull;
    _showBanner = showBanner;
    if (doFull) notifyListeners();
    try {
      final sync = SyncService(api, AppDatabase.instance);
      if (doFull) {
        await sync.fullSync();
      } else {
        await sync.pushPending();
      }
    } catch (_) {
      // Nema veze ili greška servera — ostaje lokalno.
    } finally {
      _running = false;
      _fullRunning = false;
      _showBanner = false;
      if (doFull) {
        notifyListeners();
      }
      if (_pendingAfterRun) {
        _pendingAfterRun = false;
        schedulePush();
      }
    }
  }

  static bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleFullSync();
    }
  }
}
