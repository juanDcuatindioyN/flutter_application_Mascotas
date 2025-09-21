import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Usa la IP según tu entorno (ej: 10.0.2.2 para emulator, IP local para físico)
  static const String baseUrl = 'http://10.0.2.2/mascotas_api'; 

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Método para login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_login.php'),
        headers: headers,
        body: json.encode({
          'correo': email,
          'contrasena': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en login: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método para registro
  static Future<Map<String, dynamic>> register(
    String nombre,
    String correo,
    String contrasena,
    String telefono,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api_registros.php'),
        headers: headers,
        body: json.encode({
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'telefono': telefono,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en registro: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
