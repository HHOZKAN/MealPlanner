import 'package:flutter/foundation.dart';

class ReimbursementModel {
  final int? id;
  final int? eventId;
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final double amount;
  final String status;
  final String? paymentProof;
  final DateTime? paidAt;
  final String? notes;

  ReimbursementModel({
    this.id,
      this.eventId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.status,
    this.paymentProof,
    this.paidAt,
    this.notes,
  });

  factory ReimbursementModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementModel(
      id: json['id'],
      eventId: json['event_id'] ?? 0,
      fromUserId: json['from_user']?['id'] ?? json['from_user_id'],
      fromUserName: json['from_user']?['name'] ?? json['from_user_name'] ?? 'Inconnu',
      toUserId: json['to_user']?['id'] ?? json['to_user_id'],
      toUserName: json['to_user']?['name'] ?? json['to_user_name'] ?? 'Inconnu',
      amount: _parseAmount(json['amount']),
      status: json['status'] ?? 'pending',
      paymentProof: json['payment_proof'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      notes: json['notes'],
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      // Try to parse string as number, but handle time formats
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      // If it looks like a time format (e.g., "5:00"), return 0 or throw error
      if (value.contains(':')) {
        throw FormatException('Invalid amount format: $value (appears to be time format)');
      }
      throw FormatException('Cannot parse amount: $value');
    }
    throw FormatException('Invalid amount type: ${value.runtimeType}');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'status': status,
      'payment_proof': paymentProof,
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
