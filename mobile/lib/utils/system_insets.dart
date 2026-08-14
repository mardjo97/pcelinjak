import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Bottom inset for system navigation (gesture bar / 3-button nav).
///
/// Samsung One UI on Android 15/16 often reports 0 via [MediaQuery] while the
/// nav bar still overlays content. This falls back to the window [FlutterView]
/// metrics, then to a typical nav-bar height on Android.
double systemBottomInset(BuildContext context) {
  final mq = MediaQuery.of(context);
  final fromMediaQuery = math.max(
    mq.padding.bottom,
    math.max(mq.viewPadding.bottom, mq.systemGestureInsets.bottom),
  );
  if (fromMediaQuery > 0) return fromMediaQuery;

  final view = View.maybeOf(context);
  if (view != null) {
    final dpr = view.devicePixelRatio;
    if (dpr > 0) {
      final fromView = math.max(
            view.padding.bottom,
            view.viewPadding.bottom,
          ) /
          dpr;
      if (fromView > 0) return fromView;
    }
  }

  // Edge-to-edge on Android 15+/One UI can leave insets at 0 while the system
  // nav bar still covers the bottom of the screen.
  if (!kIsWeb && Platform.isAndroid) {
    return 48;
  }
  return 0;
}

/// Standard Material FAB size (diameter).
const double kFabSize = 56;

/// Bottom padding so scrollable content can clear the Home / Add FAB row.
///
/// Matches FAB height + bottom margin + the *reported* view padding.
/// Does **not** use the Android 48px fallback from [systemBottomInset].
double fabClearancePadding(BuildContext context, {double margin = 24}) {
  final mq = MediaQuery.of(context);
  final inset = math.max(mq.viewPadding.bottom, mq.padding.bottom);
  return kFabSize + margin + inset + 8;
}

/// Settings / Profile / Privacy: nav-bar fallback plus Home FAB clearance.
double settingsScrollBottom(BuildContext context) {
  return math.max(fabClearancePadding(context), 16 + systemBottomInset(context));
}
