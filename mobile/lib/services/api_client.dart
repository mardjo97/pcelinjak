import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const baseUrlValue = 'https://pcelinjak.hexatech.rs';
  static const _tokenKey = 'auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> Function()? onUnauthorized;
  bool _handlingUnauthorized = false;

  Future<String> baseUrl() async => baseUrlValue;

  Future<String?> token() async {
    final secure = await _storage.read(key: _tokenKey);
    if (secure != null && secure.isNotEmpty) return secure;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: legacy);
      await prefs.remove(_tokenKey);
      return legacy;
    }
    return null;
  }

  Future<void> saveSession({
    required String token,
    required int userId,
    required String email,
    required String name,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.setInt('user_id', userId);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
    if (firstName != null) await prefs.setString('user_first_name', firstName);
    if (lastName != null) await prefs.setString('user_last_name', lastName);
    if (phone != null) {
      await prefs.setString('user_phone', phone);
    } else {
      await prefs.remove('user_phone');
    }
  }

  Future<Map<String, String?>> session() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': await token(),
      'email': prefs.getString('user_email'),
      'name': prefs.getString('user_name'),
      'firstName': prefs.getString('user_first_name'),
      'lastName': prefs.getString('user_last_name'),
      'phone': prefs.getString('user_phone'),
    };
  }

  Future<bool> isLoggedIn() async => (await token()) != null;

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_phone');
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
    return _decode(res, path);
  }

  Future<dynamic> post(String path, Object? body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('${await baseUrl()}$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res, path);
  }

  Future<dynamic> put(String path, Object? body, {bool auth = true}) async {
    final res = await http.put(
      Uri.parse('${await baseUrl()}$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res, path);
  }

  bool _skipUnauthorized(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/delete-account') ||
        path.contains('/auth/change-password');
  }

  Future<void> _maybeUnauthorized(int statusCode, String path) async {
    if (statusCode != 401 || _skipUnauthorized(path) || _handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      await onUnauthorized?.call();
    } catch (_) {
    } finally {
      _handlingUnauthorized = false;
    }
  }

  dynamic _decode(http.Response res, String path) {
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
    if (res.statusCode == 401) {
      unawaited(_maybeUnauthorized(res.statusCode, path));
    }
    throw ApiException(res.statusCode, message, code: code);
  }
}
