import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  Future<Map<String, dynamic>> createExpense(int eventId, Map<String, dynamic> expenseData) async {
    print('ExpenseRepository - createExpense - Start');
    print('EventId: $eventId');
    print('ExpenseData: $expenseData');
    
    try {
      final response = await _dioClient.post(
        '/events/$eventId/expenses',
        data: expenseData,
      );
      print('ExpenseRepository - createExpense - Success Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('ExpenseRepository - createExpense - Error: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
        print('Request data: ${e.requestOptions.data}');
      }
      throw Exception('Erreur lors de la création de la dépense: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExpenses(int eventId) async {
    try {
      final response = await _dioClient.get('/events/$eventId/expenses');
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Erreur inconnue');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dépenses: $e');
    }
  }

  Future<Map<String, dynamic>> updateExpense(int eventId, int expenseId, Map<String, dynamic> expenseData) async {
    try {
      final response = await _dioClient.put(
        '/events/$eventId/expenses/$expenseId',
        data: expenseData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la modification de la dépense: $e');
    }
  }

  Future<Map<String, dynamic>> getBalances(int eventId) async {
    try {
      final response = await _dioClient.get('/events/$eventId/expenses/balances');
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Erreur inconnue');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des soldes: $e');
    }
  }
}
