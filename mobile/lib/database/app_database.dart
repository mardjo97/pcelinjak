import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;
  final _uuid = const Uuid();

  /// Poziva se posle lokalne izmene (za auto-sync).
  void Function()? onLocalChange;

  void _notifyLocalChange() {
    onLocalChange?.call();
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'pcelinjak.db');
    _db = await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE hive ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE work_group_hive ADD COLUMN membershipStatus TEXT NOT NULL DEFAULT 'ACTIVE'",
      );
      await db.execute(
        'ALTER TABLE work_group_hive ADD COLUMN activeFrom TEXT',
      );
      await db.execute('ALTER TABLE work_group_hive ADD COLUMN activeTo TEXT');
      await db.execute('''
        UPDATE work_group_hive
        SET membershipStatus = CASE WHEN done = 1 THEN 'FINISHED' ELSE 'ACTIVE' END,
            activeFrom = dateCreated,
            activeTo = CASE WHEN done = 1 THEN dateModified ELSE NULL END
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE note ADD COLUMN reminderAt TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE queen ADD COLUMN endReason TEXT');
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE work_group_hive ADD COLUMN pastureType TEXT',
      );
      await db.execute(
        'ALTER TABLE work_group_hive ADD COLUMN locationName TEXT',
      );
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE apiary ADD COLUMN officialId TEXT');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE harvest ADD COLUMN workGroupHiveUuid TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE reminder ADD COLUMN inspectionUuid TEXT');
      await db.execute('''
        CREATE TABLE inspection (
          uuid TEXT PRIMARY KEY,
          hiveUuid TEXT NOT NULL,
          inspectedAt TEXT NOT NULL,
          summary TEXT,
          outcomeStatus TEXT NOT NULL DEFAULT 'OK',
          queenStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
          broodStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
          foodStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
          temperStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
          strengthStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
          followUpAt TEXT,
          sourceType TEXT,
          sourceGroupHiveUuid TEXT,
          sourceReminderUuid TEXT,
          dateCreated TEXT NOT NULL,
          dateModified TEXT NOT NULL,
          dateSynched TEXT,
          dateDeleted TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE apiary (
        uuid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT,
        workNumber INTEGER NOT NULL,
        color TEXT NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        officialId TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE hive (
        uuid TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        orderNumber INTEGER NOT NULL,
        hiveType TEXT NOT NULL,
        apiaryUuid TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE queen (
        uuid TEXT PRIMARY KEY,
        hiveUuid TEXT NOT NULL,
        queenYear INTEGER,
        marked INTEGER NOT NULL DEFAULT 0,
        origin TEXT,
        activeFrom TEXT,
        activeTo TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        endReason TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE note (
        uuid TEXT PRIMARY KEY,
        hiveUuid TEXT NOT NULL,
        content TEXT NOT NULL,
        groupType TEXT,
        groupRecordUuid TEXT,
        reminderAt TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE harvest (
        uuid TEXT PRIMARY KEY,
        hiveUuid TEXT NOT NULL,
        pastureType TEXT NOT NULL,
        amountKg REAL NOT NULL,
        collectedAt TEXT,
        harvestYear INTEGER NOT NULL,
        workGroupHiveUuid TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE work_group (
        uuid TEXT PRIMARY KEY,
        groupType TEXT NOT NULL,
        pastureType TEXT,
        locationName TEXT,
        finished INTEGER NOT NULL DEFAULT 0,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE work_group_hive (
        uuid TEXT PRIMARY KEY,
        groupUuid TEXT NOT NULL,
        hiveUuid TEXT NOT NULL,
        amount REAL,
        note TEXT,
        checkDate TEXT,
        reminderAt TEXT,
        pastureType TEXT,
        locationName TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        membershipStatus TEXT NOT NULL DEFAULT 'ACTIVE',
        activeFrom TEXT,
        activeTo TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reminder (
        uuid TEXT PRIMARY KEY,
        hiveUuid TEXT,
        groupHiveUuid TEXT,
        inspectionUuid TEXT,
        dueAt TEXT NOT NULL,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE inspection (
        uuid TEXT PRIMARY KEY,
        hiveUuid TEXT NOT NULL,
        inspectedAt TEXT NOT NULL,
        summary TEXT,
        outcomeStatus TEXT NOT NULL DEFAULT 'OK',
        queenStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
        broodStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
        foodStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
        temperStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
        strengthStatus TEXT NOT NULL DEFAULT 'NOT_CHECKED',
        followUpAt TEXT,
        sourceType TEXT,
        sourceGroupHiveUuid TEXT,
        sourceReminderUuid TEXT,
        dateCreated TEXT NOT NULL,
        dateModified TEXT NOT NULL,
        dateSynched TEXT,
        dateDeleted TEXT
      )
    ''');

    for (final type in workGroupTypes.keys) {
      final g = WorkGroup(uuid: _uuid.v4(), groupType: type);
      await db.insert('work_group', g.toMap());
    }
  }

  String newUuid() => _uuid.v4();

  Future<List<Apiary>> listApiaries() async {
    final rows = await (await db).query(
      'apiary',
      where: 'dateDeleted IS NULL',
      orderBy: 'workNumber ASC',
    );
    return rows.map(Apiary.fromMap).toList();
  }

  Future<void> upsertApiary(Apiary a) async {
    await (await db).insert(
      'apiary',
      a.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<int> nextWorkNumber() async {
    final rows = await (await db).rawQuery(
      'SELECT MAX(workNumber) as m FROM apiary WHERE dateDeleted IS NULL',
    );
    final m = rows.first['m'] as int?;
    return (m ?? 0) + 1;
  }

  Future<List<Hive>> listHives(
    String apiaryUuid, {
    bool activeOnly = true,
  }) async {
    final where = activeOnly
        ? "apiaryUuid = ? AND dateDeleted IS NULL AND (status = 'ACTIVE' OR status IS NULL OR status = '')"
        : 'apiaryUuid = ? AND dateDeleted IS NULL';
    final rows = await (await db).query(
      'hive',
      where: where,
      whereArgs: [apiaryUuid],
      orderBy: 'orderNumber ASC',
    );
    return rows.map(Hive.fromMap).toList();
  }

  Future<List<Hive>> listAllHives() async {
    final rows = await (await db).query(
      'hive',
      where: 'dateDeleted IS NULL',
      orderBy: 'orderNumber ASC',
    );
    return rows.map(Hive.fromMap).toList();
  }

  Future<Hive?> findHiveByBarcode(String barcode) async {
    final rows = await (await db).query(
      'hive',
      where: 'barcode = ? AND dateDeleted IS NULL',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Hive.fromMap(rows.first);
  }

  /// Opšta pretraga: barkod, RB, tip, opis, status, pčelinjak (ime/lokacija/RB), matica (godina/poreklo/markirana).
  /// Prazan upit → sve košnice (za pregled).
  Future<List<HiveSearchHit>> searchHives(String raw) async {
    final q = raw.trim().toLowerCase();

    final hives = await listAllHives();
    final apiaries = {for (final a in await listApiaries()) a.uuid: a};
    final queens = <String, Queen>{};
    for (final h in hives) {
      final queen = await activeQueen(h.uuid);
      if (queen != null) queens[h.uuid] = queen;
    }

    final markedWanted = const [
      'markir',
      'oznac',
      'označ',
      'marked',
      'obelez',
      'obelež',
    ].any((k) => q.contains(k));
    final unmarkedWanted = const [
      'nemark',
      'neoznac',
      'neoznač',
      'unmarked',
    ].any((k) => q.contains(k));

    final hits = <HiveSearchHit>[];
    for (final h in hives) {
      final a = apiaries[h.apiaryUuid];
      final queen = queens[h.uuid];
      if (q.isNotEmpty) {
        final hay = [
          h.barcode,
          '${h.orderNumber}',
          h.hiveType,
          h.description ?? '',
          h.status,
          hiveStatuses[h.status] ?? '',
          a?.name ?? '',
          a?.location ?? '',
          a == null ? '' : '${a.workNumber}',
          a == null ? '' : 'pčelinjak ${a.workNumber}',
          queen?.queenYear?.toString() ?? '',
          queen?.origin ?? '',
          if (queen?.marked == true) ...['markirana', 'označena', 'marked'],
          if (queen != null && !queen.marked) ...['nemarkirana', 'neoznačena'],
          if (queen == null) 'bez matice',
        ].join(' ').toLowerCase();

        var ok = hay.contains(q);
        if (!ok && markedWanted && queen?.marked == true) ok = true;
        if (!ok && unmarkedWanted && queen != null && !queen.marked) ok = true;
        if (!ok) continue;
      }

      hits.add(HiveSearchHit(hive: h, apiary: a, queen: queen));
    }

    hits.sort((x, y) {
      final ax = x.apiary?.workNumber ?? 9999;
      final ay = y.apiary?.workNumber ?? 9999;
      if (ax != ay) return ax.compareTo(ay);
      return x.hive.orderNumber.compareTo(y.hive.orderNumber);
    });
    return hits;
  }

  Future<Hive?> findHiveByUuid(String uuid) async {
    final rows = await (await db).query(
      'hive',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Hive.fromMap(rows.first);
  }

  Future<int> nextHiveOrder(String apiaryUuid) async {
    final rows = await (await db).rawQuery(
      'SELECT MAX(orderNumber) as m FROM hive WHERE apiaryUuid = ? AND dateDeleted IS NULL',
      [apiaryUuid],
    );
    final m = rows.first['m'] as int?;
    return (m ?? 0) + 1;
  }

  Future<void> upsertHive(Hive h) async {
    await (await db).insert(
      'hive',
      h.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<void> softDelete(String table, String uuid) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (await db).update(
      table,
      {'dateDeleted': now, 'dateModified': now, 'dateSynched': null},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    _notifyLocalChange();
  }

  Future<int> hiveCount([String? apiaryUuid, bool activeOnly = true]) async {
    final statusClause = activeOnly
        ? " AND (status = 'ACTIVE' OR status IS NULL OR status = '')"
        : '';
    if (apiaryUuid == null) {
      final r = await (await db).rawQuery(
        'SELECT COUNT(*) as c FROM hive WHERE dateDeleted IS NULL$statusClause',
      );
      return r.first['c'] as int;
    }
    final r = await (await db).rawQuery(
      'SELECT COUNT(*) as c FROM hive WHERE apiaryUuid = ? AND dateDeleted IS NULL$statusClause',
      [apiaryUuid],
    );
    return r.first['c'] as int;
  }

  Future<Queen?> activeQueen(String hiveUuid) async {
    final rows = await (await db).query(
      'queen',
      where: 'hiveUuid = ? AND active = 1 AND dateDeleted IS NULL',
      whereArgs: [hiveUuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Queen.fromMap(rows.first);
  }

  Future<List<Queen>> listQueens(String hiveUuid) async {
    final rows = await (await db).query(
      'queen',
      where: 'hiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [hiveUuid],
      orderBy: 'active DESC, activeFrom DESC, dateCreated DESC',
    );
    return rows.map(Queen.fromMap).toList();
  }

  Future<void> upsertQueen(Queen q) async {
    await (await db).insert(
      'queen',
      q.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<List<Note>> notesForHive(String hiveUuid) async {
    final rows = await (await db).query(
      'note',
      where: 'hiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [hiveUuid],
      orderBy: 'dateCreated DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> upsertNote(Note n) async {
    await (await db).insert(
      'note',
      n.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<List<Harvest>> harvestsForHive(String hiveUuid, {int? year}) async {
    if (year == null) {
      final rows = await (await db).query(
        'harvest',
        where: 'hiveUuid = ? AND dateDeleted IS NULL',
        whereArgs: [hiveUuid],
        orderBy: 'collectedAt DESC',
      );
      return rows.map(Harvest.fromMap).toList();
    }
    final rows = await (await db).query(
      'harvest',
      where: 'hiveUuid = ? AND harvestYear = ? AND dateDeleted IS NULL',
      whereArgs: [hiveUuid, year],
      orderBy: 'collectedAt DESC',
    );
    return rows.map(Harvest.fromMap).toList();
  }

  Future<double> harvestSum(String hiveUuid, int year) async {
    final rows = await (await db).rawQuery(
      'SELECT COALESCE(SUM(amountKg),0) as s FROM harvest WHERE hiveUuid = ? AND harvestYear = ? AND dateDeleted IS NULL',
      [hiveUuid, year],
    );
    return (rows.first['s'] as num).toDouble();
  }

  Future<void> upsertHarvest(Harvest h) async {
    await (await db).insert(
      'harvest',
      h.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<List<Inspection>> inspectionsForHive(String hiveUuid) async {
    final rows = await (await db).query(
      'inspection',
      where: 'hiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [hiveUuid],
      orderBy: 'inspectedAt DESC, dateCreated DESC',
    );
    return rows.map(Inspection.fromMap).toList();
  }

  Future<Inspection?> latestInspectionForHive(String hiveUuid) async {
    final rows = await (await db).query(
      'inspection',
      where: 'hiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [hiveUuid],
      orderBy: 'inspectedAt DESC, dateCreated DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Inspection.fromMap(rows.first);
  }

  Future<Inspection?> inspectionByUuid(String uuid) async {
    final rows = await (await db).query(
      'inspection',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Inspection.fromMap(rows.first);
  }

  Future<Inspection?> inspectionBySource({
    String? sourceGroupHiveUuid,
    String? sourceReminderUuid,
  }) async {
    if ((sourceGroupHiveUuid == null || sourceGroupHiveUuid.isEmpty) &&
        (sourceReminderUuid == null || sourceReminderUuid.isEmpty)) {
      return null;
    }
    final rows = await (await db).query(
      'inspection',
      where: '''
        dateDeleted IS NULL AND (
          (? IS NOT NULL AND sourceGroupHiveUuid = ?) OR
          (? IS NOT NULL AND sourceReminderUuid = ?)
        )
      ''',
      whereArgs: [
        sourceGroupHiveUuid,
        sourceGroupHiveUuid,
        sourceReminderUuid,
        sourceReminderUuid,
      ],
      orderBy: 'inspectedAt DESC, dateCreated DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Inspection.fromMap(rows.first);
  }

  Future<void> upsertInspection(Inspection inspection) async {
    await (await db).insert(
      'inspection',
      inspection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<Harvest?> harvestByUuid(String uuid) async {
    final rows = await (await db).query(
      'harvest',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Harvest.fromMap(rows.first);
  }

  Future<Harvest?> harvestForWorkGroupHive(String workGroupHiveUuid) async {
    final rows = await (await db).query(
      'harvest',
      where: 'workGroupHiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [workGroupHiveUuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Harvest.fromMap(rows.first);
  }

  Future<WorkGroupHive?> workGroupHiveByUuid(String uuid) async {
    final rows = await (await db).query(
      'work_group_hive',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkGroupHive.fromMap(rows.first);
  }

  Future<WorkGroup?> workGroupByUuid(String uuid) async {
    final rows = await (await db).query(
      'work_group',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkGroup.fromMap(rows.first);
  }

  Future<Reminder?> reminderByUuid(String uuid) async {
    final rows = await (await db).query(
      'reminder',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Reminder.fromMap(rows.first);
  }

  Future<Reminder?> reminderByInspection(String inspectionUuid) async {
    final rows = await (await db).query(
      'reminder',
      where: 'inspectionUuid = ? AND dateDeleted IS NULL',
      whereArgs: [inspectionUuid],
      orderBy: 'dueAt DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Reminder.fromMap(rows.first);
  }

  Future<List<Note>> notesForGroupRecord(String groupRecordUuid) async {
    final rows = await (await db).query(
      'note',
      where: 'groupRecordUuid = ? AND dateDeleted IS NULL',
      whereArgs: [groupRecordUuid],
      orderBy: 'dateCreated DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Reminder>> remindersForGroupHive(String groupHiveUuid) async {
    final rows = await (await db).query(
      'reminder',
      where: 'groupHiveUuid = ? AND dateDeleted IS NULL',
      whereArgs: [groupHiveUuid],
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<WorkGroup?> workGroupByType(String type) async {
    final rows = await (await db).query(
      'work_group',
      where: 'groupType = ? AND dateDeleted IS NULL AND finished = 0',
      whereArgs: [type],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkGroup.fromMap(rows.first);
  }

  Future<List<WorkGroup>> listWorkGroups() async {
    final rows = await (await db).query(
      'work_group',
      where: 'dateDeleted IS NULL',
    );
    return rows.map(WorkGroup.fromMap).toList();
  }

  Future<void> upsertWorkGroup(WorkGroup g) async {
    await (await db).insert(
      'work_group',
      g.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<List<WorkGroupHive>> groupHives(
    String groupUuid, {

    /// null = samo aktivne; 'FINISHED' / 'REMOVED' / 'ALL'
    String? filter,
  }) async {
    if (filter == null || filter == 'ACTIVE') {
      final rows = await (await db).query(
        'work_group_hive',
        where:
            "groupUuid = ? AND dateDeleted IS NULL AND (membershipStatus = 'ACTIVE' OR (membershipStatus IS NULL AND done = 0))",
        whereArgs: [groupUuid],
        orderBy: 'dateCreated DESC',
      );
      return rows.map(WorkGroupHive.fromMap).toList();
    }
    if (filter == 'ALL') {
      final rows = await (await db).query(
        'work_group_hive',
        where: 'groupUuid = ? AND dateDeleted IS NULL',
        whereArgs: [groupUuid],
        orderBy: 'dateCreated DESC',
      );
      return rows.map(WorkGroupHive.fromMap).toList();
    }
    final rows = await (await db).query(
      'work_group_hive',
      where: 'groupUuid = ? AND dateDeleted IS NULL AND membershipStatus = ?',
      whereArgs: [groupUuid, filter],
      orderBy: 'activeTo DESC, dateModified DESC',
    );
    return rows.map(WorkGroupHive.fromMap).toList();
  }

  Future<int> groupHiveCount(String groupUuid) async {
    final r = await (await db).rawQuery(
      "SELECT COUNT(*) as c FROM work_group_hive WHERE groupUuid = ? AND dateDeleted IS NULL AND (membershipStatus = 'ACTIVE' OR (membershipStatus IS NULL AND done = 0))",
      [groupUuid],
    );
    return r.first['c'] as int;
  }

  /// Aktivno članstvo košnice u grupi (ako postoji).
  Future<WorkGroupHive?> activeMembershipInGroup(
    String groupUuid,
    String hiveUuid,
  ) async {
    final rows = await (await db).query(
      'work_group_hive',
      where:
          "groupUuid = ? AND hiveUuid = ? AND dateDeleted IS NULL AND (membershipStatus = 'ACTIVE' OR (membershipStatus IS NULL AND done = 0))",
      whereArgs: [groupUuid, hiveUuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkGroupHive.fromMap(rows.first);
  }

  Future<WorkGroupHive?> activeMovedMembershipForHive(String hiveUuid) async {
    final rows = await (await db).rawQuery(
      '''
      SELECT wgh.*
      FROM work_group_hive wgh
      JOIN work_group wg ON wg.uuid = wgh.groupUuid
      WHERE
        wgh.hiveUuid = ?
        AND wgh.dateDeleted IS NULL
        AND wg.dateDeleted IS NULL
        AND wg.groupType = 'MOVED'
        AND (wgh.membershipStatus = 'ACTIVE' OR (wgh.membershipStatus IS NULL AND wgh.done = 0))
      ORDER BY COALESCE(wgh.activeFrom, wgh.dateCreated) DESC
      LIMIT 1
      ''',
      [hiveUuid],
    );
    if (rows.isEmpty) return null;
    return WorkGroupHive.fromMap(rows.first);
  }

  Future<void> upsertWorkGroupHive(WorkGroupHive g) async {
    await (await db).insert(
      'work_group_hive',
      g.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<void> upsertReminder(Reminder r) async {
    await (await db).insert(
      'reminder',
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyLocalChange();
  }

  Future<List<Reminder>> pendingReminders() async {
    return listReminders(history: false);
  }

  /// Budući/zakasneli (completed=0), najskoriji prvi; istorija (completed=1), najnoviji prvi.
  Future<List<Reminder>> listReminders({bool history = false}) async {
    if (history) {
      final rows = await (await db).query(
        'reminder',
        where: 'completed = 1 AND dateDeleted IS NULL',
        orderBy: 'dueAt DESC',
      );
      return rows.map(Reminder.fromMap).toList();
    }
    final rows = await (await db).query(
      'reminder',
      where: 'completed = 0 AND dateDeleted IS NULL',
      orderBy: 'dueAt ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> dirty(String table) async {
    final rows = await (await db).query(table);
    return rows.where(_rowNeedsSync).toList();
  }

  /// Zapis čeka sync ako nikad nije poslat, ili je menjan posle poslednjeg sync-a.
  static bool _rowNeedsSync(Map<String, dynamic> row) {
    final synched = _parseDt(row['dateSynched']);
    if (synched == null) return true;
    final modified = _parseDt(row['dateModified']);
    if (modified == null) return false;
    return modified.isAfter(synched);
  }

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse('$v')?.toUtc();
  }

  static const syncTables = [
    'apiary',
    'hive',
    'queen',
    'note',
    'harvest',
    'inspection',
    'work_group',
    'work_group_hive',
    'reminder',
  ];

  /// Ukupan broj lokalnih zapisa koji čekaju sync.
  Future<int> unsyncedCount() async {
    var total = 0;
    for (final t in syncTables) {
      total += (await dirty(t)).length;
    }
    return total;
  }

  Future<void> markSynched(String table, String uuid, DateTime when) async {
    final database = await db;
    final rows = await database.query(
      table,
      columns: ['dateModified'],
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    var synched = when.toUtc();
    if (rows.isNotEmpty) {
      final mod = _parseDt(rows.first['dateModified']);
      if (mod != null && mod.isAfter(synched)) synched = mod;
    }
    await database.update(
      table,
      {'dateSynched': synched.toIso8601String()},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Zamenjuje tabelu podacima sa servera. Pull = već sinhronizovano.
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    final database = await db;
    await database.delete(table);
    final pulledAt = DateTime.now().toUtc();
    for (final row in rows) {
      final r = Map<String, dynamic>.from(row);
      final mod = _parseDt(r['dateModified']);
      // Snapshot sa servera je izvor istine — ne sme ostati „dirty“.
      var synched = pulledAt;
      if (mod != null && mod.isAfter(synched)) synched = mod;
      r['dateSynched'] = synched.toIso8601String();
      await database.insert(
        table,
        r,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Briše sve lokalne podatke (npr. posle brisanja naloga).
  Future<void> clearAllUserData() async {
    final database = await db;
    for (final table in const [
      'reminder',
      'inspection',
      'work_group_hive',
      'work_group',
      'harvest',
      'note',
      'queen',
      'hive',
      'apiary',
    ]) {
      await database.delete(table);
    }
  }

  Future<Apiary?> apiaryByUuid(String uuid) async {
    final rows = await (await db).query(
      'apiary',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Apiary.fromMap(rows.first);
  }
}
