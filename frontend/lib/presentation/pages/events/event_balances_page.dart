import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/balance_provider.dart';
import '../../../presentation/providers/reimbursement_provider.dart';
import '../../../data/models/balance_model.dart';
import '../../widgets/balance_detail_modal.dart';

class EventBalancesPage extends ConsumerWidget {
  final int eventId;

  const EventBalancesPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Définition des couleurs harmonisées
    const Color primaryColor = Color(0xFFFF5722);    // Orange pour les accents
    const Color backgroundColor = Color(0xFFF9F5F0); // Beige clair pour le fond
    const Color textColor = Color(0xFF2D3142);       // Gris foncé pour le texte
    const Color cardColor = Colors.white;            // Blanc pour les cartes
    
    final balancesState = ref.watch(balancesStateProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);
    final balancesNotifier = ref.read(balancesStateProvider(eventId).notifier);
    
    // Écouter les changements dans les dépenses pour rafraîchir les soldes
    ref.listen(balancesStateProvider(eventId), (previous, next) {
      // Cette écoute permet de déclencher un rebuild quand les soldes changent
    });
    
    return Container(
      color: backgroundColor,
      child: switch (balancesState) {
        BalancesState.loading => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        
        BalancesState.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Erreur lors du chargement des soldes',
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => balancesNotifier.refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        
        BalancesState.loaded => _buildLoadedContent(
          context,
          balancesNotifier.balancesResponse,
          currentUser,
          primaryColor,
          backgroundColor,
          textColor,
          cardColor,
          balancesNotifier,
          ref,
        ),
        
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    dynamic balancesResponse,
    dynamic currentUser,
    Color primaryColor,
    Color backgroundColor,
    Color textColor,
    Color cardColor,
    dynamic balancesNotifier,
    WidgetRef ref,
  ) {
    if (balancesResponse == null) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      );
    }

    if (balancesResponse.balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune dépense enregistrée',
              style: TextStyle(
                fontSize: 18,
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des dépenses pour voir les soldes',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Trouver le solde de l'utilisateur courant
    final userBalance = currentUser != null 
        ? balancesResponse.balances.firstWhere(
            (b) => b.userId == currentUser.id,
            orElse: () => BalanceModel(userId: -1, userName: '', balance: 0),
          )
        : null;

    return Column(
      children: [
        // Carte du solde pour l'utilisateur courant
        if (userBalance != null && userBalance.userId != -1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => BalanceDetailModal(
                    balance: userBalance,
                    reimbursements: balancesResponse.reimbursements,
                    eventId: eventId,
                    onMarkAsPaid: (fromUserId, toUserId) {
                      // Rafraîchir les soldes après marquage
                      balancesNotifier.refresh();
                    },
                    onRequestPayment: (fromUserId, toUserId) {
                      // TODO: Implémenter la logique de demande de paiement
                      print('Demande de paiement: de $fromUserId à $toUserId');
                    },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: _buildBalanceCard(context, userBalance, cardColor, textColor),
            ),
          ),

        // En-tête des remboursements
        if (balancesResponse.reimbursements.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Remboursements à effectuer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calculate),
                  color: primaryColor,
                  onPressed: () {
                    ref.read(reimbursementProvider(eventId).notifier).calculateReimbursements();
                  },
                  tooltip: 'Calculer les remboursements',
                ),
              ],
            ),
          ),

          // Liste des remboursements
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: balancesResponse.reimbursements.length,
              itemBuilder: (context, index) {
                final reimbursement = balancesResponse.reimbursements[index];
                final isFromCurrentUser = currentUser?.id == reimbursement.fromUserId;
                final isToCurrentUser = currentUser?.id == reimbursement.toUserId;

                // Couleurs pour les transactions
                final Color iconColor = isFromCurrentUser
                    ? Colors.red
                    : (isToCurrentUser ? Colors.green : primaryColor);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: cardColor,
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: iconColor,
                      child: Icon(
                        isFromCurrentUser
                            ? Icons.arrow_upward
                            : (isToCurrentUser ? Icons.arrow_downward : Icons.swap_horiz),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      isFromCurrentUser
                          ? 'Tu dois payer'
                          : (isToCurrentUser
                              ? 'Tu vas recevoir'
                              : '${reimbursement.fromUserName} doit payer'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      isFromCurrentUser
                          ? 'à ${reimbursement.toUserName}'
                          : (isToCurrentUser
                              ? 'de ${reimbursement.fromUserName}'
                              : 'à ${reimbursement.toUserName}'),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    trailing: Text(
                      '${reimbursement.amount.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else if (balancesResponse.balances.isNotEmpty) ...[
          // Message quand il n'y a pas de transactions nécessaires
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tout est équilibré !',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun remboursement nécessaire',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, 
    BalanceModel balance, 
    Color cardColor, 
    Color textColor,
  ) {
    final isPositive = balance.balance >= 0;
    final Color balanceColor = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.euro_symbol : Icons.money_off,
                color: balanceColor,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive ? 'On te doit' : 'Tu dois',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.balance.abs().toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: balanceColor,
            ),
          ),
        ],
      ),
    );
  }
}
