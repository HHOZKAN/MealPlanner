import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'event_provider.dart';

// Provider for Dio client
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// Provider for authentication repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient);
});

// Possible authentication states
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// Authentication state
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
          print('Error retrieving user: $e');
          _errorMessage = "Session expired, please login again";
          _user = null;
          await _clearToken();
          state = AuthState.unauthenticated;
        }
      } else {
        _user = null;
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      print('Error checking authentication status: $e');
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
      // acceptInvitation call is handled on the backend during registration with token
      if (token != null && token.isNotEmpty) {
        // Refresh events list after registration with token
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
      print('Error during login: $e');
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
      print('Error during logout: $e');
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

// Provider for authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository, ref);
});

// Provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return authNotifier.user;
});
