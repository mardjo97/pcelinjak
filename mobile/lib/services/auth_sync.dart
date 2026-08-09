import '../database/app_database.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'device_id_service.dart';

class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<String> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final deviceUuid = await DeviceIdService.getOrCreate();
    final res =
        await api.post('/auth/register', {
              'email': email,
              'password': password,
              'name': name,
              'phone': phone,
              'deviceUuid': deviceUuid,
            }, auth: false)
            as Map<String, dynamic>;
    return res['message'] as String? ?? 'Proverite email za aktivaciju naloga.';
  }

  Future<void> login({required String email, required String password}) async {
    final deviceUuid = await DeviceIdService.getOrCreate();
    final res =
        await api.post('/auth/login', {
              'email': email,
              'password': password,
              'deviceUuid': deviceUuid,
            }, auth: false)
            as Map<String, dynamic>;
    await api.saveSession(
      token: res['token'] as String,
      userId: res['userId'] as int,
      email: res['email'] as String,
      name: res['name'] as String? ?? '',
      phone: res['phone'] as String?,
    );
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', {});
    } catch (_) {}
    await api.clearSession();
  }

  Future<void> deleteAccount({required String password}) async {
    await api.post('/auth/delete-account', {'password': password});
    await AppDatabase.instance.clearAllUserData();
    await api.clearSession();
  }
}

class SyncService {
  final ApiClient api;
  final AppDatabase db;
  SyncService(this.api, this.db);

  Future<String> fullSync() async {
    final pushed = await pushPending();
    await _pullAll();
    await db.dedupeWorkGroups();
    return pushed;
  }

  /// Samo šalje lokalne (dirty) izmene na server.
  Future<String> pushPending() async {
    var count = 0;
    count += await _pushTable('apiary', '/api/apiaries/sync', (m) => m);
    count += await _pushTable('hive', '/api/hives/sync', (m) => m);
    count += await _pushTable('queen', '/api/queens/sync', _boolish);
    count += await _pushTable('note', '/api/notes/sync', (m) => m);
    count += await _pushTable('harvest', '/api/harvests/sync', (m) => m);
    count += await _pushTable('inspection', '/api/inspections/sync', (m) => m);
    count += await _pushWorkGroups();
    count += await _pushTable(
      'work_group_hive',
      '/api/work-group-hives/sync',
      _boolish,
    );
    count += await _pushTable('reminder', '/api/reminders/sync', _boolish);
    return 'Poslato $count zapisa';
  }

  /// Sync grupa: ako server vrati drugi (kanonski) UUID, lokalna članstva se prebacuju.
  Future<int> _pushWorkGroups() async {
    final dirty = await db.dirty('work_group');
    if (dirty.isEmpty) return 0;
    final payload = dirty.map(_boolish).toList();
    final res =
        await api.post('/api/work-groups/sync', payload) as Map<String, dynamic>;
    final items = (res['items'] as List?) ?? [];
    final now = DateTime.now();

    for (var i = 0; i < dirty.length; i++) {
      final localUuid = dirty[i]['uuid'] as String?;
      if (localUuid == null) continue;
      String? serverUuid;
      if (i < items.length) {
        serverUuid = (items[i] as Map)['uuid'] as String?;
      }
      if (serverUuid != null &&
          serverUuid.isNotEmpty &&
          serverUuid != localUuid) {
        await db.remapWorkGroupUuid(localUuid, serverUuid);
        await db.softDeleteWorkGroup(localUuid);
      }
      await db.markSynched('work_group', serverUuid ?? localUuid, now);
    }
    return dirty.length;
  }

  Map<String, dynamic> _boolish(Map<String, dynamic> m) {
    final out = Map<String, dynamic>.from(m);
    for (final key in ['marked', 'active', 'finished', 'done', 'completed']) {
      if (out.containsKey(key)) {
        final v = out[key];
        out[key] = v == true || v == 1;
      }
    }
    return out;
  }

  Future<int> _pushTable(
    String table,
    String path,
    Map<String, dynamic> Function(Map<String, dynamic>) mapRow,
  ) async {
    final dirty = await db.dirty(table);
    if (dirty.isEmpty) return 0;
    final payload = dirty.map(mapRow).toList();
    final res = await api.post(path, payload) as Map<String, dynamic>;
    final items = (res['items'] as List?) ?? [];
    final now = DateTime.now();
    final marked = <String>{};
    for (final item in items) {
      final uuid = (item as Map)['uuid'] as String?;
      if (uuid != null) {
        await db.markSynched(table, uuid, now);
        marked.add(uuid);
      }
    }
    // Ako server ne vrati items, i dalje označi sve što smo uspešno poslali.
    for (final row in dirty) {
      final uuid = row['uuid'] as String?;
      if (uuid != null && !marked.contains(uuid)) {
        await db.markSynched(table, uuid, now);
      }
    }
    return dirty.length;
  }

  Future<void> _pullAll() async {
    await _pull('apiary', '/api/apiaries/all', Apiary.fromMap);
    await _pull('hive', '/api/hives/all', Hive.fromMap);
    await _pull('queen', '/api/queens/all', (m) {
      final mapped = Map<String, dynamic>.from(m);
      mapped['marked'] = m['marked'] == true ? 1 : 0;
      mapped['active'] = m['active'] == true ? 1 : 0;
      return Queen.fromMap(mapped).toMap();
    }, alreadyMap: true);
    await _pull('note', '/api/notes/all', Note.fromMap);
    await _pull('harvest', '/api/harvests/all', Harvest.fromMap);
    await _pull('inspection', '/api/inspections/all', Inspection.fromMap);
    await _pull('work_group', '/api/work-groups/all', (m) {
      return WorkGroup.fromMap(Map<String, dynamic>.from(m)).toMap();
    }, alreadyMap: true);
    await _pull('work_group_hive', '/api/work-group-hives/all', (m) {
      return WorkGroupHive.fromMap(Map<String, dynamic>.from(m)).toMap();
    }, alreadyMap: true);
    await _pull('reminder', '/api/reminders/all', (m) {
      return Reminder.fromMap(Map<String, dynamic>.from(m)).toMap();
    }, alreadyMap: true);
  }

  Future<void> _pull(
    String table,
    String path,
    dynamic Function(Map<String, dynamic>) mapper, {
    bool alreadyMap = false,
  }) async {
    final list = await api.get(path) as List<dynamic>;
    final rows = <Map<String, dynamic>>[];
    for (final item in list) {
      final m = Map<String, dynamic>.from(item as Map);
      if (alreadyMap) {
        rows.add(mapper(m) as Map<String, dynamic>);
      } else {
        final model = mapper(m);
        rows.add((model as dynamic).toMap() as Map<String, dynamic>);
      }
    }
    // Merge: keep local unfinished work groups if server empty for type — simple replace for MVP sync after login
    if (rows.isNotEmpty || table != 'work_group') {
      if (table == 'work_group' && rows.isEmpty) return;
      await db.replaceAll(table, rows);
    }
  }
}
