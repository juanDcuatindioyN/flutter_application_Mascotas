// lib/Servicios/api_servicios.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

/// Puedes sobreescribir desde línea de comando o .env:
/// flutter run --dart-define=BASE_URL=http://192.168.1.50/mascotas_api
const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

/// Si usas dispositivo físico, pon aquí la IP de tu PC en la LAN:
const String _lanBaseFallback =
    'http://192.168.1.100/mascotas_api'; // <-- cámbiala si lo necesitas

String get _autoBaseUrl {
  if (_envBase.isNotEmpty) return _envBase;

  if (kIsWeb) return 'http://localhost/mascotas_api';

  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android emulator (AVD) -> 10.0.2.2
    // Genymotion -> 10.0.3.2 (descomenta si usas genymotion)
    return 'http://10.0.2.2/mascotas_api';
    // return 'http://10.0.3.2/mascotas_api';
    // Si pruebas en DISPOSITIVO FÍSICO, usa tu IP LAN:
    // return _lanBaseFallback;
  }

  // iOS simulador suele resolver localhost. Para iPhone real, usa tu IP LAN.
  return 'http://localhost/mascotas_api';
}

class ApiService {
  static String get baseUrl => _autoBaseUrl;

  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  // ------------------ Auth ------------------
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
    bool debug = true,
  }) async {
    final url = debug ? '$baseUrl/login.php?debug=1' : '$baseUrl/login.php';
    final payload = {'correo': correo.trim(), 'contrasena': contrasena};
    try {
      final r = await http
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 12));

      return _decode(r);
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: $e',
        'http_status': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> registro(
    String nombre,
    String correo,
    String telefono,
    String contrasena,
  ) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'telefono': telefono,
          'contrasena': contrasena,
        }),
      );
      return _decode(r);
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: $e',
        'http_status': 0,
      };
    }
  }

  // ------------------ Perfil ------------------
  static Future<Map<String, dynamic>> getPerfil({
    required int idUsuario,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/usuarios_get.php',
      ).replace(queryParameters: {'id_usuario': '$idUsuario'});
      final r = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  static Future<Map<String, dynamic>> actualizarPerfil({
    required int idUsuario,
    required String nombre,
    required String correo,
    required String telefono,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/usuario.php'),
        headers: _headers,
        body: json.encode({
          'id_usuario': idUsuario,
          'nombre': nombre,
          'correo': correo,
          'telefono': telefono,
        }),
      );
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  // ------------------ Password ------------------
  static Future<Map<String, dynamic>> cambiarPassword({
    required int idUsuario,
    required String actual,
    required String nueva,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse(
              '$baseUrl/password.php',
            ), // <-- antes: usuarios_password.php
            headers: _headers,
            body: json.encode({
              'id_usuario': idUsuario,
              'actual': actual,
              'nueva': nueva,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  // ------------------ Requisitos ------------------
  static Future<Map<String, dynamic>> getRequisitos({
    required int idUsuario,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/requisitos_get.php',
      ).replace(queryParameters: {'id_usuario': '$idUsuario'});
      final r = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  static Future<Map<String, dynamic>> saveRequisitos({
    required int idUsuario,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('$baseUrl/requisitos.php');
    final bodyJson = json.encode({'id_usuario': idUsuario, ...data});

    // ---- LOGS UTILES ----
    // ignore: avoid_print
    print('POST $uri');
    // ignore: avoid_print
    print('HEADERS=$_headers');
    // ignore: avoid_print
    print('BODY=$bodyJson');

    try {
      final r = await http
          .post(uri, headers: _headers, body: bodyJson)
          .timeout(const Duration(seconds: 12));

      // ---- LOG DEL RAW POR SI EL SERVIDOR RESponde HTML ----
      // ignore: avoid_print
      print('RESP(${r.statusCode})=${r.body}');

      return _decode(r);
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: $e',
        'http_status': 0,
      };
    }
  }

  // ------------------ Solicitudes ------------------
  static Future<Map<String, dynamic>> crearSolicitud({
    required int idUsuario,
    required int idMascota,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/solicitudes_create.php'),
            headers: _headers,
            body: jsonEncode({
              'id_usuario': idUsuario,
              'id_mascota': idMascota,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  static Future<Map<String, dynamic>> solicitudesPorUsuario(
    int idUsuario,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/solicitudes.php',
      ).replace(queryParameters: {'id_usuario': '$idUsuario'});
      final r = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión', 'http_status': 0};
    }
  }

  static Future<Map<String, dynamic>> cancelarSolicitud({
    required int idSolicitud,
    bool debug = true,
  }) async {
    final url = debug
        ? '$baseUrl/solicitudes_cancel.php?debug=1'
        : '$baseUrl/solicitudes_cancel.php';
    try {
      final r = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode({'id_solicitud': idSolicitud}),
          )
          .timeout(const Duration(seconds: 12));
      return _decode(r);
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: $e',
        'http_status': 0,
      };
    }
  }

  // ------------------ Mascotas ------------------
  static Future<Map<String, dynamic>> listarMascotas({
    String estado = 'disponible',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/mascotas_list.php',
      ).replace(queryParameters: {'estado': estado});
      final r = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _decode(r);
    } catch (e) {
      return {
        'success': false,
        'msg': 'Error de conexión: $e',
        'items': const [],
        'http_status': 0,
      };
    }
  }

  // ------------------ Helper ------------------
  static Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> out;
    try {
      out =
          (r.body.isEmpty ? <String, dynamic>{} : json.decode(r.body))
              as Map<String, dynamic>;
    } catch (_) {
      // Devolver raw para depurar si el servidor responde HTML/avisos
      return {
        'success': false,
        'msg': 'Respuesta no válida del servidor',
        'raw': r.body,
        'http_status': r.statusCode,
      };
    }
    out['http_status'] = r.statusCode;
    out['success'] = out['success'] ?? out['ok'] ?? false;
    out['msg'] = out['msg'] ?? out['message'] ?? '';
    return out;
  }
}
