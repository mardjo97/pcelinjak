import '../theme/app_theme.dart';

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

  static String label(String? status) =>
      hiveStatuses[normalize(status)] ?? normalize(status);

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

  static String? blockReasonAddToGroup(String? status) {
    if (canAddToGroup(status)) return null;
    return 'Košnica je „${label(status)}” — u grupe se mogu dodati samo aktivne košnice.';
  }

  static String? blockReasonQueen(String? status) {
    if (canManageQueen(status)) return null;
    return 'Matica se menja samo na aktivnoj košnici (sada: ${label(status)}).';
  }

  static String? blockReasonHarvest(String? status) {
    if (canAddHarvest(status)) return null;
    return 'Prinos se unosi samo na aktivnoj košnici (sada: ${label(status)}).';
  }

  static String? blockReasonEditHive(String? status) {
    if (canEditHive(status)) return null;
    return 'Ugašena košnica se ne menja — prvo je vratite u aktivnu.';
  }
}
