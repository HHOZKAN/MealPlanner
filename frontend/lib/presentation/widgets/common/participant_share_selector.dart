import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Widget pour la sélection des participants et leurs parts
class ParticipantShareSelector extends StatefulWidget {
  final List<Map<String, dynamic>> participants;
  final Set<int> selectedParticipants;
  final Map<int, TextEditingController> shareControllers;
  final int? currentUserId;
  final void Function(int userId, bool isSelected) onParticipantToggle;
  final void Function() onEqualSharePressed;

  const ParticipantShareSelector({
    Key? key,
    required this.participants,
    required this.selectedParticipants,
    required this.shareControllers,
    this.currentUserId,
    required this.onParticipantToggle,
    required this.onEqualSharePressed,
  }) : super(key: key);

  @override
  State<ParticipantShareSelector> createState() => _ParticipantShareSelectorState();
}

class _ParticipantShareSelectorState extends State<ParticipantShareSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec bouton "Également"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Diviser',
              style: TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: widget.onEqualSharePressed,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Également'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        // Liste des participants
        ...widget.participants.map((participant) => 
          _ParticipantShareItem(
            participant: participant,
            isSelected: widget.selectedParticipants.contains(participant['userId']),
            isCurrentUser: participant['userId'] == widget.currentUserId,
            shareController: widget.shareControllers[participant['userId']],
            onToggle: (isSelected) => widget.onParticipantToggle(
              participant['userId'], 
              isSelected,
            ),
          ),
        ).toList(),
      ],
    );
  }
}

/// Widget pour un élément participant avec sa part
class _ParticipantShareItem extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isSelected;
  final bool isCurrentUser;
  final TextEditingController? shareController;
  final void Function(bool isSelected) onToggle;

  const _ParticipantShareItem({
    Key? key,
    required this.participant,
    required this.isSelected,
    required this.isCurrentUser,
    this.shareController,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected 
              ? AppTheme.primaryColor 
              : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Row(
          children: [
            // Checkbox personnalisé
            _CustomCheckbox(
              isSelected: isSelected,
              onTap: () => onToggle(!isSelected),
            ),
            const SizedBox(width: AppTheme.spacingM),
            
            // Nom du participant
            Expanded(
              child: Text(
                isCurrentUser 
                  ? '${participant['name']} (Moi)' 
                  : participant['name'],
                style: TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  color: isSelected 
                    ? AppTheme.textColor 
                    : AppTheme.textColor.withOpacity(0.6),
                  fontWeight: isSelected 
                    ? FontWeight.w500 
                    : FontWeight.normal,
                ),
              ),
            ),
            
            // Champ de saisie de la part
            if (isSelected && shareController != null)
              SizedBox(
                width: 90,
                child: _ShareInputField(controller: shareController!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour le checkbox personnalisé
class _CustomCheckbox extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomCheckbox({
    Key? key,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }
}

/// Widget pour le champ de saisie de la part
class _ShareInputField extends StatelessWidget {
  final TextEditingController controller;

  const _ShareInputField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingS,
          ),
          suffixText: '€',
          suffixStyle: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          hintText: '0,00',
          hintStyle: TextStyle(
            color: AppTheme.textColor,
            fontSize: AppTheme.fontSizeS,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Requis';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount < 0) {
            return 'Invalide';
          }
          return null;
        },
      ),
    );
  }
}
