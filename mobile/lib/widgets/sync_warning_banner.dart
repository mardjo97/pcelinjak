import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../screens/sync_screen.dart';
import '../services/api_client.dart';

/// Traka upozorenja za lokalne izmene koje nisu na serveru.
class SyncWarningBanner extends StatelessWidget {
  const SyncWarningBanner({
    super.key,
    required this.count,
    this.api,
    this.compact = false,
    this.message,
  });

  final int count;
  final ApiClient? api;
  final bool compact;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = message ?? (count == 1 ? l10n.unsyncedOne : l10n.unsyncedMany(count));

    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF3D3420) : const Color(0xFFFFF3CD);
    final fg = dark ? const Color(0xFFF3E2A8) : Colors.orange.shade900;
    return Material(
      color: bg,
      child: InkWell(
        onTap: api == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SyncScreen(api: api!)),
                );
              },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 8 : 12),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: fg, size: compact ? 20 : 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              if (api != null)
                Text(
                  'Sync',
                  style: TextStyle(
                    color: dark ? const Color(0xFF6FBF8F) : AppColors.meadowDark,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
