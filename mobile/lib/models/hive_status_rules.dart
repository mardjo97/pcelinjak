import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

/// Pravila šta je dozvoljeno po statusu košnice.
///
/// | Akcija              | ACTIVE | ARCHIVED | DEAD |
/// |---------------------|--------|----------|------|
/// | Pregled             | ✓      | ✓        | ✓    |
/// | Izmena barkod/tip   | ✓      | ✓        | ✗    |
/// | Napomene            | ✓      | ✓        | ✓    |
/// | Matica              | ✓      | ✗        | ✗    |
/// | Prinos              | ✓      | ✗        | ✗    |
/// | Dodavanje u grupe   | ✓      | ✗        | ✗    |
/// | → ACTIVE            | —      | ✓        | ✓    |
/// | → ARCHIVED          | ✓      | —        | ✗    |
/// | → DEAD              | ✓      | ✓        | —    |
/// | Brisanje            | ✓      | ✓        | ✓    |
class HiveStatusRules {
  static String normalize(String? status) {
    if (status == null || status.trim().isEmpty) return 'ACTIVE';
    return status;
  }

  static String label(AppLocalizations l10n, String? status) =>
      LocaleController.hiveStatusLabel(l10n, normalize(status));

  static bool isActive(String? status) => normalize(status) == 'ACTIVE';
  static bool isArchived(String? status) => normalize(status) == 'ARCHIVED';
  static bool isDead(String? status) => normalize(status) == 'DEAD';

  static bool canEditHive(String? status) => !isDead(status);
  static bool canAddNote(String? status) => true;
  static bool canManageQueen(String? status) => isActive(status);
  static bool canAddHarvest(String? status) => isActive(status);
  static bool canAddToGroup(String? status) => isActive(status);
  static bool canDelete(String? status) => true;

  /// Dozvoljeni prelazi statusa (bez trenutnog).
  static List<String> allowedTransitions(String? from) {
    switch (normalize(from)) {
      case 'ARCHIVED':
        return const ['ACTIVE', 'DEAD'];
      case 'DEAD':
        return const ['ACTIVE'];
      default:
        return const ['ARCHIVED', 'DEAD'];
    }
  }

  static bool canTransitionTo(String? from, String to) =>
      allowedTransitions(from).contains(to);

  static String? blockReasonAddToGroup(AppLocalizations l10n, String? status) {
    if (canAddToGroup(status)) return null;
    return l10n.hiveAddToGroupBlocked(label(l10n, status));
  }

  static String? blockReasonQueen(AppLocalizations l10n, String? status) {
    if (canManageQueen(status)) return null;
    return l10n.hiveQueenBlocked(label(l10n, status));
  }

  static String? blockReasonHarvest(AppLocalizations l10n, String? status) {
    if (canAddHarvest(status)) return null;
    return l10n.hiveHarvestBlocked(label(l10n, status));
  }

  static String? blockReasonEditHive(AppLocalizations l10n, String? status) {
    if (canEditHive(status)) return null;
    return l10n.hiveEditBlocked;
  }
}
