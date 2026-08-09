// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appName => 'Pčelinjak';

  @override
  String get language => 'Jezik';

  @override
  String get languageSystem => 'Jezik telefona';

  @override
  String get langSr => 'Srpski';

  @override
  String get langEn => 'English';

  @override
  String get langHr => 'Hrvatski';

  @override
  String get langBs => 'Bosanski';

  @override
  String get langCnr => 'Crnogorski';

  @override
  String get cancel => 'Odustani';

  @override
  String get save => 'Spremi';

  @override
  String get add => 'Dodaj';

  @override
  String get delete => 'Obriši';

  @override
  String get edit => 'Uredi';

  @override
  String get confirm => 'Potvrdi';

  @override
  String get continueAction => 'Nastavi';

  @override
  String get ok => 'U redu';

  @override
  String get close => 'Zatvori';

  @override
  String get home => 'Početna';

  @override
  String get scan => 'Skeniraj';

  @override
  String get scanBarcode => 'Skeniraj barkod';

  @override
  String get waiting => 'Pričekajte…';

  @override
  String get saving => 'Spremam…';

  @override
  String get authLoginSubtitle => 'Prijavite se s ovog telefona';

  @override
  String get authRegisterSubtitle =>
      'Unesite osobne podatke i otvorite Moj pčelinjak';

  @override
  String get fullName => 'Ime i prezime';

  @override
  String get phone => 'Telefon';

  @override
  String get email => 'Email';

  @override
  String get password => 'Lozinka';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get signUp => 'Registriraj se';

  @override
  String get haveAccount => 'Već imam račun';

  @override
  String get createAccount => 'Napravi račun';

  @override
  String get registerCheckEmailActivation =>
      'Provjerite email (inbox i spam) i kliknite aktivacijski link.';

  @override
  String get continueOffline => 'Nastavi offline (bez sinkronizacije)';

  @override
  String get offlineDataWarning =>
      'Radite bez prijave. Podaci s ovog telefona mogu se izgubiti kada se prijavite.';

  @override
  String get offlineContinueConfirm =>
      'Bez računa podaci ostaju samo na ovom telefonu i mogu se izgubiti pri kasnijoj prijavi.\n\nNastaviti offline?';

  @override
  String get loginReplaceDataConfirm =>
      'Lokalni podaci s ovog telefona mogu se zamijeniti podacima s računa. Nastaviti s prijavom?';

  @override
  String get authDeviceNote =>
      'Samo jedan telefon može biti prijavljen. Prijava s novog uređaja odjavljuje stari.';

  @override
  String myApiaryHives(int count) {
    return 'Moj pčelinjak · ukupno $count košnica';
  }

  @override
  String get findHive => 'Pronađi košnicu';

  @override
  String get reminders => 'Podsjetnici';

  @override
  String remindersCount(int count) {
    return 'Podsjetnici ($count)';
  }

  @override
  String get reports => 'Izvještaji';

  @override
  String get settings => 'Postavke';

  @override
  String get exportBarcodes => 'Izvezi barkodove';

  @override
  String get logout => 'Odjavi se';

  @override
  String get goToLogin => 'Idi na prijavu';

  @override
  String get addApiary => 'Dodaj pčelinjak';

  @override
  String get apiariesSection => 'Pčelinjaci';

  @override
  String get apiariesSectionHint => 'Stalne lokacije i košnice';

  @override
  String get hiveGroups => 'Grupe košnica';

  @override
  String get hiveGroupsHint => 'Privremene radne liste';

  @override
  String get total => 'UKUPNO';

  @override
  String apiaryLabel(int number) {
    return 'PČELINJAK $number';
  }

  @override
  String get noApiariesYet =>
      'Još nema pčelinjaka. Dodajte prvi — aplikacija će mu dati radni broj.';

  @override
  String get unsyncedTitle => 'Nesinkronizirani podaci';

  @override
  String unsyncedExportBody(int count) {
    return 'Imate $count lokalnih izmjena koje nisu na serveru. Izvoz će koristiti podatke s ovog telefona.\n\nNastaviti?';
  }

  @override
  String get settingsIntro =>
      'Podaci pčelara za službene obrasce (Prilog 4). ID broj pčelinjaka unosi se na svakom pčelinjaku.';

  @override
  String get beekeeperName => 'Ime i prezime pčelara';

  @override
  String get hidLabel => 'HID (veterinarski broj gospodarstva)';

  @override
  String get hidHint => 'npr. 12 znamenki';

  @override
  String get settingsSaved => 'Postavke spremljene';

  @override
  String get syncTitle => 'Sinkronizacija';

  @override
  String get syncIntro =>
      'Izmjene se šalju automatski kad ima interneta. Offline radite lokalno — sinkronizacija ovdje pošalje i povuče sve sa servera.';

  @override
  String get syncAllDone => 'Sve lokalne izmjene su sinkronizirane.';

  @override
  String get syncing => 'Sinkroniziram…';

  @override
  String get sendToServer => 'Pošalji na server';

  @override
  String get deviceMismatch => 'Račun je aktivan na drugom telefonu.';

  @override
  String unsyncedWaiting(int count) {
    return '$count lokalnih izmjena čeka slanje na server.';
  }

  @override
  String get unsyncedOne => '1 lokalna izmjena nije sinkronizirana.';

  @override
  String unsyncedMany(int count) {
    return '$count lokalnih izmjena nije sinkronizirano.';
  }

  @override
  String get reportsIntro =>
      'Odaberite izvještaj, zatim format: PDF, Word (DOCX) ili CSV. Podaci pčelara (HID, ime) i ID pčelinjaka uzimaju se iz postavki.';

  @override
  String get exportFormat => 'Format izvoza';

  @override
  String get formatPdf => 'PDF';

  @override
  String get formatDocx => 'Word (DOCX)';

  @override
  String get formatCsv => 'CSV';

  @override
  String get reportHarvestTitle => 'Prinos po paši i pčelinjaku';

  @override
  String get reportHarvestSubtitle =>
      'Sume kg za tekuću godinu, po paši i pčelinjaku';

  @override
  String get reportPrijavaTitle => 'Prijava stanja (Prilog 4)';

  @override
  String get reportPrijavaSubtitle =>
      'Obrazac s barkodovima aktivnih košnica — po pčelinjaku';

  @override
  String get reportQueensTitle => 'Pregled matica';

  @override
  String get reportQueensSubtitle =>
      'Godina, markiranje i podrijetlo aktivnih matica';

  @override
  String get noApiariesForReport => 'Nema pčelinjaka za prijavu.';

  @override
  String get missingConfig => 'Nedostaje konfiguracija';

  @override
  String get openSettings => 'Otvori postavke';

  @override
  String exportError(String error) {
    return 'Greška pri izvozu: $error';
  }

  @override
  String get newApiary => 'Novi pčelinjak';

  @override
  String get editApiary => 'Izmjena pčelinjaka';

  @override
  String get name => 'Naziv';

  @override
  String get locationOptional => 'Lokacija (opcionalno)';

  @override
  String get officialApiaryId => 'ID broj pčelinjaka (Prilog 4)';

  @override
  String get color => 'Boja';

  @override
  String get addHive => 'Dodaj košnicu';

  @override
  String workNumber(int number) {
    return 'Radni broj: $number';
  }

  @override
  String get statusActive => 'Aktivna';

  @override
  String get statusArchived => 'Arhivirana';

  @override
  String get statusDead => 'Ugašena';

  @override
  String get statusAll => 'Sve';

  @override
  String get filterActive => 'Aktivne';

  @override
  String get filterArchived => 'Arhivirane';

  @override
  String get filterDead => 'Ugašene';

  @override
  String get groupMoved => 'Seljene košnice';

  @override
  String get groupGoodPasture => 'Dobre u paši';

  @override
  String get groupQueenChange => 'Zamjena matica';

  @override
  String get groupControl => 'Za kontrolu';

  @override
  String get groupFeeding => 'Za dohranu';

  @override
  String get groupReproduction => 'Za reprodukciju';

  @override
  String get membershipActive => 'Aktivna';

  @override
  String get membershipFinished => 'Završena';

  @override
  String get membershipRemoved => 'Uklonjena';

  @override
  String get hiveSearchTitle => 'Pretraga košnica';

  @override
  String get hiveSearchHint => 'Barkod, pčelinjak, tip, matica…';

  @override
  String get noHives => 'Nema košnica.';

  @override
  String get hive => 'Košnica';

  @override
  String get notes => 'Bilješke';

  @override
  String get harvests => 'Prinosi';

  @override
  String get queen => 'Matica';

  @override
  String get barcode => 'Barkod';

  @override
  String get type => 'Tip';

  @override
  String get description => 'Opis';

  @override
  String get pasture => 'Paša';

  @override
  String get amountKg => 'Količina (kg)';

  @override
  String get location => 'Lokacija';

  @override
  String get note => 'Napomena';

  @override
  String get finishInGroup => 'Završi (kraj u grupi)';

  @override
  String get removeMistake => 'Ukloni (dodana greškom)';

  @override
  String get deleteWithoutHistory => 'Obriši bez povijesti';

  @override
  String get editInGroup => 'Uredi u grupi';

  @override
  String addToGroup(String title) {
    return 'Dodaj u $title';
  }

  @override
  String get typeCode => 'Upiši kod';

  @override
  String get code => 'Kod';

  @override
  String get hiveNotInDb => 'Košnica nije u bazi';

  @override
  String get listEmptyScan => 'Lista je prazna. Skenirajte košnicu.';

  @override
  String get historyEmpty => 'Nema zapisa u ovoj povijesti.';

  @override
  String get filterFinished => 'Završene';

  @override
  String get filterRemoved => 'Uklonjene (greška)';

  @override
  String get filterAllHistory => 'Sve (povijest)';

  @override
  String get deleteWithoutHistoryTitle => 'Brisanje bez povijesti';

  @override
  String get deleteWithoutHistoryBody =>
      'Briše članstvo iz grupe bez čuvanja povijesti. Briše se i povezani prinos (ako postoji), bilješke i podsjetnici.';

  @override
  String get barcodeShareSubject => 'Popis kodova košnica';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automatski (sustav)';

  @override
  String get themeLight => 'Svijetla';

  @override
  String get themeDark => 'Tamna';

  @override
  String get settingsAppearance => 'Izgled';

  @override
  String get settingsReports => 'Izvještaji i poslužitelj';

  @override
  String get settingsSupport => 'Podrška';

  @override
  String get settingsDanger => 'Račun';

  @override
  String get privacyPolicy => 'Politika privatnosti';

  @override
  String get privacyTitle => 'Politika privatnosti – Pčelinjak';

  @override
  String get privacyUpdated => 'Zadnje ažuriranje: srpanj 2026.';

  @override
  String get privacyBody =>
      'Aplikacija Pčelinjak prikuplja podatke potrebne za evidenciju pčelinjaka i sinkronizaciju sa serverom.\n\n1. Podaci o računu\nČuvamo email, ime, telefon (opcionalno) i hash lozinke. Jedan uređaj može biti aktivan po računu.\n\n2. Podaci o pčelinjaku\nKošnice, matici, bilješke, prinosi, grupe rada i podsjetnici čuvaju se lokalno i, kada koristite sync, na našem serveru vezano za vaš račun.\n\n3. Feedback\nAko pošaljete povratnu informaciju, poruka i email se čuvaju radi unapređenja aplikacije.\n\n4. Dijeljenje\nNe prodajemo osobne podatke. Podaci se koriste isključivo za funkcioniranje aplikacije.\n\n5. Brisanje\nMožete obrisati račun u Postavkama uz potvrdu lozinke. Time se brišu podaci na serveru i lokalno na uređaju.\n\n6. Kontakt\nZa pitanja o privatnosti koristite Feedback u aplikaciji.';

  @override
  String get feedback => 'Povratna informacija';

  @override
  String get feedbackIntro =>
      'Recite nam što treba poboljšati ili što ne radi kako treba.';

  @override
  String get feedbackMessage => 'Poruka';

  @override
  String get feedbackRequired => 'Unesite poruku.';

  @override
  String get feedbackThanks => 'Hvala! Poruka je poslana.';

  @override
  String get sendFeedback => 'Pošalji';

  @override
  String get sending => 'Šaljem…';

  @override
  String get deleteAccount => 'Obriši račun';

  @override
  String get deleteAccountConfirm =>
      'Trajno briše račun i sve podatke na serveru i na ovom telefonu. Unesite lozinku za potvrdu.';

  @override
  String get passwordRequired => 'Unesite lozinku.';

  @override
  String get accountDeleted => 'Račun je obrisan.';
}
