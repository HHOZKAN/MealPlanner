import 'package:flutter/material.dart';
import '../../data/models/reimbursement_model.dart';
import './common/reimbursement_widgets.dart';
import '../../core/theme/app_theme.dart';

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

    return BaseReimbursementCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const PaidStatusAvatar(),
        title: const Text(
          'Remboursement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
            fontSize: AppTheme.fontSizeM,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description principale
            ReimbursementDescription(
              description: ReimbursementDescriptionHelper.getPaidDescription(
                isFromCurrentUser: isFromCurrentUser,
                isToCurrentUser: isToCurrentUser,
                fromUserName: reimbursement.fromUserName,
                toUserName: reimbursement.toUserName,
              ),
            ),
            
            // Date de paiement si disponible
            if (reimbursement.paidAt != null) ...[
              const SizedBox(height: 2),
              Text(
                ReimbursementDescriptionHelper.getPaidDateDescription(
                  reimbursement.paidAt!,
                ),
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.5),
                  fontSize: AppTheme.fontSizeS - 2,
                ),
              ),
            ],
          ],
        ),
        trailing: AmountWithBadge(
          amount: reimbursement.amount,
          badgeText: 'Payé',
          badgeColor: AppTheme.successColor,
        ),
      ),
    );
  }
}
