import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pantallas/registro.dart';
import '../Servicios/api_servicios.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginUser() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      // Guardar token o datos de usuario
      // await _saveUserData(response);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión exitoso'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a pantalla principal
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de recuperación de contraseña'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
                Colors.white,
              ],
              stops: [0.0, 0.5, 0.5],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.pets,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AdoptaMascota',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Encuentra a tu compañero ideal',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bienvenido de vuelta',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo electrónico';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Por favor ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                  activeColor: Colors.blue,
                                ),
                                const Text(
                                  'Recordarme',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),

                            TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'o',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        OutlinedButton(
                          onPressed: _navigateToRegister,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.blue),
                          ),
                          child: const Text(
                            'Crear Cuenta Nueva',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}