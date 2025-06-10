import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/event_model.dart';

/// Widget pour l'en-tête d'un événement avec emoji et titre
class EventHeader extends StatelessWidget {
  final EventModel event;

  const EventHeader({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Column(
        children: [
          Text(
            event.emoji ?? '🏖️',
            style: const TextStyle(fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeL,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget pour le contrôle segmenté personnalisé
class CustomSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<String> segments;
  final Function(int) onSegmentChanged;

  const CustomSegmentedControl({
    Key? key,
    required this.selectedIndex,
    required this.segments,
    required this.onSegmentChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: segments.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            return _SegmentButton(
              index: index,
              label: label,
              isSelected: selectedIndex == index,
              onTap: () => onSegmentChanged(index),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Widget pour un bouton de segment individuel
class _SegmentButton extends StatelessWidget {
  final int index;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    Key? key,
    required this.index,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          margin: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textColor,
                fontWeight: FontWeight.w500,
                fontSize: AppTheme.fontSizeS,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour le bouton d'action flottant personnalisé
class EventActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;

  const EventActionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.add,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingM,
      ),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              text,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour les dialogues de confirmation
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.confirmColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(color: AppTheme.textColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.6),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmColor ?? AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher un lien partageable
class ShareLinkDialog extends StatelessWidget {
  final String shareableLink;

  const ShareLinkDialog({
    Key? key,
    required this.shareableLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: const Text(
        'Lien d\'invitation partageable',
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SelectableText(
        shareableLink,
        style: const TextStyle(color: AppTheme.textColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Fermer',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}

/// Widget pour le menu d'options d'événement
class EventOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventOptionsBottomSheet({
    Key? key,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.edit,
              color: AppTheme.primaryColor,
            ),
            title: const Text(
              'Modifier',
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: AppTheme.errorColor,
            ),
            title: const Text(
              'Supprimer',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
