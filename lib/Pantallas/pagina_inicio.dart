import 'package:flutter/material.dart';

class PaginaInicio extends StatelessWidget {
  const PaginaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final nombre = user?['nombre'] ?? 'Amigo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AdoptaAmigo'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 72),
            const SizedBox(height: 12),
            Text(
              '¡Hola, $nombre!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Bienvenido a AdoptaAmigo 🐾'),
          ],
        ),
      ),
    );
  }
}
