import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/ingredient_model.dart';

class IngredientRepository {
  final DioClient _dioClient;
  
  IngredientRepository(this._dioClient);
  
  Future<List<IngredientModel>> getIngredients(int eventId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString()),
      );
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return List<IngredientModel>.from(
          data['data'].map((x) => IngredientModel.fromJson(x))
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération des ingrédients');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la récupération des ingrédients');
      }
      throw Exception('Erreur lors de la récupération des ingrédients');
    }
  }
  
  Future<IngredientModel> getIngredient(int eventId, int ingredientId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString())}/$ingredientId',
      );
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return IngredientModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération de l\'ingrédient');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la récupération de l\'ingrédient');
      }
      throw Exception('Erreur lors de la récupération de l\'ingrédient');
    }
  }
  
  Future<IngredientModel> createIngredient({
    required int eventId,
    required String name,
    required double quantity,
    required String unit,
    double? estimatedPrice,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString()),
        data: {
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'estimated_price': estimatedPrice,
          'notes': notes,
        },
      );
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return IngredientModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la création de l\'ingrédient');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la création de l\'ingrédient');
      }
      throw Exception('Erreur lors de la création de l\'ingrédient');
    }
  }
  
  Future<IngredientModel> updateIngredient({
    required int eventId,
    required int ingredientId,
    String? name,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    double? actualPrice,
    String? status,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      
      if (name != null) data['name'] = name;
      if (quantity != null) data['quantity'] = quantity;
      if (unit != null) data['unit'] = unit;
      if (estimatedPrice != null) data['estimated_price'] = estimatedPrice;
      if (actualPrice != null) data['actual_price'] = actualPrice;
      if (status != null) data['status'] = status;
      if (notes != null) data['notes'] = notes;
      
      final response = await _dioClient.put(
        '${ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString())}/$ingredientId',
        data: data,
      );
      
      final responseData = response.data;
      
      if (responseData['status'] == 'success') {
        return IngredientModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Erreur lors de la mise à jour de l\'ingrédient');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la mise à jour de l\'ingrédient');
      }
      throw Exception('Erreur lors de la mise à jour de l\'ingrédient');
    }
  }
  
  Future<void> deleteIngredient(int eventId, int ingredientId) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString())}/$ingredientId',
      );
      
      final data = response.data;
      
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Erreur lors de la suppression de l\'ingrédient');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la suppression de l\'ingrédient');
      }
      throw Exception('Erreur lors de la suppression de l\'ingrédient');
    }
  }
  
  Future<IngredientAssignmentModel> assignIngredient({
    required int eventId,
    required int ingredientId,
    required int userId,
    required double quantity,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString())}/$ingredientId/assign',
        data: {
          'user_id': userId,
          'quantity': quantity,
        },
      );
      
      final data = response.data;
      
      if (data['status'] == 'success') {
        return IngredientAssignmentModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'assignation de l\'ingrédient');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de l\'assignation de l\'ingrédient');
      }
      throw Exception('Erreur lors de l\'assignation de l\'ingrédient');
    }
  }
  
  Future<IngredientAssignmentModel> updateAssignment({
    required int eventId,
    required int ingredientId,
    required int assignmentId,
    required String status,
    double? pricePaid,
    String? storeName,
    String? receiptImage,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
      };
      
      if (pricePaid != null) data['price_paid'] = pricePaid;
      if (storeName != null) data['store_name'] = storeName;
      if (receiptImage != null) data['receipt_image'] = receiptImage;
      
      final response = await _dioClient.put(
        '${ApiConstants.eventIngredients.replaceAll('{id}', eventId.toString())}/$ingredientId/assignments/$assignmentId',
        data: data,
      );
      
      final responseData = response.data;
      
      if (responseData['status'] == 'success') {
        return IngredientAssignmentModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Erreur lors de la mise à jour de l\'assignation');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ?? 'Erreur lors de la mise à jour de l\'assignation');
      }
      throw Exception('Erreur lors de la mise à jour de l\'assignation');
    }
  }
}