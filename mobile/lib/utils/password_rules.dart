import '../l10n/app_localizations.dart';

class PasswordRules {
  static const minLength = 6;

  static bool isLetterUpper(String ch) {
    final upper = ch.toUpperCase();
    final lower = ch.toLowerCase();
    return upper != lower && ch == upper;
  }

  static bool isLetterLower(String ch) {
    final upper = ch.toUpperCase();
    final lower = ch.toLowerCase();
    return upper != lower && ch == lower;
  }

  static String? errorMessage(AppLocalizations l10n, String password) {
    final parts = <String>[];
    if (password.length < minLength) {
      parts.add(l10n.passwordReqLength);
    }
    final chars = password.split('');
    if (!chars.any(isLetterUpper)) {
      parts.add(l10n.passwordReqUpper);
    }
    if (!chars.any(isLetterLower)) {
      parts.add(l10n.passwordReqLower);
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      parts.add(l10n.passwordReqDigit);
    }
    if (parts.isEmpty) return null;
    return l10n.passwordMustInclude(_join(parts, l10n.listAnd));
  }

  static String _join(List<String> parts, String andWord) {
    if (parts.length == 1) return parts.single;
    return '${parts.sublist(0, parts.length - 1).join(', ')} $andWord ${parts.last}';
  }
}
