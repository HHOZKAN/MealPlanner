import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reimbursement_model.dart';

/// Widget de base pour les cartes de remboursement
class BaseReimbursementCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const BaseReimbursementCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );
  }
}

/// Widget pour l'en-tête d'une carte de remboursement
class ReimbursementCardHeader extends StatelessWidget {
  final double amount;
  final IconData icon;
  final String title;
  final Color? iconColor;

  const ReimbursementCardHeader({
    Key? key,
    required this.amount,
    this.icon = Icons.payment,
    this.title = 'Remboursement',
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? AppTheme.textColor.withOpacity(0.6),
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeM,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const Spacer(),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: AppTheme.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }
}

/// Widget pour la description d'un remboursement
class ReimbursementDescription extends StatelessWidget {
  final String description;

  const ReimbursementDescription({
    Key? key,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(
        color: AppTheme.textColor.withOpacity(0.6),
        fontSize: AppTheme.fontSizeS,
      ),
    );
  }
}

/// Widget pour le badge de statut d'un remboursement
class ReimbursementStatusBadge extends StatelessWidget {
  final String status;
  final DateTime? paidAt;

  const ReimbursementStatusBadge({
    Key? key,
    required this.status,
    this.paidAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    final color = isPaid ? AppTheme.successColor : AppTheme.primaryColor;
    final text = isPaid 
        ? (paidAt != null 
            ? 'Payé le ${DateFormat('dd/MM/yyyy').format(paidAt!)}'
            : 'Remboursement effectué')
        : 'En attente';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontSizeS - 2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Widget pour le bouton "C'est payé"
class MarkAsPaidButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const MarkAsPaidButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'C\'est payé !',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Widget pour l'avatar de statut payé
class PaidStatusAvatar extends StatelessWidget {
  const PaidStatusAvatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppTheme.successColor,
      radius: 20,
      child: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Widget pour les informations de montant avec badge
class AmountWithBadge extends StatelessWidget {
  final double amount;
  final String badgeText;
  final Color badgeColor;

  const AmountWithBadge({
    Key? key,
    required this.amount,
    required this.badgeText,
    required this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: badgeColor,
            fontSize: AppTheme.fontSizeM,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXS,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Utilitaire pour générer les descriptions de remboursement
class ReimbursementDescriptionHelper {
  /// Génère la description pour un remboursement en attente
  static String getPendingDescription({
    required bool isFromCurrentUser,
    required String fromUserName,
    required String toUserName,
  }) {
    if (isFromCurrentUser) {
      return 'Tu dois rembourser $toUserName';
    } else {
      return '$fromUserName te doit de l\'argent';
    }
  }

  /// Génère la description pour un remboursement payé
  static String getPaidDescription({
    required bool isFromCurrentUser,
    required bool isToCurrentUser,
    required String fromUserName,
    required String toUserName,
  }) {
    if (isFromCurrentUser) {
      return 'Vous avez remboursé $toUserName';
    } else if (isToCurrentUser) {
      return '$fromUserName vous a remboursé';
    } else {
      return '$fromUserName a remboursé $toUserName';
    }
  }

  /// Génère la description avec date de paiement
  static String getPaidDateDescription(DateTime paidAt) {
    return 'Payé le ${DateFormat('dd/MM/yyyy à HH:mm').format(paidAt)}';
  }
}
