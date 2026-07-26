import '../database/app_database.dart';
import '../models/models.dart';
import 'reminder_service.dart';

/// Dvosmerna sinhronizacija deljenih podataka: članstvo u grupi ↔ prinos / napomena / podsetnik.
class GroupSharedDataSync {
  GroupSharedDataSync([AppDatabase? db]) : db = db ?? AppDatabase.instance;

  final AppDatabase db;

  static bool usesHarvest(String groupType) =>
      groupType == 'MOVED' || groupType == 'GOOD_PASTURE';

  /// Posle izmene članstva: ažurira povezani prinos i napomenu.
  Future<void> syncFromMembership(WorkGroupHive item, {required String groupType}) async {
    if (usesHarvest(groupType)) {
      await _upsertLinkedHarvest(item);
    }
    await _syncLinkedNote(item, groupType: groupType);
  }

  /// Posle izmene prinosa: ažurira povezano članstvo (paša + kg).
  Future<void> syncFromHarvest(Harvest harvest) async {
    final link = harvest.workGroupHiveUuid;
    if (link == null || link.isEmpty) return;
    final item = await db.workGroupHiveByUuid(link);
    if (item == null || item.dateDeleted != null) return;

    item.pastureType = harvest.pastureType;
    item.amount = harvest.amountKg;
    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
  }

  /// Brisanje prinosa: ako je vezan za grupu — briše i članstvo bez istorije.
  Future<void> deleteHarvest(Harvest harvest) async {
    final link = harvest.workGroupHiveUuid;
    await db.softDelete('harvest', harvest.uuid);
    if (link == null || link.isEmpty) return;
    final item = await db.workGroupHiveByUuid(link);
    if (item == null || item.dateDeleted != null) return;
    await deleteMembershipWithoutHistory(item, alsoDeleteHarvest: false);
  }

  /// Brisanje člana grupe bez istorije — briše i povezani prinos, napomene i podsetnike.
  Future<void> deleteMembershipWithoutHistory(
    WorkGroupHive item, {
    bool alsoDeleteHarvest = true,
  }) async {
    if (alsoDeleteHarvest) {
      final h = await db.harvestForWorkGroupHive(item.uuid);
      if (h != null) await db.softDelete('harvest', h.uuid);
    }

    for (final n in await db.notesForGroupRecord(item.uuid)) {
      await db.softDelete('note', n.uuid);
    }

    for (final r in await db.remindersForGroupHive(item.uuid)) {
      await ReminderService.instance.cancel(r.uuid.hashCode & 0x7fffffff);
      await db.softDelete('reminder', r.uuid);
    }

    await db.softDelete('work_group_hive', item.uuid);
  }

  /// Posle izmene napomene sa vezaom na grupu — ažurira note na članstvu.
  Future<void> syncFromNote(Note note) async {
    final link = note.groupRecordUuid;
    if (link == null || link.isEmpty) return;
    final item = await db.workGroupHiveByUuid(link);
    if (item == null || item.dateDeleted != null) return;
    item.note = note.content;
    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
  }

  /// Brisanje napomene vezane za grupu — čisti note na članstvu (ne briše članstvo).
  Future<void> onNoteDeleted(Note note) async {
    final link = note.groupRecordUuid;
    if (link == null || link.isEmpty) return;
    final item = await db.workGroupHiveByUuid(link);
    if (item == null || item.dateDeleted != null) return;
    item.note = null;
    item.touch();
    item.dateSynched = null;
    await db.upsertWorkGroupHive(item);
  }

  Future<void> _upsertLinkedHarvest(WorkGroupHive item) async {
    final existing = await db.harvestForWorkGroupHive(item.uuid);
    final pasture = item.pastureType ?? 'Drugo';
    final kg = item.amount ?? 0;
    if (existing != null) {
      existing.pastureType = pasture;
      existing.amountKg = kg;
      existing.touch();
      existing.dateSynched = null;
      await db.upsertHarvest(existing);
      return;
    }
    await db.upsertHarvest(Harvest(
      uuid: db.newUuid(),
      hiveUuid: item.hiveUuid,
      pastureType: pasture,
      amountKg: kg,
      collectedAt: item.activeFrom ?? DateTime.now(),
      harvestYear: (item.activeFrom ?? DateTime.now()).year,
      workGroupHiveUuid: item.uuid,
    ));
  }

  Future<void> _syncLinkedNote(WorkGroupHive item, {required String groupType}) async {
    final notes = await db.notesForGroupRecord(item.uuid);
    final text = item.note?.trim();
    if (text == null || text.isEmpty) {
      for (final n in notes) {
        await db.softDelete('note', n.uuid);
      }
      return;
    }
    if (notes.isNotEmpty) {
      final n = notes.first;
      n.content = text;
      n.touch();
      n.dateSynched = null;
      await db.upsertNote(n);
      return;
    }
    await db.upsertNote(Note(
      uuid: db.newUuid(),
      hiveUuid: item.hiveUuid,
      content: text,
      groupType: groupType,
      groupRecordUuid: item.uuid,
    ));
  }
}
