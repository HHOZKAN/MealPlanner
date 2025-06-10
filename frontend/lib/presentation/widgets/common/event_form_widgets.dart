import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget pour le sélecteur d'emoji
class EmojiSelector extends StatelessWidget {
  final String selectedEmoji;
  final VoidCallback onTap;

  const EmojiSelector({
    Key? key,
    required this.selectedEmoji,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: AppTheme.textColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              selectedEmoji,
              style: const TextStyle(
                fontSize: 48,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour le sélecteur d'emoji modal
class EmojiPickerModal extends StatelessWidget {
  final List<String> emojis;
  final Function(String) onEmojiSelected;

  const EmojiPickerModal({
    Key? key,
    required this.emojis,
    required this.onEmojiSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choisir un emoji',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Wrap(
            spacing: AppTheme.spacingL,
            runSpacing: AppTheme.spacingL,
            children: emojis.map((emoji) => _EmojiItem(
              emoji: emoji,
              onTap: () {
                onEmojiSelected(emoji);
                Navigator.pop(context);
              },
            )).toList(),
          ),
          const SizedBox(height: AppTheme.spacingL),
        ],
      ),
    );
  }
}

/// Widget pour un élément emoji individuel
class _EmojiItem extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiItem({
    Key? key,
    required this.emoji,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: AppTheme.textColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 40,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour le champ de texte stylisé avec ombre
class ShadowedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool isRequired;

  const ShadowedTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textColor),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: AppTheme.textColor),
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.textColor.withOpacity(0.6),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppTheme.primaryColor)
              : null,
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
        maxLines: maxLines,
        validator: validator ?? (isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              }
            : null),
      ),
    );
  }
}

/// Widget pour le sélecteur de date/heure
class DateTimePicker extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const DateTimePicker({
    Key? key,
    required this.icon,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.cardShadow,
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: AppTheme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: AppTheme.fontSizeM,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour le message d'erreur
class ErrorMessageDisplay extends StatelessWidget {
  final String message;

  const ErrorMessageDisplay({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppTheme.errorColor.withOpacity(0.8),
        ),
      ),
    );
  }
}

/// Widget pour le bouton de soumission
class SubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const SubmitButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.fontSizeM,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
