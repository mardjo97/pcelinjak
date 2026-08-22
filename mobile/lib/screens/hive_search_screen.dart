import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scan.dart';
import '../widgets/home_fab.dart';
import '../utils/system_insets.dart';
import '../widgets/keyboard_dismiss.dart';
import 'hive_screen.dart';

class HiveSearchScreen extends StatefulWidget {
  const HiveSearchScreen({super.key});

  @override
  State<HiveSearchScreen> createState() => _HiveSearchScreenState();
}

class _HiveSearchScreenState extends State<HiveSearchScreen> {
  final db = AppDatabase.instance;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<HiveSearchHit> _hits = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _search(value));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final hits = await db.searchHives(q);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  Future<void> _scan() async {
    final code = await scanBarcode(context);
    if (code == null || code.isEmpty || !mounted) return;
    _ctrl.text = code;
    await _search(code);
    if (_hits.length == 1 && mounted) {
      await _open(_hits.first);
    }
  }

  Future<void> _open(HiveSearchHit hit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HiveScreen(hiveUuid: hit.hive.uuid)),
    );
    _search(_ctrl.text);
  }

  String _queenLine(AppLocalizations l10n, Queen? q) {
    if (q == null) return l10n.noQueen;
    final parts = <String>[];
    if (q.queenYear != null) parts.add('${q.queenYear}');
    if (q.marked) parts.add(l10n.queenMarkedShort);
    if (q.origin != null && q.origin!.trim().isNotEmpty) parts.add(q.origin!);
    return parts.isEmpty ? l10n.queen : l10n.queenLine(parts.join(' · '));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _ctrl.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hiveSearchTitle)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onQueryChanged,
              onTapOutside: dismissKeyboardOnTapOutside,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.hiveSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (q.isNotEmpty)
                      IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          _search('');
                        },
                      ),
                    IconButton(
                      tooltip: l10n.scan,
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              q.isEmpty
                  ? l10n.hiveSearchAllHint
                  : l10n.hiveSearchResultCount(_hits.length),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted(context)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DismissKeyboardOnPointer(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          q.isEmpty
                              ? l10n.noHives
                              : l10n.hiveSearchNoResults(q),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, fabClearancePadding(context)),
                      itemCount: _hits.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final hit = _hits[i];
                        final h = hit.hive;
                        final a = hit.apiary;
                        final status = LocaleController.hiveStatusLabel(l10n, h.status);
                        return Material(
                          color: AppTheme.card(context),
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.tintedSurface(
                                context,
                                AppColors.mist,
                              ),
                              foregroundColor: AppTheme.isDark(context)
                                  ? Theme.of(context).colorScheme.onSurface
                                  : AppColors.meadowDark,
                              child: Text(
                                '${h.orderNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              '${h.barcode} · ${h.hiveType}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (a != null)
                                  l10n.apiaryNamed(a.workNumber, a.name),
                                _queenLine(l10n, hit.queen),
                                if (h.status != 'ACTIVE') status,
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(hit),
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
