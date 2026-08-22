import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/hive_status_rules.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../services/locale_service.dart';
import '../services/reminder_notification_title.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/hive_editors.dart';
import '../widgets/home_fab.dart';
import '../utils/system_insets.dart';
import '../widgets/keyboard_dismiss.dart';
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

  String title(BuildContext context) => LocaleController.workGroupTitle(
    AppLocalizations.of(context),
    widget.groupType,
  );

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
    await db.dedupeWorkGroups();
    var group = await db.workGroupByType(widget.groupType);
    if (group == null) {
      group = WorkGroup(uuid: db.newUuid(), groupType: widget.groupType);
      await db.upsertWorkGroup(group);
    }
    final items = await db.groupHivesByType(
      widget.groupType,
      filter: _filter,
    );
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

    final markedWanted = const [
      'markir',
      'oznac',
      'označ',
      'marked',
      'obelez',
      'obelež',
    ].any((k) => q.contains(k));
    final unmarkedWanted = const [
      'nemark',
      'neoznac',
      'neoznač',
      'unmarked',
    ].any((k) => q.contains(k));

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
    final queryCtrl = TextEditingController();
    final pending = <Hive>[];
    final hits = <HiveSearchHit>[];
    var searching = false;
    var scanMany = false;
    var flash = '';
    DateTime? cooldownUntil;
    Timer? debounce;

    Future<void> refreshHits(StateSetter setLocal, String query) async {
      if (query.trim().isEmpty) {
        setLocal(() {
          hits.clear();
          searching = false;
        });
        return;
      }
      setLocal(() => searching = true);
      final next = await db.searchHives(query);
      if (!mounted) return;
      setLocal(() {
        hits
          ..clear()
          ..addAll(next);
        searching = false;
      });
    }

    void showReject(StateSetter setLocal, String message) {
      setLocal(() => flash = message);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> appendHive(StateSetter setLocal, Hive hive) async {
      if (pending.any((item) => item.uuid == hive.uuid)) {
        showReject(setLocal, 'Već u listi: ${hive.barcode}');
        return;
      }
      final resolved = await _resolveHiveForGroup(hive.barcode);
      if (resolved.hive == null) {
        showReject(
          setLocal,
          resolved.error ?? 'Ne može da se doda: ${hive.barcode}',
        );
        return;
      }
      setLocal(() {
        pending.add(resolved.hive!);
        flash = 'Dodato: ${resolved.hive!.barcode}';
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: StatefulBuilder(
          builder: (ctx, setLocal) => DefaultTabController(
            length: 2,
            child: UnfocusOnTabChange(
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Dodaj u ${title(context)}'),
                  bottom: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: AppColors.honey,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'Scan', icon: Icon(Icons.qr_code_scanner)),
                      Tab(text: 'Ručno', icon: Icon(Icons.keyboard)),
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        children: [
                          Column(
                            children: [
                              CheckboxListTile(
                                value: scanMany,
                                title: const Text('Skeniraj više'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                onChanged: (v) =>
                                    setLocal(() => scanMany = v ?? false),
                              ),
                              Expanded(
                                flex: 3,
                                child: DismissKeyboardOnPointer(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      MobileScanner(
                                        onDetect: (capture) async {
                                          final raw = capture
                                              .barcodes
                                              .firstOrNull
                                              ?.rawValue
                                              ?.trim();
                                          if (raw == null || raw.isEmpty)
                                            return;
                                          final now = DateTime.now();
                                          if (cooldownUntil != null &&
                                              now.isBefore(cooldownUntil!)) {
                                            return;
                                          }
                                          cooldownUntil = now.add(
                                            Duration(
                                              milliseconds: scanMany
                                                  ? 1400
                                                  : 1800,
                                            ),
                                          );
                                          final hive =
                                              await db.findHiveByBarcode(raw);
                                          if (hive == null) {
                                            showReject(
                                              setLocal,
                                              'Nije u bazi: $raw',
                                            );
                                            return;
                                          }
                                          await appendHive(setLocal, hive);
                                        },
                                      ),
                                      if (flash.isNotEmpty)
                                        Positioned(
                                          left: 12,
                                          right: 12,
                                          bottom: 12,
                                          child: Material(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              child: Text(
                                                flash,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: DismissKeyboardOnPointer(
                                  child: _PendingHiveList(
                                    hives: pending,
                                    emptyText:
                                        'Skenirajte postojeće košnice za dodavanje u grupu.',
                                    onRemove: (i) =>
                                        setLocal(() => pending.removeAt(i)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: queryCtrl,
                                  autofocus: true,
                                  onTapOutside: dismissKeyboardOnTapOutside,
                                  onChanged: (value) {
                                    debounce?.cancel();
                                    debounce = Timer(
                                      const Duration(milliseconds: 220),
                                      () => refreshHits(setLocal, value),
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Pretraži košnicu',
                                    hintText: 'Barkod, RB, pčelinjak, tip…',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: DismissKeyboardOnPointer(
                                    child: searching
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Builder(
                                            builder: (context) {
                                              final availableHits = hits
                                                  .where(
                                                    (hit) => !pending.any(
                                                      (p) =>
                                                          p.uuid ==
                                                          hit.hive.uuid,
                                                    ),
                                                  )
                                                  .toList();
                                              if (hits.isEmpty) {
                                                return _PendingHiveList(
                                                  hives: pending,
                                                  emptyText:
                                                      'Pretražite i izaberite postojeću košnicu.',
                                                  onRemove: (i) => setLocal(
                                                    () => pending.removeAt(i),
                                                  ),
                                                );
                                              }
                                              return Column(
                                                children: [
                                                  Expanded(
                                                    child: availableHits.isEmpty
                                                        ? Center(
                                                            child: Text(
                                                              pending.isEmpty
                                                                  ? 'Nema rezultata.'
                                                                  : 'Sve pronađene košnice su već izabrane.',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    AppTheme.muted(
                                                                      context,
                                                                    ),
                                                              ),
                                                            ),
                                                          )
                                                        : ListView.separated(
                                                            itemCount:
                                                                availableHits
                                                                    .length,
                                                            separatorBuilder:
                                                                (_, _) =>
                                                                    const Divider(
                                                                      height: 1,
                                                                    ),
                                                            itemBuilder:
                                                                (context, i) {
                                                              final hit =
                                                                  availableHits[i];
                                                              final hive =
                                                                  hit.hive;
                                                              return ListTile(
                                                                title: Text(
                                                                  '${hive.barcode} · ${hive.hiveType}',
                                                                ),
                                                                subtitle: Text(
                                                                  hit.apiary ==
                                                                          null
                                                                      ? 'Košnica ${hive.orderNumber}'
                                                                      : 'Pčelinjak ${hit.apiary!.workNumber} · ${hit.apiary!.name}\nKošnica ${hive.orderNumber}',
                                                                ),
                                                                isThreeLine:
                                                                    hit.apiary !=
                                                                    null,
                                                                trailing:
                                                                    const Icon(
                                                                      Icons
                                                                          .add_circle_outline,
                                                                    ),
                                                                onTap: () async =>
                                                                    appendHive(
                                                                      setLocal,
                                                                      hive,
                                                                    ),
                                                              );
                                                            },
                                                          ),
                                                  ),
                                                  Expanded(
                                                    child: _PendingHiveList(
                                                      hives: pending,
                                                      emptyText:
                                                          'Još nema izabranih košnica.',
                                                      onRemove: (i) =>
                                                          setLocal(
                                                            () => pending
                                                                .removeAt(i),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Otkaži'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: pending.isEmpty
                                    ? null
                                    : () => Navigator.pop(ctx, true),
                                child: Text(
                                  pending.length == 1
                                      ? 'Dodaj 1 košnicu'
                                      : 'Dodaj ${pending.length} košnica',
                                ),
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
          ),
        ),
      ),
    );
    debounce?.cancel();
    queryCtrl.dispose();
    if (saved != true || pending.isEmpty) return;

    final draft = await _collectGroupAddDetails(
      summary: pending.length == 1
          ? 'Košnica ${pending.first.orderNumber} · ${pending.first.barcode}'
          : '${pending.length} košnica',
    );
    if (draft == null) return;

    var added = 0;
    var skipped = 0;
    for (final hive in pending) {
      final ok = await _commitHiveToGroup(hive, draft);
      if (ok) {
        added++;
      } else {
        skipped++;
      }
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skipped == 0
              ? 'Dodato $added košnica.'
              : 'Dodato $added · preskočeno $skipped.',
        ),
      ),
    );
  }

  /// Vraća košnicu spremnu za grupu, ili [error] poruku ako se ne može dodati.
  Future<({Hive? hive, String? error})> _resolveHiveForGroup(
    String code,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hive = await db.findHiveByBarcode(code);
    if (hive == null) {
      return (hive: null, error: 'Nije u bazi: $code');
    }
    final statusBlock = HiveStatusRules.blockReasonAddToGroup(
      l10n,
      hive.status,
    );
    if (statusBlock != null) {
      return (hive: null, error: '${hive.barcode}: $statusBlock');
    }
    final group = _group;
    if (group == null) {
      return (hive: null, error: 'Grupa nije učitana.');
    }
    final existing = await db.activeMembershipInGroupType(
      widget.groupType,
      hive.uuid,
    );
    if (existing != null) {
      return (
        hive: null,
        error: 'Košnica ${hive.barcode} je već dodata u ovu grupu.',
      );
    }
    return (hive: hive, error: null);
  }

  Future<_GroupAddDraft?> _collectGroupAddDetails({
    required String summary,
  }) async {
    final group = _group;
    if (group == null) return null;
    String? pasture = group.pastureType ?? pastureTypes.first;
    final locCtrl = TextEditingController(text: group.locationName ?? '');
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController(
      text: widget.groupType == 'MOVED' ? '1' : '',
    );
    DateTime? checkDate;
    var reminderDayBefore = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final fields = <Widget>[
            Text(summary),
            if (widget.groupType == 'MOVED' ||
                widget.groupType == 'GOOD_PASTURE')
              DropdownButtonFormField<String>(
                initialValue: pasture,
                items: pastureTypes
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setLocal(() => pasture = v),
                decoration: const InputDecoration(labelText: 'Paša'),
              ),
            if (widget.groupType == 'MOVED')
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Lokacija'),
              ),
            if (widget.groupType == 'GOOD_PASTURE' ||
                widget.groupType == 'FEEDING' ||
                widget.groupType == 'MOVED')
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Količina (kg)'),
                keyboardType: TextInputType.number,
              ),
            if (widget.groupType == 'CONTROL' ||
                widget.groupType == 'REPRODUCTION' ||
                widget.groupType == 'QUEEN_CHANGE')
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Napomena'),
                maxLines: 2,
              ),
            if (widget.groupType == 'CONTROL' ||
                widget.groupType == 'QUEEN_CHANGE') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Podsetnik dan ranije'),
                subtitle: Text(
                  reminderDayBefore
                      ? 'U 08:00 dan pre provere'
                      : 'U 08:00 na dan provere',
                ),
                value: reminderDayBefore,
                onChanged: (v) =>
                    setLocal(() => reminderDayBefore = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ];

          return AlertDialog(
            title: Text('Dodaj u ${title(context)}'),
            content: SingleChildScrollView(
              child: FormSpacedColumn(children: fields),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Otkaži'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return null;

    final noteText = noteCtrl.text.trim();
    final parsedAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    final amount = GroupSharedDataSync.usesHarvest(widget.groupType)
        ? (parsedAmount ?? (widget.groupType == 'MOVED' ? 1.0 : 0.0))
        : parsedAmount;
    final location = locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim();

    return _GroupAddDraft(
      pasture: pasture,
      locationName: location,
      noteText: noteText,
      amount: amount,
      checkDate: checkDate,
      reminderAt: _reminderAtFromCheckDate(
        checkDate,
        dayBefore: reminderDayBefore,
      ),
    );
  }

  /// Podsetnik u 08:00 lokalnog vremena — dan pre ili na dan provere.
  static DateTime? _reminderAtFromCheckDate(
    DateTime? checkDate, {
    required bool dayBefore,
  }) {
    if (checkDate == null) return null;
    final local = checkDate.toLocal();
    var day = DateTime(local.year, local.month, local.day);
    if (dayBefore) day = day.subtract(const Duration(days: 1));
    return DateTime(day.year, day.month, day.day, 8, 0);
  }

  static bool _isReminderDayBefore(DateTime? checkDate, DateTime? reminderAt) {
    if (checkDate == null || reminderAt == null) return true;
    final check = checkDate.toLocal();
    final rem = reminderAt.toLocal();
    final checkDay = DateTime(check.year, check.month, check.day);
    final remDay = DateTime(rem.year, rem.month, rem.day);
    return remDay.isBefore(checkDay);
  }

  /// Vraća true ako je košnica uspešno dodata.
  Future<bool> _commitHiveToGroup(Hive hive, _GroupAddDraft draft) async {
    final group = _group;
    if (group == null) return false;

    final already = await db.activeMembershipInGroupType(
      widget.groupType,
      hive.uuid,
    );
    if (already != null) return false;

    if (widget.groupType == 'MOVED') {
      group.pastureType = draft.pasture;
      group.locationName = draft.locationName;
      group.touch();
      group.dateSynched = null;
      await db.upsertWorkGroup(group);
    }

    if (!mounted) return false;
    final groupTitle = title(context);

    final item = WorkGroupHive(
      uuid: db.newUuid(),
      groupUuid: group.uuid,
      hiveUuid: hive.uuid,
      amount: draft.amount,
      note: draft.noteText.isEmpty ? null : draft.noteText,
      checkDate: draft.checkDate,
      reminderAt: draft.reminderAt,
      pastureType:
          (widget.groupType == 'MOVED' || widget.groupType == 'GOOD_PASTURE')
          ? draft.pasture
          : null,
      locationName: widget.groupType == 'MOVED' ? draft.locationName : null,
      membershipStatus: 'ACTIVE',
      activeFrom: DateTime.now(),
    );
    await db.upsertWorkGroupHive(item);

    if (GroupSharedDataSync.usesHarvest(widget.groupType)) {
      await db.upsertHarvest(
        Harvest(
          uuid: db.newUuid(),
          hiveUuid: hive.uuid,
          pastureType: draft.pasture ?? 'Drugo',
          amountKg: draft.amount ?? 0,
          collectedAt: DateTime.now(),
          harvestYear: DateTime.now().year,
          workGroupHiveUuid: item.uuid,
        ),
      );
    }

    if (draft.noteText.isNotEmpty) {
      await db.upsertNote(
        Note(
          uuid: db.newUuid(),
          hiveUuid: hive.uuid,
          content: draft.noteText,
          groupType: widget.groupType,
          groupRecordUuid: item.uuid,
        ),
      );
    }

    if (widget.groupType == 'QUEEN_CHANGE' && draft.checkDate != null) {
      final q =
          await db.activeQueen(hive.uuid) ??
          Queen(
            uuid: db.newUuid(),
            hiveUuid: hive.uuid,
            activeFrom: draft.checkDate,
          );
      q.activeFrom = draft.checkDate;
      q.touch();
      q.dateSynched = null;
      await db.upsertQueen(q);
    }

    if (draft.reminderAt != null) {
      final remTitle = draft.noteText.isEmpty
          ? '$groupTitle · ${hive.barcode}'
          : '$groupTitle · ${hive.barcode}\n${draft.noteText}';
      final rem = Reminder(
        uuid: db.newUuid(),
        hiveUuid: hive.uuid,
        groupHiveUuid: item.uuid,
        dueAt: draft.reminderAt!,
        title: remTitle,
      );
      await db.upsertReminder(rem);
      final apiary =
          _apiaries[hive.apiaryUuid] ?? await db.apiaryByUuid(hive.apiaryUuid);
      await ReminderService.instance.schedule(
        id: rem.uuid.hashCode & 0x7fffffff,
        title: ReminderNotificationTitle.forHive(hive, apiary),
        body: draft.noteText.isEmpty
            ? 'Podsetnik 1 dan pre provere'
            : draft.noteText,
        when: draft.reminderAt!,
        reminderUuid: rem.uuid,
      );
    }
    return true;
  }

  Future<void> _closeMembership(
    WorkGroupHive item,
    String status, {
    bool queenLaid = false,
  }) async {
    item.membershipStatus = status;
    item.activeFrom ??= item.dateCreated;
    item.activeTo = DateTime.now();
    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
    if (queenLaid) {
      await db.upsertNote(
        Note(
          uuid: db.newUuid(),
          hiveUuid: item.hiveUuid,
          content:
              'Matica je pronela — završeno u grupi zamene (${item.periodLabel}).',
          groupType: widget.groupType,
          groupRecordUuid: item.uuid,
        ),
      );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
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
    String? pasture =
        item.pastureType ?? group.pastureType ?? pastureTypes.first;
    final locCtrl = TextEditingController(
      text: item.locationName ?? group.locationName ?? '',
    );
    final noteCtrl = TextEditingController(text: item.note ?? '');
    final amountCtrl = TextEditingController(
      text: item.amount != null ? '${item.amount}' : '',
    );
    DateTime? checkDate = item.checkDate;
    var reminderDayBefore = _isReminderDayBefore(
      item.checkDate,
      item.reminderAt,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final fields = <Widget>[
            if (widget.groupType == 'MOVED' ||
                widget.groupType == 'GOOD_PASTURE')
              DropdownButtonFormField<String>(
                initialValue: pastureTypes.contains(pasture)
                    ? pasture
                    : pastureTypes.last,
                items: pastureTypes
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setLocal(() => pasture = v),
                decoration: const InputDecoration(labelText: 'Paša'),
              ),
            if (widget.groupType == 'MOVED')
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Lokacija'),
              ),
            if (widget.groupType == 'GOOD_PASTURE' ||
                widget.groupType == 'FEEDING' ||
                widget.groupType == 'MOVED')
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Količina (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            if (widget.groupType == 'CONTROL' ||
                widget.groupType == 'REPRODUCTION' ||
                widget.groupType == 'QUEEN_CHANGE' ||
                widget.groupType == 'FEEDING')
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Napomena'),
                maxLines: 2,
              ),
            if (widget.groupType == 'CONTROL' ||
                widget.groupType == 'QUEEN_CHANGE') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Podsetnik dan ranije'),
                subtitle: Text(
                  reminderDayBefore
                      ? 'U 08:00 dan pre provere'
                      : 'U 08:00 na dan provere',
                ),
                value: reminderDayBefore,
                onChanged: (v) =>
                    setLocal(() => reminderDayBefore = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ];

          return AlertDialog(
            title: const Text('Izmeni u grupi'),
            content: SingleChildScrollView(
              child: FormSpacedColumn(children: fields),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Otkaži'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sačuvaj'),
              ),
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
      item.locationName = locCtrl.text.trim().isEmpty
          ? null
          : locCtrl.text.trim();
      group.pastureType = pasture;
      group.locationName = item.locationName;
      group.touch();
      group.dateSynched = null;
      await db.upsertWorkGroup(group);
    }
    if (widget.groupType == 'GOOD_PASTURE' ||
        widget.groupType == 'FEEDING' ||
        widget.groupType == 'MOVED') {
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
      item.reminderAt = _reminderAtFromCheckDate(
        checkDate,
        dayBefore: reminderDayBefore,
      );
    }

    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
    await GroupSharedDataSync().syncFromMembership(
      item,
      groupType: widget.groupType,
    );
    await _reload();
  }

  Future<void> _createInspectionFromGroup(WorkGroupHive item) async {
    if (widget.groupType != 'CONTROL') return;
    final hive =
        _hives[item.hiveUuid] ?? await db.findHiveByUuid(item.hiveUuid);
    if (hive == null || !mounted) return;
    final existing = await db.inspectionBySource(
      sourceGroupHiveUuid: item.uuid,
    );
    if (!mounted) return;
    final saved = await editInspectionDialog(
      context,
      hiveUuid: hive.uuid,
      existing: existing,
      sourceType: 'CONTROL_GROUP',
      sourceGroupHiveUuid: item.uuid,
      initialInspectedAt: item.checkDate ?? DateTime.now(),
      initialSummary: item.note,
    );
    if (!saved) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Kontrola je upisana za košnicu ${hive.barcode}.'
              : 'Kontrola je ažurirana za košnicu ${hive.barcode}.',
        ),
      ),
    );
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

  List<Widget> _detailRows(
    WorkGroupHive item,
    Hive? hive,
    Apiary? apiary,
    Queen? queen,
  ) {
    final pasture = item.pastureType ?? _group?.pastureType;
    final location = item.locationName ?? _group?.locationName;
    final rows = <Widget>[];

    void add(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (apiary != null)
      add('Pčelinjak', '${apiary.workNumber} · ${apiary.name}');
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
          add(
            'Podsetnik',
            item.reminderAt!.toLocal().toString().split('.').first,
          );
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
    final l10n = AppLocalizations.of(context);
    final color = workGroupColor(widget.groupType);
    final showingHistory = _filter != 'ACTIVE';
    final visible = _filtered;
    final q = _searchCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(
          '${title(context)} · ${visible.length}${q.isNotEmpty ? ' / ${_items.length}' : ''}',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.filterAllHistory,
            icon: const Icon(Icons.history),
            onSelected: _setFilter,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'ACTIVE',
                checked: _filter == 'ACTIVE',
                child: Text(l10n.filterActive),
              ),
              CheckedPopupMenuItem(
                value: 'FINISHED',
                checked: _filter == 'FINISHED',
                child: Text(l10n.filterFinished),
              ),
              CheckedPopupMenuItem(
                value: 'REMOVED',
                checked: _filter == 'REMOVED',
                child: Text(l10n.filterRemoved),
              ),
              CheckedPopupMenuItem(
                value: 'ALL',
                checked: _filter == 'ALL',
                child: Text(l10n.filterAllHistory),
              ),
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
                    label: l10n.filterActive,
                    selected: _filter == 'ACTIVE',
                    color: color,
                    onTap: () => _setFilter('ACTIVE'),
                  ),
                  _FilterChip(
                    label: l10n.filterFinished,
                    selected: _filter == 'FINISHED',
                    color: _membershipColor('FINISHED', color),
                    onTap: () => _setFilter('FINISHED'),
                  ),
                  _FilterChip(
                    label: l10n.filterRemoved,
                    selected: _filter == 'REMOVED',
                    color: _membershipColor('REMOVED', color),
                    onTap: () => _setFilter('REMOVED'),
                  ),
                  _FilterChip(
                    label: l10n.statusAll,
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
              onTapOutside: dismissKeyboardOnTapOutside,
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
            child: DismissKeyboardOnPointer(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        showingHistory
                            ? 'Nema zapisa u ovoj istoriji.'
                            : 'Lista je prazna. Skenirajte košnicu.',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : visible.isEmpty
                  ? Center(
                      child: Text(
                        'Nema rezultata za „$q”.',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, fabClearancePadding(context)),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = visible[i];
                        final hive = _hives[item.hiveUuid];
                        final apiary = hive == null
                            ? null
                            : _apiaries[hive.apiaryUuid];
                        final queen = _queens[item.hiveUuid];
                        final statusColor = _statusColor(item, color);
                        return Material(
                          color: statusColor.withValues(
                            alpha: item.isActive ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: hive == null
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HiveScreen(hiveUuid: hive.uuid),
                                      ),
                                    );
                                    _reload();
                                  },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                  left: BorderSide(
                                    color: statusColor,
                                    width: 7,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                LocaleController.membershipStatusLabel(
                                                  l10n,
                                                  item.membershipStatus,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        ..._detailRows(
                                          item,
                                          hive,
                                          apiary,
                                          queen,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.isActive)
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit')
                                          await _editMembership(item);
                                        if (v == 'inspect')
                                          await _createInspectionFromGroup(
                                            item,
                                          );
                                        if (v == 'finish')
                                          await _closeMembership(
                                            item,
                                            'FINISHED',
                                          );
                                        if (v == 'remove')
                                          await _closeMembership(
                                            item,
                                            'REMOVED',
                                          );
                                        if (v == 'purge')
                                          await _deleteWithoutHistory(item);
                                        if (v == 'laid')
                                          await _closeMembership(
                                            item,
                                            'FINISHED',
                                            queenLaid: true,
                                          );
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Izmeni'),
                                        ),
                                        if (widget.groupType == 'CONTROL')
                                          const PopupMenuItem(
                                            value: 'inspect',
                                            child: Text('Evidentiraj kontrolu'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'finish',
                                          child: Text('Završi (kraj u grupi)'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text(
                                            'Ukloni (dodata greškom)',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'purge',
                                          child: Text('Obriši bez istorije'),
                                        ),
                                        if (widget.groupType == 'QUEEN_CHANGE')
                                          const PopupMenuItem(
                                            value: 'laid',
                                            child: Text('Matica je pronela'),
                                          ),
                                      ],
                                    )
                                  else
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'purge')
                                          await _deleteWithoutHistory(item);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'purge',
                                          child: Text('Obriši bez istorije'),
                                        ),
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
          ),
        ],
      ),
    );
  }
}

class _GroupAddDraft {
  const _GroupAddDraft({
    required this.pasture,
    required this.locationName,
    required this.noteText,
    required this.amount,
    required this.checkDate,
    required this.reminderAt,
  });

  final String? pasture;
  final String? locationName;
  final String noteText;
  final double? amount;
  final DateTime? checkDate;
  final DateTime? reminderAt;
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
          color: AppTheme.chipLabel(context, selected: selected, accent: color),
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: color),
      ),
    );
  }
}

class _PendingHiveList extends StatelessWidget {
  const _PendingHiveList({
    required this.hives,
    required this.emptyText,
    required this.onRemove,
  });

  final List<Hive> hives;
  final String emptyText;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final panelColor = AppTheme.tintedSurface(
      context,
      AppColors.mist,
    );
    final borderColor = scheme.outline.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rtl,
                  size: 18,
                  color: AppTheme.muted(context),
                ),
                const SizedBox(width: 8),
                Text(
                  hives.isEmpty
                      ? 'Izabrane košnice'
                      : 'Izabrane košnice (${hives.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.muted(context),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: hives.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted(context)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: hives.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: borderColor,
                    ),
                    itemBuilder: (context, i) {
                      final hive = hives[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.meadow.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: AppColors.meadow,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          '${hive.barcode} · ${hive.hiveType}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Košnica ${hive.orderNumber}'),
                        trailing: IconButton(
                          tooltip: 'Ukloni',
                          icon: const Icon(Icons.close),
                          onPressed: () => onRemove(i),
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
