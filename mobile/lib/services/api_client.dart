import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'device_id_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, {this.code});

  bool get isDeviceMismatch => code == 'DEVICE_MISMATCH' || message.contains('DEVICE_MISMATCH');

  @override
  String toString() => message;
}

class ApiClient {
  static const defaultBaseUrl = 'http://192.168.8.175:8081';

  Future<String> baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url.replaceAll(RegExp(r'/$'), ''));
  }

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveSession({
    required String token,
    required int userId,
    required String email,
    required String name,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
    if (phone != null) await prefs.setString('user_phone', phone);
  }

  Future<Map<String, String?>> session() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('auth_token'),
      'email': prefs.getString('user_email'),
      'name': prefs.getString('user_name'),
      'phone': prefs.getString('user_phone'),
    };
  }

  Future<bool> isLoggedIn() async => (await token()) != null;

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final deviceId = await DeviceIdService.getOrCreate();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-Id': deviceId,
    };
    if (auth) {
      final t = await token();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('${await baseUrl()}$path'), headers: await _headers(auth: auth));
    return _decode(res);
  }

  Future<dynamic> post(String path, Object? body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('${await baseUrl()}$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, Object? body, {bool auth = true}) async {
    final res = await http.put(
      Uri.parse('${await baseUrl()}$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final text = res.body.isEmpty ? '{}' : res.body;
    dynamic json;
    try {
      json = jsonDecode(text);
    } catch (_) {
      json = {'message': text};
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    final code = json is Map ? json['code'] as String? : null;
    final message = json is Map
        ? (json['message'] as String? ?? json.toString())
        : text;
    throw ApiException(res.statusCode, message, code: code);
  }
}
