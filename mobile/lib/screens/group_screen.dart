import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/hive_status_rules.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scan.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/home_fab.dart';
import 'hive_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.groupType});

  final String groupType;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final db = AppDatabase.instance;
  final _searchCtrl = TextEditingController();
  WorkGroup? _group;
  List<WorkGroupHive> _items = [];
  final Map<String, Hive> _hives = {};
  final Map<String, Apiary> _apiaries = {};
  final Map<String, Queen> _queens = {};
  /// ACTIVE | FINISHED | REMOVED | ALL
  String _filter = 'ACTIVE';
  Timer? _debounce;

  String title(BuildContext context) =>
      LocaleController.workGroupTitle(AppLocalizations.of(context), widget.groupType);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    var group = await db.workGroupByType(widget.groupType);
    if (group == null) {
      group = WorkGroup(uuid: db.newUuid(), groupType: widget.groupType);
      await db.upsertWorkGroup(group);
    }
    final items = await db.groupHives(group.uuid, filter: _filter);
    final map = <String, Hive>{};
    final apiaries = <String, Apiary>{};
    final queens = <String, Queen>{};
    for (final i in items) {
      final h = await db.findHiveByUuid(i.hiveUuid);
      if (h != null) {
        map[h.uuid] = h;
        if (!apiaries.containsKey(h.apiaryUuid)) {
          final a = await db.apiaryByUuid(h.apiaryUuid);
          if (a != null) apiaries[h.apiaryUuid] = a;
        }
        final q = await db.activeQueen(h.uuid);
        if (q != null) queens[h.uuid] = q;
      }
    }
    if (!mounted) return;
    setState(() {
      _group = group;
      _items = items;
      _hives
        ..clear()
        ..addAll(map);
      _apiaries
        ..clear()
        ..addAll(apiaries);
      _queens
        ..clear()
        ..addAll(queens);
    });
  }

  List<WorkGroupHive> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _items;

    final markedWanted = const ['markir', 'oznac', 'označ', 'marked', 'obelez', 'obelež']
        .any((k) => q.contains(k));
    final unmarkedWanted = const ['nemark', 'neoznac', 'neoznač', 'unmarked'].any((k) => q.contains(k));

    return _items.where((item) {
      final hive = _hives[item.hiveUuid];
      final apiary = hive == null ? null : _apiaries[hive.apiaryUuid];
      final queen = _queens[item.hiveUuid];
      final check = item.checkDate?.toLocal().toString().split(' ').first ?? '';
      final hay = [
        hive?.barcode ?? '',
        hive == null ? '' : '${hive.orderNumber}',
        hive?.hiveType ?? '',
        hive?.description ?? '',
        apiary?.name ?? '',
        apiary?.location ?? '',
        apiary == null ? '' : '${apiary.workNumber}',
        apiary == null ? '' : 'pčelinjak ${apiary.workNumber}',
        item.note ?? '',
        item.amount == null ? '' : '${item.amount}',
        item.amount == null ? '' : '${item.amount} kg',
        item.statusLabel,
        item.periodLabel,
        check,
        item.checkDate == null ? '' : 'provera $check',
        item.pastureType ?? _group?.pastureType ?? '',
        item.locationName ?? _group?.locationName ?? '',
        _group?.pastureType ?? '',
        _group?.locationName ?? '',
        queen?.queenYear?.toString() ?? '',
        queen?.origin ?? '',
        if (queen?.marked == true) ...['markirana', 'označena', 'marked'],
        if (queen != null && !queen.marked) ...['nemarkirana', 'neoznačena'],
        if (queen == null) 'bez matice',
      ].join(' ').toLowerCase();

      if (hay.contains(q)) return true;
      if (markedWanted && queen?.marked == true) return true;
      if (unmarkedWanted && queen != null && !queen.marked) return true;
      return false;
    }).toList();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _addHive() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.qr_code_scanner), title: const Text('Skeniraj'), onTap: () => Navigator.pop(ctx, 'scan')),
            ListTile(leading: const Icon(Icons.keyboard), title: const Text('Ukucaj kod'), onTap: () => Navigator.pop(ctx, 'type')),
          ],
        ),
      ),
    );
    if (choice == null) return;
    String? code;
    if (choice == 'scan') {
      if (!mounted) return;
      code = await scanBarcode(context);
    } else {
      if (!mounted) return;
      final ctrl = TextEditingController();
      code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kod'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Barkod'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
          ],
        ),
      );
    }
    if (code == null || code.isEmpty) return;
    final hive = await db.findHiveByBarcode(code);
    if (hive == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Košnica nije u bazi')));
      return;
    }
    final statusBlock = HiveStatusRules.blockReasonAddToGroup(hive.status);
    if (statusBlock != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(statusBlock)));
      return;
    }
    final group = _group;
    if (group == null) return;
    final existing = await db.activeMembershipInGroup(group.uuid, hive.uuid);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Košnica ${hive.barcode} je već aktivna u ovoj grupi. '
            'Završite ili uklonite trenutni period da je dodate ponovo.',
          ),
        ),
      );
      return;
    }
    await _promptDetailsAndSave(hive);
  }

  Future<void> _promptDetailsAndSave(Hive hive) async {
    final group = _group!;
    String? pasture = group.pastureType ?? pastureTypes.first;
    final locCtrl = TextEditingController(text: group.locationName ?? '');
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: widget.groupType == 'MOVED' ? '1' : '');
    DateTime? checkDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final fields = <Widget>[
            Text('Košnica ${hive.orderNumber} · ${hive.barcode}'),
            if (widget.groupType == 'MOVED' || widget.groupType == 'GOOD_PASTURE')
              DropdownButtonFormField<String>(
                initialValue: pasture,
                items: pastureTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setLocal(() => pasture = v),
                decoration: const InputDecoration(labelText: 'Paša'),
              ),
            if (widget.groupType == 'MOVED')
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokacija')),
            if (widget.groupType == 'GOOD_PASTURE' || widget.groupType == 'FEEDING' || widget.groupType == 'MOVED')
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Količina (kg)'),
                keyboardType: TextInputType.number,
              ),
            if (widget.groupType == 'CONTROL' || widget.groupType == 'REPRODUCTION' || widget.groupType == 'QUEEN_CHANGE')
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Napomena'), maxLines: 2),
            if (widget.groupType == 'CONTROL' || widget.groupType == 'QUEEN_CHANGE')
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: DateTime.now().add(const Duration(days: 2)),
                    );
                    if (d != null) setLocal(() => checkDate = d);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    checkDate == null
                        ? 'Datum provere'
                        : 'Provera: ${checkDate!.toLocal().toString().split(' ').first}',
                  ),
                ),
              ),
          ];

          return AlertDialog(
            title: Text('Dodaj u ${title(context)}'),
            content: SingleChildScrollView(
              child: FormSpacedColumn(children: fields),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dodaj')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    final groupTitle = title(context);

    // Ponovna provera (npr. ako je u međuvremenu dodata sa drugog mesta).
    final already = await db.activeMembershipInGroup(group.uuid, hive.uuid);
    if (already != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Košnica ${hive.barcode} je već aktivna u ovoj grupi.')),
      );
      return;
    }

    if (widget.groupType == 'MOVED') {
      group.pastureType = pasture;
      group.locationName = locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim();
      group.touch();
      group.dateSynched = null;
      await db.upsertWorkGroup(group);
    }

    final noteText = noteCtrl.text.trim();
    DateTime? reminderAt;
    if (checkDate != null) {
      reminderAt = checkDate!.subtract(const Duration(days: 1));
    }

    final parsedAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    final amount = GroupSharedDataSync.usesHarvest(widget.groupType)
        ? (parsedAmount ?? (widget.groupType == 'MOVED' ? 1.0 : 0.0))
        : parsedAmount;

    final item = WorkGroupHive(
      uuid: db.newUuid(),
      groupUuid: group.uuid,
      hiveUuid: hive.uuid,
      amount: amount,
      note: noteText.isEmpty ? null : noteText,
      checkDate: checkDate,
      reminderAt: reminderAt,
      pastureType: (widget.groupType == 'MOVED' || widget.groupType == 'GOOD_PASTURE') ? pasture : null,
      locationName: widget.groupType == 'MOVED'
          ? (locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim())
          : null,
      membershipStatus: 'ACTIVE',
      activeFrom: DateTime.now(),
    );
    await db.upsertWorkGroupHive(item);

    if (GroupSharedDataSync.usesHarvest(widget.groupType)) {
      await db.upsertHarvest(Harvest(
        uuid: db.newUuid(),
        hiveUuid: hive.uuid,
        pastureType: pasture ?? 'Drugo',
        amountKg: amount ?? 0,
        collectedAt: DateTime.now(),
        harvestYear: DateTime.now().year,
        workGroupHiveUuid: item.uuid,
      ));
    }

    if (noteText.isNotEmpty) {
      await db.upsertNote(Note(
        uuid: db.newUuid(),
        hiveUuid: hive.uuid,
        content: noteText,
        groupType: widget.groupType,
        groupRecordUuid: item.uuid,
      ));
    }

    if (widget.groupType == 'QUEEN_CHANGE' && checkDate != null) {
      final q = await db.activeQueen(hive.uuid) ?? Queen(uuid: db.newUuid(), hiveUuid: hive.uuid, activeFrom: checkDate);
      q.activeFrom = checkDate;
      q.touch();
      q.dateSynched = null;
      await db.upsertQueen(q);
    }

    if (reminderAt != null) {
      final remTitle = noteText.isEmpty
          ? '$groupTitle · ${hive.barcode}'
          : '$groupTitle · ${hive.barcode}\n$noteText';
      final rem = Reminder(
        uuid: db.newUuid(),
        hiveUuid: hive.uuid,
        groupHiveUuid: item.uuid,
        dueAt: reminderAt,
        title: remTitle,
      );
      await db.upsertReminder(rem);
      await ReminderService.instance.schedule(
        id: rem.uuid.hashCode & 0x7fffffff,
        title: '$groupTitle · ${hive.barcode}',
        body: noteText.isEmpty ? 'Podsetnik 1 dan pre provere' : noteText,
        when: reminderAt,
      );
    }

    await _reload();
  }

  Future<void> _closeMembership(WorkGroupHive item, String status, {bool queenLaid = false}) async {
    item.membershipStatus = status;
    item.activeFrom ??= item.dateCreated;
    item.activeTo = DateTime.now();
    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
    if (queenLaid) {
      await db.upsertNote(Note(
        uuid: db.newUuid(),
        hiveUuid: item.hiveUuid,
        content: 'Matica je pronela — završeno u grupi zamene (${item.periodLabel}).',
        groupType: widget.groupType,
        groupRecordUuid: item.uuid,
      ));
    }
    await _reload();
  }

  Future<void> _deleteWithoutHistory(WorkGroupHive item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje bez istorije'),
        content: const Text(
          'Obriše članstvo iz grupe bez čuvanja istorije. '
          'Briše se i povezani prinos (ako postoji), napomene i podsetnici.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await GroupSharedDataSync().deleteMembershipWithoutHistory(item);
    await _reload();
  }

  Future<void> _editMembership(WorkGroupHive item) async {
    final group = _group!;
    String? pasture = item.pastureType ?? group.pastureType ?? pastureTypes.first;
    final locCtrl = TextEditingController(text: item.locationName ?? group.locationName ?? '');
    final noteCtrl = TextEditingController(text: item.note ?? '');
    final amountCtrl = TextEditingController(text: item.amount != null ? '${item.amount}' : '');
    DateTime? checkDate = item.checkDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final fields = <Widget>[
            if (widget.groupType == 'MOVED' || widget.groupType == 'GOOD_PASTURE')
              DropdownButtonFormField<String>(
                initialValue: pastureTypes.contains(pasture) ? pasture : pastureTypes.last,
                items: pastureTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setLocal(() => pasture = v),
                decoration: const InputDecoration(labelText: 'Paša'),
              ),
            if (widget.groupType == 'MOVED')
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokacija')),
            if (widget.groupType == 'GOOD_PASTURE' || widget.groupType == 'FEEDING' || widget.groupType == 'MOVED')
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Količina (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            if (widget.groupType == 'CONTROL' || widget.groupType == 'REPRODUCTION' || widget.groupType == 'QUEEN_CHANGE' || widget.groupType == 'FEEDING')
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Napomena'), maxLines: 2),
            if (widget.groupType == 'CONTROL' || widget.groupType == 'QUEEN_CHANGE')
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: checkDate ?? DateTime.now(),
                    );
                    if (d != null) setLocal(() => checkDate = d);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    checkDate == null
                        ? 'Datum provere'
                        : 'Provera: ${checkDate!.toLocal().toString().split(' ').first}',
                  ),
                ),
              ),
          ];

          return AlertDialog(
            title: const Text('Izmeni u grupi'),
            content: SingleChildScrollView(
              child: FormSpacedColumn(children: fields),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    if (widget.groupType == 'MOVED' || widget.groupType == 'GOOD_PASTURE') {
      item.pastureType = pasture;
    }
    if (widget.groupType == 'MOVED') {
      item.locationName = locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim();
      group.pastureType = pasture;
      group.locationName = item.locationName;
      group.touch();
      group.dateSynched = null;
      await db.upsertWorkGroup(group);
    }
    if (widget.groupType == 'GOOD_PASTURE' || widget.groupType == 'FEEDING' || widget.groupType == 'MOVED') {
      item.amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    }
    if (widget.groupType == 'CONTROL' ||
        widget.groupType == 'REPRODUCTION' ||
        widget.groupType == 'QUEEN_CHANGE' ||
        widget.groupType == 'FEEDING') {
      final t = noteCtrl.text.trim();
      item.note = t.isEmpty ? null : t;
    }
    if (widget.groupType == 'CONTROL' || widget.groupType == 'QUEEN_CHANGE') {
      item.checkDate = checkDate;
      item.reminderAt = checkDate?.subtract(const Duration(days: 1));
    }

    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
    await GroupSharedDataSync().syncFromMembership(item, groupType: widget.groupType);
    await _reload();
  }

  Future<void> _setFilter(String filter) async {
    setState(() => _filter = filter);
    await _reload();
  }

  Color _statusColor(WorkGroupHive item, Color groupColor) {
    return _membershipColor(item.membershipStatus, groupColor);
  }

  Color _membershipColor(String status, Color groupColor) {
    switch (status) {
      case 'FINISHED':
        return const Color(0xFF4A5568);
      case 'REMOVED':
        return const Color(0xFFC53030);
      default:
        return groupColor;
    }
  }

  List<Widget> _detailRows(WorkGroupHive item, Hive? hive, Apiary? apiary, Queen? queen) {
    final pasture = item.pastureType ?? _group?.pastureType;
    final location = item.locationName ?? _group?.locationName;
    final rows = <Widget>[];

    void add(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55), fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ));
    }

    if (apiary != null) add('Pčelinjak', '${apiary.workNumber} · ${apiary.name}');
    if (hive != null) add('Tip', hive.hiveType);

    switch (widget.groupType) {
      case 'MOVED':
        add('Lokacija', location);
        add('Paša', pasture);
        if (item.amount != null) add('Količina', '${item.amount} kg');
        break;
      case 'GOOD_PASTURE':
        add('Paša', pasture);
        if (item.amount != null) add('Prinos', '${item.amount} kg');
        break;
      case 'FEEDING':
        if (item.amount != null) add('Dohrana', '${item.amount} kg');
        break;
      case 'CONTROL':
      case 'QUEEN_CHANGE':
        add('Napomena', item.note);
        if (item.checkDate != null) {
          add('Provera', item.checkDate!.toLocal().toString().split(' ').first);
        }
        if (item.reminderAt != null) {
          add('Podsetnik', item.reminderAt!.toLocal().toString().split('.').first);
        }
        if (widget.groupType == 'QUEEN_CHANGE' && queen != null) {
          final parts = <String>[
            if (queen.queenYear != null) '${queen.queenYear}',
            if (queen.marked) 'markirana',
            if (queen.origin != null && queen.origin!.isNotEmpty) queen.origin!,
          ];
          if (parts.isNotEmpty) add('Matica', parts.join(' · '));
        }
        break;
      case 'REPRODUCTION':
        add('Napomena', item.note);
        break;
      default:
        add('Napomena', item.note);
        if (item.amount != null) add('Količina', '${item.amount} kg');
    }

    add('Period', item.periodLabel);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final color = workGroupColor(widget.groupType);
    final showingHistory = _filter != 'ACTIVE';
    final visible = _filtered;
    final q = _searchCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text('${title(context)} · ${visible.length}${q.isNotEmpty ? ' / ${_items.length}' : ''}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Istorija / filter',
            icon: const Icon(Icons.history),
            onSelected: _setFilter,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'ACTIVE', checked: _filter == 'ACTIVE', child: const Text('Aktivne')),
              CheckedPopupMenuItem(value: 'FINISHED', checked: _filter == 'FINISHED', child: const Text('Završene')),
              CheckedPopupMenuItem(value: 'REMOVED', checked: _filter == 'REMOVED', child: const Text('Uklonjene (greška)')),
              CheckedPopupMenuItem(value: 'ALL', checked: _filter == 'ALL', child: const Text('Sve (istorija)')),
            ],
          ),
        ],
      ),
      floatingActionButton: _filter == 'ACTIVE'
          ? HomeFab.pair(
              primary: FloatingActionButton.extended(
                heroTag: 'group_add_fab',
                backgroundColor: color,
                foregroundColor: Colors.white,
                onPressed: _addHive,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Dodaj skenom'),
              ),
            )
          : const HomeFab(),
      floatingActionButtonLocation: _filter == 'ACTIVE'
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          Material(
            color: color.withValues(alpha: 0.12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Aktivne',
                    selected: _filter == 'ACTIVE',
                    color: color,
                    onTap: () => _setFilter('ACTIVE'),
                  ),
                  _FilterChip(
                    label: 'Završene',
                    selected: _filter == 'FINISHED',
                    color: _membershipColor('FINISHED', color),
                    onTap: () => _setFilter('FINISHED'),
                  ),
                  _FilterChip(
                    label: 'Uklonjene',
                    selected: _filter == 'REMOVED',
                    color: _membershipColor('REMOVED', color),
                    onTap: () => _setFilter('REMOVED'),
                  ),
                  _FilterChip(
                    label: 'Sve',
                    selected: _filter == 'ALL',
                    color: color,
                    onTap: () => _setFilter('ALL'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Barkod, tip, pčelinjak, napomena, matica…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Obriši',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      showingHistory ? 'Nema zapisa u ovoj istoriji.' : 'Lista je prazna. Skenirajte košnicu.',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  )
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          'Nema rezultata za „$q”.',
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = visible[i];
                          final hive = _hives[item.hiveUuid];
                          final apiary = hive == null ? null : _apiaries[hive.apiaryUuid];
                          final queen = _queens[item.hiveUuid];
                          final statusColor = _statusColor(item, color);
                          return Material(
                            color: statusColor.withValues(alpha: item.isActive ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: hive == null
                                  ? null
                                  : () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => HiveScreen(hiveUuid: hive.uuid)));
                                      _reload();
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border(left: BorderSide(color: statusColor, width: 7)),
                                ),
                                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  hive == null
                                                      ? item.hiveUuid
                                                      : '${hive.orderNumber} · ${hive.barcode}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.statusLabel,
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ..._detailRows(item, hive, apiary, queen),
                                        ],
                                      ),
                                    ),
                                    if (item.isActive)
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'edit') await _editMembership(item);
                                          if (v == 'finish') await _closeMembership(item, 'FINISHED');
                                          if (v == 'remove') await _closeMembership(item, 'REMOVED');
                                          if (v == 'purge') await _deleteWithoutHistory(item);
                                          if (v == 'laid') await _closeMembership(item, 'FINISHED', queenLaid: true);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                                          const PopupMenuItem(value: 'finish', child: Text('Završi (kraj u grupi)')),
                                          const PopupMenuItem(value: 'remove', child: Text('Ukloni (dodata greškom)')),
                                          const PopupMenuItem(value: 'purge', child: Text('Obriši bez istorije')),
                                          if (widget.groupType == 'QUEEN_CHANGE')
                                            const PopupMenuItem(value: 'laid', child: Text('Matica je pronela')),
                                        ],
                                      )
                                    else
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'purge') await _deleteWithoutHistory(item);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'purge', child: Text('Obriši bez istorije')),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: color),
      ),
    );
  }
}
