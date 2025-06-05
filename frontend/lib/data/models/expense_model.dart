class ExpenseModel {
  final int id;
  final int eventId;
  final int? ingredientId;
  final int payerId;
  final String payerName;
  final double amount;
  final Map<String, double> shares;
  final DateTime createdAt;
  final String ingredientName;

  ExpenseModel({
    required this.id,
    required this.eventId,
    this.ingredientId,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.shares,
    required this.createdAt,
    required this.ingredientName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExpenseModel(
        id: int.parse(json['id'].toString()),
        eventId: int.parse(json['event_id'].toString()),
        ingredientId: json['ingredient_id'] != null ? int.parse(json['ingredient_id'].toString()) : null,
        payerId: int.parse(json['payer_id'].toString()),
        payerName: json['payer_name'] ?? 'Inconnu',
        amount: double.parse(json['amount'].toString()),
        shares: Map<String, double>.from(json['shares'].map(
          (key, value) => MapEntry(key.toString(), double.parse(value.toString())),
        )),
        createdAt: DateTime.parse(json['created_at']),
        ingredientName: json['category'] == 'remboursement' ? 'Remboursement' : (json['ingredient_name'] ?? 'Ingrédient inconnu'),
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
      'payer_id': payerId,
      'payer_name': payerName,
      'amount': amount,
      'shares': shares,
      'created_at': createdAt.toIso8601String(),
      'ingredient_name': ingredientName,
    };
  }
}
