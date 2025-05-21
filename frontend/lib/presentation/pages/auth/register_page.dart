import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' show pi, sin, cos;
import '../../../presentation/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authStateProvider.notifier).register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              passwordConfirmation: _confirmPasswordController.text,
              phoneNumber: _phoneController.text.trim(),
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

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!(hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters)) {
      return 'Le mot de passe doit contenir des majuscules, minuscules, chiffres et symboles';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: color, // <-- couleur du texte tapé
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: color.withOpacity(1),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Définition de la palette de couleurs personnalisable
    final backgroundColor =
        const Color(0xFFF0F7FF); // Couleur de fond de la page
    final primaryColor = const Color(
        0xFFF15A29); // Couleur principale (utilisée pour les icônes et textes)
    final accentColor =
        const Color(0xFFF15A29); // Couleur d'accent (utilisée pour le dégradé)
    final tertiaryColor =
        const Color(0xFFFF6B6B); // Couleur pour les messages d'erreur
    final quaternaryColor =
        const Color(0xFFF15A29); // Couleur pour le bouton principal

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      // Couleur de fond de la page
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor.withOpacity(0.1),
        elevation: 0, // Pas d'ombre
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: primaryColor), // Couleur de l'icône de retour
          onPressed: () => context.go('/login'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            children: [
              // Arrière-plan dégradé
              Positioned(
                top: 0,
                right: 0,
                child: _WavyShape(
                  color:
                      primaryColor.withOpacity(0.1), // Couleur de l'ondulation
                  size: width * 1, // Taille de l'ondulation
                ),
              ),
              // Forme de bulle en bas
              Positioned(
                bottom: 0,
                left: 0,
                child: _BubbleShape(
                  color: accentColor.withOpacity(0.1), // Couleur de la bulle
                  size: width * 0.6, // Taille de la bulle
                ),
              ),
              SingleChildScrollView(
                padding:
                    const EdgeInsets.all(24.0), // Espacement autour du contenu
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        // Ajoutez ce widget
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [primaryColor, accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Rejoignez Meal Planner',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_errorMessage != null || authState == AuthState.error)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tertiaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tertiaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage ??
                                ref
                                    .read(authStateProvider.notifier)
                                    .errorMessage ??
                                'Une erreur est survenue',
                            style: TextStyle(color: tertiaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom complet',
                        icon: Icons.person_outline,
                        color: primaryColor,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        color: primaryColor,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Téléphone (optionnel)',
                        icon: Icons.phone_outlined,
                        color: primaryColor,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        icon: Icons.lock_outline,
                        color: primaryColor,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '8 caractères minimum avec majuscules, minuscules, chiffres et symboles',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline,
                        color: primaryColor,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: quaternaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 255, 255, 255)),
                                ),
                              )
                            : const Text(
                                'Créer mon compte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Déjà membre ? ',
                            style:
                                TextStyle(color: primaryColor.withOpacity(0.8)),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'Se connecter',
                              style: TextStyle(
                                color: quaternaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WavyShape extends StatefulWidget {
  final Color color;
  final double size;

  const _WavyShape({
    required this.color,
    required this.size,
  });

  @override
  State<_WavyShape> createState() => _WavyShapeState();
}

class _WavyShapeState extends State<_WavyShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WavyShapePainter(
            color: widget.color,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class _WavyShapePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _WavyShapePainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.8);

    for (var i = 0; i <= 5; i++) {
      final x = size.width - (size.width * (i / 5));
      final waveHeight = sin(animationValue + i) * 10;
      path.lineTo(x, size.height * 0.6 + waveHeight);
    }

    path.lineTo(0, size.height * 0.4);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyShapePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _BubbleShape extends StatefulWidget {
  final Color color;
  final double size;

  const _BubbleShape({
    required this.color,
    required this.size,
  });

  @override
  State<_BubbleShape> createState() => _BubbleShapeState();
}

class _BubbleShapeState extends State<_BubbleShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BubbleShapePainter(
            color: widget.color,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}

class _BubbleShapePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _BubbleShapePainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Dessiner la forme principale
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);

    // Créer une courbe ondulée avec des bulles
    final curveHeight = size.height * 0.6;
    path.quadraticBezierTo(
      size.width * 0.7,
      curveHeight + (sin(animationValue * pi) * 20),
      size.width * 0.3,
      curveHeight - (cos(animationValue * pi) * 20),
    );

    path.close();
    canvas.drawPath(path, paint);

    // Ajouter des bulles décoratives
    final bubblePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Dessiner plusieurs bulles avec animation
    for (var i = 0; i < 5; i++) {
      final xOffset = size.width * (0.2 + (i * 0.15));
      final yOffset = size.height * (0.3 + (i * 0.1));
      final radius = 10 + (sin(animationValue * pi + i) * 5);

      canvas.drawCircle(
        Offset(
          xOffset + (cos(animationValue * pi + i) * 10),
          yOffset + (sin(animationValue * pi + i) * 10),
        ),
        radius,
        bubblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleShapePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
