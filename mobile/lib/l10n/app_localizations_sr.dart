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
  String get offlineDataWarning =>
      'Radite bez prijave. Podaci sa ovog telefona mogu se izgubiti kada se prijavite.';

  @override
  String get offlineContinueConfirm =>
      'Bez naloga podaci ostaju samo na ovom telefonu i mogu se izgubiti pri kasnijoj prijavi.\n\nNastaviti offline?';

  @override
  String get loginReplaceDataConfirm =>
      'Lokalni podaci sa ovog telefona mogu se zameniti podacima sa naloga. Nastaviti sa prijavom?';

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
  String get unsyncedTitle => 'Nesinhronizovani podaci';

  @override
  String unsyncedExportBody(int count) {
    return 'Imate $count lokalnih izmena koje nisu na serveru. Izvoz će koristiti podatke sa ovog telefona.\n\nNastaviti?';
  }

  @override
  String get settingsIntro => 'Tema, jezik i ostala podešavanja aplikacije.';

  @override
  String get beekeeperName => 'Ime i prezime pčelara';

  @override
  String get hidLabel => 'HID (veterinarski broj gazdinstva)';

  @override
  String get hidHint => 'npr. 12 cifara';

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
      'Izaberite izveštaj, zatim format: PDF, Word (DOCX) ili CSV. Podaci pčelara (HID, ime) i ID pčelinjaka uzimaju se iz profila.';

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
  String get privacyUpdated => 'Poslednje ažuriranje: avgust 2026.';

  @override
  String get privacyBody =>
      'Aplikacija Pčelinjak prikuplja podatke neophodne za evidenciju pčelinjaka i sinhronizaciju sa serverom.\n\n1. Podaci o nalogu\nČuvamo email, ime, prezime, telefon (opciono) i heš lozinke. Jedan uređaj može biti aktivan po nalogu.\n\n2. Podaci o pčelinjaku\nKošnice, matici, napomene, prinosi, grupe rada i podsetnici čuvaju se lokalno na uređaju i, kada koristite sync, na našem serveru vezano za vaš nalog.\n\n3. Feedback\nAko pošaljete povratnu informaciju, poruka i email se čuvaju radi unapređenja aplikacije.\n\n4. Deljenje\nNe prodajemo lične podatke trećim stranama. Podaci se koriste isključivo za funkcionisanje aplikacije.\n\n5. Brisanje\nMožete obrisati nalog u Profilu uz potvrdu lozinke. Time se brišu podaci na serveru i lokalno na uređaju.\n\n6. Kontakt\nZa pitanja o privatnosti koristite Feedback u aplikaciji.';

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

  @override
  String get profile => 'Profil';

  @override
  String get profileIntro =>
      'Lični podaci za nalog i zvanične obrasce (Prilog 4). ID broj pčelinjaka unosi se na svakom pčelinjaku.';

  @override
  String get profileAccount => 'Nalog';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Prezime';

  @override
  String get nameRequired => 'Unesite ime i prezime.';

  @override
  String get invalidPhone => 'Neispravan broj telefona.';

  @override
  String get profileSaved => 'Profil je sačuvan.';

  @override
  String get changePassword => 'Promeni lozinku';

  @override
  String get currentPassword => 'Trenutna lozinka';

  @override
  String get newPassword => 'Nova lozinka';

  @override
  String get confirmPassword => 'Potvrdi lozinku';

  @override
  String get passwordMismatch => 'Lozinke se ne poklapaju.';

  @override
  String get passwordTooShort =>
      'Nova lozinka mora imati najmanje 6 karaktera.';

  @override
  String get passwordChanged => 'Lozinka je promenjena.';

  @override
  String get passwordHint => 'Najmanje 6 karaktera, veliko i malo slovo i broj';

  @override
  String passwordMustInclude(String requirements) {
    return 'Lozinka mora imati: $requirements.';
  }

  @override
  String get passwordReqLength => 'najmanje 6 karaktera';

  @override
  String get passwordReqUpper => 'veliko slovo';

  @override
  String get passwordReqLower => 'malo slovo';

  @override
  String get passwordReqDigit => 'broj';

  @override
  String get listAnd => 'i';

  @override
  String get showPassword => 'Prikaži lozinku';

  @override
  String get hidePassword => 'Sakrij lozinku';

  @override
  String get settingsTextSize => 'Veličina slova';

  @override
  String get settingsTextSmall => 'Mala';

  @override
  String get settingsTextNormal => 'Obična';

  @override
  String get settingsTextLarge => 'Velika';

  @override
  String get settingsTextVeryLarge => 'Veća';

  @override
  String get settingsAutorotation => 'Autorotacija';

  @override
  String get settingsAutorotationSubtitle => 'Dozvoli pejzažni prikaz';

  @override
  String get openProfile => 'Otvori profil';

  @override
  String get authLoginInvalidCredentials => 'Pogrešan email ili lozinka.';

  @override
  String get authAccountNotActivated =>
      'Nalog nije aktiviran. Proverite email za aktivacioni link.';

  @override
  String get authEmailExists => 'Korisnik sa ovim email-om već postoji.';

  @override
  String get authWrongPassword => 'Pogrešna lozinka.';

  @override
  String get authUserNotFound => 'Korisnik nije pronađen.';

  @override
  String get hiveSearchAllHint =>
      'Sve košnice · filtrirajte po barkodu, imenu/RB pčelinjaka, tipu (LR, DB…), godini matice, poreklu, „markirana“…';

  @override
  String hiveSearchResultCount(int count) {
    return '$count rezultata';
  }

  @override
  String hiveSearchNoResults(String query) {
    return 'Nema rezultata za „$query”.';
  }

  @override
  String get noQueen => 'Bez matice';

  @override
  String get queenMarkedShort => 'markirana';

  @override
  String queenLine(String details) {
    return 'Matica: $details';
  }

  @override
  String apiaryNamed(int number, String name) {
    return 'Pčelinjak $number · $name';
  }

  @override
  String get remindersShowHistory => 'Prikaži istoriju';

  @override
  String get remindersCompletedList => 'Završeni podsetnici';

  @override
  String get remindersUpcomingList => 'Budući i zakasneli';

  @override
  String get today => 'Danas';

  @override
  String get tomorrow => 'Sutra';

  @override
  String get remindersEmptyUpcoming => 'Nema budućih podsetnika.';

  @override
  String get remindersEmptyHistory => 'Nema završenih podsetnika.';

  @override
  String remindersNoneForDay(String day) {
    return 'Nema podsetnika za $day.';
  }

  @override
  String get reminderReactivated => 'Podsetnik je ponovo aktivan';

  @override
  String get markDone => 'Označi kao urađeno';

  @override
  String get restoreActive => 'Vrati u aktivne';

  @override
  String hiveBarcode(String barcode) {
    return 'Košnica $barcode';
  }

  @override
  String get overdue => 'Zakasnelo';

  @override
  String get reminder => 'Podsetnik';

  @override
  String get reminderNotFound => 'Podsetnik nije pronađen.';

  @override
  String get completed => 'Završeno';

  @override
  String get related => 'Povezano';

  @override
  String get noLinkedHive => 'Nema povezane košnice.';

  @override
  String get openHive => 'Otvori košnicu';

  @override
  String get openGroup => 'Otvori grupu';

  @override
  String get recordInspection => 'Evidentiraj kontrolu';

  @override
  String get openInspection => 'Otvori kontrolu';

  @override
  String get reminderMarkedDone => 'Podsetnik označen kao urađen';

  @override
  String get hiveNotFound => 'Košnica nije pronađena.';

  @override
  String loadError(String error) {
    return 'Greška pri učitavanju: $error';
  }

  @override
  String get back => 'Nazad';

  @override
  String get previousHive => 'Prethodna košnica';

  @override
  String get nextHive => 'Sledeća košnica';

  @override
  String get editHive => 'Izmeni košnicu';

  @override
  String get editNotAllowed => 'Izmeni (nije dozvoljeno)';

  @override
  String get deleteHive => 'Obriši košnicu';

  @override
  String get deleteHiveConfirm =>
      'Košnica će biti obrisana (može se sinhronizovati kao obrisana).';

  @override
  String get hiveStatusConfirmTitle => 'Status košnice';

  @override
  String hiveStatusConfirmBody(String status) {
    return 'Postaviti status na „$status”?';
  }

  @override
  String hiveStatusTransitionBlocked(String from, String to) {
    return 'Nije dozvoljen prelaz $from → $to.';
  }

  @override
  String get status => 'Status';

  @override
  String get move => 'Selidba';

  @override
  String get locationNotEntered => 'Lokacija nije uneta';

  @override
  String get queenOnlyActive => 'Samo aktivna';

  @override
  String get enterQueen => 'Unesi maticu';

  @override
  String get editCurrentQueen => 'Izmeni trenutnu';

  @override
  String get editQueen => 'Izmeni maticu';

  @override
  String hiveQueenBlocked(String status) {
    return 'Matica se menja samo na aktivnoj košnici (sada: $status).';
  }

  @override
  String hiveHarvestBlocked(String status) {
    return 'Prinos se unosi samo na aktivnoj košnici (sada: $status).';
  }

  @override
  String get hiveEditBlocked =>
      'Ugašena košnica se ne menja — prvo je vratite u aktivnu.';

  @override
  String hiveAddToGroupBlocked(String status) {
    return 'Košnica je „$status” — u grupe se mogu dodati samo aktivne košnice.';
  }

  @override
  String get noActiveQueen => 'Nema aktivne matice.';

  @override
  String queenYearLabel(String year) {
    return 'Godina: $year';
  }

  @override
  String queenMarkedLabel(String value) {
    return 'Obeležena: $value';
  }

  @override
  String get year => 'Godina';

  @override
  String get origin => 'Poreklo';

  @override
  String get marked => 'Obeležena';

  @override
  String get yes => 'DA';

  @override
  String get no => 'NE';

  @override
  String originWithValue(String value) {
    return 'Poreklo: $value';
  }

  @override
  String periodFrom(String date) {
    return 'Od $date';
  }

  @override
  String get newQueen => 'Nova matica';

  @override
  String get endQueen => 'Završi maticu';

  @override
  String get endQueenDied => 'Završi / uginula';

  @override
  String queenHistoryCount(int count) {
    return 'Istorija matica ($count)';
  }

  @override
  String currentQueenLine(String year, String period) {
    return 'Trenutna: godina $year · $period';
  }

  @override
  String get queenEndReasonLabel => 'Šta se desilo sa starom?';

  @override
  String get enterNewQueenAfter => 'Posle toga unesite podatke nove matice.';

  @override
  String get queenEndDied => 'Uginula';

  @override
  String get queenEndReplaced => 'Zamenjena';

  @override
  String get queenEndSuperseded => 'Zamenjena novom';

  @override
  String get queenEndOther => 'Drugo';

  @override
  String get hiveInspection => 'Kontrola košnice';

  @override
  String get addInspection => 'Dodaj kontrolu';

  @override
  String get noInspectionsYet => 'Još nema unetih kontrola za ovu košnicu.';

  @override
  String get lastInspection => 'Poslednja kontrola';

  @override
  String get source => 'Izvor';

  @override
  String allInspections(int count) {
    return 'Sve kontrole ($count)';
  }

  @override
  String get addNote => 'Dodaj napomenu';

  @override
  String get noNotesYet => 'Još nema napomena za ovu košnicu.';

  @override
  String get lastNote => 'Poslednja napomena';

  @override
  String reminderAt(String when) {
    return 'Podsetnik: $when';
  }

  @override
  String allNotes(int count) {
    return 'Sve napomene ($count)';
  }

  @override
  String get honeyHarvest => 'Prinos meda';

  @override
  String get addHarvest => 'Dodaj prinos';

  @override
  String harvestYearTotal(int year, String amount) {
    return 'Ukupno $year: $amount kg';
  }

  @override
  String get noHarvestsThisYear => 'Još nema unosa prinosa ove godine.';

  @override
  String allHarvests(int count) {
    return 'Svi prinosi ($count)';
  }

  @override
  String get deleteNoteTitle => 'Obriši napomenu';

  @override
  String get deleteNoteConfirm => 'Obrisati ovu napomenu?';

  @override
  String get inspectionSourceManual => 'Ručno';

  @override
  String get inspectionSourceGroup => 'Grupa kontrole';

  @override
  String get inspectionSourceReminder => 'Podsetnik';

  @override
  String get inspectionOutcomeOk => 'U redu';

  @override
  String get inspectionOutcomeFollowUp => 'Potrebna kontrola';

  @override
  String get inspectionOutcomeUrgent => 'Hitno';

  @override
  String get inspectionOutcomeResolved => 'Rešeno';
}
