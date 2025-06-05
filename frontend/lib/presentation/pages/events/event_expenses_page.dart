import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/expense_provider_new.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/reimbursement_provider.dart';
import '../../../presentation/providers/paid_reimbursement_provider.dart';
import '../../widgets/edit_expense_modal.dart';
import '../../widgets/reimbursement_card.dart';
import '../../widgets/paid_reimbursement_card.dart';

class EventExpensesPage extends ConsumerWidget {
  final int eventId;

  const EventExpensesPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(expensesStateProvider(eventId));
    final notifier = ref.watch(expensesStateProvider(eventId).notifier);
    final currentUser = ref.watch(currentUserProvider);
    
    switch (expensesState) {
      case ExpensesState.loading:
        return const Center(child: CircularProgressIndicator());
      
      case ExpensesState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Erreur lors du chargement des dépenses',
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadExpenses(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      
      case ExpensesState.loaded:
            final expenses = notifier.expenses;
            
            if (expenses.isEmpty) {
              return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucune dépense pour le moment',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculer les totaux
        final myExpenses = expenses
            .where((expense) => expense.payerId == currentUser?.id)
            .fold(0.0, (sum, expense) => sum + expense.amount);
        
        final totalExpenses = expenses
            .fold(0.0, (sum, expense) => sum + expense.amount);

            // Observer les remboursements
            final reimbursementsState = ref.watch(reimbursementProvider(eventId));

            return Column(
          children: [
            // Expenses Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExpenseCard(
                    'Mes dépenses',
                    myExpenses,
                    const Color(0xFFFF5722),
                  ),
                  _buildExpenseCard(
                    'Dépenses totales',
                    totalExpenses,
                    const Color(0xFF2D3142),
                  ),
                ],
              ),
            ),
            
            // Expenses and Reimbursements List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await notifier.loadExpenses();
                  ref.read(reimbursementProvider(eventId).notifier).calculateReimbursements();
                  ref.invalidate(paidReimbursementProvider(eventId));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: Column(
                    children: [
                      // Afficher les remboursements en attente
                      reimbursementsState.when(
                        data: (reimbursements) {
                          if (reimbursements.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Remboursements en attente',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ),
                                ...reimbursements.map((reimbursement) => 
                                  ReimbursementCard(
                                    reimbursement: reimbursement,
                                    currentUserId: currentUser?.id ?? -1,
                                    eventId: eventId,
                                    onMarkAsPaid: () {
                                      ref.read(reimbursementProvider(eventId).notifier).markAsPaid(
                                        fromUserId: reimbursement.fromUserId,
                                        toUserId: reimbursement.toUserId,
                                      );
                                    },
                                  )
                                ).toList(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),

                      // Afficher les remboursements payés
                      ref.watch(paidReimbursementProvider(eventId)).when(
                        data: (paidReimbursements) {
                          if (paidReimbursements.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Remboursements effectués',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ),
                                ...paidReimbursements.map((reimbursement) => 
                                  PaidReimbursementCard(
                                    reimbursement: reimbursement,
                                    currentUserId: currentUser?.id ?? -1,
                                  )
                                ).toList(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                      
                      // Afficher les dépenses
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Dépenses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      ...expenses.map((expense) {
                        final isMyExpense = expense.payerId == currentUser?.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => EditExpenseModal(
                                  eventId: eventId,
                                  expense: expense,
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isMyExpense 
                                    ? const Color(0xFFFF5722) 
                                    : const Color(0xFF2D3142),
                                child: const Icon(
                                  Icons.receipt,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                expense.ingredientName ?? 'Dépense',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payé par ${isMyExpense ? 'vous' : expense.payerName ?? 'Inconnu'}',
                                    style: TextStyle(
                                      color: const Color(0xFF2D3142).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberFormat.currency(locale: 'fr_FR', symbol: '€')
                                        .format(expense.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (expense.shares.containsKey(currentUser?.id.toString())) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Votre part: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(expense.shares[currentUser!.id.toString()] ?? 0)}',
                                      style: TextStyle(
                                        color: const Color(0xFF2D3142).withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExpenseCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
