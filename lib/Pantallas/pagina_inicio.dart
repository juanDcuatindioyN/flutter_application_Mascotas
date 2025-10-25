import 'package:flutter/material.dart';
import '../Servicios/ui_messages.dart';
import '../Servicios/api_servicios.dart';
import '../Servicios/session_manager.dart';
import '../Servicios/ui_helpers.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late Future<_MascotasData> _future;
  int _currentIndex = 0;
  String? _nombreUsuario;

  bool _sendingAdopt = false; // bloquea Adoptar mientras se envía

  @override
  void initState() {
    super.initState();
    _future = _cargarMascotas();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final u = await SessionManager.getUser();
    if (!mounted) return;
    setState(() => _nombreUsuario = u?['nombre']?.toString());
  }

  Future<_MascotasData> _cargarMascotas() async {
    final resp = await ApiService.listarMascotas(estado: 'disponible');
    if (resp['success'] == true && resp['items'] is List) {
      final items = (resp['items'] as List)
          .map((e) => _MascotaItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return _MascotasData(items: items);
    }
    return _MascotasData(error: resp['msg']?.toString() ?? 'Error de conexión');
  }

  Future<void> _refresh() async {
    setState(() => _future = _cargarMascotas());
    await _future;
  }

  void _onNavTap(int i) {
    if (i == 0) {
      setState(() => _currentIndex = 0);
    } else if (i == 1) {
      Navigator.of(context).pushNamed('/solicitudes');
    } else if (i == 2) {
      Navigator.of(context).pushNamed('/account');
    }
  }

  // ------------------ Adoptar (con feedback bonito) ------------------
  Future<void> _adoptarMascota({
    required int idMascota,
    required String nombre,
    VoidCallback? afterSuccessClose, // para cerrar el sheet
  }) async {
    if (_sendingAdopt) return;
    setState(() => _sendingAdopt = true);

    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        _showTopMessage(context, 'Inicia sesión para adoptar');
        setState(() => _sendingAdopt = false);
        return;
      }
      final idU = (user['id_usuario'] as num).toInt();

      final resp = await ApiService.crearSolicitud(
        idUsuario: idU,
        idMascota: idMascota,
      );

      if (resp['success'] == true) {
        _showTopMessage(context, 'Solicitud enviada', ok: true);
        // cierra ficha si está abierta
        afterSuccessClose?.call();
        await _showAdoptSuccessSheet(context, nombreMascota: nombre);
      } else {
        _showTopMessage(
          context,
          resp['msg']?.toString() ?? 'No se pudo enviar la solicitud',
        );
      }
    } catch (e) {
      _showTopMessage(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _sendingAdopt = false);
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FutureBuilder<_MascotasData>(
        future: _future,
        builder: (context, snap) {
          final header = _HeaderHome(
            title: 'AdoptaAmigo',
            subtitle: 'Encuentra tu compañero perfecto',
            greeting: _nombreUsuario == null ? null : 'Hola, $_nombreUsuario',
            onLogout: () async {
              await SessionManager.clear();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (_) => false);
            },
          );

          if (!snap.hasData) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: header),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            );
          }

          final data = snap.data!;
          final items = data.items;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: header),

                if (data.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_off, size: 36),
                          const SizedBox(height: 8),
                          Text(data.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (items.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final m = items[i];
                        return _PetCard(
                          item: m,
                          onDetails: () => _openDetails(m),
                        );
                      },
                    ),
                  ),

                if (items.isEmpty && data.error == null)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No hay mascotas disponibles')),
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == _currentIndex) return;
          clearTopMessages(context);
          setState(() => _currentIndex = i);

          if (i == 1) {
            Navigator.of(context).pushNamed('/solicitudes');
          } else if (i == 2) {
            Navigator.of(context).pushNamed('/account');
          } else if (i == 0) {
            Navigator.of(context).pushNamed('/home');
          }
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

  // ---------- SHEET DETALLES ----------
  Future<void> _openDetails(_MascotaItem m) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: m.foto == null || m.foto!.isEmpty
                      ? Container(
                          color: cs.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.pets, size: 48),
                          ),
                        )
                      : Image.network(
                          m.foto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceVariant,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.nombre,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.label_important, size: 16),
                              const SizedBox(width: 6),
                              Text(m.estado),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.pets,
                      label: 'Especie',
                      value: m.especie,
                    ),
                    _DetailRow(
                      icon: Icons.cake_outlined,
                      label: 'Edad',
                      value: m.edad == null ? '-' : '${m.edad} años',
                    ),
                    _DetailRow(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Salud',
                      value: m.estadoSalud ?? '-',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sendingAdopt
                            ? null
                            : () => _adoptarMascota(
                                idMascota: m.id,
                                nombre: m.nombre,
                                afterSuccessClose: () => Navigator.pop(context),
                              ),
                        icon: _sendingAdopt
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.volunteer_activism),
                        label: Text(_sendingAdopt ? 'Enviando...' : 'Adoptar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Mensaje superior reutilizable (bonito) ---
  void _showTopMessage(BuildContext context, String msg, {bool ok = false}) {
    final cs = Theme.of(context).colorScheme;
    final bar = MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: ok ? Colors.green : Colors.blue,
      content: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.info_outline,
            color: cs.onPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

  // --- Sheet de éxito tras adoptar ---
  Future<void> _showAdoptSuccessSheet(
    BuildContext context, {
    required String nombreMascota,
  }) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 34,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Solicitud enviada!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu solicitud para adoptar a $nombreMascota fue enviada correctamente.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Seguir viendo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/solicitudes');
                      },
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text('Ver solicitudes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================== HEADER ================== */

class _HeaderHome extends StatelessWidget {
  const _HeaderHome({
    required this.title,
    required this.subtitle,
    this.greeting,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final String? greeting;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
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
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (greeting != null) ...[
              const SizedBox(height: 8),
              Text(
                greeting!,
                style: TextStyle(
                  color: Colors.white.withOpacity(.95),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ================== MODELOS ================== */

class _MascotasData {
  final List<_MascotaItem> items;
  final String? error;
  _MascotasData({this.items = const [], this.error});
}

class _MascotaItem {
  final int id;
  final String nombre;
  final String especie;
  final int? edad;
  final String? estadoSalud;
  final String? foto;
  final String estado;

  _MascotaItem({
    required this.id,
    required this.nombre,
    required this.especie,
    this.edad,
    this.estadoSalud,
    this.foto,
    required this.estado,
  });

  factory _MascotaItem.fromJson(Map<String, dynamic> j) {
    return _MascotaItem(
      id: (j['id_mascota'] as num?)?.toInt() ?? 0,
      nombre: (j['nombre'] ?? '').toString(),
      especie: (j['especie'] ?? '').toString(),
      edad: (j['edad'] as num?)?.toInt(),
      estadoSalud: j['estado_salud']?.toString(),
      foto: j['foto']?.toString(),
      estado: (j['estado'] ?? '').toString(),
    );
  }
}

/* ================== CARD ================== */

class _PetCard extends StatelessWidget {
  const _PetCard({required this.item, required this.onDetails});
  final _MascotaItem item;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen (con loader y fallback)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: cs.surfaceVariant.withOpacity(.4)),
                if (item.foto != null && item.foto!.isNotEmpty)
                  Image.network(
                    item.foto!,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, w, progress) {
                      if (progress == null) return w;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                  )
                else
                  Icon(Icons.pets, size: 48, color: cs.onSurfaceVariant),
                Positioned(top: 8, left: 8, child: _Tag(label: item.estado)),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black.withOpacity(.25),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.especie,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.edad ?? '-'} años  •  ${item.estadoSalud ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.pets, color: cs.primary.withOpacity(.9)),
              ],
            ),
          ),

          // Ver detalles
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver detalles'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
