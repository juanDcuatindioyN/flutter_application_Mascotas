import 'package:flutter/material.dart';
import '../Servicios/api_servicios.dart';
import '../Servicios/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  bool _flashShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearMaterialBanners();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowFlash();
  }

  void _maybeShowFlash() {
    if (_flashShown) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    String? msg;
    if (args is Map && args['flash'] is String) msg = args['flash'] as String;

    if (msg != null && msg!.isNotEmpty) {
      _flashShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            elevation: 0,
            backgroundColor: cs.primaryContainer,
            leading: Icon(Icons.check_circle, color: cs.onPrimaryContainer),
            content: Text(
              msg!,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ),
            ],
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(
        correo: _correoCtrl.text.trim(),
        contrasena: _passCtrl.text,
        debug: true,
      );

      final ok = data['success'] == true;
      final msg =
          (data['msg'] ?? (ok ? '¡Bienvenido!' : 'Credenciales inválidas'))
              .toString();

      if (!mounted) return;

      if (ok) {
        final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
        await SessionManager.saveUser(user);

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (_) => false,
          arguments: {'user': user, 'flash': '¡Iniciaste sesión con éxito!'},
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
      ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
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
          // Todo el contenido desplazable
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight, // para centrar vertical
                        maxWidth: 480,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // HEADER
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

                          // CARD FORM
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
                                      'Iniciar sesión',
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
                                            controller: _correoCtrl,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              labelText: 'Correo electrónico',
                                              prefixIcon: Icon(
                                                Icons.alternate_email,
                                              ),
                                            ),
                                            validator: (v) {
                                              final s = v?.trim() ?? '';
                                              if (s.isEmpty)
                                                return 'Ingresa tu correo';
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
                                                (v == null || v.isEmpty)
                                                ? 'Ingresa tu contraseña'
                                                : null,
                                            onFieldSubmitted: (_) =>
                                                _iniciarSesion(),
                                          ),
                                          const SizedBox(height: 18),
                                          SizedBox(
                                            height: 46,
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _iniciarSesion,
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
                                                  : const Text('Ingresar'),
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

                          // ENLACE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed('/register'),
                                child: const Text(
                                  '¿No tienes cuenta? Regístrate',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16), // pequeño respiro
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

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
