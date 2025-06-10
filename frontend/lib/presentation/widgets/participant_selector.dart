import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './common/modal_widgets.dart';
import '../../core/theme/app_theme.dart';

class ParticipantSelector extends ConsumerStatefulWidget {
  final List<String> selectedNicknames;
  final Function(List<String>) onParticipantsChanged;
  final String? title;
  final String? subtitle;

  const ParticipantSelector({
    Key? key,
    required this.selectedNicknames,
    required this.onParticipantsChanged,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  ConsumerState<ParticipantSelector> createState() => _ParticipantSelectorState();
}

class _ParticipantSelectorState extends ConsumerState<ParticipantSelector> {
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<String> _nicknames = [];

  @override
  void initState() {
    super.initState();
    _nicknames = List.from(widget.selectedNicknames);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// Valide si le pseudo respecte les critères
  bool _isValidNickname(String nickname) {
    return nickname.length >= 2 && nickname.length <= 30;
  }

  /// Ajoute un nouveau participant
  void _addNickname() {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text.trim();
      if (!_nicknames.contains(nickname)) {
        setState(() {
          _nicknames.add(nickname);
          _nicknameController.clear();
        });
        widget.onParticipantsChanged(_nicknames);
      } else {
        _showErrorSnackBar('Ce pseudo est déjà ajouté');
      }
    }
  }

  /// Supprime un participant
  void _removeNickname(String nickname) {
    setState(() {
      _nicknames.remove(nickname);
    });
    widget.onParticipantsChanged(_nicknames);
  }

  /// Affiche un message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  /// Affiche la boîte de dialogue pour ajouter un participant
  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddParticipantDialog(
        formKey: _formKey,
        controller: _nicknameController,
        onAdd: _addNickname,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un prénom ou pseudo';
          }
          if (!_isValidNickname(value)) {
            return 'Le prénom doit faire entre 2 et 30 caractères';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec titre et bouton d'ajout
            _ParticipantSelectorHeader(
              title: widget.title ?? 'Participants',
              subtitle: widget.subtitle,
              onAddPressed: _showAddParticipantDialog,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Liste des participants ou état vide
            _nicknames.isEmpty
                ? const _EmptyParticipantsState()
                : _ParticipantsList(
                    nicknames: _nicknames,
                    onRemove: _removeNickname,
                  ),
            
            // Résumé du nombre de participants
            if (_nicknames.isNotEmpty)
              _ParticipantsSummary(count: _nicknames.length),
          ],
        ),
      ),
    );
  }
}

/// Widget pour l'en-tête du sélecteur de participants
class _ParticipantSelectorHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onAddPressed;

  const _ParticipantSelectorHeader({
    Key? key,
    required this.title,
    this.subtitle,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeS,
                  color: AppTheme.textColor.withOpacity(0.6),
                ),
              ),
          ],
        ),
        IconButton(
          onPressed: onAddPressed,
          icon: const Icon(
            Icons.person_add,
            color: AppTheme.primaryColor,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour l'état vide (aucun participant)
class _EmptyParticipantsState extends StatelessWidget {
  const _EmptyParticipantsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.textColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: AppTheme.textColor.withOpacity(0.4),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Aucun participant ajouté',
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.6),
              fontSize: AppTheme.fontSizeS,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Appuyez sur + pour ajouter des participants',
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.5),
              fontSize: AppTheme.fontSizeS - 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour la liste des participants
class _ParticipantsList extends StatelessWidget {
  final List<String> nicknames;
  final Function(String) onRemove;

  const _ParticipantsList({
    Key? key,
    required this.nicknames,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: nicknames.map((nickname) => 
        _ParticipantItem(
          nickname: nickname,
          onRemove: () => onRemove(nickname),
        ),
      ).toList(),
    );
  }
}

/// Widget pour un élément participant individuel
class _ParticipantItem extends StatelessWidget {
  final String nickname;
  final VoidCallback onRemove;

  const _ParticipantItem({
    Key? key,
    required this.nickname,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar avec initiale
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                nickname[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeS,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          
          // Nom du participant
          Expanded(
            child: Text(
              nickname,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: AppTheme.fontSizeS,
              ),
            ),
          ),
          
          // Bouton de suppression
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Widget pour le résumé du nombre de participants
class _ParticipantsSummary extends StatelessWidget {
  final int count;

  const _ParticipantsSummary({
    Key? key,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingS),
      child: Text(
        '$count participant${count > 1 ? 's' : ''} ajouté${count > 1 ? 's' : ''}',
        style: TextStyle(
          fontSize: AppTheme.fontSizeS - 2,
          color: AppTheme.textColor.withOpacity(0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Dialog pour ajouter un participant
class _AddParticipantDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final String? Function(String?) validator;

  const _AddParticipantDialog({
    Key? key,
    required this.formKey,
    required this.controller,
    required this.onAdd,
    required this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: const Text(
        'Ajouter un participant',
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledTextField(
              controller: controller,
              hintText: 'Ex: Jean, Marie, Alex...',
              prefixIcon: Icons.person,
              validator: validator,
              onChanged: (_) {}, // Requis par StyledTextField
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.clear();
            Navigator.pop(context);
          },
          child: Text(
            'Annuler',
            style: TextStyle(color: AppTheme.textColor.withOpacity(0.6)),
          ),
        ),
        PrimaryButton(
          text: 'Ajouter',
          onPressed: () {
            onAdd();
            Navigator.pop(context);
          },
          height: 40,
        ),
      ],
    );
  }
}
