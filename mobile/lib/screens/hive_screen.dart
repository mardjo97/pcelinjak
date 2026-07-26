import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/hive_status_rules.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scan.dart';
import '../widgets/form_spaced_column.dart';
import '../widgets/hive_editors.dart';
import '../widgets/home_fab.dart';
import 'hive_harvests_screen.dart';
import 'hive_notes_screen.dart';

class HiveScreen extends StatefulWidget {
  const HiveScreen({super.key, required this.hiveUuid});

  final String hiveUuid;

  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  final db = AppDatabase.instance;
  Hive? _hive;
  Apiary? _apiary;
  Queen? _queen;
  List<Queen> _queenHistory = [];
  List<Note> _notes = [];
  List<Harvest> _harvests = [];
  double _yearSum = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hive = await db.findHiveByUuid(widget.hiveUuid);
      if (hive == null || hive.dateDeleted != null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Košnica nije pronađena.';
          _hive = null;
        });
        return;
      }
      final apiary = await db.apiaryByUuid(hive.apiaryUuid);
      final queen = await db.activeQueen(hive.uuid);
      final queens = await db.listQueens(hive.uuid);
      final notes = await db.notesForHive(hive.uuid);
      final year = DateTime.now().year;
      final harvests = await db.harvestsForHive(hive.uuid, year: year);
      final sum = await db.harvestSum(hive.uuid, year);
      if (!mounted) return;
      setState(() {
        _hive = hive;
        _apiary = apiary;
        _queen = queen;
        _queenHistory = queens.where((q) => !q.active).toList();
        _notes = notes;
        _harvests = harvests;
        _yearSum = sum;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Greška pri učitavanju: $e';
      });
    }
  }

  Future<bool> _confirm(String title, String message) => confirmDialog(context, title, message);

  Future<void> _editHive() async {
    final hive = _hive!;
    final blocked = HiveStatusRules.blockReasonEditHive(hive.status);
    if (blocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final barcodeCtrl = TextEditingController(text: hive.barcode);
    final descCtrl = TextEditingController(text: hive.description ?? '');
    String type = hive.hiveType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Izmeni košnicu'),
          content: FormSpacedColumn(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barcodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Barkod'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await scanBarcode(context);
                      if (code != null) barcodeCtrl.text = code;
                    },
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: hiveTypes.contains(type) ? type : hiveTypes.last,
                items: hiveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setLocal(() => type = v ?? type),
                decoration: const InputDecoration(labelText: 'Tip'),
              ),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Opis'), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
          ],
        ),
      ),
    );
    if (ok != true || barcodeCtrl.text.trim().isEmpty) return;
    hive.barcode = barcodeCtrl.text.trim();
    hive.hiveType = type;
    hive.description = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
    hive.touch();
    hive.dateSynched = null;
    await db.upsertHive(hive);
    await _reload();
  }

  Future<void> _setHiveStatus(String status) async {
    final hive = _hive!;
    if (HiveStatusRules.normalize(hive.status) == status) return;
    if (!HiveStatusRules.canTransitionTo(hive.status, status)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nije dozvoljen prelaz ${HiveStatusRules.label(hive.status)} → ${HiveStatusRules.label(status)}.',
          ),
        ),
      );
      return;
    }
    final label = HiveStatusRules.label(status);
    if (!await _confirm('Status košnice', 'Postaviti status na „$label”?')) return;
    hive.status = status;
    hive.touch();
    hive.dateSynched = null;
    await db.upsertHive(hive);
    await _reload();
  }

  Future<void> _deleteHive() async {
    if (!await _confirm('Obriši košnicu', 'Košnica će biti obrisana (može se sinhronizovati kao obrisana).')) return;
    await db.softDelete('hive', widget.hiveUuid);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _editQueen({Queen? existing}) async {
    final blocked = HiveStatusRules.blockReasonQueen(_hive?.status);
    if (blocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final q0 = existing ?? _queen;
    final yearCtrl = TextEditingController(text: '${q0?.queenYear ?? DateTime.now().year}');
    final originCtrl = TextEditingController(text: q0?.origin ?? '');
    var marked = q0?.marked ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(q0 == null ? 'Unesi maticu' : 'Izmeni maticu'),
          content: SingleChildScrollView(
            child: FormSpacedColumn(
              children: [
                TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Godina'), keyboardType: TextInputType.number),
                TextField(controller: originCtrl, decoration: const InputDecoration(labelText: 'Poreklo')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Obeležena'),
                  value: marked,
                  onChanged: (v) => setLocal(() => marked = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final year = int.tryParse(yearCtrl.text.trim());
    final q = q0 ??
        Queen(
          uuid: db.newUuid(),
          hiveUuid: widget.hiveUuid,
          activeFrom: DateTime.now(),
        );
    q.queenYear = year;
    q.marked = marked;
    q.origin = originCtrl.text.trim().isEmpty ? null : originCtrl.text.trim();
    q.active = true;
    q.activeFrom ??= DateTime.now();
    q.touch();
    q.dateSynched = null;
    await db.upsertQueen(q);
    await _reload();
  }

  /// Završava trenutnu maticu (npr. uginula) i opciono odmah unosi novu.
  Future<void> _replaceQueen({bool addNew = true}) async {
    final blocked = HiveStatusRules.blockReasonQueen(_hive?.status);
    if (blocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final current = _queen;
    String endReason = 'DIED';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(addNew ? 'Nova matica' : 'Završi maticu'),
          content: FormSpacedColumn(
            children: [
              if (current != null)
                Text(
                  'Trenutna: godina ${current.queenYear ?? '—'} · ${current.periodLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              DropdownButtonFormField<String>(
                initialValue: endReason,
                items: queenEndReasons.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setLocal(() => endReason = v ?? endReason),
                decoration: const InputDecoration(labelText: 'Šta se desilo sa starom?'),
              ),
              if (addNew)
                Text(
                  'Posle toga unesite podatke nove matice.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(addNew ? 'Nastavi' : 'Završi')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    if (current != null && current.active) {
      current.active = false;
      current.activeTo = DateTime.now();
      current.endReason = endReason;
      current.touch();
      current.dateSynched = null;
      await db.upsertQueen(current);
    }

    if (addNew) {
      await _createNewQueenForm();
    } else {
      await _reload();
    }
  }

  Future<void> _createNewQueenForm() async {
    final blocked = HiveStatusRules.blockReasonQueen(_hive?.status);
    if (blocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final originCtrl = TextEditingController();
    var marked = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nova matica'),
          content: SingleChildScrollView(
            child: FormSpacedColumn(
              children: [
                TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Godina'), keyboardType: TextInputType.number),
                TextField(controller: originCtrl, decoration: const InputDecoration(labelText: 'Poreklo')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Obeležena'),
                  value: marked,
                  onChanged: (v) => setLocal(() => marked = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otkaži')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sačuvaj')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final q = Queen(
      uuid: db.newUuid(),
      hiveUuid: widget.hiveUuid,
      queenYear: int.tryParse(yearCtrl.text.trim()),
      marked: marked,
      origin: originCtrl.text.trim().isEmpty ? null : originCtrl.text.trim(),
      activeFrom: DateTime.now(),
      active: true,
    );
    await db.upsertQueen(q);
    await _reload();
  }

  Future<void> _editNote({Note? existing}) async {
    final saved = await editNoteDialog(context, hiveUuid: widget.hiveUuid, existing: existing);
    if (saved) await _reload();
  }

  Future<void> _deleteNote(Note n) async {
    if (!await _confirm('Obriši napomenu', 'Obrisati ovu napomenu?')) return;
    await db.softDelete('note', n.uuid);
    await GroupSharedDataSync().onNoteDeleted(n);
    await _reload();
  }

  Future<void> _editHarvest({Harvest? existing}) async {
    final blocked = HiveStatusRules.blockReasonHarvest(_hive?.status);
    if (blocked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final saved = await editHarvestDialog(context, hiveUuid: widget.hiveUuid, existing: existing);
    if (saved) await _reload();
  }

  Future<void> _openNotesPage() async {
    final hive = _hive;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HiveNotesScreen(
          hiveUuid: widget.hiveUuid,
          hiveLabel: hive?.barcode,
        ),
      ),
    );
    _reload();
  }

  Future<void> _openHarvestsPage() async {
    final hive = _hive;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HiveHarvestsScreen(
          hiveUuid: widget.hiveUuid,
          hiveLabel: hive?.barcode,
        ),
      ),
    );
    _reload();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ARCHIVED':
        return Colors.blueGrey;
      case 'DEAD':
        return Colors.red.shade700;
      default:
        return AppColors.meadow;
    }
  }

  Widget _latestNoteTile(Note n) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        n.reminderAt != null ? Icons.alarm : Icons.notes,
        color: AppColors.meadow,
      ),
      title: Text(
        notePreviewLine(n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text([
        n.dateCreated.toLocal().toString().split('.').first,
        if (n.reminderAt != null)
          'Podsetnik: ${n.reminderAt!.toLocal().toString().split('.').first}',
      ].join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await showNoteDetailsDialog(
          context,
          note: n,
          onEdit: () => _editNote(existing: n),
          onDelete: () => _deleteNote(n),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        floatingActionButton: HomeFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _hive == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Košnica')),
        floatingActionButton: const HomeFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Košnica nije pronađena.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Nazad')),
              ],
            ),
          ),
        ),
      );
    }

    final hive = _hive!;
    final status = HiveStatusRules.normalize(hive.status);
    final statusLabel = HiveStatusRules.label(status);
    final canQueen = HiveStatusRules.canManageQueen(status);
    final canHarvest = HiveStatusRules.canAddHarvest(status);
    final canEdit = HiveStatusRules.canEditHive(status);
    final title = '${_apiary?.name ?? 'Pčelinjak'} · ${hive.orderNumber}';
    final discColor = (_queen?.marked == true && _queen?.queenYear != null)
        ? queenMarkColor(_queen!.queenYear!)
        : Colors.black87;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await _editHive();
                case 'ACTIVE':
                case 'ARCHIVED':
                case 'DEAD':
                  await _setHiveStatus(v);
                case 'delete':
                  await _deleteHive();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                enabled: canEdit,
                child: Text(canEdit ? 'Izmeni košnicu' : 'Izmeni (nije dozvoljeno)'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: status,
                enabled: false,
                child: Text('✓ Status: $statusLabel'),
              ),
              ...HiveStatusRules.allowedTransitions(status).map(
                (key) => PopupMenuItem(
                  value: key,
                  child: Text('Status: ${HiveStatusRules.label(key)}'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Obriši košnicu', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Kod: ${hive.barcode} · ${hive.hiveType}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(hive.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // NAPOMENA
          _HiveBlock(
            color: const Color(0xFFEDF7F0),
            accent: AppColors.meadow,
            icon: Icons.sticky_note_2_outlined,
            title: 'Napomena',
            actionLabel: 'Dodaj napomenu',
            onAction: () => _editNote(),
            child: _notes.isEmpty
                ? const Text('Još nema napomena za ovu košnicu.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Poslednja napomena',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.5)),
                      ),
                      _latestNoteTile(_notes.first),
                      if (_notes.length > 1)
                        TextButton.icon(
                          onPressed: _openNotesPage,
                          icon: const Icon(Icons.list_alt),
                          label: Text('Sve napomene (${_notes.length})'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // MATICA
          _HiveBlock(
            color: const Color(0xFFFFF6E5),
            accent: AppColors.honey,
            icon: Icons.spa_outlined,
            title: 'Matica',
            actionLabel: !canQueen
                ? 'Samo aktivna'
                : (_queen == null ? 'Unesi maticu' : 'Izmeni trenutnu'),
            onAction: !canQueen
                ? null
                : () => _queen == null ? _createNewQueenForm() : _editQueen(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canQueen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      HiveStatusRules.blockReasonQueen(status)!,
                      style: TextStyle(color: Colors.brown.shade700, fontSize: 13),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: discColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 2),
                        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2))],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _queen == null
                            ? 'Nema aktivne matice.'
                            : 'Godina: ${_queen!.queenYear ?? '—'}\n'
                                'Obeležena: ${_queen!.marked ? 'DA' : 'NE'}\n'
                                '${_queen!.periodLabel}'
                                '${_queen!.origin != null && _queen!.origin!.isNotEmpty ? '\nPoreklo: ${_queen!.origin}' : ''}',
                        style: const TextStyle(height: 1.35, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (canQueen && _queen != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _replaceQueen(addNew: true),
                          icon: const Icon(Icons.add),
                          label: const Text('Nova matica'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                          onPressed: () => _replaceQueen(addNew: false),
                          child: const Text('Završi / uginula'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_queenHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        'Istorija matica (${_queenHistory.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        for (final q in _queenHistory)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: (q.marked && q.queenYear != null) ? queenMarkColor(q.queenYear!) : Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            title: Text('Godina ${q.queenYear ?? '—'} · ${q.marked ? 'obeležena' : 'neobeležena'}'),
                            subtitle: Text([
                              q.periodLabel,
                              if (q.endReason != null) queenEndReasons[q.endReason!] ?? q.endReason!,
                              if (q.origin != null && q.origin!.isNotEmpty) q.origin!,
                            ].join(' · ')),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // PRINOS
          _HiveBlock(
            color: const Color(0xFFEAF2FB),
            accent: const Color(0xFF2B6CB0),
            icon: Icons.water_drop_outlined,
            title: 'Prinos meda',
            actionLabel: canHarvest ? 'Dodaj prinos' : 'Samo aktivna',
            onAction: canHarvest ? () => _editHarvest() : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canHarvest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      HiveStatusRules.blockReasonHarvest(status)!,
                      style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
                    ),
                  ),
                Text(
                  'Ukupno ${DateTime.now().year}: ${_yearSum.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                if (_harvests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Još nema unosa prinosa ove godine.'),
                  )
                else
                  TextButton.icon(
                    onPressed: _openHarvestsPage,
                    icon: const Icon(Icons.list_alt),
                    label: Text('Svi prinosi (${_harvests.length})'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HiveBlock extends StatelessWidget {
  const _HiveBlock({
    required this.color,
    required this.accent,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final Color color;
  final Color accent;
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
