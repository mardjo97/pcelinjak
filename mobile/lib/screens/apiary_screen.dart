import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/apiary_edit_dialog.dart';
import '../widgets/home_fab.dart';
import '../widgets/keyboard_dismiss.dart';
import 'hive_screen.dart';

class ApiaryScreen extends StatefulWidget {
  const ApiaryScreen({super.key, required this.apiaryUuid});

  final String apiaryUuid;

  @override
  State<ApiaryScreen> createState() => _ApiaryScreenState();
}

class _ApiaryScreenState extends State<ApiaryScreen> {
  final db = AppDatabase.instance;
  final _searchCtrl = TextEditingController();
  Apiary? _apiary;
  List<Hive> _hives = [];
  final Map<String, Queen> _queens = {};

  /// ACTIVE | ARCHIVED | DEAD | ALL
  String _statusFilter = 'ACTIVE';
  Timer? _debounce;

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
    final a = await db.apiaryByUuid(widget.apiaryUuid);
    final h = await db.listHives(widget.apiaryUuid, activeOnly: false);
    final queens = <String, Queen>{};
    for (final hive in h) {
      final q = await db.activeQueen(hive.uuid);
      if (q != null) queens[hive.uuid] = q;
    }
    if (!mounted) return;
    setState(() {
      _apiary = a;
      _hives = h;
      _queens
        ..clear()
        ..addAll(queens);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ARCHIVED':
        return const Color(0xFF4A5568);
      case 'DEAD':
        return const Color(0xFFC53030);
      default:
        return AppColors.meadow;
    }
  }

