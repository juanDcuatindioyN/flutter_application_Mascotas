import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _kLoggedIn = 'logged_in';
  static const _kUserJson = 'user_json';

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kUserJson, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kUserJson);
  }

  // ===== Alias en español (compatibilidad) =====
  static Future<void> guardarUsuario(Map<String, dynamic> u) => saveUser(u);
  static Future<Map<String, dynamic>?> cargarUsuario() => getUser();
  static Future<bool> haySesion() => isLoggedIn();
  static Future<void> limpiar() => clear();

  /// Convierte con seguridad el id del usuario a int (venga como int o String).
  static int parseUserId(Map<String, dynamic> u) =>
      int.tryParse(u['id_usuario']?.toString() ?? '') ?? 0;
}
