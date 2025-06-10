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
    String? eventId,
    String? token,
  }) async {
    try {
      final dataToSend = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone_number': phoneNumber,
      };
      if (eventId != null) {
        dataToSend['event_id'] = eventId;
      }
      if (token != null) {
        dataToSend['token'] = token;
      }
      final response = await _dioClient.post(
        ApiConstants.register,
        data: dataToSend,
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
        throw Exception(data['message'] ?? 'Error during registration');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Error during registration');
      }
      throw Exception('Error during registration');
    }
  }
  
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    print('Login attempt with email: $email');
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      print('Response received: ${response.data}');
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        try {
          final token = data['data']['token'];
          final user = UserModel.fromJson(data['data']['user']);
          
          print('Login successful, token: $token');
          print('User: ${user.toString()}');
          
          // Sauvegarder le token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          
          return user;
        } catch (e) {
          print('Error deserializing data: $e');
          throw Exception('Login error: incorrect data format');
        }
      } else {
        print('Error in response: ${data['message']}');
        throw Exception(data['message'] ?? 'Error during login');
      }
    } catch (e) {
      print('Exception during login: $e');
      if (e is DioException) {
        print('DioException: ${e.response?.data}');
        final data = e.response?.data;
        if (e.response?.statusCode == 401) {
          throw Exception('Invalid credentials');
        }
        throw Exception(data?['message'] ?? 'Error during login');
      }
      throw Exception('Error during login: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    try {
      await _dioClient.post(ApiConstants.logout);
      
      // Remove the token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      // Even in case of error, remove the local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Error during logout');
      }
      throw Exception('Error during logout');
    }
  }
  
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiConstants.me);
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Error retrieving profile');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Error retrieving profile');
      }
      throw Exception('Error retrieving profile');
    }
  }
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }
}
