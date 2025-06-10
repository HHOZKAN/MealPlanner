import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

/// Repository pour la gestion des dépenses
class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  /// Crée une nouvelle dépense pour un événement
  Future<Map<String, dynamic>> createExpense(int eventId, Map<String, dynamic> expenseData) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.eventExpenses.replaceAll('{id}', eventId.toString()),
        data: expenseData,
      );
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Erreur réseau';
        
        switch (statusCode) {
          case 400:
            throw Exception('Données invalides: $errorMessage');
          case 401:
            throw Exception('Non autorisé');
          case 403:
            throw Exception('Accès refusé');
          case 404:
            throw Exception('Événement non trouvé');
          case 422:
            throw Exception('Erreur de validation: $errorMessage');
          default:
            throw Exception('Erreur serveur: $errorMessage');
        }
      }
      throw Exception('Erreur lors de la création de la dépense: $e');
    }
  }

  /// Récupère toutes les dépenses d'un événement
  Future<List<Map<String, dynamic>>> getExpenses(int eventId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.eventExpenses.replaceAll('{id}', eventId.toString())
      );
      
      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      
      throw Exception(response.data['message'] ?? 'Format de réponse invalide');
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Erreur réseau';
        
        switch (statusCode) {
          case 401:
            throw Exception('Non autorisé');
          case 403:
            throw Exception('Accès refusé');
          case 404:
            throw Exception('Événement non trouvé');
          default:
            throw Exception('Erreur serveur: $errorMessage');
        }
      }
      throw Exception('Erreur lors de la récupération des dépenses: $e');
    }
  }

  /// Met à jour une dépense existante
  Future<Map<String, dynamic>> updateExpense(int eventId, int expenseId, Map<String, dynamic> expenseData) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.eventExpenses.replaceAll('{id}', eventId.toString())}/$expenseId',
        data: expenseData,
      );
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Erreur réseau';
        
        switch (statusCode) {
          case 400:
            throw Exception('Données invalides: $errorMessage');
          case 401:
            throw Exception('Non autorisé');
          case 403:
            throw Exception('Accès refusé');
          case 404:
            throw Exception('Dépense non trouvée');
          case 422:
            throw Exception('Erreur de validation: $errorMessage');
          default:
            throw Exception('Erreur serveur: $errorMessage');
        }
      }
      throw Exception('Erreur lors de la modification de la dépense: $e');
    }
  }

  /// Récupère les soldes des participants pour un événement
  Future<Map<String, dynamic>> getBalances(int eventId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.eventExpenses.replaceAll('{id}', eventId.toString())}/balances'
      );
      
      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      
      throw Exception(response.data['message'] ?? 'Format de réponse invalide');
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Erreur réseau';
        
        switch (statusCode) {
          case 401:
            throw Exception('Non autorisé');
          case 403:
            throw Exception('Accès refusé');
          case 404:
            throw Exception('Événement non trouvé');
          default:
            throw Exception('Erreur serveur: $errorMessage');
        }
      }
      throw Exception('Erreur lors de la récupération des soldes: $e');
    }
  }
}
