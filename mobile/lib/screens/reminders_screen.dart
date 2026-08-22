import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/reminder_notification_title.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../utils/system_insets.dart';
import '../widgets/home_fab.dart';
import 'reminder_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.initialReminderUuid});

  /// Ako je setovan, odmah otvara detalj (npr. iz notifikacije).
  final String? initialReminderUuid;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final db = AppDatabase.instance;
  final _fmt = DateFormat('dd.MM.yyyy. HH:mm');
  List<Reminder> _items = [];
  final Map<String, Hive> _hives = {};
  bool _showHistory = false;
  bool _loading = true;
  /// null = bez filtera; 'today' | 'tomorrow' — međusobno isključivo
  String? _dayFilter;

  @override
  void initState() {
    super.initState();
    _reload().then((_) {
      final uuid = widget.initialReminderUuid;
      if (uuid != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReminderDetailScreen(reminderUuid: uuid)),
        );
      }
    });
  }

  DateTime get _todayStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Reminder> get _visible {
    if (_dayFilter == null) return _items;
    final today = _todayStart;
    final tomorrow = today.add(const Duration(days: 1));
    return _items.where((r) {
      final d = r.dueAt.toLocal();
      if (_dayFilter == 'today') return _isSameDay(d, today);
      if (_dayFilter == 'tomorrow') return _isSameDay(d, tomorrow);
      return true;
    }).toList();
  }

  void _toggleDayFilter(String day) {
    setState(() {
      _dayFilter = _dayFilter == day ? null : day;
    });
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await db.listReminders(history: _showHistory);
    final hives = <String, Hive>{};
    for (final r in list) {
      final id = r.hiveUuid;
      if (id != null && !hives.containsKey(id)) {
        final h = await db.findHiveByUuid(id);
        if (h != null) hives[id] = h;
      }
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _hives
        ..clear()
        ..addAll(hives);
      _loading = false;
    });
  }

  Future<void> _complete(Reminder r) async {
    r.completed = true;
    r.dateModified = DateTime.now();
    r.dateSynched = null;
    await db.upsertReminder(r);
    await ReminderService.instance.cancel(r.uuid.hashCode & 0x7fffffff);
    await _reload();
  }

  Future<void> _reactivate(Reminder r) async {
    r.completed = false;
    r.dateModified = DateTime.now();
    r.dateSynched = null;
    await db.upsertReminder(r);
    await ReminderService.instance.schedule(
      id: r.uuid.hashCode & 0x7fffffff,
      title: await ReminderNotificationTitle.forHiveUuid(r.hiveUuid),
      body: r.title,
      when: r.dueAt,
      reminderUuid: r.uuid,
    );
    if (!mounted) return;
    setState(() => _showHistory = false);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).reminderReactivated)),
    );
  }

  Future<void> _openDetail(Reminder r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReminderDetailScreen(reminderUuid: r.uuid)),
    );
    _reload();
  }

  String _metaLine(AppLocalizations l10n, Reminder r) {
    final hive = r.hiveUuid != null ? _hives[r.hiveUuid!] : null;
    final parts = <String>[_fmt.format(r.dueAt.toLocal())];
    if (hive != null) parts.add(l10n.hiveBarcode(hive.barcode));
    if (_isOverdue(r) && !r.completed) parts.insert(0, l10n.overdue);
    return parts.join(' · ');
  }

  bool _isOverdue(Reminder r) {
    return !r.completed && r.dueAt.isBefore(DateTime.now());
  }

  Widget _buildList() {
    final l10n = AppLocalizations.of(context);
    final visible = _visible;
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _showHistory ? l10n.remindersEmptyHistory : l10n.remindersEmptyUpcoming,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      final label = _dayFilter == 'today' ? l10n.today : l10n.tomorrow;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.remindersNoneForDay(label.toLowerCase()),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, fabClearancePadding(context)),
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = visible[i];
        final overdue = _isOverdue(r);
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return Material(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openDetail(r),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: overdue
                        ? (AppTheme.isDark(context) ? Colors.red.shade900 : Colors.red.shade100)
                        : AppTheme.tintedSurface(
                            context,
                            r.completed ? AppColors.mist : AppColors.honeySoft,
                          ),
                    foregroundColor: overdue
                        ? (AppTheme.isDark(context) ? Colors.red.shade200 : Colors.red.shade800)
                        : (AppTheme.isDark(context) ? onSurface : AppColors.meadowDark),
                    child: Icon(r.completed ? Icons.check : Icons.alarm),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _metaLine(l10n, r),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: overdue
                                ? (AppTheme.isDark(context) ? Colors.red.shade300 : Colors.red.shade700)
                                : AppTheme.muted(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.title,
                          softWrap: true,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            decoration: r.completed ? TextDecoration.lineThrough : null,
                            color: r.completed ? AppTheme.muted(context) : onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_showHistory && !r.completed)
                    IconButton(
                      tooltip: l10n.markDone,
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _complete(r),
                    )
                  else if (_showHistory && r.completed)
                    IconButton(
                      tooltip: l10n.restoreActive,
                      icon: const Icon(Icons.undo),
                      onPressed: () => _reactivate(r),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 8, right: 8),
                      child: Icon(Icons.chevron_right),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.remindersShowHistory),
            subtitle: Text(_showHistory ? l10n.remindersCompletedList : l10n.remindersUpcomingList),
            value: _showHistory,
            activeThumbColor: AppColors.meadow,
            onChanged: (v) {
              setState(() {
                _showHistory = v;
                _dayFilter = null;
              });
              _reload();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.today),
                  selected: _dayFilter == 'today',
                  selectedColor: AppColors.meadow,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: AppTheme.chipLabel(
                      context,
                      selected: _dayFilter == 'today',
                      accent: AppColors.meadowDark,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => _toggleDayFilter('today'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.tomorrow),
                  selected: _dayFilter == 'tomorrow',
                  selectedColor: AppColors.meadow,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: AppTheme.chipLabel(
                      context,
                      selected: _dayFilter == 'tomorrow',
                      accent: AppColors.meadowDark,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => _toggleDayFilter('tomorrow'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator()) : _buildList(),
          ),
        ],
      ),
    );
  }
}
