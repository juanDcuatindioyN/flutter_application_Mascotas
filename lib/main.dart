import 'package:flutter/material.dart';

// Pantallas
import 'Pantallas/login.dart';
import 'Pantallas/register.dart';
import 'Pantallas/pagina_inicio.dart';
import 'Pantallas/solicitudes.dart';
import 'Pantallas/cuenta.dart';

// Servicios
import 'Servicios/session_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF00796B); // verde bonito

    return MaterialApp(
      title: 'AdoptaAmigo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      ),

      // Arrancamos en un Splash que decide a dónde ir
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashGate(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const PaginaInicio(),
        '/solicitudes': (_) => const SolicitudesScreen(),
        '/account': (_) => const CuentaScreen(),
      },
    );
  }
}

/// Pantalla de arranque que decide a dónde navegar según la sesión guardada
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    // pequeña espera para que el árbol exista
    await Future.delayed(const Duration(milliseconds: 50));

    final user = await SessionManager.getUser(); // puede ser null
    final destino = (user != null) ? '/home' : '/login';

    if (!mounted) return;
    // Navegamos fuera del frame de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(destino);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Cargando…', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
