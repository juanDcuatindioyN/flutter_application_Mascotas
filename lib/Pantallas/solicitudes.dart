import 'dart:async';
import 'package:flutter/material.dart';
import '../Servicios/api_servicios.dart';
import '../Servicios/session_manager.dart';

/// ====== MODELOS ======

class SolicitudItem {
  final int idSolicitud;
  final int? idMascota; // opcional
  final String mascota; // nombre de la mascota
  final String? especie; // opcional
  final String? fundacion; // opcional
  final String estado; // pendiente | aprobada | rechazada | cancelada
  final String? foto; // opcional

  SolicitudItem({
    required this.idSolicitud,
    required this.mascota,
    required this.estado,
    this.idMascota,
    this.especie,
    this.fundacion,
    this.foto,
  });

  factory SolicitudItem.fromJson(Map<String, dynamic> j) {
    String? nombre;
    String? especie;
    String? fundacion;
    String? foto;
    int? idMasc;

    final m = j['mascota'];
    if (m is Map) {
      idMasc = _toInt(m['id'] ?? m['id_mascota']);
      nombre = m['nombre']?.toString();
      especie = m['especie']?.toString();
      fundacion = (m['fundacion'] ?? m['nombre_fundacion'])?.toString();
      foto = m['foto']?.toString();
    }

    return SolicitudItem(
      idSolicitud: _toInt(j['id_solicitud']) ?? 0,
      idMascota: idMasc ?? _toInt(j['id_mascota']),
      mascota: (nombre ?? j['nombre_mascota'] ?? j['mascota'] ?? '').toString(),
      especie: especie ?? j['especie']?.toString(),
      fundacion: fundacion ?? j['fundacion']?.toString(),
      estado: (j['estado'] ?? '').toString(),
      foto: foto ?? j['foto']?.toString(),
    );
  }

  // para actualizar un campo (p.ej. estado) sin perder los demás
  SolicitudItem copyWith({
    int? idSolicitud,
    int? idMascota,
    String? mascota,
    String? especie,
    String? fundacion,
    String? estado,
    String? foto,
  }) {
    return SolicitudItem(
      idSolicitud: idSolicitud ?? this.idSolicitud,
      idMascota: idMascota ?? this.idMascota,
      mascota: mascota ?? this.mascota,
      especie: especie ?? this.especie,
      fundacion: fundacion ?? this.fundacion,
      estado: estado ?? this.estado,
      foto: foto ?? this.foto,
    );
  }
}

int? _toInt(dynamic v) => v == null ? null : int.tryParse('$v');

class _RespSolicitudes {
  final List<SolicitudItem> items;
  final String? msg;
  const _RespSolicitudes({required this.items, this.msg});

  factory _RespSolicitudes.fromMap(Map<String, dynamic> m) {
    final list = (m['items'] as List? ?? [])
        .map((e) => SolicitudItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return _RespSolicitudes(items: list, msg: m['msg']?.toString());
  }

  factory _RespSolicitudes.empty({String? msg}) =>
      _RespSolicitudes(items: const [], msg: msg);
}

/// ========= PANTALLA =========

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  late Future<_RespSolicitudes> _future;
  List<SolicitudItem> _cache = [];
  String _filtro = 'todas'; // todas | pendiente | aprobada | rechazada

  @override
  void initState() {
    super.initState();
    _future = _cargarSolicitudes();
  }

  // Agrupa 'cancelada' dentro de 'rechazada' para filtros/contadores
  String _estadoFiltro(String raw) {
    switch (raw.toLowerCase()) {
      case 'pendiente':
        return 'pendiente';
      case 'aprobada':
        return 'aprobada';
      case 'rechazada':
      case 'cancelada':
      default:
        return 'rechazada';
    }
  }

  // Etiqueta visual: respeta la palabra 'cancelada' si es el caso
  String _estadoLabel(String raw) {
    final r = raw.toLowerCase();
    if (r == 'cancelada') return 'cancelada';
    if (r == 'rechazada') return 'rechazada';
    if (r == 'aprobada') return 'aprobada';
    return 'pendiente';
  }

  int get _countTotal => _cache.length;
  int get _countPend =>
      _cache.where((e) => _estadoFiltro(e.estado) == 'pendiente').length;
  int get _countApr =>
      _cache.where((e) => _estadoFiltro(e.estado) == 'aprobada').length;
  int get _countRech =>
      _cache.where((e) => _estadoFiltro(e.estado) == 'rechazada').length;

  List<SolicitudItem> get _filtered {
    if (_filtro == 'todas') return _cache;
    return _cache.where((e) => _estadoFiltro(e.estado) == _filtro).toList();
  }

  Future<_RespSolicitudes> _cargarSolicitudes() async {
    final user = await SessionManager.getUser();
    if (user == null) {
      return _RespSolicitudes.empty(msg: 'Sin sesión');
    }
    final id = (user['id_usuario'] as num).toInt();
    final resp = await ApiService.solicitudesPorUsuario(id);
    if (resp['success'] == true) {
      final parsed = _RespSolicitudes.fromMap(resp);
      setState(() => _cache = parsed.items);
      return parsed;
    } else {
      return _RespSolicitudes.empty(
        msg: resp['msg']?.toString() ?? 'Error de conexión',
      );
    }
  }

