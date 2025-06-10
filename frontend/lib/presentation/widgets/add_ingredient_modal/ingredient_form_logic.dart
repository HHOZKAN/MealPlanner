import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ingredient_provider.dart';

/// Classe pour gérer la logique du formulaire d'ajout d'ingrédient
class IngredientFormLogic {
  final WidgetRef ref;
  final int eventId;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController estimatedPriceController;
  final TextEditingController notesController;
  
  bool _isLoading = false;
  String _selectedUnit = 'piece';

  bool get isLoading => _isLoading;
  String get selectedUnit => _selectedUnit;

  IngredientFormLogic({
    required this.ref,
    required this.eventId,
    required this.formKey,
    required this.nameController,
    required this.quantityController,
    required this.estimatedPriceController,
    required this.notesController,
  });

  /// Change l'unité sélectionnée
  void setSelectedUnit(String unit) {
    _selectedUnit = unit;
  }

  /// Valide le formulaire et retourne un résultat de validation
  ValidationResult validateForm() {
    if (!formKey.currentState!.validate()) {
      return ValidationResult(
        isValid: false,
        message: 'Veuillez corriger les erreurs dans le formulaire',
      );
    }

    final quantity = double.tryParse(quantityController.text);
    if (quantity == null || quantity <= 0) {
      return ValidationResult(
        isValid: false,
        message: 'La quantité doit être un nombre positif',
      );
    }

    if (estimatedPriceController.text.isNotEmpty) {
      final price = double.tryParse(estimatedPriceController.text);
      if (price == null || price < 0) {
        return ValidationResult(
          isValid: false,
          message: 'Le prix estimé doit être un nombre positif',
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  /// Sauvegarde l'ingrédient
  Future<void> saveIngredient(BuildContext context, VoidCallback setState) async {
    final validation = validateForm();
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _isLoading = true;
    setState();

    try {
      final notifier = ref.read(ingredientsStateProvider(eventId).notifier);
      
      final quantity = double.parse(quantityController.text);
      final estimatedPrice = estimatedPriceController.text.isNotEmpty
          ? double.parse(estimatedPriceController.text)
          : null;

      await notifier.createIngredient(
        name: nameController.text.trim(),
        quantity: quantity,
        unit: _selectedUnit,
        estimatedPrice: estimatedPrice,
        notes: notesController.text.isNotEmpty ? notesController.text.trim() : null,
      );

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingrédient ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        _isLoading = false;
        setState();
      }
    }
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    estimatedPriceController.dispose();
    notesController.dispose();
  }
}

/// Classe pour représenter le résultat d'une validation
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({
    required this.isValid,
    this.message,
  });
}
