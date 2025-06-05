import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/reimbursement_model.dart';
import '../providers/paid_reimbursement_provider.dart';

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
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isPending = reimbursement.status == 'pending';
    final isFromCurrentUser = reimbursement.fromUserId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Remboursement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  currencyFormat.format(reimbursement.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFromCurrentUser 
                ? 'Tu dois rembourser ${reimbursement.toUserName}'
                : '${reimbursement.fromUserName} te doit de l\'argent',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (isPending && isFromCurrentUser && onMarkAsPaid != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Rafraîchir les remboursements payés
                    ref.invalidate(paidReimbursementProvider(eventId));
                    // Appeler le callback
                    onMarkAsPaid?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
            ],
            if (!isPending) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reimbursement.paidAt != null 
                    ? 'Payé le ${DateFormat('dd/MM/yyyy').format(reimbursement.paidAt!)}'
                    : 'Remboursement effectué',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
