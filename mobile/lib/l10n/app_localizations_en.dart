// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Apiary';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get langSr => 'Serbian';

  @override
  String get langEn => 'English';

  @override
  String get langHr => 'Croatian';

  @override
  String get langBs => 'Bosnian';

  @override
  String get langCnr => 'Montenegrin';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueAction => 'Continue';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get home => 'Home';

  @override
  String get scan => 'Scan';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get waiting => 'Please wait…';

  @override
  String get saving => 'Saving…';

  @override
  String get authLoginSubtitle => 'Sign in on this phone';

  @override
  String get authRegisterSubtitle => 'Enter your details and open My apiary';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get createAccount => 'Create account';

  @override
  String get registerCheckEmailActivation =>
      'Check your email (inbox and spam) and click the activation link.';

  @override
  String get continueOffline => 'Continue offline (no sync)';

  @override
  String get offlineDataWarning =>
      'You are using the app without signing in. Data on this phone may be lost when you sign in.';

  @override
  String get offlineContinueConfirm =>
      'Without an account, data stays only on this phone and may be lost when you later sign in.\n\nContinue offline?';

  @override
  String get loginReplaceDataConfirm =>
      'Local data on this phone may be replaced by account data. Continue signing in?';

  @override
  String get authDeviceNote =>
      'Only one phone can be signed in. Signing in on a new device signs out the old one.';

  @override
  String myApiaryHives(int count) {
    return 'My apiary · $count hives total';
  }

  @override
  String get findHive => 'Find hive';

  @override
  String get reminders => 'Reminders';

  @override
  String remindersCount(int count) {
    return 'Reminders ($count)';
  }

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get exportBarcodes => 'Export barcodes';

  @override
  String get logout => 'Sign out';

  @override
  String get goToLogin => 'Go to sign in';

  @override
  String get addApiary => 'Add apiary';

  @override
  String get apiariesSection => 'Apiaries';

  @override
  String get apiariesSectionHint => 'Permanent locations and hives';

  @override
  String get hiveGroups => 'Hive groups';

  @override
  String get hiveGroupsHint => 'Temporary work lists';

  @override
  String get total => 'TOTAL';

  @override
  String apiaryLabel(int number) {
    return 'APIARY $number';
  }

  @override
  String get noApiariesYet =>
      'No apiaries yet. Add the first one — it will get a work number.';

  @override
  String get unsyncedTitle => 'Unsynced data';

  @override
  String unsyncedExportBody(int count) {
    return 'You have $count local changes not on the server. Export will use data from this phone.\n\nContinue?';
  }

  @override
  String get settingsIntro => 'Theme, language and other app preferences.';

  @override
  String get beekeeperName => 'Beekeeper full name';

  @override
  String get hidLabel => 'HID (farm veterinary number)';

  @override
  String get hidHint => 'e.g. 12 digits';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncIntro =>
      'Changes are sent automatically when online. Offline work stays local — sync here pushes and pulls everything from the server.';

  @override
  String get syncAllDone => 'All local changes are synced.';

  @override
  String get syncing => 'Syncing…';

  @override
  String get sendToServer => 'Send to server';

  @override
  String get deviceMismatch => 'Account is active on another phone.';

  @override
  String unsyncedWaiting(int count) {
    return '$count local changes waiting to send.';
  }

  @override
  String get unsyncedOne => '1 local change is not synced.';

  @override
  String unsyncedMany(int count) {
    return '$count local changes are not synced.';
  }

  @override
  String get reportsIntro =>
      'Choose a report, then format: PDF, Word (DOCX) or CSV. Beekeeper data (HID, name) and apiary ID come from your profile.';

  @override
  String get exportFormat => 'Export format';

  @override
  String get formatPdf => 'PDF';

  @override
  String get formatDocx => 'Word (DOCX)';

  @override
  String get formatCsv => 'CSV';

  @override
  String get reportHarvestTitle => 'Yield by pasture and apiary';

  @override
  String get reportHarvestSubtitle =>
      'Kg totals for the current year, by pasture and apiary';

  @override
  String get reportPrijavaTitle => 'Status declaration (Annex 4)';

  @override
  String get reportPrijavaSubtitle =>
      'Form with active hive barcodes — per apiary';

  @override
  String get reportQueensTitle => 'Queen overview';

  @override
  String get reportQueensSubtitle =>
      'Year, marking and origin of active queens';

  @override
  String get noApiariesForReport => 'No apiaries for the declaration.';

  @override
  String get missingConfig => 'Missing configuration';

  @override
  String get openSettings => 'Open settings';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get newApiary => 'New apiary';

  @override
  String get editApiary => 'Edit apiary';

  @override
  String get name => 'Name';

  @override
  String get locationOptional => 'Location (optional)';

  @override
  String get officialApiaryId => 'Apiary ID (Annex 4)';

  @override
  String get color => 'Color';

  @override
  String get addHive => 'Add hive';

  @override
  String workNumber(int number) {
    return 'Work number: $number';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusArchived => 'Archived';

  @override
  String get statusDead => 'Dead';

  @override
  String get statusAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterArchived => 'Archived';

  @override
  String get filterDead => 'Dead';

  @override
  String get groupMoved => 'Moved hives';

  @override
  String get groupGoodPasture => 'Good on pasture';

  @override
  String get groupQueenChange => 'Queen replacement';

  @override
  String get groupControl => 'For inspection';

  @override
  String get groupFeeding => 'For feeding';

  @override
  String get groupReproduction => 'For reproduction';

  @override
  String get membershipActive => 'Active';

  @override
  String get membershipFinished => 'Finished';

  @override
  String get membershipRemoved => 'Removed';

  @override
  String get hiveSearchTitle => 'Search hives';

  @override
  String get hiveSearchHint => 'Barcode, apiary, type, queen…';

  @override
  String get noHives => 'No hives.';

  @override
  String get hive => 'Hive';

  @override
  String get notes => 'Notes';

  @override
  String get harvests => 'Harvests';

  @override
  String get queen => 'Queen';

  @override
  String get barcode => 'Barcode';

  @override
  String get type => 'Type';

  @override
  String get description => 'Description';

  @override
  String get pasture => 'Pasture';

  @override
  String get amountKg => 'Amount (kg)';

  @override
  String get location => 'Location';

  @override
  String get note => 'Note';

  @override
  String get finishInGroup => 'Finish (end in group)';

  @override
  String get removeMistake => 'Remove (added by mistake)';

  @override
  String get deleteWithoutHistory => 'Delete without history';

  @override
  String get editInGroup => 'Edit in group';

  @override
  String addToGroup(String title) {
    return 'Add to $title';
  }

  @override
  String get typeCode => 'Type code';

  @override
  String get code => 'Code';

  @override
  String get hiveNotInDb => 'Hive not in database';

  @override
  String get listEmptyScan => 'List is empty. Scan a hive.';

  @override
  String get historyEmpty => 'No records in this history.';

  @override
  String get filterFinished => 'Finished';

  @override
  String get filterRemoved => 'Removed (mistake)';

  @override
  String get filterAllHistory => 'All (history)';

  @override
  String get deleteWithoutHistoryTitle => 'Delete without history';

  @override
  String get deleteWithoutHistoryBody =>
      'Deletes group membership without keeping history. Also deletes linked harvest (if any), notes and reminders.';

  @override
  String get barcodeShareSubject => 'Hive barcode list';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic (system)';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsReports => 'Reports and server';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsDanger => 'Account';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyTitle => 'Privacy policy – Pčelinjak';

  @override
  String get privacyUpdated => 'Last updated: August 2026.';

  @override
  String get privacyBody =>
      'The Pčelinjak app collects data needed for apiary records and sync with the server.\n\n1. Account data\nWe store email, first name, last name, phone (optional) and a password hash. Only one device can be active per account.\n\n2. Apiary data\nHives, queens, notes, harvests, work groups and reminders are stored locally and, when you sync, on our server linked to your account.\n\n3. Feedback\nIf you send feedback, the message and email are stored to improve the app.\n\n4. Sharing\nWe do not sell personal data. Data is used only to operate the app.\n\n5. Deletion\nYou can delete your account in Profile with password confirmation. This removes data on the server and on this device.\n\n6. Contact\nFor privacy questions use Feedback in the app.';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackIntro => 'Tell us what to improve or what is not working.';

  @override
  String get feedbackMessage => 'Message';

  @override
  String get feedbackRequired => 'Please enter a message.';

  @override
  String get feedbackThanks => 'Thanks! Your message was sent.';

  @override
  String get sendFeedback => 'Send';

  @override
  String get sending => 'Sending…';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Permanently deletes your account and all data on the server and this phone. Enter your password to confirm.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get accountDeleted => 'Account deleted.';

  @override
  String get profile => 'Profile';

  @override
  String get profileIntro =>
      'Account details for official forms (Annex 4). Apiary ID is set on each apiary.';

  @override
  String get profileAccount => 'Account';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get nameRequired => 'Enter first and last name.';

  @override
  String get invalidPhone => 'Invalid phone number.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get passwordTooShort => 'New password must be at least 6 characters.';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get passwordHint =>
      'At least 6 characters, an uppercase letter, a lowercase letter and a number';

  @override
  String passwordMustInclude(String requirements) {
    return 'Password must include: $requirements.';
  }

  @override
  String get passwordReqLength => 'at least 6 characters';

  @override
  String get passwordReqUpper => 'an uppercase letter';

  @override
  String get passwordReqLower => 'a lowercase letter';

  @override
  String get passwordReqDigit => 'a number';

  @override
  String get listAnd => 'and';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSmall => 'Small';

  @override
  String get settingsTextNormal => 'Normal';

  @override
  String get settingsTextLarge => 'Large';

  @override
  String get settingsTextVeryLarge => 'Larger';

  @override
  String get settingsAutorotation => 'Autorotation';

  @override
  String get settingsAutorotationSubtitle => 'Allow landscape orientation';

  @override
  String get openProfile => 'Open profile';

  @override
  String get authLoginInvalidCredentials => 'Wrong email or password.';

  @override
  String get authAccountNotActivated =>
      'Account is not activated. Check your email for the activation link.';

  @override
  String get authEmailExists => 'A user with this email already exists.';

  @override
  String get authWrongPassword => 'Wrong password.';

  @override
  String get authUserNotFound => 'User not found.';

  @override
  String get hiveSearchAllHint =>
      'All hives · filter by barcode, apiary name/number, type (LR, DB…), queen year, origin, “marked”…';

  @override
  String hiveSearchResultCount(int count) {
    return '$count results';
  }

  @override
  String hiveSearchNoResults(String query) {
    return 'No results for “$query”.';
  }

  @override
  String get noQueen => 'No queen';

  @override
  String get queenMarkedShort => 'marked';

  @override
  String queenLine(String details) {
    return 'Queen: $details';
  }

  @override
  String apiaryNamed(int number, String name) {
    return 'Apiary $number · $name';
  }

  @override
  String get remindersShowHistory => 'Show history';

  @override
  String get remindersCompletedList => 'Completed reminders';

  @override
  String get remindersUpcomingList => 'Upcoming and overdue';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get remindersEmptyUpcoming => 'No upcoming reminders.';

  @override
  String get remindersEmptyHistory => 'No completed reminders.';

  @override
  String remindersNoneForDay(String day) {
    return 'No reminders for $day.';
  }

  @override
  String get reminderReactivated => 'Reminder is active again';

  @override
  String get markDone => 'Mark as done';

  @override
  String get restoreActive => 'Restore to active';

  @override
  String hiveBarcode(String barcode) {
    return 'Hive $barcode';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderNotFound => 'Reminder not found.';

  @override
  String get completed => 'Completed';

  @override
  String get related => 'Related';

  @override
  String get noLinkedHive => 'No linked hive.';

  @override
  String get openHive => 'Open hive';

  @override
  String get openGroup => 'Open group';

  @override
  String get recordInspection => 'Record inspection';

  @override
  String get openInspection => 'Open inspection';

  @override
  String get reminderMarkedDone => 'Reminder marked as done';

  @override
  String get hiveNotFound => 'Hive not found.';

  @override
  String loadError(String error) {
    return 'Could not load: $error';
  }

  @override
  String get back => 'Back';

  @override
  String get previousHive => 'Previous hive';

  @override
  String get nextHive => 'Next hive';

  @override
  String get editHive => 'Edit hive';

  @override
  String get editNotAllowed => 'Edit (not allowed)';

  @override
  String get deleteHive => 'Delete hive';

  @override
  String get deleteHiveConfirm =>
      'The hive will be deleted (it can sync as deleted).';

  @override
  String get hiveStatusConfirmTitle => 'Hive status';

  @override
  String hiveStatusConfirmBody(String status) {
    return 'Set status to “$status”?';
  }

  @override
  String hiveStatusTransitionBlocked(String from, String to) {
    return 'Cannot change $from → $to.';
  }

  @override
  String get status => 'Status';

  @override
  String get move => 'Move';

  @override
  String get locationNotEntered => 'Location not entered';

  @override
  String get queenOnlyActive => 'Active only';

  @override
  String get enterQueen => 'Add queen';

  @override
  String get editCurrentQueen => 'Edit current';

  @override
  String get editQueen => 'Edit queen';

  @override
  String hiveQueenBlocked(String status) {
    return 'The queen can be changed only on an active hive (now: $status).';
  }

  @override
  String hiveHarvestBlocked(String status) {
    return 'Harvest can be added only on an active hive (now: $status).';
  }

  @override
  String get hiveEditBlocked =>
      'A dead hive cannot be edited — set it to active first.';

  @override
  String hiveAddToGroupBlocked(String status) {
    return 'Hive is “$status” — only active hives can be added to groups.';
  }

  @override
  String get noActiveQueen => 'No active queen.';

  @override
  String queenYearLabel(String year) {
    return 'Year: $year';
  }

  @override
  String queenMarkedLabel(String value) {
    return 'Marked: $value';
  }

  @override
  String get year => 'Year';

  @override
  String get origin => 'Origin';

  @override
  String get marked => 'Marked';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String originWithValue(String value) {
    return 'Origin: $value';
  }

  @override
  String periodFrom(String date) {
    return 'From $date';
  }

  @override
  String get newQueen => 'New queen';

  @override
  String get endQueen => 'End queen';

  @override
  String get endQueenDied => 'End / died';

  @override
  String queenHistoryCount(int count) {
    return 'Queen history ($count)';
  }

  @override
  String currentQueenLine(String year, String period) {
    return 'Current: year $year · $period';
  }

  @override
  String get queenEndReasonLabel => 'What happened to the previous queen?';

  @override
  String get enterNewQueenAfter => 'Then enter the new queen’s details.';

  @override
  String get queenEndDied => 'Died';

  @override
  String get queenEndReplaced => 'Replaced';

  @override
  String get queenEndSuperseded => 'Superseded';

  @override
  String get queenEndOther => 'Other';

  @override
  String get hiveInspection => 'Hive inspection';

  @override
  String get addInspection => 'Add inspection';

  @override
  String get noInspectionsYet => 'No inspections for this hive yet.';

  @override
  String get lastInspection => 'Latest inspection';

  @override
  String get source => 'Source';

  @override
  String allInspections(int count) {
    return 'All inspections ($count)';
  }

  @override
  String get addNote => 'Add note';

  @override
  String get noNotesYet => 'No notes for this hive yet.';

  @override
  String get lastNote => 'Latest note';

  @override
  String reminderAt(String when) {
    return 'Reminder: $when';
  }

  @override
  String allNotes(int count) {
    return 'All notes ($count)';
  }

  @override
  String get honeyHarvest => 'Honey yield';

  @override
  String get addHarvest => 'Add harvest';

  @override
  String harvestYearTotal(int year, String amount) {
    return 'Total $year: $amount kg';
  }

  @override
  String get noHarvestsThisYear => 'No harvests recorded this year.';

  @override
  String allHarvests(int count) {
    return 'All harvests ($count)';
  }

  @override
  String get deleteNoteTitle => 'Delete note';

  @override
  String get deleteNoteConfirm => 'Delete this note?';

  @override
  String get inspectionSourceManual => 'Manual';

  @override
  String get inspectionSourceGroup => 'Inspection group';

  @override
  String get inspectionSourceReminder => 'Reminder';

  @override
  String get inspectionOutcomeOk => 'OK';

  @override
  String get inspectionOutcomeFollowUp => 'Follow-up needed';

  @override
  String get inspectionOutcomeUrgent => 'Urgent';

  @override
  String get inspectionOutcomeResolved => 'Resolved';
}
