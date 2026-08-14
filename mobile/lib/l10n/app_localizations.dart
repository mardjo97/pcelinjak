import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_cnr.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bs'),
    Locale('cnr'),
    Locale('en'),
    Locale('hr'),
    Locale('sr'),
  ];

  /// No description provided for @appName.
  ///
  /// In sr, this message translates to:
  /// **'Pčelinjak'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In sr, this message translates to:
  /// **'Jezik'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In sr, this message translates to:
  /// **'Jezik telefona'**
  String get languageSystem;

  /// No description provided for @langSr.
  ///
  /// In sr, this message translates to:
  /// **'Srpski'**
  String get langSr;

  /// No description provided for @langEn.
  ///
  /// In sr, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langHr.
  ///
  /// In sr, this message translates to:
  /// **'Hrvatski'**
  String get langHr;

  /// No description provided for @langBs.
  ///
  /// In sr, this message translates to:
  /// **'Bosanski'**
  String get langBs;

  /// No description provided for @langCnr.
  ///
  /// In sr, this message translates to:
  /// **'Crnogorski'**
  String get langCnr;

  /// No description provided for @cancel.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get save;

  /// No description provided for @add.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In sr, this message translates to:
  /// **'Obriši'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi'**
  String get confirm;

  /// No description provided for @continueAction.
  ///
  /// In sr, this message translates to:
  /// **'Nastavi'**
  String get continueAction;

  /// No description provided for @ok.
  ///
  /// In sr, this message translates to:
  /// **'U redu'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In sr, this message translates to:
  /// **'Zatvori'**
  String get close;

  /// No description provided for @home.
  ///
  /// In sr, this message translates to:
  /// **'Početna'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj'**
  String get scan;

  /// No description provided for @scanBarcode.
  ///
  /// In sr, this message translates to:
  /// **'Skeniraj barkod'**
  String get scanBarcode;

  /// No description provided for @waiting.
  ///
  /// In sr, this message translates to:
  /// **'Sačekajte…'**
  String get waiting;

  /// No description provided for @saving.
  ///
  /// In sr, this message translates to:
  /// **'Čuvam…'**
  String get saving;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se sa ovog telefona'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Unesite lične podatke i otvorite Moj pčelinjak'**
  String get authRegisterSubtitle;

  /// No description provided for @fullName.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In sr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In sr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In sr, this message translates to:
  /// **'Lozinka'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In sr, this message translates to:
  /// **'Registruj se'**
  String get signUp;

  /// No description provided for @haveAccount.
  ///
  /// In sr, this message translates to:
  /// **'Već imam nalog'**
  String get haveAccount;

  /// No description provided for @createAccount.
  ///
  /// In sr, this message translates to:
  /// **'Napravi nalog'**
  String get createAccount;

  /// No description provided for @registerCheckEmailActivation.
  ///
  /// In sr, this message translates to:
  /// **'Proverite email (inbox i spam) i kliknite aktivacioni link.'**
  String get registerCheckEmailActivation;

  /// No description provided for @continueOffline.
  ///
  /// In sr, this message translates to:
  /// **'Nastavi offline (bez sync-a)'**
  String get continueOffline;

  /// No description provided for @offlineDataWarning.
  ///
  /// In sr, this message translates to:
  /// **'Radite bez prijave. Podaci sa ovog telefona mogu se izgubiti kada se prijavite.'**
  String get offlineDataWarning;

  /// No description provided for @offlineContinueConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Bez naloga podaci ostaju samo na ovom telefonu i mogu se izgubiti pri kasnijoj prijavi.\n\nNastaviti offline?'**
  String get offlineContinueConfirm;

  /// No description provided for @loginReplaceDataConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Lokalni podaci sa ovog telefona mogu se zameniti podacima sa naloga. Nastaviti sa prijavom?'**
  String get loginReplaceDataConfirm;

  /// No description provided for @authDeviceNote.
  ///
  /// In sr, this message translates to:
  /// **'Samo jedan telefon može biti prijavljen. Prijava sa novog uređaja odjavljuje stari.'**
  String get authDeviceNote;

  /// No description provided for @myApiaryHives.
  ///
  /// In sr, this message translates to:
  /// **'Moj pčelinjak · ukupno {count} košnica'**
  String myApiaryHives(int count);

  /// No description provided for @findHive.
  ///
  /// In sr, this message translates to:
  /// **'Pronađi košnicu'**
  String get findHive;

  /// No description provided for @reminders.
  ///
  /// In sr, this message translates to:
  /// **'Podsetnici'**
  String get reminders;

  /// No description provided for @remindersCount.
  ///
  /// In sr, this message translates to:
  /// **'Podsetnici ({count})'**
  String remindersCount(int count);

  /// No description provided for @reports.
  ///
  /// In sr, this message translates to:
  /// **'Izveštaji'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In sr, this message translates to:
  /// **'Konfiguracija'**
  String get settings;

  /// No description provided for @exportBarcodes.
  ///
  /// In sr, this message translates to:
  /// **'Izvezi barkodove'**
  String get exportBarcodes;

  /// No description provided for @logout.
  ///
  /// In sr, this message translates to:
  /// **'Odjavi se'**
  String get logout;

  /// No description provided for @goToLogin.
  ///
  /// In sr, this message translates to:
  /// **'Idi na prijavu'**
  String get goToLogin;

  /// No description provided for @addApiary.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj pčelinjak'**
  String get addApiary;

  /// No description provided for @apiariesSection.
  ///
  /// In sr, this message translates to:
  /// **'Pčelinjaci'**
  String get apiariesSection;

  /// No description provided for @apiariesSectionHint.
  ///
  /// In sr, this message translates to:
  /// **'Stalne lokacije i košnice'**
  String get apiariesSectionHint;

  /// No description provided for @hiveGroups.
  ///
  /// In sr, this message translates to:
  /// **'Grupe košnica'**
  String get hiveGroups;

  /// No description provided for @hiveGroupsHint.
  ///
  /// In sr, this message translates to:
  /// **'Privremene radne liste'**
  String get hiveGroupsHint;

  /// No description provided for @total.
  ///
  /// In sr, this message translates to:
  /// **'UKUPNO'**
  String get total;

  /// No description provided for @apiaryLabel.
  ///
  /// In sr, this message translates to:
  /// **'PČELINJAK {number}'**
  String apiaryLabel(int number);

  /// No description provided for @noApiariesYet.
  ///
  /// In sr, this message translates to:
  /// **'Još nema pčelinjaka. Dodajte prvi — aplikacija će mu dati radni broj.'**
  String get noApiariesYet;

  /// No description provided for @unsyncedTitle.
  ///
  /// In sr, this message translates to:
  /// **'Nesinhronizovani podaci'**
  String get unsyncedTitle;

  /// No description provided for @unsyncedExportBody.
  ///
  /// In sr, this message translates to:
  /// **'Imate {count} lokalnih izmena koje nisu na serveru. Izvoz će koristiti podatke sa ovog telefona.\n\nNastaviti?'**
  String unsyncedExportBody(int count);

  /// No description provided for @settingsIntro.
  ///
  /// In sr, this message translates to:
  /// **'Tema, jezik i ostala podešavanja aplikacije.'**
  String get settingsIntro;

  /// No description provided for @beekeeperName.
  ///
  /// In sr, this message translates to:
  /// **'Ime i prezime pčelara'**
  String get beekeeperName;

  /// No description provided for @hidLabel.
  ///
  /// In sr, this message translates to:
  /// **'HID (veterinarski broj gazdinstva)'**
  String get hidLabel;

  /// No description provided for @hidHint.
  ///
  /// In sr, this message translates to:
  /// **'npr. 12 cifara'**
  String get hidHint;

  /// No description provided for @settingsSaved.
  ///
  /// In sr, this message translates to:
  /// **'Konfiguracija sačuvana'**
  String get settingsSaved;

  /// No description provided for @syncTitle.
  ///
  /// In sr, this message translates to:
  /// **'Sinhronizacija'**
  String get syncTitle;

  /// No description provided for @syncIntro.
  ///
  /// In sr, this message translates to:
  /// **'Izmene se šalju automatski kad ima interneta. Offline radite lokalno — sync ovde pošalje i povuče sve sa servera.'**
  String get syncIntro;

  /// No description provided for @syncAllDone.
  ///
  /// In sr, this message translates to:
  /// **'Sve lokalne izmene su sinhronizovane.'**
  String get syncAllDone;

  /// No description provided for @syncing.
  ///
  /// In sr, this message translates to:
  /// **'Sinhronizujem…'**
  String get syncing;

  /// No description provided for @sendToServer.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji na server'**
  String get sendToServer;

  /// No description provided for @deviceMismatch.
  ///
  /// In sr, this message translates to:
  /// **'Nalog je aktivan na drugom telefonu.'**
  String get deviceMismatch;

  /// No description provided for @unsyncedWaiting.
  ///
  /// In sr, this message translates to:
  /// **'{count} lokalnih izmena čeka slanje na server.'**
  String unsyncedWaiting(int count);

  /// No description provided for @unsyncedOne.
  ///
  /// In sr, this message translates to:
  /// **'1 lokalna izmena nije sinhronizovana.'**
  String get unsyncedOne;

  /// No description provided for @unsyncedMany.
  ///
  /// In sr, this message translates to:
  /// **'{count} lokalnih izmena nije sinhronizovano.'**
  String unsyncedMany(int count);

  /// No description provided for @reportsIntro.
  ///
  /// In sr, this message translates to:
  /// **'Izaberite izveštaj, zatim format: PDF, Word (DOCX) ili CSV. Podaci pčelara (HID, ime) i ID pčelinjaka uzimaju se iz profila.'**
  String get reportsIntro;

  /// No description provided for @exportFormat.
  ///
  /// In sr, this message translates to:
  /// **'Format izvoza'**
  String get exportFormat;

  /// No description provided for @formatPdf.
  ///
  /// In sr, this message translates to:
  /// **'PDF'**
  String get formatPdf;

  /// No description provided for @formatDocx.
  ///
  /// In sr, this message translates to:
  /// **'Word (DOCX)'**
  String get formatDocx;

  /// No description provided for @formatCsv.
  ///
  /// In sr, this message translates to:
  /// **'CSV'**
  String get formatCsv;

  /// No description provided for @reportHarvestTitle.
  ///
  /// In sr, this message translates to:
  /// **'Prinos po paši i pčelinjaku'**
  String get reportHarvestTitle;

  /// No description provided for @reportHarvestSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Sume kg za tekuću godinu, po paši i pčelinjaku'**
  String get reportHarvestSubtitle;

  /// No description provided for @reportPrijavaTitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijava stanja (Prilog 4)'**
  String get reportPrijavaTitle;

  /// No description provided for @reportPrijavaSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Obrazac sa barkodovima aktivnih košnica — po pčelinjaku'**
  String get reportPrijavaSubtitle;

  /// No description provided for @reportQueensTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pregled matica'**
  String get reportQueensTitle;

  /// No description provided for @reportQueensSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Godina, markiranje i poreklo aktivnih matica'**
  String get reportQueensSubtitle;

  /// No description provided for @noApiariesForReport.
  ///
  /// In sr, this message translates to:
  /// **'Nema pčelinjaka za prijavu.'**
  String get noApiariesForReport;

  /// No description provided for @missingConfig.
  ///
  /// In sr, this message translates to:
  /// **'Nedostaje konfiguracija'**
  String get missingConfig;

  /// No description provided for @openSettings.
  ///
  /// In sr, this message translates to:
  /// **'Otvori konfiguraciju'**
  String get openSettings;

  /// No description provided for @exportError.
  ///
  /// In sr, this message translates to:
  /// **'Greška pri izvozu: {error}'**
  String exportError(String error);

  /// No description provided for @newApiary.
  ///
  /// In sr, this message translates to:
  /// **'Novi pčelinjak'**
  String get newApiary;

  /// No description provided for @editApiary.
  ///
  /// In sr, this message translates to:
  /// **'Izmena pčelinjaka'**
  String get editApiary;

  /// No description provided for @name.
  ///
  /// In sr, this message translates to:
  /// **'Naziv'**
  String get name;

  /// No description provided for @locationOptional.
  ///
  /// In sr, this message translates to:
  /// **'Lokacija (opciono)'**
  String get locationOptional;

  /// No description provided for @officialApiaryId.
  ///
  /// In sr, this message translates to:
  /// **'ID broj pčelinjaka (Prilog 4)'**
  String get officialApiaryId;

  /// No description provided for @color.
  ///
  /// In sr, this message translates to:
  /// **'Boja'**
  String get color;

  /// No description provided for @addHive.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj košnicu'**
  String get addHive;

  /// No description provided for @workNumber.
  ///
  /// In sr, this message translates to:
  /// **'Radni broj: {number}'**
  String workNumber(int number);

  /// No description provided for @statusActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivna'**
  String get statusActive;

  /// No description provided for @statusArchived.
  ///
  /// In sr, this message translates to:
  /// **'Arhivirana'**
  String get statusArchived;

  /// No description provided for @statusDead.
  ///
  /// In sr, this message translates to:
  /// **'Ugašena'**
  String get statusDead;

  /// No description provided for @statusAll.
  ///
  /// In sr, this message translates to:
  /// **'Sve'**
  String get statusAll;

  /// No description provided for @filterActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivne'**
  String get filterActive;

  /// No description provided for @filterArchived.
  ///
  /// In sr, this message translates to:
  /// **'Arhivirane'**
  String get filterArchived;

  /// No description provided for @filterDead.
  ///
  /// In sr, this message translates to:
  /// **'Ugašene'**
  String get filterDead;

  /// No description provided for @groupMoved.
  ///
  /// In sr, this message translates to:
  /// **'Seljene košnice'**
  String get groupMoved;

  /// No description provided for @groupGoodPasture.
  ///
  /// In sr, this message translates to:
  /// **'Dobre u paši'**
  String get groupGoodPasture;

  /// No description provided for @groupQueenChange.
  ///
  /// In sr, this message translates to:
  /// **'Zamena matica'**
  String get groupQueenChange;

  /// No description provided for @groupControl.
  ///
  /// In sr, this message translates to:
  /// **'Za kontrolu'**
  String get groupControl;

  /// No description provided for @groupFeeding.
  ///
  /// In sr, this message translates to:
  /// **'Za dohranu'**
  String get groupFeeding;

  /// No description provided for @groupReproduction.
  ///
  /// In sr, this message translates to:
  /// **'Za reprodukciju'**
  String get groupReproduction;

  /// No description provided for @membershipActive.
  ///
  /// In sr, this message translates to:
  /// **'Aktivna'**
  String get membershipActive;

  /// No description provided for @membershipFinished.
  ///
  /// In sr, this message translates to:
  /// **'Završena'**
  String get membershipFinished;

  /// No description provided for @membershipRemoved.
  ///
  /// In sr, this message translates to:
  /// **'Uklonjena'**
  String get membershipRemoved;

  /// No description provided for @hiveSearchTitle.
  ///
  /// In sr, this message translates to:
  /// **'Pretraga košnica'**
  String get hiveSearchTitle;

  /// No description provided for @hiveSearchHint.
  ///
  /// In sr, this message translates to:
  /// **'Barkod, pčelinjak, tip, matica…'**
  String get hiveSearchHint;

  /// No description provided for @noHives.
  ///
  /// In sr, this message translates to:
  /// **'Nema košnica.'**
  String get noHives;

  /// No description provided for @hive.
  ///
  /// In sr, this message translates to:
  /// **'Košnica'**
  String get hive;

  /// No description provided for @notes.
  ///
  /// In sr, this message translates to:
  /// **'Napomene'**
  String get notes;

  /// No description provided for @harvests.
  ///
  /// In sr, this message translates to:
  /// **'Prinosi'**
  String get harvests;

  /// No description provided for @queen.
  ///
  /// In sr, this message translates to:
  /// **'Matica'**
  String get queen;

  /// No description provided for @barcode.
  ///
  /// In sr, this message translates to:
  /// **'Barkod'**
  String get barcode;

  /// No description provided for @type.
  ///
  /// In sr, this message translates to:
  /// **'Tip'**
  String get type;

  /// No description provided for @description.
  ///
  /// In sr, this message translates to:
  /// **'Opis'**
  String get description;

  /// No description provided for @pasture.
  ///
  /// In sr, this message translates to:
  /// **'Paša'**
  String get pasture;

  /// No description provided for @amountKg.
  ///
  /// In sr, this message translates to:
  /// **'Količina (kg)'**
  String get amountKg;

  /// No description provided for @location.
  ///
  /// In sr, this message translates to:
  /// **'Lokacija'**
  String get location;

  /// No description provided for @note.
  ///
  /// In sr, this message translates to:
  /// **'Napomena'**
  String get note;

  /// No description provided for @finishInGroup.
  ///
  /// In sr, this message translates to:
  /// **'Završi (kraj u grupi)'**
  String get finishInGroup;

  /// No description provided for @removeMistake.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni (dodata greškom)'**
  String get removeMistake;

  /// No description provided for @deleteWithoutHistory.
  ///
  /// In sr, this message translates to:
  /// **'Obriši bez istorije'**
  String get deleteWithoutHistory;

  /// No description provided for @editInGroup.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni u grupi'**
  String get editInGroup;

  /// No description provided for @addToGroup.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj u {title}'**
  String addToGroup(String title);

  /// No description provided for @typeCode.
  ///
  /// In sr, this message translates to:
  /// **'Ukucaj kod'**
  String get typeCode;

  /// No description provided for @code.
  ///
  /// In sr, this message translates to:
  /// **'Kod'**
  String get code;

  /// No description provided for @hiveNotInDb.
  ///
  /// In sr, this message translates to:
  /// **'Košnica nije u bazi'**
  String get hiveNotInDb;

  /// No description provided for @listEmptyScan.
  ///
  /// In sr, this message translates to:
  /// **'Lista je prazna. Skenirajte košnicu.'**
  String get listEmptyScan;

  /// No description provided for @historyEmpty.
  ///
  /// In sr, this message translates to:
  /// **'Nema zapisa u ovoj istoriji.'**
  String get historyEmpty;

  /// No description provided for @filterFinished.
  ///
  /// In sr, this message translates to:
  /// **'Završene'**
  String get filterFinished;

  /// No description provided for @filterRemoved.
  ///
  /// In sr, this message translates to:
  /// **'Uklonjene (greška)'**
  String get filterRemoved;

  /// No description provided for @filterAllHistory.
  ///
  /// In sr, this message translates to:
  /// **'Sve (istorija)'**
  String get filterAllHistory;

  /// No description provided for @deleteWithoutHistoryTitle.
  ///
  /// In sr, this message translates to:
  /// **'Brisanje bez istorije'**
  String get deleteWithoutHistoryTitle;

  /// No description provided for @deleteWithoutHistoryBody.
  ///
  /// In sr, this message translates to:
  /// **'Obriše članstvo iz grupe bez čuvanja istorije. Briše se i povezani prinos (ako postoji), napomene i podsetnici.'**
  String get deleteWithoutHistoryBody;

  /// No description provided for @barcodeShareSubject.
  ///
  /// In sr, this message translates to:
  /// **'Spisak kodova košnica'**
  String get barcodeShareSubject;

  /// No description provided for @theme.
  ///
  /// In sr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In sr, this message translates to:
  /// **'Automatski (sistem)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In sr, this message translates to:
  /// **'Svetla'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In sr, this message translates to:
  /// **'Tamna'**
  String get themeDark;

  /// No description provided for @settingsAppearance.
  ///
  /// In sr, this message translates to:
  /// **'Izgled'**
  String get settingsAppearance;

  /// No description provided for @settingsReports.
  ///
  /// In sr, this message translates to:
  /// **'Izveštaji i server'**
  String get settingsReports;

  /// No description provided for @settingsSupport.
  ///
  /// In sr, this message translates to:
  /// **'Podrška'**
  String get settingsSupport;

  /// No description provided for @settingsDanger.
  ///
  /// In sr, this message translates to:
  /// **'Nalog'**
  String get settingsDanger;

  /// No description provided for @privacyPolicy.
  ///
  /// In sr, this message translates to:
  /// **'Politika privatnosti'**
  String get privacyPolicy;

  /// No description provided for @privacyTitle.
  ///
  /// In sr, this message translates to:
  /// **'Politika privatnosti – Pčelinjak'**
  String get privacyTitle;

  /// No description provided for @privacyUpdated.
  ///
  /// In sr, this message translates to:
  /// **'Poslednje ažuriranje: avgust 2026.'**
  String get privacyUpdated;

  /// No description provided for @privacyBody.
  ///
  /// In sr, this message translates to:
  /// **'Aplikacija Pčelinjak prikuplja podatke neophodne za evidenciju pčelinjaka i sinhronizaciju sa serverom.\n\n1. Podaci o nalogu\nČuvamo email, ime, prezime, telefon (opciono) i heš lozinke. Jedan uređaj može biti aktivan po nalogu.\n\n2. Podaci o pčelinjaku\nKošnice, matici, napomene, prinosi, grupe rada i podsetnici čuvaju se lokalno na uređaju i, kada koristite sync, na našem serveru vezano za vaš nalog.\n\n3. Feedback\nAko pošaljete povratnu informaciju, poruka i email se čuvaju radi unapređenja aplikacije.\n\n4. Deljenje\nNe prodajemo lične podatke trećim stranama. Podaci se koriste isključivo za funkcionisanje aplikacije.\n\n5. Brisanje\nMožete obrisati nalog u Profilu uz potvrdu lozinke. Time se brišu podaci na serveru i lokalno na uređaju.\n\n6. Kontakt\nZa pitanja o privatnosti koristite Feedback u aplikaciji.'**
  String get privacyBody;

  /// No description provided for @feedback.
  ///
  /// In sr, this message translates to:
  /// **'Povratna informacija'**
  String get feedback;

  /// No description provided for @feedbackIntro.
  ///
  /// In sr, this message translates to:
  /// **'Recite nam šta treba poboljšati ili šta ne radi kako treba.'**
  String get feedbackIntro;

  /// No description provided for @feedbackMessage.
  ///
  /// In sr, this message translates to:
  /// **'Poruka'**
  String get feedbackMessage;

  /// No description provided for @feedbackRequired.
  ///
  /// In sr, this message translates to:
  /// **'Unesite poruku.'**
  String get feedbackRequired;

  /// No description provided for @feedbackThanks.
  ///
  /// In sr, this message translates to:
  /// **'Hvala! Poruka je poslata.'**
  String get feedbackThanks;

  /// No description provided for @sendFeedback.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji'**
  String get sendFeedback;

  /// No description provided for @sending.
  ///
  /// In sr, this message translates to:
  /// **'Šaljem…'**
  String get sending;

  /// No description provided for @deleteAccount.
  ///
  /// In sr, this message translates to:
  /// **'Obriši nalog'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In sr, this message translates to:
  /// **'Trajno briše nalog i sve podatke na serveru i na ovom telefonu. Unesite lozinku da potvrdite.'**
  String get deleteAccountConfirm;

  /// No description provided for @passwordRequired.
  ///
  /// In sr, this message translates to:
  /// **'Unesite lozinku.'**
  String get passwordRequired;

  /// No description provided for @accountDeleted.
  ///
  /// In sr, this message translates to:
  /// **'Nalog je obrisan.'**
  String get accountDeleted;

  /// No description provided for @profile.
  ///
  /// In sr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @profileIntro.
  ///
  /// In sr, this message translates to:
  /// **'Lični podaci za nalog i zvanične obrasce (Prilog 4). ID broj pčelinjaka unosi se na svakom pčelinjaku.'**
  String get profileIntro;

  /// No description provided for @profileAccount.
  ///
  /// In sr, this message translates to:
  /// **'Nalog'**
  String get profileAccount;

  /// No description provided for @firstName.
  ///
  /// In sr, this message translates to:
  /// **'Ime'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In sr, this message translates to:
  /// **'Prezime'**
  String get lastName;

  /// No description provided for @nameRequired.
  ///
  /// In sr, this message translates to:
  /// **'Unesite ime i prezime.'**
  String get nameRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In sr, this message translates to:
  /// **'Neispravan broj telefona.'**
  String get invalidPhone;

  /// No description provided for @profileSaved.
  ///
  /// In sr, this message translates to:
  /// **'Profil je sačuvan.'**
  String get profileSaved;

  /// No description provided for @changePassword.
  ///
  /// In sr, this message translates to:
  /// **'Promeni lozinku'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In sr, this message translates to:
  /// **'Trenutna lozinka'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In sr, this message translates to:
  /// **'Nova lozinka'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi lozinku'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In sr, this message translates to:
  /// **'Lozinke se ne poklapaju.'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In sr, this message translates to:
  /// **'Nova lozinka mora imati najmanje 6 karaktera.'**
  String get passwordTooShort;

  /// No description provided for @passwordChanged.
  ///
  /// In sr, this message translates to:
  /// **'Lozinka je promenjena.'**
  String get passwordChanged;

  /// No description provided for @passwordHint.
  ///
  /// In sr, this message translates to:
  /// **'Najmanje 6 karaktera, veliko i malo slovo i broj'**
  String get passwordHint;

  /// No description provided for @passwordMustInclude.
  ///
  /// In sr, this message translates to:
  /// **'Lozinka mora imati: {requirements}.'**
  String passwordMustInclude(String requirements);

  /// No description provided for @passwordReqLength.
  ///
  /// In sr, this message translates to:
  /// **'najmanje 6 karaktera'**
  String get passwordReqLength;

  /// No description provided for @passwordReqUpper.
  ///
  /// In sr, this message translates to:
  /// **'veliko slovo'**
  String get passwordReqUpper;

  /// No description provided for @passwordReqLower.
  ///
  /// In sr, this message translates to:
  /// **'malo slovo'**
  String get passwordReqLower;

  /// No description provided for @passwordReqDigit.
  ///
  /// In sr, this message translates to:
  /// **'broj'**
  String get passwordReqDigit;

  /// No description provided for @listAnd.
  ///
  /// In sr, this message translates to:
  /// **'i'**
  String get listAnd;

  /// No description provided for @showPassword.
  ///
  /// In sr, this message translates to:
  /// **'Prikaži lozinku'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In sr, this message translates to:
  /// **'Sakrij lozinku'**
  String get hidePassword;

  /// No description provided for @settingsTextSize.
  ///
  /// In sr, this message translates to:
  /// **'Veličina slova'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSmall.
  ///
  /// In sr, this message translates to:
  /// **'Mala'**
  String get settingsTextSmall;

  /// No description provided for @settingsTextNormal.
  ///
  /// In sr, this message translates to:
  /// **'Obična'**
  String get settingsTextNormal;

  /// No description provided for @settingsTextLarge.
  ///
  /// In sr, this message translates to:
  /// **'Velika'**
  String get settingsTextLarge;

  /// No description provided for @settingsTextVeryLarge.
  ///
  /// In sr, this message translates to:
  /// **'Veća'**
  String get settingsTextVeryLarge;

  /// No description provided for @settingsAutorotation.
  ///
  /// In sr, this message translates to:
  /// **'Autorotacija'**
  String get settingsAutorotation;

  /// No description provided for @settingsAutorotationSubtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dozvoli pejzažni prikaz'**
  String get settingsAutorotationSubtitle;

  /// No description provided for @openProfile.
  ///
  /// In sr, this message translates to:
  /// **'Otvori profil'**
  String get openProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bs', 'cnr', 'en', 'hr', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'cnr':
      return AppLocalizationsCnr();
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
