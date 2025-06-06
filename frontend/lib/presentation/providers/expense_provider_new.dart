import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';
import '../providers/auth_provider.dart';

// Provider pour le repository des dépenses
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ExpenseRepository(dioClient);
});

// État des dépenses
enum ExpensesState { loading, loaded, error }

// Provider pour l'état des dépenses
final expensesStateProvider = StateNotifierProvider.family<ExpensesNotifier, ExpensesState, int>((ref, eventId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repository, eventId);
});

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _repository;
  final int _eventId;
  List<ExpenseModel> _expenses = [];
  String _errorMessage = '';

  ExpensesNotifier(this._repository, this._eventId) : super(ExpensesState.loading) {
    loadExpenses();
  }

  List<ExpenseModel> get expenses => _expenses;
  String get errorMessage => _errorMessage;

  Future<void> loadExpenses() async {
    try {
      state = ExpensesState.loading;
      final expensesData = await _repository.getExpenses(_eventId);
      _expenses = expensesData.map((data) {
        try {
          return ExpenseModel.fromJson(data);
        } catch (e) {
          print('Erreur parsing expense: $e');
          print('Data: $data');
          rethrow;
        }
      }).toList();
      state = ExpensesState.loaded;
    } catch (e) {
      print('Erreur loadExpenses: $e');
      _errorMessage = e.toString();
      state = ExpensesState.error;
    }
  }

  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    try {
      final newExpense = await _repository.createExpense(_eventId, expenseData);
      _expenses.insert(0, ExpenseModel.fromJson(newExpense));
      state = ExpensesState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = ExpensesState.error;
    }
  }

  Future<void> updateExpense(int expenseId, Map<String, dynamic> expenseData) async {
    try {
      final updatedExpense = await _repository.updateExpense(_eventId, expenseId, expenseData);
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = ExpenseModel.fromJson(updatedExpense);
      }
      state = ExpensesState.loaded;
    } catch (e) {
      print('Erreur updateExpense: $e');
      _errorMessage = e.toString();
      state = ExpensesState.error;
    }
  }
}

// Provider pour créer une dépense
final createExpenseProvider = Provider.family<Future<Map<String, dynamic>> Function(Map<String, dynamic>), int>((ref, eventId) {
  final repository = ref.watch(expenseRepositoryProvider);
  final notifier = ref.watch(expensesStateProvider(eventId).notifier);
  
  return (Map<String, dynamic> expenseData) async {
    print('ExpenseProvider - createExpense - Start');
    print('EventId: $eventId');
    print('ExpenseData: $expenseData');
    
    try {
      final result = await repository.createExpense(eventId, expenseData);
      print('ExpenseProvider - createExpense - Success, reloading expenses');
      await notifier.loadExpenses(); // Recharger les dépenses après l'ajout
      print('ExpenseProvider - createExpense - Expenses reloaded');
      return result;
    } catch (e) {
      print('ExpenseProvider - createExpense - Error: $e');
      rethrow;
    }
  };
});
