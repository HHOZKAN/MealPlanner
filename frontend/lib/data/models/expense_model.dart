import 'expense_share_model.dart';

class ExpenseModel {
  final int id;
  final int eventId;
  final int? ingredientId;
  final String? ingredientName;
  final int payerId;
  final String payerName;
  final double amount;
  final String? description;
  final String? category;
  final String categoryLabel;
  final String? receiptImage;
  final List<ExpenseShareModel> shares;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.eventId,
    this.ingredientId,
    this.ingredientName,
    required this.payerId,
    required this.payerName,
    required this.amount,
    this.description,
    this.category,
    required this.categoryLabel,
    this.receiptImage,
    required this.shares,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseModel(
        id: int.parse(json['id'].toString()),
        eventId: int.parse(json['event_id'].toString()),
        ingredientId: json['ingredient_id'] != null ? int.parse(json['ingredient_id'].toString()) : null,
        ingredientName: json['ingredient_name'],
        payerId: int.parse(json['payer_id'].toString()),
        payerName: json['payer_name'] ?? 'Inconnu',
        amount: double.parse(json['amount'].toString()),
        description: json['description'],
        category: json['category'],
        categoryLabel: json['category_label'] ?? 'N/A',
        receiptImage: json['receipt_image'],
        shares: (json['shares'] as List<dynamic>)
            .map((shareJson) => ExpenseShareModel.fromJson(shareJson))
            .toList(),
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
    } catch (e) {
      print('Erreur parsing ExpenseModel: $e');
      print('JSON reçu: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'payer_id': payerId,
      'payer_name': payerName,
      'amount': amount,
      'description': description,
      'category': category,
      'category_label': categoryLabel,
      'receipt_image': receiptImage,
      'shares': shares.map((share) => share.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthode utilitaire pour obtenir les shares sous forme de Map (pour compatibilité)
  Map<String, double> get sharesAsMap {
    return Map.fromEntries(
      shares.map((share) => MapEntry(share.userId.toString(), share.amount))
    );
  }

  // Méthode pour obtenir le nom de l'ingrédient ou catégorie
  String get displayName {
    if (category == 'remboursement') return 'Remboursement';
    return ingredientName ?? 'Dépense générale';
  }
}
