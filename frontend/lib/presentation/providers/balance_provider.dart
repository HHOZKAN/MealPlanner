import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/balance_model.dart';
import '../../core/network/dio_client.dart';
import 'auth_provider.dart';
import 'expense_provider_new.dart';
import 'reimbursement_provider.dart';

enum BalancesState { loading, loaded, error }

class BalancesNotifier extends StateNotifier<BalancesState> {
  final ExpenseRepository _expenseRepository;
  final int eventId;
  
  BalancesResponse? _balancesResponse;
  String? _errorMessage;

  BalancesNotifier(this._expenseRepository, this.eventId) : super(BalancesState.loading);

  BalancesResponse? get balancesResponse => _balancesResponse;
  String? get errorMessage => _errorMessage;

  Future<void> loadBalances() async {
    state = BalancesState.loading;
    try {
      final response = await _expenseRepository.getBalances(eventId);
      _balancesResponse = BalancesResponse.fromJson(response);
      _errorMessage = null;
      state = BalancesState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = BalancesState.error;
    }
  }

  void refresh() {
    loadBalances();
  }
}

final balancesStateProvider = StateNotifierProvider.family<BalancesNotifier, BalancesState, int>(
  (ref, eventId) {
    final dioClient = ref.read(dioClientProvider);
    final expenseRepository = ExpenseRepository(dioClient);
    final notifier = BalancesNotifier(expenseRepository, eventId);
    
    // Écouter les changements dans les dépenses
    ref.listen(expensesStateProvider(eventId), (previous, next) {
      if (next == ExpensesState.loaded) {
        // Rafraîchir les soldes quand les dépenses sont modifiées
        notifier.loadBalances();
      }
    });
    
    // Écouter les changements dans les remboursements
    ref.listen(reimbursementProvider(eventId), (previous, next) {
      // Rafraîchir les soldes quand les remboursements changent
      notifier.loadBalances();
    });
    
    notifier.loadBalances();
    return notifier;
  },
);