  Future<void> _refresh() async {
    final data = await _cargarSolicitudes();
    if (mounted) {
      setState(() {
        _future = Future.value(data);
      });
    }
  }

  Future<void> _cancelar(SolicitudItem item) async {
    final ok = await _confirmar(
      context,
      title: 'Cancelar solicitud',
      message:
          '¿Seguro que quieres cancelar tu solicitud por "${item.mascota}"?',
    );
    if (ok != true) return;

    final r = await ApiService.cancelarSolicitud(idSolicitud: item.idSolicitud);

    if (r['success'] == true) {
      _showTopMessage(context, 'Solicitud cancelada', ok: true);
      setState(() {
        final i = _cache.indexWhere((s) => s.idSolicitud == item.idSolicitud);
        if (i != -1) {
          _cache[i] = _cache[i].copyWith(estado: 'cancelada');
        }
      });
    } else {
      _showTopMessage(context, r['msg']?.toString() ?? 'No se pudo cancelar');
    }
  }

  Future<bool?> _confirmar(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _showTopMessage(BuildContext context, String msg, {bool ok = false}) {
    final cs = Theme.of(context).colorScheme;
    final bar = MaterialBanner(
      content: Text(msg, style: TextStyle(color: cs.onPrimary)),
      backgroundColor: ok ? Colors.green : Colors.blue,
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('OK'),
        ),
      ],
    );
    final sm = ScaffoldMessenger.of(context);
    sm.clearMaterialBanners();
    sm.showMaterialBanner(bar);
    Future.delayed(const Duration(seconds: 2), () {
      if (sm.mounted) sm.hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                total: _countTotal,
                pendientes: _countPend,
                aprobadas: _countApr,
                rechazadas: _countRech,
                filtro: _filtro,
                onChangeFiltro: (f) => setState(() => _filtro = f),
              ),
            ),
            FutureBuilder<_RespSolicitudes>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      icon: Icons.error_outline,
                      text: 'Error: ${snap.error}',
                    ),
                  );
                }

                final items = _filtered;
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      icon: Icons.image_not_supported_outlined,
                      text: 'No tienes solicitudes pendientes',
                    ),
                  );
                }

                return SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final estFiltro = _estadoFiltro(it.estado);
                    final estLabel = _estadoLabel(it.estado);
                    return _SolicitudCard(
                      indexText: '#${it.idSolicitud}',
                      item: it,
                      estadoFiltro: estFiltro,
                      estadoLabel: estLabel,
                      onCancel: estFiltro == 'pendiente'
                          ? () => _cancelar(it)
                          : null,
                    );
                  },
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/home');
          if (i == 1) return;
          if (i == 2) Navigator.pushReplacementNamed(context, '/account');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

/// ========= HEADER con filtros =========
class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.pendientes,
    required this.aprobadas,
    required this.rechazadas,
    required this.filtro,
    required this.onChangeFiltro,
  });

  final int total;
  final int pendientes;
  final int aprobadas;
  final int rechazadas;
  final String filtro;
  final ValueChanged<String> onChangeFiltro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chipSel(String key, String label, int count) {
      final selected = filtro == key;
      return ChoiceChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? cs.primaryContainer : cs.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onSelected: (_) => onChangeFiltro(key),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tablet_mac, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Mis solicitudes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Revisa el estado de tus solicitudes',
              style: TextStyle(color: Colors.white.withOpacity(.95)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chipSel('todas', 'Todas', total),
                chipSel('pendiente', 'Pendiente', pendientes),
                chipSel('aprobada', 'Aprobada', aprobadas),
                chipSel('rechazada', 'Rechazada', rechazadas),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ========= UI auxiliares =========

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 36, color: cs.primary),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: cs.onSurface)),
      ],
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({
    required this.indexText,
    required this.item,
    required this.estadoFiltro,
    required this.estadoLabel,
    this.onCancel,
  });

  final String indexText;
  final SolicitudItem item;
  final String
  estadoFiltro; // pendiente | aprobada | rechazada(agrupa cancelada)
  final String estadoLabel; // pendiente | aprobada | rechazada | cancelada
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color chipBg;
    IconData chipIcon;
    switch (estadoFiltro) {
      case 'aprobada':
        chipBg = Colors.green.shade100;
        chipIcon = Icons.check_circle;
        break;
      case 'rechazada':
        chipBg = Colors.red.shade100;
        chipIcon = Icons.cancel;
        break;
      default:
        chipBg = Colors.amber.shade100;
        chipIcon = Icons.hourglass_bottom_rounded;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.foto == null || item.foto!.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: cs.surfaceVariant,
                      child: const Icon(Icons.pets),
                    )
                  : Image.network(
                      item.foto!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: cs.surfaceVariant,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.mascota,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        indexText,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.especie} · ${item.fundacion}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chipIcon, size: 16),
                            const SizedBox(width: 6),
                            Text(estadoLabel),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (onCancel != null)
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
