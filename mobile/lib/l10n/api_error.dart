import '../services/api_client.dart';
import 'app_localizations.dart';

String localizeApiError(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return '$error';
  final message = error.message;
  if (error.isDeviceMismatch) {
    return l10n.deviceMismatch;
  }
  if (message == 'Pogrešan email ili lozinka.' ||
      (error.statusCode == 401 && message.toLowerCase().contains('email'))) {
    return l10n.authLoginInvalidCredentials;
  }
  if (message.startsWith('Nalog nije aktiviran') || error.statusCode == 403) {
    return l10n.authAccountNotActivated;
  }
  if (message == 'Korisnik sa ovim email-om već postoji.') {
    return l10n.authEmailExists;
  }
  if (message == 'Pogrešna lozinka.') {
    return l10n.authWrongPassword;
  }
  if (message == 'Korisnik nije pronađen.') {
    return l10n.authUserNotFound;
  }
  if (message == 'Neispravan broj telefona.') {
    return l10n.invalidPhone;
  }
  if (message == 'Ime i prezime su obavezni.') {
    return l10n.nameRequired;
  }
  if (message == 'Lozinka je obavezna.') {
    return l10n.passwordRequired;
  }
  return message;
}
