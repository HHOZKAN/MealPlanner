import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/auth/login_page.dart';
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
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      print('GoRouter redirect - authState: $authState, path: $path');
      
      // Si l'état d'authentification est en cours de chargement, rediriger vers l'écran de chargement
      if (authState == AuthState.loading || authState == AuthState.initial) {
        return '/loading';
      }
      
      // Si l'utilisateur n'est pas authentifié et qu'il essaie d'accéder à une page protégée
      if (authState == AuthState.unauthenticated && 
          !path.startsWith('/login') && 
          !path.startsWith('/register') &&
          !path.startsWith('/loading')) {
        print('Redirection vers /login');
        
        // Si une erreur d'authentification s'est produite, ajouter un paramètre d'erreur
        if (authStateNotifier.errorMessage != null) {
          return '/login?error=${Uri.encodeComponent(authStateNotifier.errorMessage!)}';
        }
        
        return '/login';
      }
      
      // Si l'utilisateur est authentifié et qu'il essaie d'accéder à la page de connexion ou d'inscription
      if (authState == AuthState.authenticated && 
          (path.startsWith('/login') || path.startsWith('/register'))) {
        print('Redirection vers /');
        return '/';
      }
      
      return null;
    },
    routes: [
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