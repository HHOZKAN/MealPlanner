import 'dart:convert';
import 'user_model.dart';

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
  });
  
  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'],
      eventId: json['event_id'],
      name: json['name'],
      quantity: json['quantity'].toDouble(),
      unit: json['unit'],
      estimatedPrice: json['estimated_price']?.toDouble(),
      actualPrice: json['actual_price']?.toDouble(),
      status: json['status'],
      notes: json['notes'],
      addedBy: json['added_by'],
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
      id: json['id'],
      ingredientId: json['ingredient_id'],
      userId: json['user_id'],
      quantity: json['quantity'].toDouble(),
      status: json['status'],
      pricePaid: json['price_paid']?.toDouble(),
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