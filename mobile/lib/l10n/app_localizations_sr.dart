// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

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
  String get cancel => 'Otkaži';

  @override
  String get save => 'Sačuvaj';

  @override
  String get add => 'Dodaj';

  @override
  String get delete => 'Obriši';

  @override
  String get edit => 'Izmeni';

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
  String get waiting => 'Sačekajte…';

  @override
  String get saving => 'Čuvam…';

  @override
  String get authLoginSubtitle => 'Prijavite se sa ovog telefona';

  @override
  String get authRegisterSubtitle =>
      'Unesite lične podatke i otvorite Moj pčelinjak';

  @override
  String get fullName => 'Ime i prezime';

  @override
  String get phone => 'Telefon';

  @override
  String get email => 'Email';

  @override
  String get password => 'Lozinka';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get signUp => 'Registruj se';

  @override
  String get haveAccount => 'Već imam nalog';

  @override
  String get createAccount => 'Napravi nalog';

  @override
  String get registerCheckEmailActivation =>
      'Proverite email (inbox i spam) i kliknite aktivacioni link.';

  @override
  String get continueOffline => 'Nastavi offline (bez sync-a)';

  @override
  String get authDeviceNote =>
      'Samo jedan telefon može biti prijavljen. Prijava sa novog uređaja odjavljuje stari.';

  @override
  String myApiaryHives(int count) {
    return 'Moj pčelinjak · ukupno $count košnica';
  }

  @override
  String get findHive => 'Pronađi košnicu';

  @override
  String get reminders => 'Podsetnici';

  @override
  String remindersCount(int count) {
    return 'Podsetnici ($count)';
  }

  @override
  String get reports => 'Izveštaji';

  @override
  String get settings => 'Konfiguracija';

  @override
  String get exportBarcodes => 'Izvezi barkodove';

  @override
  String get logout => 'Odjavi se';

  @override
  String get addApiary => 'Dodaj pčelinjak';

  @override
  String get hiveGroups => 'Grupe košnica';

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
  String get unsyncedTitle => 'Nesinhronizovani podaci';

  @override
  String unsyncedExportBody(int count) {
    return 'Imate $count lokalnih izmena koje nisu na serveru. Izvoz će koristiti podatke sa ovog telefona.\n\nNastaviti?';
  }

  @override
  String get settingsIntro =>
      'Podaci pčelara za zvanične obrasce (Prilog 4). ID broj pčelinjaka unosi se na svakom pčelinjaku.';

  @override
  String get beekeeperName => 'Ime i prezime pčelara';

  @override
  String get hidLabel => 'HID (veterinarski broj gazdinstva)';

  @override
  String get hidHint => 'npr. 12 cifara';

  @override
  String get serverAddress => 'Adresa servera';

  @override
  String get settingsSaved => 'Konfiguracija sačuvana';

  @override
  String get syncTitle => 'Sinhronizacija';

  @override
  String get syncIntro =>
      'Izmene se šalju automatski kad ima interneta. Offline radite lokalno — sync ovde pošalje i povuče sve sa servera.';

  @override
  String get syncAllDone => 'Sve lokalne izmene su sinhronizovane.';

  @override
  String get syncing => 'Sinhronizujem…';

  @override
  String get sendToServer => 'Pošalji na server';

  @override
  String get deviceMismatch => 'Nalog je aktivan na drugom telefonu.';

  @override
  String unsyncedWaiting(int count) {
    return '$count lokalnih izmena čeka slanje na server.';
  }

  @override
  String get unsyncedOne => '1 lokalna izmena nije sinhronizovana.';

  @override
  String unsyncedMany(int count) {
    return '$count lokalnih izmena nije sinhronizovano.';
  }

  @override
  String get reportsIntro =>
      'Izaberite izveštaj, zatim format: PDF, Word (DOCX) ili CSV. Podaci pčelara (HID, ime) i ID pčelinjaka uzimaju se iz konfiguracije.';

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
      'Obrazac sa barkodovima aktivnih košnica — po pčelinjaku';

  @override
  String get reportQueensTitle => 'Pregled matica';

  @override
  String get reportQueensSubtitle =>
      'Godina, markiranje i poreklo aktivnih matica';

  @override
  String get noApiariesForReport => 'Nema pčelinjaka za prijavu.';

  @override
  String get missingConfig => 'Nedostaje konfiguracija';

  @override
  String get openSettings => 'Otvori konfiguraciju';

  @override
  String exportError(String error) {
    return 'Greška pri izvozu: $error';
  }

  @override
  String get newApiary => 'Novi pčelinjak';

  @override
  String get editApiary => 'Izmena pčelinjaka';

  @override
  String get name => 'Naziv';

  @override
  String get locationOptional => 'Lokacija (opciono)';

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
  String get groupQueenChange => 'Zamena matica';

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
  String get notes => 'Napomene';

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
  String get removeMistake => 'Ukloni (dodata greškom)';

  @override
  String get deleteWithoutHistory => 'Obriši bez istorije';

  @override
  String get editInGroup => 'Izmeni u grupi';

  @override
  String addToGroup(String title) {
    return 'Dodaj u $title';
  }

  @override
  String get typeCode => 'Ukucaj kod';

  @override
  String get code => 'Kod';

  @override
  String get hiveNotInDb => 'Košnica nije u bazi';

  @override
  String get listEmptyScan => 'Lista je prazna. Skenirajte košnicu.';

  @override
  String get historyEmpty => 'Nema zapisa u ovoj istoriji.';

  @override
  String get filterFinished => 'Završene';

  @override
  String get filterRemoved => 'Uklonjene (greška)';

  @override
  String get filterAllHistory => 'Sve (istorija)';

  @override
  String get deleteWithoutHistoryTitle => 'Brisanje bez istorije';

  @override
  String get deleteWithoutHistoryBody =>
      'Obriše članstvo iz grupe bez čuvanja istorije. Briše se i povezani prinos (ako postoji), napomene i podsetnici.';

  @override
  String get barcodeShareSubject => 'Spisak kodova košnica';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automatski (sistem)';

  @override
  String get themeLight => 'Svetla';

  @override
  String get themeDark => 'Tamna';

  @override
  String get settingsAppearance => 'Izgled';

  @override
  String get settingsReports => 'Izveštaji i server';

  @override
  String get settingsSupport => 'Podrška';

  @override
  String get settingsDanger => 'Nalog';

  @override
  String get privacyPolicy => 'Politika privatnosti';

  @override
  String get privacyTitle => 'Politika privatnosti – Pčelinjak';

  @override
  String get privacyUpdated => 'Poslednje ažuriranje: jul 2026.';

  @override
  String get privacyBody =>
      'Aplikacija Pčelinjak prikuplja podatke neophodne za evidenciju pčelinjaka i sinhronizaciju sa serverom.\n\n1. Podaci o nalogu\nČuvamo email, ime, telefon (opciono) i heš lozinke. Jedan uređaj može biti aktivan po nalogu.\n\n2. Podaci o pčelinjaku\nKošnice, matici, napomene, prinosi, grupe rada i podsetnici čuvaju se lokalno na uređaju i, kada koristite sync, na našem serveru vezano za vaš nalog.\n\n3. Feedback\nAko pošaljete povratnu informaciju, poruka i email se čuvaju radi unapređenja aplikacije.\n\n4. Deljenje\nNe prodajemo lične podatke trećim stranama. Podaci se koriste isključivo za funkcionisanje aplikacije.\n\n5. Brisanje\nMožete obrisati nalog u Podešavanjima uz potvrdu lozinke. Time se brišu podaci na serveru i lokalno na uređaju.\n\n6. Kontakt\nZa pitanja o privatnosti koristite Feedback u aplikaciji.';

  @override
  String get feedback => 'Povratna informacija';

  @override
  String get feedbackIntro =>
      'Recite nam šta treba poboljšati ili šta ne radi kako treba.';

  @override
  String get feedbackMessage => 'Poruka';

  @override
  String get feedbackRequired => 'Unesite poruku.';

  @override
  String get feedbackThanks => 'Hvala! Poruka je poslata.';

  @override
  String get sendFeedback => 'Pošalji';

  @override
  String get sending => 'Šaljem…';

  @override
  String get deleteAccount => 'Obriši nalog';

  @override
  String get deleteAccountConfirm =>
      'Trajno briše nalog i sve podatke na serveru i na ovom telefonu. Unesite lozinku da potvrdite.';

  @override
  String get passwordRequired => 'Unesite lozinku.';

  @override
  String get accountDeleted => 'Nalog je obrisan.';
}
