class ExpenseShareModel {
  final int id;
  final int userId;
  final String userName;
  final double amount;
  final String status;
  final String statusLabel;
  final DateTime? paidAt;

  ExpenseShareModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.paidAt,
  });

  factory ExpenseShareModel.fromJson(Map<String, dynamic> json) {
    return ExpenseShareModel(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      userName: json['user_name'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      statusLabel: json['status_label'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'amount': amount,
      'status': status,
      'status_label': statusLabel,
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}
