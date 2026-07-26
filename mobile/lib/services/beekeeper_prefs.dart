import 'package:shared_preferences/shared_preferences.dart';

/// Podaci pčelara za zvanične obrasce (Prilog 4).
class BeekeeperPrefs {
  static const _hidKey = 'beekeeper_hid';
  static const _nameKey = 'beekeeper_report_name';

  static Future<String> hid() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_hidKey) ?? '';
  }

  static Future<void> setHid(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_hidKey, value.replaceAll(RegExp(r'\D'), ''));
  }

  static Future<String> reportName({String? fallback}) async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_nameKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return fallback?.trim() ?? '';
  }

  static Future<void> setReportName(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_nameKey, value.trim());
  }
}
