import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';
import '../providers/auth_provider.dart';

/// Provider pour le repository des dépenses
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ExpenseRepository(dioClient);
});

/// États possibles pour la gestion des dépenses
enum ExpensesState { loading, loaded, error }

/// Provider pour l'état des dépenses d'un événement spécifique
final expensesStateProvider = StateNotifierProvider.family<ExpensesNotifier, ExpensesState, int>((ref, eventId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repository, eventId);
});

/// Notifier pour gérer l'état des dépenses d'un événement
class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _repository;
  final int _eventId;
  List<ExpenseModel> _expenses = [];
  String _errorMessage = '';

  ExpensesNotifier(this._repository, this._eventId) : super(ExpensesState.loading) {
    loadExpenses();
  }

  /// Liste des dépenses chargées
  List<ExpenseModel> get expenses => _expenses;
  
  /// Message d'erreur en cas d'échec
  String get errorMessage => _errorMessage;

  /// Charge les dépenses depuis le repository
  Future<void> loadExpenses() async {
    try {
      state = ExpensesState.loading;
      final expensesData = await _repository.getExpenses(_eventId);
      _expenses = expensesData.map((data) {
        try {
          return ExpenseModel.fromJson(data);
        } catch (e) {
          // Log l'erreur pour le debugging mais ne pas exposer les détails
          _errorMessage = 'Erreur lors du parsing des données de dépense';
          rethrow;
        }
      }).toList();
      state = ExpensesState.loaded;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des dépenses: ${e.toString()}';
      state = ExpensesState.error;
    }
  }

  /// Ajoute une nouvelle dépense à la liste
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    try {
      final newExpense = await _repository.createExpense(_eventId, expenseData);
      _expenses.insert(0, ExpenseModel.fromJson(newExpense));
      state = ExpensesState.loaded;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de la dépense: ${e.toString()}';
      state = ExpensesState.error;
    }
  }

  /// Met à jour une dépense existante
  Future<void> updateExpense(int expenseId, Map<String, dynamic> expenseData) async {
    try {
      final updatedExpense = await _repository.updateExpense(_eventId, expenseId, expenseData);
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = ExpenseModel.fromJson(updatedExpense);
      }
      state = ExpensesState.loaded;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la dépense: ${e.toString()}';
      state = ExpensesState.error;
    }
  }
}

/// Provider pour créer une dépense avec rechargement automatique
final createExpenseProvider = Provider.family<Future<Map<String, dynamic>> Function(Map<String, dynamic>), int>((ref, eventId) {
  final repository = ref.watch(expenseRepositoryProvider);
  final notifier = ref.watch(expensesStateProvider(eventId).notifier);
  
  return (Map<String, dynamic> expenseData) async {
    try {
      final result = await repository.createExpense(eventId, expenseData);
      // Recharger les dépenses après l'ajout pour maintenir la cohérence
      await notifier.loadExpenses();
      return result;
    } catch (e) {
      rethrow;
    }
  };
});
