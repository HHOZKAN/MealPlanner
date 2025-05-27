import 'dart:convert';
import 'user_model.dart';

// Helper functions to safely parse numbers from various formats
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
  }
  return null;
}

int _parseRequiredInt(dynamic value, {int defaultValue = 0}) {
  return _parseInt(value) ?? defaultValue;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    // Remove any currency symbols or spaces
    final cleanString = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleanString);
  }
  return null;
}

double _parseRequiredDouble(dynamic value, {double defaultValue = 0.0}) {
  return _parseDouble(value) ?? defaultValue;
}

class IngredientModel {
  final int id;
  final int eventId;
  final String name;
  final double quantity;
  final String unit;
  final double? estimatedPrice;
  final double? actualPrice;
  final String status;
  final String? notes;
  final int addedBy;
  final UserModel? addedByUser;
  final List<IngredientAssignmentModel>? assignments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? emoji;
  
  IngredientModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.actualPrice,
    required this.status,
    this.notes,
    required this.addedBy,
    this.addedByUser,
    this.assignments,
    this.createdAt,
    this.updatedAt,
    this.emoji,
  });
  
  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: _parseRequiredInt(json['id']),
      eventId: _parseRequiredInt(json['event_id']), // Default to 0 if missing
      name: json['name'] ?? '',
      quantity: _parseRequiredDouble(json['quantity']),
      unit: json['unit'] ?? '',
      estimatedPrice: _parseDouble(json['estimated_price']),
      actualPrice: _parseDouble(json['actual_price']),
      status: json['status'] ?? 'needed',
      notes: json['notes'],
      addedBy: _parseRequiredInt(json['added_by']),
      addedByUser: json['added_by_user'] != null 
          ? UserModel.fromJson(json['added_by_user']) 
          : null,
      assignments: json['assignments'] != null 
          ? List<IngredientAssignmentModel>.from(
              json['assignments'].map((x) => IngredientAssignmentModel.fromJson(x))
            )
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      emoji: json['emoji'] ?? '🛒',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'actual_price': actualPrice,
      'status': status,
      'notes': notes,
      'added_by': addedBy,
      'added_by_user': addedByUser?.toJson(),
      'assignments': assignments?.map((x) => x.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'emoji': emoji,
    };
  }
  
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class IngredientAssignmentModel {
  final int id;
  final int ingredientId;
  final int userId;
  final double quantity;
  final String status;
  final double? pricePaid;
  final String? storeName;
  final String? receiptImage;
  final UserModel? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  IngredientAssignmentModel({
    required this.id,
    required this.ingredientId,
    required this.userId,
    required this.quantity,
    required this.status,
    this.pricePaid,
    this.storeName,
    this.receiptImage,
    this.user,
    this.createdAt,
    this.updatedAt,
  });
  
  factory IngredientAssignmentModel.fromJson(Map<String, dynamic> json) {
    return IngredientAssignmentModel(
      id: _parseRequiredInt(json['id']),
      ingredientId: _parseRequiredInt(json['ingredient_id']),
      userId: _parseRequiredInt(json['user_id']),
      quantity: _parseRequiredDouble(json['quantity']),
      status: json['status'] ?? 'pending',
      pricePaid: _parseDouble(json['price_paid']),
      storeName: json['store_name'],
      receiptImage: json['receipt_image'],
      user: json['user'] != null 
          ? UserModel.fromJson(json['user']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient_id': ingredientId,
      'user_id': userId,
      'quantity': quantity,
      'status': status,
      'price_paid': pricePaid,
      'store_name': storeName,
      'receipt_image': receiptImage,
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
