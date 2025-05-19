import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_planner/core/constants/api_constants.dart';
import '../../../presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authStateProvider.notifier).login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Si l'authentification est réussie, l'utilisateur sera redirigé par le GoRouter

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo ou image
                // État d'authentification (pour le débogage)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade200,
                  child: Text(
                    'État d\'authentification: $authState',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 32),

                // Titre
                const Text(
                  'Bienvenue !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Message d'erreur
                if (_errorMessage != null || authState == AuthState.error)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage ??
                          ref.read(authStateProvider.notifier).errorMessage ??
                          'Une erreur est survenue',
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_errorMessage != null || authState == AuthState.error)
                  const SizedBox(height: 16),

                // Champ email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Bouton de connexion
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),

                // Lien vers la page d'inscription
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Pas encore de compte ? S\'inscrire'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      final dio = Dio();
                      final response = await dio.post(
                        '${ApiConstants.baseUrl}/auth/login',
                        data: {
                          'email': _emailController.text.trim(),
                          'password': _passwordController.text,
                        },
                      );
                      print('Test direct - Réponse: ${response.data}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Test réussi: ${response.data}')),
                      );
                    } catch (e) {
                      print('Test direct - Erreur: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Test échoué: $e')),
                      );
                    }
                  },
                  child: const Text('Test direct API'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
