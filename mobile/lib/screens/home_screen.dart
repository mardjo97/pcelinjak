import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_sync.dart';
import '../services/auto_sync_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apiary_edit_dialog.dart';
import '../widgets/sync_warning_banner.dart';
import 'apiary_screen.dart';
import 'auth_screen.dart';
import 'group_screen.dart';
import 'hive_search_screen.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = AppDatabase.instance;
  List<Apiary> _apiaries = [];
  int _totalHives = 0;
  int _pendingReminders = 0;
  int _unsynced = 0;
  final Map<String, int> _groupCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final apiaries = await db.listApiaries();
    final total = await db.hiveCount();
    final pending = await db.pendingReminders();
    final unsynced = await db.unsyncedCount();
    final counts = <String, int>{};
    for (final g in await db.listWorkGroups()) {
      counts[g.groupType] = await db.groupHiveCount(g.uuid);
    }
    if (!mounted) return;
    setState(() {
      _apiaries = apiaries;
      _totalHives = total;
      _pendingReminders = pending.length;
      _unsynced = unsynced;
      _groupCounts
        ..clear()
        ..addAll(counts);
      _loading = false;
    });
  }

  Future<void> _addApiary() async {
    final a = await showApiaryEditor(context);
    if (a != null) await _reload();
  }

  Future<void> _editApiary(Apiary a) async {
    final updated = await showApiaryEditor(context, existing: a);
    if (updated != null) await _reload();
  }

  Future<void> _findHive() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const HiveSearchScreen()));
    _reload();
  }

  Future<void> _exportCodes() async {
    final l10n = AppLocalizations.of(context);
    if (_unsynced > 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.unsyncedTitle),
          content: Text(l10n.unsyncedExportBody(_unsynced)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.continueAction)),
          ],
        ),
      );
      if (go != true) return;
    }
    final hives = await db.listAllHives();
    final buf = StringBuffer('barkod;pcelinjak;rb;tip\n');
    for (final h in hives) {
      final a = await db.apiaryByUuid(h.apiaryUuid);
      buf.writeln('${h.barcode};${a?.name ?? ''};${h.orderNumber};${h.hiveType}');
    }
    await SharePlus.instance.share(ShareParams(text: buf.toString(), subject: l10n.barcodeShareSubject));
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return AppColors.meadow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5EE), AppColors.cream],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.appName, style: AppTheme.brandTitle(size: 34))),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SyncScreen(api: widget.api))).then((_) => _reload()),
                      icon: const Icon(Icons.cloud_upload_outlined),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'settings') {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(api: widget.api)));
                        }
                        if (v == 'export') await _exportCodes();
                        if (v == 'logout') {
                          AutoSyncService.instance.stop();
                          await AuthService(widget.api).logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen(api: widget.api)));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'settings', child: Text(l10n.settings)),
                        PopupMenuItem(value: 'export', child: Text(l10n.exportBarcodes)),
                        PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  l10n.myApiaryHives(_totalHives),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FilledButton.icon(
                  onPressed: _findHive,
                  icon: const Icon(Icons.search),
                  label: Text(l10n.findHive),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())).then((_) => _reload()),
                  icon: const Icon(Icons.alarm),
                  label: Text(
                    _pendingReminders == 0 ? l10n.reminders : l10n.remindersCount(_pendingReminders),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.meadowDark,
                    side: const BorderSide(color: AppColors.meadow, width: 1.5),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(api: widget.api))).then((_) => _reload()),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.reports),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.meadowDark,
                    side: const BorderSide(color: AppColors.meadow, width: 1.5),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              SyncWarningBanner(count: _unsynced, api: widget.api, compact: true),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      if (_loading)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else if (_apiaries.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              l10n.noApiariesYet,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      else
                        ..._apiaries.map((a) {
                          final color = _parseColor(a.color);
                          return FutureBuilder<int>(
                            future: db.hiveCount(a.uuid),
                            builder: (context, snap) {
                              final count = snap.data ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiaryScreen(apiaryUuid: a.uuid)));
                                      _reload();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border(left: BorderSide(color: color, width: 8)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(l10n.apiaryLabel(a.workNumber), style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                                                Text(a.name, style: Theme.of(context).textTheme.titleLarge),
                                                if (a.location != null) Text(a.location!),
                                              ],
                                            ),
                                          ),
                                          Text('${l10n.total}\n$count', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          IconButton(
                                            tooltip: l10n.edit,
                                            icon: Icon(Icons.edit_outlined, color: color),
                                            onPressed: () => _editApiary(a),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      const SizedBox(height: 24),
                      Text(l10n.hiveGroups, style: AppTheme.brandTitle(size: 24)),
                      const SizedBox(height: 8),
                      ...workGroupTypes.keys.map((key) {
                        final count = _groupCounts[key] ?? 0;
                        final color = workGroupColor(key);
                        final title = LocaleController.workGroupTitle(l10n, key);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupScreen(groupType: key)));
                                _reload();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border(left: BorderSide(color: color, width: 8)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: color),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addApiary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addApiary),
      ),
    );
  }
}
