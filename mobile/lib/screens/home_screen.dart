import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/locale_service.dart';
import '../services/notification_nav.dart';
import '../services/push_device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/apiary_edit_dialog.dart';
import '../widgets/sync_warning_banner.dart';
import 'apiary_screen.dart';
import 'group_screen.dart';
import 'hive_search_screen.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

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
    PushDeviceService(widget.api).start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNav.flushPending();
    });
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.homeGradient(context),
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
                    Expanded(child: Text(l10n.appName, style: AppTheme.brandTitle(size: 34, context: context))),
                    IconButton(
                      tooltip: l10n.settings,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen(api: widget.api)),
                      ).then((_) => _reload()),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  l10n.myApiaryHives(_totalHives),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
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
                                  color: AppTheme.card(context),
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
                                                if (a.location != null)
                                                  Text(a.location!, style: TextStyle(color: AppTheme.muted(context))),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${l10n.total}\n$count',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                                          ),
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
                      Text(l10n.hiveGroups, style: AppTheme.brandTitle(context: context, size: 24)),
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