  List<Hive> get _filtered {
    Iterable<Hive> list = _hives;
    if (_statusFilter != 'ALL') {
      list = list.where((h) {
        final s = h.status.isEmpty ? 'ACTIVE' : h.status;
        return s == _statusFilter;
      });
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list.toList();

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

    return list.where((h) {
      final queen = _queens[h.uuid];
      final hay = [
        h.barcode,
        '${h.orderNumber}',
        h.hiveType,
        h.description ?? '',
        h.status,
        hiveStatuses[h.status] ?? '',
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

  void _setStatusFilter(String filter) {
    setState(() => _statusFilter = filter);
  }

  Future<void> _editApiary() async {
    final a = _apiary;
    if (a == null) return;
    final updated = await showApiaryEditor(context, existing: a);
    if (updated != null) await _reload();
  }

  Future<void> _pickAddHiveMode() async {
    final db = AppDatabase.instance;
    final manualCtrl = TextEditingController();
    var type = hiveTypes.first;
    var scanMany = false;
    var flash = '';
    final codes = <String>[];
    DateTime? cooldownUntil;

    Future<void> appendCode(StateSetter setLocal, String raw) async {
      final code = raw.trim();
      if (code.isEmpty) return;
      final existing = await db.findHiveByBarcode(code);
      if (existing != null) {
        setLocal(() => flash = 'Barkod već postoji: $code');
        return;
      }
      if (codes.contains(code)) {
        setLocal(() => flash = 'Već dodato u listu: $code');
        return;
      }
      setLocal(() {
        codes.add(code);
        flash = 'Dodato: $code';
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
                  title: const Text('Dodaj košnice'),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        items: hiveTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => type = v ?? type),
                        decoration: const InputDecoration(
                          labelText: 'Tip košnice',
                        ),
                      ),
                    ),
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
                                          await appendCode(setLocal, raw);
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
                                  child: _PendingCodeList(
                                    codes: codes,
                                    emptyText:
                                        'Skenirajte barkodove za dodavanje.',
                                    onRemove: (i) =>
                                        setLocal(() => codes.removeAt(i)),
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
                                  controller: manualCtrl,
                                  keyboardType: TextInputType.number,
                                  onTapOutside: dismissKeyboardOnTapOutside,
                                  decoration: InputDecoration(
                                    labelText: 'Barkod',
                                    suffixIcon: IgnoreKeyboardDismiss(
                                      child: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () async {
                                          await appendCode(
                                            setLocal,
                                            manualCtrl.text,
                                          );
                                          manualCtrl.clear();
                                        },
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) async {
                                    await appendCode(setLocal, manualCtrl.text);
                                    manualCtrl.clear();
                                  },
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: DismissKeyboardOnPointer(
                                    child: _PendingCodeList(
                                      codes: codes,
                                      emptyText:
                                          'Ručno unesite barkod i dodajte ga u listu.',
                                      onRemove: (i) =>
                                          setLocal(() => codes.removeAt(i)),
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
                                onPressed: codes.isEmpty
                                    ? null
                                    : () => Navigator.pop(ctx, true),
                                child: Text(
                                  codes.length == 1
                                      ? 'Dodaj 1 košnicu'
                                      : 'Dodaj ${codes.length} košnica',
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
    if (saved != true) return;

    var created = 0;
    var skipped = 0;
    var order = await db.nextHiveOrder(widget.apiaryUuid);
    for (final code in codes) {
      final existing = await db.findHiveByBarcode(code);
      if (existing != null) {
        skipped++;
        continue;
      }
      await db.upsertHive(
        Hive(
          uuid: db.newUuid(),
          barcode: code,
          orderNumber: order,
          hiveType: type,
          apiaryUuid: widget.apiaryUuid,
          status: 'ACTIVE',
        ),
      );
      order++;
      created++;
    }
    await _reload();
    if (!mounted) return;
    final msg = skipped == 0
        ? 'Dodato $created košnica ($type).'
        : 'Dodato $created · preskočeno $skipped.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final a = _apiary;
    final visible = _filtered;
    final q = _searchCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          a == null ? 'Pčelinjak' : 'Pčelinjak ${a.workNumber} · ${a.name}',
        ),
        actions: [
          IconButton(
            tooltip: 'Izmeni pčelinjak',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editApiary,
          ),
          IconButton(
            tooltip: 'Dodaj više skeniranjem',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _pickAddHiveMode,
          ),
        ],
      ),
      floatingActionButton: HomeFab.pair(
        primary: FloatingActionButton.extended(
          heroTag: 'add_hive_fab',
          onPressed: _pickAddHiveMode,
          icon: const Icon(Icons.add),
          label: const Text('Dodaj košnicu'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Material(
            color: AppTheme.tintedSurface(context, AppColors.mist),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'Aktivne',
                    selected: _statusFilter == 'ACTIVE',
                    color: _statusColor('ACTIVE'),
                    onTap: () => _setStatusFilter('ACTIVE'),
                  ),
                  _StatusChip(
                    label: 'Arhivirane',
                    selected: _statusFilter == 'ARCHIVED',
                    color: _statusColor('ARCHIVED'),
                    onTap: () => _setStatusFilter('ARCHIVED'),
                  ),
                  _StatusChip(
                    label: 'Ugašene',
                    selected: _statusFilter == 'DEAD',
                    color: _statusColor('DEAD'),
                    onTap: () => _setStatusFilter('DEAD'),
                  ),
                  _StatusChip(
                    label: 'Sve',
                    selected: _statusFilter == 'ALL',
                    color: AppColors.meadowDark,
                    onTap: () => _setStatusFilter('ALL'),
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
                hintText: 'Barkod, tip, RB, matica…',
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
          if (q.isNotEmpty || _statusFilter != 'ALL')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${visible.length} košnica',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted(context),
                  ),
                ),
              ),
            ),
          Expanded(
            child: DismissKeyboardOnPointer(
              child: _hives.isEmpty
                  ? const Center(
                      child: Text(
                        'Nema košnica. Skenirajte barkodove redom.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : visible.isEmpty
                  ? Center(
                      child: Text(
                        q.isNotEmpty
                            ? 'Nema rezultata za „$q”.'
                            : 'Nema košnica za ovaj status.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'RB',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TIP',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'KOD',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...visible.map((h) {
                          final contextHiveUuids = visible
                              .map((item) => item.uuid)
                              .toList(growable: false);
                          final status = h.status.isEmpty ? 'ACTIVE' : h.status;
                          final color = _statusColor(status);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HiveScreen(
                                        hiveUuid: h.uuid,
                                        contextHiveUuids: contextHiveUuids,
                                      ),
                                    ),
                                  );
                                  _reload();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(color: color, width: 7),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${h.orderNumber}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(h.hiveType),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              h.barcode,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                hiveStatuses[status] ?? status,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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

class _PendingCodeList extends StatelessWidget {
  const _PendingCodeList({
    required this.codes,
    required this.emptyText,
    required this.onRemove,
  });

  final List<String> codes;
  final String emptyText;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (codes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted(context)),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: codes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text(
            '${i + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          codes[i],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          tooltip: 'Ukloni',
          icon: const Icon(Icons.close),
          onPressed: () => onRemove(i),
        ),
      ),
    );
  }
}
