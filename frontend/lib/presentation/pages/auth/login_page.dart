import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' show pi, sin, cos;
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
          color: color,
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
    final creamColor = const Color(0xFFF9F4E9);
    final orangeColor = const Color(0xFFF15A29);
    final blueColor = const Color(0xFF8AC6D1);
    final pinkColor = const Color(0xFFF7B2B7);
    final greenColor = const Color(0xFF6B6B3F);
    final mustardColor = const Color(0xFFCFA14A);

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: creamColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0), // Hauteur minimale
        child: AppBar(
          backgroundColor: creamColor,
          elevation: 0,
          toolbarHeight: 0, // Hauteur minimale
          automaticallyImplyLeading: false,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              // Top right shape
              Positioned(
                top: 0, // Changé de -width * 0.1 à 0
                right: 0, // Changé de -width * 0.1 à 0
                child: _CornerShape(
                  color: orangeColor,
                  size: width * 0.4,
                  cornerPosition: CornerPosition.topRight,
                ),
              ),
              // Bottom right shape
              Positioned(
                bottom: -width * 0.1,
                right: -width * 0.1,
                child: _CornerShape(
                  color: orangeColor.withOpacity(0.8),
                  size: width * 0.45,
                  cornerPosition: CornerPosition.bottomRight,
                ),
              ),
              // Top left shape
              Positioned(
                top: -10,
                left: 0,
                child: _CornerShape(
                  color: blueColor,
                  size: width * 0.35,
                  cornerPosition: CornerPosition.topLeft,
                ),
              ),
              // Bottom left shape
              Positioned(
                bottom: -width * 0.1,
                left: -width * 0.1,
                child: _CornerShape(
                  color: pinkColor,
                  size: width * 0.4,
                  cornerPosition: CornerPosition.bottomLeft,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title "Meal Planner" with multi-color letters
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                            children: [
                              TextSpan(
                                  text: 'M',
                                  style: TextStyle(color: blueColor)),
                              TextSpan(
                                  text: 'e',
                                  style: TextStyle(color: orangeColor)),
                              TextSpan(
                                  text: 'a',
                                  style: TextStyle(color: mustardColor)),
                              TextSpan(
                                  text: 'l',
                                  style: TextStyle(color: greenColor)),
                              const TextSpan(text: '\n'),
                              TextSpan(
                                  text: 'P',
                                  style: TextStyle(color: orangeColor)),
                              TextSpan(
                                  text: 'l',
                                  style: TextStyle(color: blueColor)),
                              TextSpan(
                                  text: 'a',
                                  style: TextStyle(color: pinkColor)),
                              TextSpan(
                                  text: 'n',
                                  style: TextStyle(color: greenColor)),
                              TextSpan(
                                  text: 'n',
                                  style: TextStyle(color: mustardColor)),
                              TextSpan(
                                  text: 'e',
                                  style: TextStyle(color: orangeColor)),
                              TextSpan(
                                  text: 'r',
                                  style: TextStyle(color: blueColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Error message
                        if (_errorMessage != null ||
                            authState == AuthState.error)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage ??
                                  ref
                                      .read(authStateProvider.notifier)
                                      .errorMessage ??
                                  'Une erreur est survenue',
                              style: TextStyle(color: Colors.red.shade800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_errorMessage != null ||
                            authState == AuthState.error)
                          const SizedBox(height: 16),

                        // Email TextField
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          color: orangeColor,
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
                        const SizedBox(height: 24),

                        // Password TextField
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: Icons.lock,
                          color: orangeColor,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 36),

                        // Login button
                        OutlinedButton(
                          onPressed: _isLoading ? null : _login,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: orangeColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 100),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Se connecter',
                                  style: TextStyle(
                                      color: orangeColor, fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Sign up text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Pas encore de compte ? ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  color: orangeColor,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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

enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _CornerShape extends StatefulWidget {
  final Color color;
  final double size;
  final CornerPosition cornerPosition;

  const _CornerShape({
    Key? key,
    required this.color,
    required this.size,
    required this.cornerPosition,
  }) : super(key: key);

  @override
  State<_CornerShape> createState() => _CornerShapeState();
}

class _CornerShapeState extends State<_CornerShape>
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
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CornerShapePainter(
              color: widget.color,
              cornerPosition: widget.cornerPosition,
              animationValue: _animation.value,
            ),
          ),
        );
      },
    );
  }
}

class _CornerShapePainter extends CustomPainter {
  final Color color;
  final CornerPosition cornerPosition;
  final double animationValue;

  _CornerShapePainter({
    required this.color,
    required this.cornerPosition,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Facteur d'ondulation basé sur l'animation
    final waveFactor = sin(animationValue * pi) * size.width * 0.05;

    switch (cornerPosition) {
      case CornerPosition.topLeft:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.quadraticBezierTo(
          size.width * 0.3 + waveFactor,
          size.height * 0.3 + waveFactor,
          0,
          size.height,
        );
        path.close();
        break;

      case CornerPosition.topRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.quadraticBezierTo(
          size.width * 0.7 - waveFactor,
          size.height * 0.3 + waveFactor,
          0,
          0,
        );
        path.close();
        break;

      case CornerPosition.bottomLeft:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.quadraticBezierTo(
          size.width * 0.3 + waveFactor,
          size.height * 0.7 - waveFactor,
          0,
          0,
        );
        path.close();
        break;

      case CornerPosition.bottomRight:
        path.moveTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.quadraticBezierTo(
          size.width * 0.7 - waveFactor,
          size.height * 0.7 - waveFactor,
          size.width,
          0,
        );
        path.close();
        break;
    }

    // Créer un dégradé
    final gradient = LinearGradient(
      begin: _getGradientBegin(),
      end: _getGradientEnd(),
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    canvas.drawPath(path, paint);

    // Ajouter des points décoratifs animés
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final xPos =
          size.width * (0.3 + (i * 0.15)) + (sin(animationValue * pi + i) * 5);
      final yPos =
          size.height * (0.3 + (i * 0.15)) + (cos(animationValue * pi + i) * 5);

      if (_isPointInShape(path, Offset(xPos, yPos))) {
        canvas.drawCircle(
          Offset(xPos, yPos),
          3 + sin(animationValue * pi + i) * 1,
          dotPaint,
        );
      }
    }
  }

  Alignment _getGradientBegin() {
    switch (cornerPosition) {
      case CornerPosition.topLeft:
        return Alignment.bottomRight;
      case CornerPosition.topRight:
        return Alignment.bottomLeft;
      case CornerPosition.bottomLeft:
        return Alignment.topRight;
      case CornerPosition.bottomRight:
        return Alignment.topLeft;
    }
  }

  Alignment _getGradientEnd() {
    switch (cornerPosition) {
      case CornerPosition.topLeft:
        return Alignment.topLeft;
      case CornerPosition.topRight:
        return Alignment.topRight;
      case CornerPosition.bottomLeft:
        return Alignment.bottomLeft;
      case CornerPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  bool _isPointInShape(Path path, Offset point) {
    return path.contains(point);
  }

  @override
  bool shouldRepaint(covariant _CornerShapePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
