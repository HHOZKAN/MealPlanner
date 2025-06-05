import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/reimbursement_model.dart';

class PaidReimbursementCard extends StatelessWidget {
  final ReimbursementModel reimbursement;
  final int currentUserId;

  const PaidReimbursementCard({
    Key? key,
    required this.reimbursement,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFromCurrentUser = reimbursement.fromUserId == currentUserId;
    final isToCurrentUser = reimbursement.toUserId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Remboursement',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFromCurrentUser) ...[
              Text(
                'Vous avez remboursé ${reimbursement.toUserName}',
                style: TextStyle(
                  color: const Color(0xFF2D3142).withOpacity(0.7),
                ),
              ),
            ] else if (isToCurrentUser) ...[
              Text(
                '${reimbursement.fromUserName} vous a remboursé',
                style: TextStyle(
                  color: const Color(0xFF2D3142).withOpacity(0.7),
                ),
              ),
            ] else ...[
              Text(
                '${reimbursement.fromUserName} a remboursé ${reimbursement.toUserName}',
                style: TextStyle(
                  color: const Color(0xFF2D3142).withOpacity(0.7),
                ),
              ),
            ],
            if (reimbursement.paidAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Payé le ${DateFormat('dd/MM/yyyy à HH:mm').format(reimbursement.paidAt!)}',
                style: TextStyle(
                  color: const Color(0xFF2D3142).withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(locale: 'fr_FR', symbol: '€')
                  .format(reimbursement.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Payé',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
