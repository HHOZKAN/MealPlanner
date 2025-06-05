import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/balance_model.dart';
import '../../data/models/reimbursement_model.dart';
import '../providers/reimbursement_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/expense_provider_new.dart';
import '../providers/paid_reimbursement_provider.dart';
import 'reimbursement_card.dart';

class BalanceDetailModal extends ConsumerWidget {
  final BalanceModel balance;
  final List<ReimbursementModel> reimbursements;
  final Function(int fromUserId, int toUserId)? onMarkAsPaid;
  final Function(int fromUserId, int toUserId)? onRequestPayment;
  final int eventId;

  const BalanceDetailModal({
    Key? key,
    required this.balance,
    required this.reimbursements,
    required this.eventId,
    this.onMarkAsPaid,
    this.onRequestPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Définition des couleurs harmonisées
    const Color primaryColor = Color(0xFFFF5722);    // Orange pour les accents
    const Color backgroundColor = Color(0xFFF9F5F0); // Beige clair pour le fond
    const Color textColor = Color(0xFF2D3142);       // Gris foncé pour le texte
    const Color cardColor = Colors.white;            // Blanc pour les cartes
    
    final isPositive = balance.balance >= 0;
    final absoluteBalance = balance.balance.abs();

    // Cas 3: Solde équilibré
    if (absoluteBalance < 0.01) {
      return _buildBalancedModal(context);
    }

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre visuelle en haut du modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Bouton de fermeture
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: textColor),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Titre et montant principal
          Text(
            isPositive ? 'On te doit' : 'Tu dois',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(absoluteBalance),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des remboursements
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: reimbursements.map((reimbursement) => _buildTransactionItem(
                  context, 
                  reimbursement, 
                  isPositive,
                  primaryColor,
                  textColor,
                  cardColor,
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancedModal(BuildContext context) {
    // Définition des couleurs harmonisées
    const Color primaryColor = Color(0xFFFF5722);    // Orange pour les accents
    const Color backgroundColor = Color(0xFFF9F5F0); // Beige clair pour le fond
    const Color textColor = Color(0xFF2D3142);       // Gris foncé pour le texte
    
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre visuelle en haut du modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Bouton de fermeture
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: textColor),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 40),
          
          const Text(
            'Le tricount est réglé',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '0,00 €',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Icône de check
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 48,
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, 
    ReimbursementModel reimbursement, 
    bool isReceiving,
    Color primaryColor,
    Color textColor,
    Color cardColor,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        // Déterminer si l'utilisateur actuel est celui qui doit payer
        final shouldShowPayButton = !isReceiving; // Si on ne reçoit pas, c'est qu'on doit payer
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Texte de la transaction
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                  children: [
                    if (isReceiving) ...[
                      TextSpan(
                        text: reimbursement.fromUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' te doit ',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ] else ...[
                      TextSpan(
                        text: reimbursement.fromUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' doit à ',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      TextSpan(
                        text: reimbursement.toUserName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Montant
              Text(
                NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(reimbursement.amount),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isReceiving ? Colors.green : Colors.red,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bouton "C'est payé" seulement si l'utilisateur doit payer
              if (shouldShowPayButton) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        print('Début du processus de remboursement');
                        print('Remboursement: De ${reimbursement.fromUserName} (${reimbursement.fromUserId}) vers ${reimbursement.toUserName} (${reimbursement.toUserId}) - ${reimbursement.amount}€');
                        
                        print('Marquage du remboursement comme payé');
                        
                        // Marquer comme payé (cela va automatiquement supprimer le remboursement et recalculer les soldes)
                        await ref.read(reimbursementProvider(eventId).notifier).markAsPaid(
                          fromUserId: reimbursement.fromUserId,
                          toUserId: reimbursement.toUserId,
                        );
                        
                        print('Remboursement marqué comme payé avec succès');
                        
                        // Rafraîchir les soldes
                        ref.read(balancesStateProvider(eventId).notifier).refresh();
                        
                        // Rafraîchir les remboursements en attente
                        ref.read(reimbursementProvider(eventId).notifier).calculateReimbursements();
                        
                        // Rafraîchir les remboursements payés
                        ref.invalidate(paidReimbursementProvider(eventId));
                        
                        // Appeler le callback pour rafraîchir les données
                        if (onMarkAsPaid != null) {
                          onMarkAsPaid!(reimbursement.fromUserId, reimbursement.toUserId);
                        }
                        
                        // Fermer le modal
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        
                        // Afficher un message de confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Remboursement de ${reimbursement.amount.toStringAsFixed(2)}€ enregistré !'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('Erreur lors du remboursement: $e');
                        // Afficher un message d'erreur
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'C\'est payé !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Message pour celui qui doit recevoir l'argent
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'En attente du remboursement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
