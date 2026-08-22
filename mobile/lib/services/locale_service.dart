import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Upravljanje jezikom aplikacije.
///
/// `null` = pratiti jezik telefona (uz podršku + fallback na srpski).
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale_code';

  static const supported = <Locale>[
    Locale('sr'),
    Locale('en'),
    Locale('hr'),
    Locale('bs'),
    Locale('cnr'),
  ];

  /// Sačuvani izbor: `system` ili languageCode (`sr`, `en`, …).
  String _preference = 'system';

  String get preference => _preference;

  /// Locale koji MaterialApp treba da koristi (uvek konkretan).
  Locale get locale => resolve(_preference);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preference = prefs.getString(_prefsKey) ?? 'system';
    notifyListeners();
  }

  Future<void> setPreference(String code) async {
    _preference = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }

  static Locale resolve(String preference) {
    if (preference != 'system') {
      final match = supported.where((l) => l.languageCode == preference);
      if (match.isNotEmpty) return match.first;
    }
    return fromDevice(WidgetsBinding.instance.platformDispatcher.locale);
  }

  static Locale fromDevice(Locale device) {
    final lang = device.languageCode.toLowerCase();
    final country = (device.countryCode ?? '').toUpperCase();

    // Crna Gora često dolazi kao sr_ME.
    if (lang == 'cnr' || (lang == 'sr' && country == 'ME') || lang == 'me') {
      return const Locale('cnr');
    }
    if (lang == 'hr') return const Locale('hr');
    if (lang == 'bs') return const Locale('bs');
    if (lang == 'en') return const Locale('en');
    if (lang == 'sr') return const Locale('sr');

    return const Locale('sr');
  }

  static String labelFor(AppLocalizations l10n, String code) {
    switch (code) {
      case 'system':
        return l10n.languageSystem;
      case 'sr':
        return l10n.langSr;
      case 'en':
        return l10n.langEn;
      case 'hr':
        return l10n.langHr;
      case 'bs':
        return l10n.langBs;
      case 'cnr':
        return l10n.langCnr;
      default:
        return code;
    }
  }

  static String workGroupTitle(AppLocalizations l10n, String type) {
    switch (type) {
      case 'MOVED':
        return l10n.groupMoved;
      case 'GOOD_PASTURE':
        return l10n.groupGoodPasture;
      case 'QUEEN_CHANGE':
        return l10n.groupQueenChange;
      case 'CONTROL':
        return l10n.groupControl;
      case 'FEEDING':
        return l10n.groupFeeding;
      case 'REPRODUCTION':
        return l10n.groupReproduction;
      default:
        return type;
    }
  }

  static String hiveStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'ARCHIVED':
        return l10n.statusArchived;
      case 'DEAD':
        return l10n.statusDead;
      default:
        return l10n.statusActive;
    }
  }

  static String membershipStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return l10n.membershipFinished;
      case 'REMOVED':
        return l10n.membershipRemoved;
      default:
        return l10n.membershipActive;
    }
  }

  static String periodLabel(AppLocalizations l10n, DateTime from, DateTime? to) {
    final fromStr = from.toLocal().toString().split(' ').first;
    if (to == null) return l10n.periodFrom(fromStr);
    return '$fromStr → ${to.toLocal().toString().split(' ').first}';
  }

  static String queenEndReason(AppLocalizations l10n, String? reason) {
    switch (reason) {
      case 'DIED':
        return l10n.queenEndDied;
      case 'REPLACED':
        return l10n.queenEndReplaced;
      case 'SUPERSEDED':
        return l10n.queenEndSuperseded;
      case 'OTHER':
        return l10n.queenEndOther;
      default:
        return reason ?? '';
    }
  }

  static String inspectionSourceLabel(AppLocalizations l10n, String? sourceType) {
    switch (sourceType) {
      case 'CONTROL_GROUP':
        return l10n.inspectionSourceGroup;
      case 'REMINDER':
        return l10n.inspectionSourceReminder;
      default:
        return l10n.inspectionSourceManual;
    }
  }

  static String inspectionOutcomeLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'FOLLOW_UP':
        return l10n.inspectionOutcomeFollowUp;
      case 'URGENT':
        return l10n.inspectionOutcomeUrgent;
      case 'RESOLVED':
        return l10n.inspectionOutcomeResolved;
      default:
        return l10n.inspectionOutcomeOk;
    }
  }
}
