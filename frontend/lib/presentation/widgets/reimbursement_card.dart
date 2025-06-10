import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reimbursement_model.dart';
import '../providers/paid_reimbursement_provider.dart';
import './common/reimbursement_widgets.dart';

class ReimbursementCard extends ConsumerWidget {
  final ReimbursementModel reimbursement;
  final int currentUserId;
  final VoidCallback? onMarkAsPaid;
  final int eventId;

  const ReimbursementCard({
    Key? key,
    required this.reimbursement,
    required this.currentUserId,
    required this.eventId,
    this.onMarkAsPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = reimbursement.status == 'pending';
    final isFromCurrentUser = reimbursement.fromUserId == currentUserId;

    return BaseReimbursementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec montant
          ReimbursementCardHeader(amount: reimbursement.amount),
          
          const SizedBox(height: 8),
          
          // Description du remboursement
          ReimbursementDescription(
            description: ReimbursementDescriptionHelper.getPendingDescription(
              isFromCurrentUser: isFromCurrentUser,
              fromUserName: reimbursement.fromUserName,
              toUserName: reimbursement.toUserName,
            ),
          ),

          // Bouton "C'est payé" pour les remboursements en attente
          if (isPending && isFromCurrentUser && onMarkAsPaid != null) ...[
            const SizedBox(height: 16),
            MarkAsPaidButton(
              onPressed: () {
                // Rafraîchir les remboursements payés
                ref.invalidate(paidReimbursementProvider(eventId));
                // Appeler le callback
                onMarkAsPaid?.call();
              },
            ),
          ],

          // Badge de statut pour les remboursements payés
          if (!isPending) ...[
            const SizedBox(height: 8),
            ReimbursementStatusBadge(
              status: reimbursement.status,
              paidAt: reimbursement.paidAt,
            ),
          ],
        ],
      ),
    );
  }
}
