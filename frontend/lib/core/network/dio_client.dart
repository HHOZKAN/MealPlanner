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
      // Add these options for web platform
      validateStatus: (status) => true, // Accept all status codes
      followRedirects: false,
    ));
    
    // Initialize interceptors immediately
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
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
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }
          return handler.next(e);
        },
      ),
    );
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    print('GET request to: ${ApiConstants.baseUrl}$path');
    print('Query parameters: $queryParameters');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Auth token present: ${token != null}');
      
      final response = await _dio.get(path, queryParameters: queryParameters);
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      return response;
    } catch (e) {
      print('Error in GET request: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Response: ${e.response}');
        print('  Request URL: ${e.requestOptions.uri}');
        print('  Headers: ${e.requestOptions.headers}');
      }
      rethrow;
    }
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