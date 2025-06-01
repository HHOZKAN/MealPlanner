import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Router will handle navigation automatically based on auth state
    // No manual navigation needed here
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Define sizes based on screen width
    final iconContainerSize = screenWidth * 0.12; // 12% of screen width
    final iconSize = iconContainerSize * 0.5; // 50% of container size
    final textSize = screenWidth * 0.08; // 8% of screen width
    final buttonHeight = 56.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F4E9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo and App Name
              Column(
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(iconContainerSize / 2),
                    ),
                    child: Icon(
                      Icons.eco_sharp,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  Text(
                    'Meal Planner',
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15A29),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Already a member? ',
                            style: TextStyle(
                              color: Color.fromARGB(255, 88, 86, 86),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: Color(0xFFF15A29),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.06),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
