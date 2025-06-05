import '../../core/network/dio_client.dart';

class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  Future<Map<String, dynamic>> createExpense(int eventId, Map<String, dynamic> expenseData) async {
    try {
      final response = await _dioClient.post(
        '/events/$eventId/expenses',
        data: expenseData,
      );
      return response.data;
    } catch (e) {
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
