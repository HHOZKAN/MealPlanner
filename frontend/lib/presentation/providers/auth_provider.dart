import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'event_provider.dart';

// Provider pour le client Dio
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

// États possibles de l'authentification
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// État de l'authentification
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;
  UserModel? _user;
  String? _errorMessage;

  AuthStateNotifier(this._authRepository, this._ref) : super(AuthState.initial) {
    checkAuthStatus();
  }

  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    try {
      state = AuthState.loading;
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        try {
          _user = await _authRepository.getCurrentUser();
          state = AuthState.authenticated;
        } catch (e) {
          print('Erreur lors de la récupération de l\'utilisateur: $e');
          _errorMessage = "Session expirée, veuillez vous reconnecter";
          _user = null;
          await _clearToken();
          state = AuthState.unauthenticated;
        }
      } else {
        _user = null;
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut d\'authentification: $e');
      _errorMessage = e.toString();
      _user = null;
      state = AuthState.unauthenticated;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phoneNumber,
    String? eventId,
    String? token,
  }) async {
    try {
      state = AuthState.loading;
      _user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phoneNumber: phoneNumber,
        eventId: eventId,
        token: token,
      );
      // L'appel à acceptInvitation est géré côté backend lors de l'inscription avec token
      if (token != null && token.isNotEmpty) {
        // Rafraîchir la liste des événements après inscription avec token
        final eventsNotifier = _ref.read(eventsStateProvider.notifier);
        await eventsNotifier.loadEvents();
      }
      state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _user = null;
      state = AuthState.unauthenticated;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = AuthState.loading;
      _user = await _authRepository.login(
        email: email,
        password: password,
      );
      _errorMessage = null; // Clear any previous error
      state = AuthState.authenticated;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      _errorMessage = e.toString();
      _user = null;
      state = AuthState.unauthenticated;
    }
  }

  Future<void> logout() async {
    try {
      state = AuthState.loading;
      await _authRepository.logout();
      _user = null;
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      _errorMessage = e.toString();
    } finally {
      await _clearToken();
      state = AuthState.unauthenticated;
    }
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

// Provider pour l'état d'authentification
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository, ref);
});

// Provider pour l'utilisateur courant
final currentUserProvider = Provider<UserModel?>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return authNotifier.user;
});
