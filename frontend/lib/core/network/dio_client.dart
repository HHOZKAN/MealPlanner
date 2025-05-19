import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class DioClient {
  late Dio _dio;
  
  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  Future<void> _setupInterceptors() async {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'authentification si disponible
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Gérer l'expiration du token
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            // Rediriger vers la page de connexion
            // Vous devrez implémenter cette logique
          }
          return handler.next(e);
        },
      ),
    );
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
Future<Response> post(String path, {dynamic data}) async {
  print('POST request to: ${ApiConstants.baseUrl}$path');
  print('Data: $data');
  try {
    final response = await _dio.post(path, data: data);
    print('Response status: ${response.statusCode}');
    print('Response data: ${response.data}');
    return response;
  } catch (e) {
    print('Error in POST request: $e');
    rethrow;
  }
}
  
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}