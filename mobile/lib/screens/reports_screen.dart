import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/beekeeper_prefs.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_fab.dart';
import 'settings_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final db = AppDatabase.instance;
  ReportType? _busy;

  Future<void> _run(ReportType type) async {
    final l10n = AppLocalizations.of(context);
    if (type == ReportType.prijavaStanja) {
      final ready = await _ensurePrijavaConfig();
      if (!ready) return;
    }

    final format = await _pickFormat();
    if (format == null) return;

    setState(() => _busy = type);
    try {
      await ReportService(db).generateAndShare(type, format: format);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportError('$e'))));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<ReportFormat?> _pickFormat() {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<ReportFormat>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.exportFormat, style: const TextStyle(fontWeight: FontWeight.w800))),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.formatPdf),
              onTap: () => Navigator.pop(ctx, ReportFormat.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.formatDocx),
              onTap: () => Navigator.pop(ctx, ReportFormat.docx),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.formatCsv),
              onTap: () => Navigator.pop(ctx, ReportFormat.csv),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensurePrijavaConfig() async {
    final l10n = AppLocalizations.of(context);
    final session = await widget.api.session();
    final name = await BeekeeperPrefs.reportName(fallback: session['name']);
    final hid = await BeekeeperPrefs.hid();
    final apiaries = await db.listApiaries();
    if (!mounted) return false;

    if (apiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noApiariesForReport)),
      );
      return false;
    }

    final missingIdentity = name.isEmpty || hid.isEmpty;
    final missingIds = apiaries.where((a) => a.officialId == null || a.officialId!.isEmpty).toList();

    if (missingIdentity || missingIds.isNotEmpty) {
      final parts = <String>[];
      if (name.isEmpty) parts.add(l10n.beekeeperName);
      if (hid.isEmpty) parts.add('HID');
      if (missingIds.isNotEmpty) {
        parts.add(
          '${l10n.officialApiaryId}: ${missingIds.map((a) => '${a.workNumber} · ${a.name}').join(', ')}',
        );
      }
      final goSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.missingConfig),
          content: Text('• ${parts.join('\n• ')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            if (missingIdentity)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.openSettings),
              )
            else
              FilledButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.ok)),
          ],
        ),
      );
      if (goSettings == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen(api: widget.api)),
        );
      }
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      floatingActionButton: const HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(l10n.reportsIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final type in ReportType.values) ...[
            _ReportCard(
              type: type,
              loading: _busy == type,
              enabled: _busy == null,
              onTap: () => _run(type),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.type,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final ReportType type;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: AppTheme.card(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: AppColors.meadow, width: 6)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.ios_share_outlined,
                color: AppTheme.isDark(context) ? onSurface : AppColors.meadowDark,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title(l10n),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(type.subtitle(l10n), style: TextStyle(color: AppTheme.muted(context))),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right, color: AppColors.meadow),
            ],
          ),
        ),
      ),
    );
  }
}
