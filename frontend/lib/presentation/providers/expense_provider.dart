import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expense_repository.dart';
import '../providers/auth_provider.dart';

// Provider pour le repository des dépenses
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ExpenseRepository(dioClient);
});

// Provider pour créer une dépense
final expenseProvider = Provider.family<Future<Map<String, dynamic>> Function(Map<String, dynamic>), int>((ref, eventId) {
  final repository = ref.watch(expenseRepositoryProvider);
  
  return (Map<String, dynamic> expenseData) async {
    return repository.createExpense(eventId, expenseData);
  };
});
