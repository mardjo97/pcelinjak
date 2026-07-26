import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_fab.dart';
import 'group_screen.dart';
import 'hive_screen.dart';

class ReminderDetailScreen extends StatefulWidget {
  const ReminderDetailScreen({super.key, required this.reminderUuid});

  final String reminderUuid;

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  final db = AppDatabase.instance;
  final _fmt = DateFormat('dd.MM.yyyy. HH:mm');

  Reminder? _reminder;
  Hive? _hive;
  Apiary? _apiary;
  WorkGroupHive? _groupHive;
  WorkGroup? _group;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rem = await db.reminderByUuid(widget.reminderUuid);
    Hive? hive;
    Apiary? apiary;
    WorkGroupHive? groupHive;
    WorkGroup? group;

    if (rem != null) {
      if (rem.hiveUuid != null) {
        hive = await db.findHiveByUuid(rem.hiveUuid!);
        if (hive != null) {
          apiary = await db.apiaryByUuid(hive.apiaryUuid);
        }
      }
      if (rem.groupHiveUuid != null) {
        groupHive = await db.workGroupHiveByUuid(rem.groupHiveUuid!);
        if (groupHive != null) {
          group = await db.workGroupByUuid(groupHive.groupUuid);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _reminder = rem;
      _hive = hive;
      _apiary = apiary;
      _groupHive = groupHive;
      _group = group;
      _loading = false;
    });
  }

  Future<void> _complete() async {
    final r = _reminder;
    if (r == null || r.completed) return;
    r.completed = true;
    r.dateModified = DateTime.now();
    r.dateSynched = null;
    await db.upsertReminder(r);
    await ReminderService.instance.cancel(r.uuid.hashCode & 0x7fffffff);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Podsetnik označen kao urađen')),
    );
    await _load();
  }

  Future<void> _openHive() async {
    final hiveUuid = _reminder?.hiveUuid ?? _hive?.uuid;
    if (hiveUuid == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => HiveScreen(hiveUuid: hiveUuid)));
    _load();
  }

  Future<void> _openGroup() async {
    final type = _group?.groupType;
    if (type == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupScreen(groupType: type)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = _reminder;

    return Scaffold(
      appBar: AppBar(title: const Text('Podsetnik')),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? const Center(child: Text('Podsetnik nije pronađen.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    Text(
                      r.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: r.completed ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.schedule, _fmt.format(r.dueAt.toLocal())),
                    if (r.completed)
                      _infoRow(Icons.check_circle, 'Završeno', color: AppColors.meadow)
                    else if (r.dueAt.isBefore(DateTime.now()))
                      _infoRow(Icons.warning_amber, 'Zakasnelo', color: Colors.red.shade700),
                    const SizedBox(height: 20),
                    Text('Povezano', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (_hive != null) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.hive_outlined),
                        title: Text('Košnica ${_hive!.barcode}'),
                        subtitle: Text([
                          if (_apiary != null) _apiary!.name,
                          if (_hive!.hiveType.isNotEmpty) _hive!.hiveType,
                        ].where((e) => e.isNotEmpty).join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openHive,
                      ),
                    ] else
                      Text('Nema povezane košnice.', style: TextStyle(color: AppTheme.muted(context))),
                    if (_group != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(LocaleController.workGroupTitle(l10n, _group!.groupType)),
                        subtitle: _groupHive?.periodLabel != null && _groupHive!.periodLabel.isNotEmpty
                            ? Text(_groupHive!.periodLabel)
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openGroup,
                      ),
                    const SizedBox(height: 28),
                    if (!r.completed)
                      FilledButton.icon(
                        onPressed: _complete,
                        icon: const Icon(Icons.check),
                        label: const Text('Označi kao urađeno'),
                      ),
                    if (_hive != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openHive,
                        icon: const Icon(Icons.hive_outlined),
                        label: const Text('Otvori košnicu'),
                      ),
                    ],
                    if (_group != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openGroup,
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Otvori grupu'),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.muted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
