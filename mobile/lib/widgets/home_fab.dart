import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Floating „Početna” — vraća na root (HomeScreen).
class HomeFab extends StatelessWidget {
  const HomeFab({super.key, this.mini = false});

  final bool mini;

  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Početna levo, primarni FAB desno.
  static Widget pair({
    required Widget primary,
    bool showHome = true,
  }) {
    return Builder(
      builder: (context) {
        final width = MediaQuery.sizeOf(context).width - 32;
        return SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showHome) const HomeFab() else const SizedBox.shrink(),
              primary,
            ],
          ),
        );
      },
    );
  }

  /// @Deprecated — koristi [pair]; ostaje alias radi kompatibilnosti.
  static Widget column({
    required Widget primary,
    bool showHome = true,
  }) =>
      pair(primary: primary, showHome: showHome);

  @override
  Widget build(BuildContext context) {
    final homeLabel = AppLocalizations.of(context).home;
    if (mini) {
      return FloatingActionButton.small(
        heroTag: 'home_fab',
        backgroundColor: AppColors.meadowDark,
        foregroundColor: Colors.white,
        onPressed: () => goHome(context),
        child: const Icon(Icons.home),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'home_fab',
      backgroundColor: AppColors.meadowDark,
      foregroundColor: Colors.white,
      onPressed: () => goHome(context),
      icon: const Icon(Icons.home),
      label: Text(homeLabel),
    );
  }
}
