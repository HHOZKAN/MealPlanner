import 'reimbursement_model.dart';

class BalanceModel {
  final int userId;
  final String userName;
  final double balance;

  BalanceModel({
    required this.userId,
    required this.userName,
    required this.balance,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'balance': balance,
    };
  }
}

class BalancesResponse {
  final List<BalanceModel> balances;
  final List<ReimbursementModel> reimbursements;
  final double totalExpenses;

  BalancesResponse({
    required this.balances,
    required this.reimbursements,
    required this.totalExpenses,
  });

  factory BalancesResponse.fromJson(Map<String, dynamic> json) {
    return BalancesResponse(
      balances: (json['balances'] as List)
          .map((balance) => BalanceModel.fromJson(balance))
          .toList(),
      reimbursements: (json['reimbursements'] as List)
          .map((reimbursement) => ReimbursementModel.fromJson(reimbursement))
          .toList(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balances': balances.map((balance) => balance.toJson()).toList(),
      'reimbursements': reimbursements.map((reimbursement) => reimbursement.toJson()).toList(),
      'total_expenses': totalExpenses,
    };
  }
}
