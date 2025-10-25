import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <- para inputFormatters
import '../Servicios/api_servicios.dart';
import '../Servicios/session_manager.dart';
import '../Servicios/ui_helpers.dart';

class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});

  @override
  State<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  // --------- estado / sesión ----------
  Map<String, dynamic>? _user;
  bool _loadingPerfil = true;
  bool _savingPerfil = false;
  bool _loadingReq = true;
  bool _savingReq = false;
  bool _savingPass = false;

  // --------- form perfil ----------
  final _perfilKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  // --------- form requisitos ----------
  final _requisitosKey = GlobalKey<FormState>();
  String? _ciudad; // <-- ahora como dropdown
  final _direccionCtrl = TextEditingController(); // <-- NUEVO
  final _ocupacionCtrl = TextEditingController();

  // enums como strings
  String? _viviendaPropiedad; // propia | alquilada | familiar
  String? _tipoVivienda; // casa | apartamento | finca | otro

  // booleans
  bool _tieneNinos = false;
  bool _tieneMascotas = false;
  bool _espacioExterior = false;

  final _tiempoLibreCtrl = TextEditingController();
  // final _ingresosCtrl = TextEditingController(); // Eliminado
  final _referenciasCtrl = TextEditingController();
  bool _aceptoTerminos = false;

  // --------- form password ----------
  final _passKey = GlobalKey<FormState>();
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();

  // flags de modal
  bool _perfilSheetAbierto = false;
  bool _reqSheetAbierto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      clearTopMessages(context);
      _cargarTodo(); // solo carga datos
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telCtrl.dispose();
    _direccionCtrl.dispose();
    _ocupacionCtrl.dispose();
    _tiempoLibreCtrl.dispose();
    _referenciasCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    super.dispose();
  }

  // --------- helpers UI ----------
  void _toastTop(String msg, {bool ok = true}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          elevation: 2,
          backgroundColor: ok ? cs.secondaryContainer : cs.errorContainer,
          content: Text(
            msg,
            style: TextStyle(
              color: ok ? cs.onSecondaryContainer : cs.onErrorContainer,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: ok ? cs.onSecondaryContainer : cs.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _cargarTodo() async {
    final u = await SessionManager.getUser();
    setState(() => _user = u);

    // Fallback inmediato con los datos en sesión (por si la API tarda)
    if (_user != null) {
      _nombreCtrl.text = (_user!['nombre'] ?? '').toString();
      _correoCtrl.text = (_user!['correo'] ?? '').toString();
      _telCtrl.text = (_user!['telefono'] ?? '').toString();
    }

    // Luego refresca desde el servidor
    await Future.wait([_cargarPerfil(), _cargarRequisitos()]);
  }

  // ============= PERFIL =============
  Future<void> _cargarPerfil() async {
    setState(() => _loadingPerfil = true);
    try {
      if (_user == null) return;
      final idU = (_user!['id_usuario'] as num).toInt();
      final resp = await ApiService.getPerfil(idUsuario: idU);
      if (resp['success'] == true && resp['data'] is Map) {
        final d = resp['data'] as Map<String, dynamic>;
        setState(() {
          _nombreCtrl.text = (d['nombre'] ?? '').toString();
          _correoCtrl.text = (d['correo'] ?? '').toString();
          _telCtrl.text = (d['telefono'] ?? '').toString();
        });
      }
    } catch (_) {
      /* noop */
    } finally {
      if (mounted) setState(() => _loadingPerfil = false);
    }
  }

  Future<void> _guardarPerfil() async {
    if (_user == null || !(_perfilKey.currentState?.validate() ?? false))
      return;
    setState(() => _savingPerfil = true);
    try {
      final idU = (_user!['id_usuario'] as num).toInt();
      final resp = await ApiService.actualizarPerfil(
        idUsuario: idU,
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        telefono: _telCtrl.text.trim(),
      );
      if (resp['success'] == true) {
        _toastTop('Perfil actualizado', ok: true);
        final newUser = Map<String, dynamic>.from(_user!);
        newUser['nombre'] = _nombreCtrl.text.trim();
        newUser['correo'] = _correoCtrl.text.trim();
        newUser['telefono'] = _telCtrl.text.trim();
        await SessionManager.saveUser(newUser);
        setState(() => _user = newUser);
      } else {
        _toastTop(
          resp['msg']?.toString() ?? 'No se pudo actualizar',
          ok: false,
        );
      }
    } catch (e) {
      _toastTop('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _savingPerfil = false);
    }
  }

  // ============= REQUISITOS =============
  Future<void> _cargarRequisitos() async {
    setState(() => _loadingReq = true);
    try {
      if (_user == null) return;
      final idU = (_user!['id_usuario'] as num).toInt();
      final resp = await ApiService.getRequisitos(idUsuario: idU);

      if (resp['success'] == true && resp['data'] is Map) {
        final d = Map<String, dynamic>.from(resp['data'] as Map);
        setState(() {
          _ciudad = (d['ciudad'] ?? '') as String?;
          _direccionCtrl.text = (d['direccion'] ?? '').toString();
          _ocupacionCtrl.text = (d['ocupacion'] ?? '').toString();
          _viviendaPropiedad = (d['vivienda_propiedad'] ?? '') as String?;
          _tipoVivienda = (d['tipo_vivienda'] ?? '') as String?;
          _tieneNinos = (d['tiene_ninos'] == 1 || d['tiene_ninos'] == true);
          _tieneMascotas =
              (d['tiene_mascotas'] == 1 || d['tiene_mascotas'] == true);
          _espacioExterior =
              (d['espacio_exterior'] == 1 || d['espacio_exterior'] == true);
          _tiempoLibreCtrl.text = (d['tiempo_libre'] ?? '').toString();
          _referenciasCtrl.text = (d['referencias'] ?? '').toString();
          _aceptoTerminos =
              (d['acepto_terminos'] == 1 || d['acepto_terminos'] == true);
        });
      }
    } catch (_) {
      /* noop */
    } finally {
      if (mounted) setState(() => _loadingReq = false);
    }
  }

  bool get _requisitosCompletos =>
      (_ciudad != null && _ciudad!.isNotEmpty) &&
      _direccionCtrl.text.trim().isNotEmpty &&
      _aceptoTerminos;

  String _requisitosEstadoTexto() {
    final faltan = <String>[];
    if (_ciudad == null || _ciudad!.isEmpty) faltan.add('ciudad');
    if (_direccionCtrl.text.trim().isEmpty) faltan.add('dirección');
    if (!_aceptoTerminos) faltan.add('términos');
    return faltan.isEmpty ? 'Completo ✓' : 'Faltan: ${faltan.join(', ')}';
  }

  Future<void> _guardarRequisitos() async {
    if (_ciudad == null || _ciudad!.isEmpty) {
      _toastTop('Selecciona tu ciudad', ok: false);
      return;
    }
    if (_direccionCtrl.text.trim().isEmpty) {
      _toastTop('Ingresa tu dirección', ok: false);
      return;
    }
    if (!_aceptoTerminos) {
      _toastTop('Debes aceptar términos y condiciones', ok: false);
      return;
    }
    if (_user == null) {
      _toastTop('Sesión no disponible', ok: false);
      return;
    }

    setState(() => _savingReq = true);
    try {
      final int idU = (_user!['id_usuario'] as num).toInt();

      final payload = {
        'ciudad': _ciudad,
        'direccion': _direccionCtrl.text.trim(),
        'ocupacion': _ocupacionCtrl.text.trim(),
        'vivienda_propiedad': _viviendaPropiedad,
        'tipo_vivienda': _tipoVivienda,
        'tiene_ninos': _tieneNinos ? 1 : 0,
        'tiene_mascotas': _tieneMascotas ? 1 : 0,
        'espacio_exterior': _espacioExterior ? 1 : 0,
        'tiempo_libre': _tiempoLibreCtrl.text.trim(),
        'referencias': _referenciasCtrl.text.trim(),
        'acepto_terminos': _aceptoTerminos ? 1 : 0,
      };

      print('PAYLOAD REQ: $payload');
      final resp = await ApiService.saveRequisitos(
        idUsuario: idU,
        data: payload,
      );

      final ok = resp['success'] == true;
      final msg =
          (resp['msg'] ??
                  resp['message'] ??
                  resp['raw'] ??
                  (ok ? 'Requisitos guardados' : 'No se pudo guardar'))
              .toString();

      _toastTop(msg, ok: ok);

      // Si usas modal para editar requisitos, ciérralo aquí:
      // if (ok) Navigator.of(context).pop();
    } catch (e) {
      _toastTop('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _savingReq = false);
    }
  }

  // ============= MODALES =============
  Future<void> _openEditarPerfil() async {
    // si aún no cargamos el perfil, lo cargamos y luego abrimos
    if (_loadingPerfil && _user != null) {
      await _cargarPerfil();
    }

    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Icon(Icons.person, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Editar perfil',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loadingPerfil)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Form(
                      key: _perfilKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu nombre'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _correoCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              final ok = RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(s);
                              return ok ? null : 'Correo inválido';
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _telCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Celular (Colombia)',
                              prefixIcon: Icon(Icons.phone_android),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return null; // opcional
                              return RegExp(r'^3\d{9}$').hasMatch(s)
                                  ? null
                                  : 'Celular inválido (ej: 3145910357)';
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _savingPerfil
                                  ? null
                                  : () async {
                                      if (!(_perfilKey.currentState
                                              ?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      await _guardarPerfil();
                                      if (ctx.mounted && !_savingPerfil) {
                                        Navigator.pop(ctx);
                                      }
                                    },
                              icon: _savingPerfil
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Guardar perfil'),
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
      },
    );
  }

  Future<void> _openRequisitos() async {
    if (_reqSheetAbierto) return;
    _reqSheetAbierto = true;
    try {
      final cs = Theme.of(context).colorScheme;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final insets = MediaQuery.of(ctx).viewInsets;

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: insets.bottom),
              child: StatefulBuilder(
                // <-- clave
                builder: (ctx, setModalState) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fact_check, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Requisitos del adoptante',
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Form(
                            key: _requisitosKey,
                            child: Column(
                              children: [
                                // Ciudad (Dropdown)
                                DropdownButtonFormField<String>(
                                  value: _ciudad,
                                  decoration: const InputDecoration(
                                    labelText: 'Ciudad',
                                    prefixIcon: Icon(
                                      Icons.location_city_outlined,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Pasto',
                                      child: Text('Pasto'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Ipiales',
                                      child: Text('Ipiales'),
                                    ),
                                  ],
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Selecciona tu ciudad'
                                      : null,
                                  onChanged: (v) => setModalState(
                                    () => _ciudad = v,
                                  ), // <-- usa setModalState
                                ),
                                const SizedBox(height: 12),

                                // Dirección
                                TextFormField(
                                  controller: _direccionCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección',
                                    prefixIcon: Icon(Icons.place_outlined),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Ingresa tu dirección'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Ocupación
                                TextFormField(
                                  controller: _ocupacionCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Ocupación',
                                    prefixIcon: Icon(Icons.work_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Vivienda propiedad
                                DropdownButtonFormField<String>(
                                  value: _viviendaPropiedad,
                                  decoration: const InputDecoration(
                                    labelText: 'Vivienda (propiedad)',
                                    prefixIcon: Icon(Icons.home_work_outlined),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'propia',
                                      child: Text('Propia'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'alquilada',
                                      child: Text('Alquilada'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'familiar',
                                      child: Text('Familiar'),
                                    ),
                                  ],
                                  onChanged: (v) => setModalState(
                                    () => _viviendaPropiedad = v,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tipo de vivienda
                                DropdownButtonFormField<String>(
                                  value: _tipoVivienda,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de vivienda',
                                    prefixIcon: Icon(Icons.house_outlined),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'casa',
                                      child: Text('Casa'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'apartamento',
                                      child: Text('Apartamento'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'finca',
                                      child: Text('Finca'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'otro',
                                      child: Text('Otro'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setModalState(() => _tipoVivienda = v),
                                ),
                                const SizedBox(height: 12),

                                // Switches con Sí/No (ahora sí cambian)
                                SwitchListTile.adaptive(
                                  value: _tieneNinos,
                                  onChanged: (v) =>
                                      setModalState(() => _tieneNinos = v),
                                  title: const Text('¿Hay niños en casa?'),
                                  secondary: const Icon(
                                    Icons.escalator_warning,
                                  ),
                                  subtitle: Text(_tieneNinos ? 'Sí' : 'No'),
                                ),
                                SwitchListTile.adaptive(
                                  value: _tieneMascotas,
                                  onChanged: (v) =>
                                      setModalState(() => _tieneMascotas = v),
                                  title: const Text('¿Ya tienes mascotas?'),
                                  secondary: const Icon(Icons.pets_outlined),
                                  subtitle: Text(_tieneMascotas ? 'Sí' : 'No'),
                                ),
                                SwitchListTile.adaptive(
                                  value: _espacioExterior,
                                  onChanged: (v) =>
                                      setModalState(() => _espacioExterior = v),
                                  title: const Text(
                                    '¿Tienes patio/espacio exterior?',
                                  ),
                                  secondary: const Icon(Icons.park_outlined),
                                  subtitle: Text(
                                    _espacioExterior ? 'Sí' : 'No',
                                  ),
                                ),
                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _tiempoLibreCtrl,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Tiempo libre (breve descripción)',
                                    prefixIcon: Icon(Icons.schedule),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                TextFormField(
                                  controller: _referenciasCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Referencias / experiencia previa',
                                    prefixIcon: Icon(Icons.notes_outlined),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                CheckboxListTile(
                                  value: _aceptoTerminos,
                                  onChanged: (v) => setModalState(
                                    () => _aceptoTerminos = v ?? false,
                                  ),
                                  title: const Text(
                                    'Acepto términos y condiciones',
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _savingReq
                                        ? null
                                        : () async {
                                            if (!(_requisitosKey.currentState
                                                    ?.validate() ??
                                                false)) {
                                              return;
                                            }
                                            await _guardarRequisitos();
                                            if (ctx.mounted && !_savingReq)
                                              Navigator.pop(ctx);
                                            if (mounted)
                                              setState(
                                                () {},
                                              ); // refresca el tile de estado
                                          },
                                    icon: _savingReq
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: const Text('Guardar requisitos'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } finally {
      _reqSheetAbierto = false;
    }
  }

  Future<void> _openCambiarPassword() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_reset,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cambiar contraseña',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _passKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passActualCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña actual',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Mínimo 6 caracteres',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passNuevaCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Mínimo 6 caracteres',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _savingPass
                                ? null
                                : () async {
                                    await _cambiarPassword();
                                    if (mounted && !_savingPass)
                                      Navigator.pop(ctx);
                                  },
                            icon: _savingPass
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Actualizar contraseña'),
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
      },
    );
  }

  Future<void> _cambiarPassword() async {
    if (_user == null || !(_passKey.currentState?.validate() ?? false)) return;
    setState(() => _savingPass = true);
    try {
      final idU = (_user!['id_usuario'] as num).toInt();
      final resp = await ApiService.cambiarPassword(
        idUsuario: idU,
        actual: _passActualCtrl.text,
        nueva: _passNuevaCtrl.text,
      );
      if (resp['success'] == true) {
        _toastTop('Contraseña actualizada', ok: true);
        _passActualCtrl.clear();
        _passNuevaCtrl.clear();
      } else {
        _toastTop(
          resp['msg']?.toString() ?? 'No se pudo actualizar',
          ok: false,
        );
      }
    } catch (e) {
      _toastTop('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await SessionManager.clear();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _HeaderUser(user: _user),
            const SizedBox(height: 16),

            // --- acceso a Editar perfil ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar perfil'),
                subtitle: Text(
                  _user?['nombre']?.toString().isNotEmpty == true
                      ? _user!['nombre'].toString()
                      : 'Actualiza tu nombre y celular',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openEditarPerfil,
              ),
            ),

            const SizedBox(height: 16),

            // --- acceso a Cambiar contraseña ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Actualiza tu contraseña de acceso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openCambiarPassword,
              ),
            ),

            const SizedBox(height: 16),

            // --- acceso a Requisitos del adoptante ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.fact_check),
                title: const Text('Requisitos del adoptante'),
                subtitle: Text(_requisitosEstadoTexto()),
                trailing: Icon(
                  _requisitosCompletos
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color: _requisitosCompletos ? cs.primary : cs.error,
                ),
                onTap: _openRequisitos,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),

      // ========= NAV BOTTOM =========
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2, // Estamos en Cuenta
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, '/solicitudes');
          } else {
            // i == 2 -> ya estamos en Cuenta: no hacer nada
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
}

// ===== widgets pequeños =====
class _HeaderUser extends StatelessWidget {
  const _HeaderUser({required this.user});
  final Map<String, dynamic>? user;

  @override
  Widget build(BuildContext context) {
    final name = user?['nombre']?.toString() ?? 'Usuario';
    final email = user?['correo']?.toString() ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.person, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
