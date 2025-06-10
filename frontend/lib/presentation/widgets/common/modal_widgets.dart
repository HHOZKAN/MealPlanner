import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Widget pour la barre de poignée des modales
class ModalHandle extends StatelessWidget {
  const ModalHandle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Widget pour les titres de modales
class ModalTitle extends StatelessWidget {
  final String title;
  
  const ModalTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTheme.fontSizeXL,
        fontWeight: FontWeight.bold,
        color: AppTheme.textColor,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour les labels de sections
class SectionLabel extends StatelessWidget {
  final String label;
  
  const SectionLabel({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppTheme.fontSizeM,
        fontWeight: FontWeight.bold,
        color: AppTheme.textColor,
      ),
    );
  }
}

/// Widget pour les champs de texte avec style uniforme
class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? suffixText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const StyledTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.suffixText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
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
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.6)),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusL)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(color: AppTheme.textColor),
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: AppTheme.primaryColor)
            : null,
        ),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: AppTheme.fontSizeM,
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// Widget pour les dropdowns avec style uniforme
class StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hintText;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const StyledDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.hintText,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textColor),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusL)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
        dropdownColor: AppTheme.cardColor,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: AppTheme.fontSizeM,
        ),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// Widget pour les boutons principaux
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.primaryShadow,
      ),
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
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
            : Text(
                text,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Widget pour les conteneurs de date
class DateDisplay extends StatelessWidget {
  final DateTime date;

  const DateDisplay({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            '${date.day} ${_getMonthName(date.month)} ${date.year}',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeM,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return months[month];
  }
}
