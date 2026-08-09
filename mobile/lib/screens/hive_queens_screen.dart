import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/home_fab.dart';

class HiveQueensScreen extends StatefulWidget {
  const HiveQueensScreen({super.key, required this.hiveUuid, this.hiveLabel});

  final String hiveUuid;
  final String? hiveLabel;

  @override
  State<HiveQueensScreen> createState() => _HiveQueensScreenState();
}

class _HiveQueensScreenState extends State<HiveQueensScreen> {
  final db = AppDatabase.instance;
  List<Queen> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final queens = await db.listQueens(widget.hiveUuid);
    if (!mounted) return;
    setState(() {
      _history = queens.where((q) => !q.active).toList();
      _loading = false;
    });
  }

  Future<void> _openDetails(Queen q) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matica'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (q.marked && q.queenYear != null)
                            ? queenMarkColor(q.queenYear!)
                            : Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Godina ${q.queenYear ?? '—'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Obeležena', q.marked ? 'DA' : 'NE'),
                _detailRow('Period', q.periodLabel),
                if (q.endReason != null)
                  _detailRow(
                    'Razlog završetka',
                    queenEndReasons[q.endReason!] ?? q.endReason!,
                  ),
                if (q.origin != null && q.origin!.isNotEmpty)
                  _detailRow('Poreklo', q.origin!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.honey,
        foregroundColor: Colors.white,
        title: Text(
          widget.hiveLabel == null
              ? 'Istorija matica'
              : 'Istorija matica · ${widget.hiveLabel}',
        ),
      ),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Nema ranijih matica.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final q = _history[i];
                    return Material(
                      color: AppTheme.card(context),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (q.marked && q.queenYear != null)
                                ? queenMarkColor(q.queenYear!)
                                : Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        title: Text(
                          'Godina ${q.queenYear ?? '—'} · ${q.marked ? 'obeležena' : 'neobeležena'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            q.periodLabel,
                            if (q.endReason != null)
                              queenEndReasons[q.endReason!] ?? q.endReason!,
                            if (q.origin != null && q.origin!.isNotEmpty)
                              q.origin!,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetails(q),
                      ),
                    );
                  },
                ),
    );
  }
}
