import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // ======= CONFIGURA AQUÍ TU BASE URL =======
  // XAMPP (Apache en puerto 80):
  static const String baseUrlWeb = 'http://localhost/mascotas_api';
  // Android Emulator (accede al host con 10.0.2.2):
  static const String baseUrlEmu = 'http://10.0.2.2/mascotas_api';
  // Si pruebas en dispositivo físico, usa la IP de tu PC en la misma red:
  // static const String baseUrlDevice = 'http://TU-IP-LAN/mascotas_api';

  static String get _base {
    // Para Web/Escritorio usa localhost; para Android Emulator usa 10.0.2.2
    return kIsWeb ? baseUrlWeb : baseUrlEmu;
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 15);

  // ---------- Utils ----------
  static Map<String, dynamic> _safeDecode(String src) {
    try {
      final decoded = json.decode(src);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'_nonmap': true, 'raw': src};
    } catch (_) {
      return {'_invalid_json': true, 'raw': src};
    }
  }

  static Exception _buildException(
    http.Response resp,
    Map<String, dynamic> data,
    String fallback,
  ) {
    // Si no vino JSON válido, muestra el body crudo para debug
    if (data['_invalid_json'] == true || data['_nonmap'] == true) {
      return Exception(
        'HTTP ${resp.statusCode}. Respuesta no-JSON: ${resp.body}',
      );
    }
    // Si vino JSON, intenta usar su mensaje
    return Exception(data['message'] ?? '$fallback (HTTP ${resp.statusCode})');
  }

  // ---------- Endpoints ----------
  /// Login con correo y contraseña.
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
  }) async {
    final uri = Uri.parse('$_base/login.php');
    final resp = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
        )
        .timeout(_timeout);

    final data = _safeDecode(resp.body);

    if (resp.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw _buildException(resp, data, 'Error al iniciar sesión');
  }

  /// Registro de usuario adoptante (rol forzado en backend).
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String correo,
    required String contrasena,
    required String telefono,
  }) async {
    final uri = Uri.parse('$_base/register.php');
    final body = {
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'telefono': telefono,
    };

    final resp = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    final data = _safeDecode(resp.body);

    // register.php debe responder 201 en éxito
    if ((resp.statusCode == 201 || resp.statusCode == 200) &&
        data['success'] == true) {
      return data;
    }
    throw _buildException(resp, data, 'Error al registrarse');
  }

  /// Ping opcional para verificar que el backend responde.
  static Future<bool> ping() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/ping.php'))
          .timeout(_timeout);
      final data = _safeDecode(resp.body);
      return resp.statusCode == 200 && (data['ok'] == true);
    } catch (_) {
      return false;
    }
  }
}
