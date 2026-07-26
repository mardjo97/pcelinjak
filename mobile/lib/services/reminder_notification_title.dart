import '../database/app_database.dart';
import '../models/models.dart';

/// Naslov notifikacije: „Naziv pčelinjaka - barcode”.
class ReminderNotificationTitle {
  static String format({String? apiaryName, String? barcode}) {
    final name = (apiaryName ?? '').trim();
    final code = (barcode ?? '').trim();
    if (name.isNotEmpty && code.isNotEmpty) return '$name - $code';
    if (code.isNotEmpty) return code;
    if (name.isNotEmpty) return name;
    return 'Podsetnik';
  }

  static Future<String> forHiveUuid(String? hiveUuid) async {
    if (hiveUuid == null || hiveUuid.isEmpty) return 'Podsetnik';
    final db = AppDatabase.instance;
    final hive = await db.findHiveByUuid(hiveUuid);
    if (hive == null) return 'Podsetnik';
    final apiary = await db.apiaryByUuid(hive.apiaryUuid);
    return format(apiaryName: apiary?.name, barcode: hive.barcode);
  }

  static String forHive(Hive hive, Apiary? apiary) =>
      format(apiaryName: apiary?.name, barcode: hive.barcode);
}
