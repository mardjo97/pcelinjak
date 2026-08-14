import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auto_sync_service.dart';
import '../services/locale_service.dart';
import '../services/notification_nav.dart';
import '../services/push_device_service.dart';
import '../theme/app_theme.dart';
import '../utils/system_insets.dart';
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
  bool _loggedIn = false;
  bool _initialLoad = true;

  static const _groupsAccent = Color(0xFF6B46C1);
  static const _addAccent = Color(0xFF2B6CB0);

  @override
  void initState() {
    super.initState();
    AutoSyncService.instance.addListener(_onSyncChanged);
    _reload();
    PushDeviceService(widget.api).start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNav.flushPending();
    });
  }

  @override
  void dispose() {
    AutoSyncService.instance.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    setState(() {});
    if (!AutoSyncService.instance.isFullSyncing) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (_initialLoad && mounted) setState(() => _loading = true);
    await db.dedupeWorkGroups();
    final apiaries = await db.listApiaries();
    final total = await db.hiveCount();
    final pending = await db.pendingReminders();
    final unsynced = await db.unsyncedCount();
    final loggedIn = await widget.api.isLoggedIn();
    final counts = <String, int>{};
    for (final type in workGroupTypes.keys) {
      counts[type] = await db.groupHiveCountByType(type);
    }
    if (!mounted) return;
    setState(() {
      _apiaries = apiaries;
      _totalHives = total;
      _pendingReminders = pending.length;
      _unsynced = unsynced;
      _loggedIn = loggedIn;
      _groupCounts
        ..clear()
        ..addAll(counts);
      _loading = false;
      _initialLoad = false;
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HiveSearchScreen()),
    );
    _reload();
  }

  Future<void> _openReminders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemindersScreen()),
    );
    _reload();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return AppColors.meadow;
    }
  }

  /// Section backdrop: darker than cards in dark mode so lists don't melt together.
  Color _sectionTint(BuildContext context, Color lightTint) {
    if (AppTheme.isDark(context)) {
      return const Color(0xFF18241E);
    }
    return lightTint;
  }

  /// Apiary card fill: slightly lifted above the section panel in dark mode.
  Color _apiaryCardColor(BuildContext context) {
    if (AppTheme.isDark(context)) {
      return const Color(0xFF2A3A32);
    }
    return AppTheme.card(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomBarWidth = MediaQuery.sizeOf(context).width - 32;
    final remindersLabel = _pendingReminders == 0
        ? l10n.reminders
        : l10n.remindersCount(_pendingReminders);
    final apiaryCardColor = _apiaryCardColor(context);

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
                    Expanded(
                      child: Text(
                        l10n.appName,
                        style: AppTheme.brandTitle(size: 34, context: context),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.reports,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportsScreen(api: widget.api),
                        ),
                      ).then((_) => _reload()),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.settings,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(api: widget.api),
                        ),
                      ).then((_) => _reload()),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  l10n.myApiaryHives(_totalHives),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
                ),
              ),
              if (!_loggedIn)
                SyncWarningBanner(
                  count: 1,
                  compact: true,
                  message: l10n.offlineDataWarning,
                  actionLabel: l10n.goToLogin,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(api: widget.api),
                      ),
                    ).then((_) => _reload());
                  },
                )
              else
                SyncWarningBanner(
                  count: _unsynced,
                  api: widget.api,
                  compact: true,
                ),
              if (AutoSyncService.instance.showSyncBanner)
                const _SyncingBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, fabClearancePadding(context)),
                    children: [
                      _HomeSectionPanel(
                        tint: _sectionTint(context, AppColors.mist),
                        borderColor: AppColors.meadow.withValues(alpha: 0.28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HomeSectionHeader(
                              icon: Icons.home_work_outlined,
                              accent: AppTheme.isDark(context)
                                  ? const Color(0xFF6FBF8F)
                                  : AppColors.meadowDark,
                              title: l10n.apiariesSection,
                              subtitle: l10n.apiariesSectionHint,
                            ),
                            const SizedBox(height: 12),
                            if (_loading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_apiaries.isEmpty)
                              Material(
                                color: apiaryCardColor,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    l10n.noApiariesYet,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
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
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Material(
                                        color: apiaryCardColor,
                                        elevation: 0,
                                        borderRadius: BorderRadius.circular(16),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ApiaryScreen(
                                                  apiaryUuid: a.uuid,
                                                ),
                                              ),
                                            );
                                            _reload();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border(
                                                left: BorderSide(
                                                  color: color,
                                                  width: 8,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: color
                                                      .withValues(alpha: 0.14),
                                                  foregroundColor: color,
                                                  child: const Icon(
                                                    Icons.home_work_outlined,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        l10n.apiaryLabel(
                                                          a.workNumber,
                                                        ),
                                                        style: TextStyle(
                                                          color: color,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 0.6,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        a.name,
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.titleLarge,
                                                      ),
                                                      if (a.location != null)
                                                        Text(
                                                          a.location!,
                                                          style: TextStyle(
                                                            color:
                                                                AppTheme.muted(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '${l10n.total}\n$count',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: scheme.onSurface,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: l10n.edit,
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: color,
                                                  ),
                                                  onPressed: () =>
                                                      _editApiary(a),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _HomeSectionPanel(
                        tint: _sectionTint(context, const Color(0xFFF0EAFB)),
                        borderColor: _groupsAccent.withValues(alpha: 0.28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HomeSectionHeader(
                              icon: Icons.folder_special_outlined,
                              accent: AppTheme.isDark(context)
                                  ? const Color(0xFFB794F4)
                                  : _groupsAccent,
                              title: l10n.hiveGroups,
                              subtitle: l10n.hiveGroupsHint,
                            ),
                            const SizedBox(height: 12),
                            ...workGroupTypes.keys.map((key) {
                              final count = _groupCounts[key] ?? 0;
                              final color = workGroupColor(key);
                              final title = LocaleController.workGroupTitle(
                                l10n,
                                key,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GroupScreen(groupType: key),
                                        ),
                                      );
                                      _reload();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border(
                                          left: BorderSide(
                                            color: color,
                                            width: 8,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
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
                                          Icon(
                                            Icons.chevron_right,
                                            color: color,
                                          ),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: bottomBarWidth,
        child: Row(
          children: [
            Expanded(
              child: _HomeBottomAction(
                color: AppColors.meadowDark,
                icon: Icons.search,
                label: l10n.findHive,
                onPressed: _findHive,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeBottomAction(
                color: AppColors.honey,
                icon: Icons.alarm,
                label: remindersLabel,
                onPressed: _openReminders,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeBottomAction(
                color: _addAccent,
                icon: Icons.add,
                label: l10n.addApiary,
                onPressed: _addApiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? const Color(0xFF6FBF8F) : AppColors.meadowDark;
    final bg = dark ? const Color(0xFF1E3328) : const Color(0xFFE8F5E9);
    return Material(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            minHeight: 2,
            color: fg,
            backgroundColor: bg,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.syncing,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBottomAction extends StatelessWidget {
  const _HomeBottomAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionPanel extends StatelessWidget {
  const _HomeSectionPanel({
    required this.tint,
    required this.borderColor,
    required this.child,
  });

  final Color tint;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.brandTitle(context: context, size: 24),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
