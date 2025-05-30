import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/events/event_list_page.dart';
import '../../presentation/pages/events/event_detail_page.dart';
import '../../presentation/pages/events/create_event_page.dart';
import '../../presentation/pages/events/event_participants_page.dart';
import '../../presentation/pages/events/event_ingredients_page.dart';
import '../../presentation/pages/events/event_expenses_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/widgets/loading_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.watch(authStateProvider.notifier);
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      print('GoRouter redirect - authState: $authState, path: $path');
      
      // Only show loading screen during initial load
      if (authState == AuthState.initial) {
        return '/loading';
      }

      // Handle authenticated state
      if (authState == AuthState.authenticated) {
        // Always redirect to dashboard if authenticated, except for protected routes
        if (path.startsWith('/login') || 
            path.startsWith('/register') || 
            path.startsWith('/splash') ||
            path == '/') {
          return '/';
        }
        // Allow access to other protected routes (events, profile, etc.)
        return null;
      }

      // Handle unauthenticated state
      if (authState == AuthState.unauthenticated) {
        // Allow access to public routes
        if (path.startsWith('/login') || 
            path.startsWith('/register')) {
          return null;
        }
        
        // Add error message if exists
        if (authStateNotifier.errorMessage != null) {
          return '/login?error=${Uri.encodeComponent(authStateNotifier.errorMessage!)}';
        }
        
        return '/login'; // Redirect to login for protected routes
      }
      
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Écran de chargement
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      
      // Pages d'authentification
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Pages principales
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
      ),
      
      // Pages d'événements
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventListPage(),
      ),
      GoRoute(
        path: '/events/create',
        builder: (context, state) => const CreateEventPage(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) {
          final eventId = int.parse(state.pathParameters['id']!);
          return EventDetailPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/edit',
        builder: (context, state) {
          final eventId = int.parse(state.pathParameters['id']!);
          // Vous devrez adapter cette partie pour récupérer l'événement
          return EventDetailPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/participants',
        builder: (context, state) {
          final eventId = int.parse(state.pathParameters['id']!);
          return EventParticipantsPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/ingredients',
        builder: (context, state) {
          final eventId = int.parse(state.pathParameters['id']!);
          return EventIngredientsPage(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/events/:id/expenses',
        builder: (context, state) {
          final eventId = int.parse(state.pathParameters['id']!);
          return EventExpensesPage(eventId: eventId);
        },
      ),
      
      // Page de profil
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.uri.path}'),
      ),
    ),
  );
});