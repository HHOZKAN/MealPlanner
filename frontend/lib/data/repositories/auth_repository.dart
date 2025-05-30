import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  
  AuthRepository(this._dioClient);
  
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone_number': phoneNumber,
        },
      );
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);
        
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        return user;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de l\'inscription');
      }
      throw Exception('Erreur lors de l\'inscription');
    }
  }
  
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    print('Tentative de connexion avec email: $email');
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      print('Réponse reçue: ${response.data}');
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        try {
          final token = data['data']['token'];
          final user = UserModel.fromJson(data['data']['user']);
          
          print('Connexion réussie, token: $token');
          print('Utilisateur: ${user.toString()}');
          
          // Sauvegarder le token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          
          return user;
        } catch (e) {
          print('Erreur lors de la désérialisation des données: $e');
          throw Exception('Erreur lors de la connexion: format de données incorrect');
        }
      } else {
        print('Erreur dans la réponse: ${data['message']}');
        throw Exception(data['message'] ?? 'Erreur lors de la connexion');
      }
    } catch (e) {
      print('Exception lors de la connexion: $e');
      if (e is DioException) {
        print('DioException: ${e.response?.data}');
        final data = e.response?.data;
        if (e.response?.statusCode == 401) {
          throw Exception('Identifiants incorrects');
        }
        throw Exception(data?['message'] ?? 'Erreur lors de la connexion');
      }
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    try {
      await _dioClient.post(ApiConstants.logout);
      
      // Supprimer le token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      // Même en cas d'erreur, on supprime le token local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la déconnexion');
      }
      throw Exception('Erreur lors de la déconnexion');
    }
  }
  
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération du profil');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la récupération du profil');
      }
      throw Exception('Erreur lors de la récupération du profil');
    }
  }
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }
}
