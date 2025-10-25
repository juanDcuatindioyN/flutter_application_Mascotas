import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Servicios/api_servicios.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validarCelCo(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa tu número de celular';
    final reg = RegExp(r'^3\d{9}$'); // 10 dígitos, inicia en 3 (Colombia)
    if (!reg.hasMatch(s)) return 'Celular inválido (ej: 3145910357)';
    return null;
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final resp = await ApiService.registro(
        _nombreCtrl.text.trim(),
        _correoCtrl.text.trim(),
        _telCtrl.text.trim(),
        _passCtrl.text,
      );

      final ok = resp['success'] == true;
      final msg =
          (resp['msg'] ?? (ok ? '¡Registro exitoso!' : 'No se pudo registrar'))
              .toString();

      if (!mounted) return;

      if (ok) {
        // Volver a login mostrando banner de éxito
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
          arguments: {'flash': '¡Cuenta creada con éxito! Inicia sesión.'},
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fallo de red: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Contenido desplazable y centrado
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: 480,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header degradado (no se superpone nada)
                          Container(
                            height: 140,
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
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.pets,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'AdoptaAmigo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Card con formulario
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  22,
                                  16,
                                  22,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Crear cuenta',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _nombreCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Nombre',
                                              prefixIcon: Icon(
                                                Icons.person_outline,
                                              ),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                ? 'Ingresa tu nombre'
                                                : null,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _correoCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Correo electrónico',
                                              prefixIcon: Icon(
                                                Icons.alternate_email,
                                              ),
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (v) {
                                              final s = v?.trim() ?? '';
                                              if (s.isEmpty) {
                                                return 'Ingresa tu correo';
                                              }
                                              final ok = RegExp(
                                                r'^[^@]+@[^@]+\.[^@]+$',
                                              ).hasMatch(s);
                                              return ok
                                                  ? null
                                                  : 'Correo inválido';
                                            },
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _telCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Celular (Colombia)',
                                              hintText: 'Ej: 3145910357',
                                              prefixIcon: Icon(
                                                Icons.phone_android,
                                              ),
                                              counterText: '',
                                            ),
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                            ],
                                            validator: _validarCelCo,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _passCtrl,
                                            obscureText: _obscure,
                                            decoration: InputDecoration(
                                              labelText: 'Contraseña',
                                              prefixIcon: const Icon(
                                                Icons.lock_outline,
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                  () => _obscure = !_obscure,
                                                ),
                                                icon: Icon(
                                                  _obscure
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                ),
                                              ),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.length < 6)
                                                ? 'Mínimo 6 caracteres'
                                                : null,
                                            onFieldSubmitted: (_) =>
                                                _registrar(),
                                          ),
                                          const SizedBox(height: 18),
                                          SizedBox(
                                            height: 46,
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _registrar,
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 22,
                                                      width: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Text('Registrarme'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Enlace a login
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login'),
                                child: const Text(
                                  '¿Ya tienes cuenta? Inicia sesión',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer decorativo (fuera del scroll)
          const _BottomDecor(),
        ],
      ),
    );
  }
}

class _BottomDecor extends StatelessWidget {
  const _BottomDecor();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.secondaryContainer.withOpacity(.35), cs.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Wrap(
          spacing: 14,
          children: List.generate(
            8,
            (i) =>
                Icon(Icons.pets, size: 20, color: cs.primary.withOpacity(.25)),
          ),
        ),
      ),
    );
  }
}
