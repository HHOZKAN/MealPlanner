import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/event_participants_provider.dart' as participants_provider;
import '../../providers/event_provider.dart' as event_provider;
import '../../providers/expense_provider_new.dart';

/// Classe pour gérer la logique métier du formulaire d'ajout de dépense
class ExpenseFormLogic {
  final WidgetRef ref;
  final int eventId;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  
  // État du formulaire
  int? selectedIngredientId;
  int? selectedPayerId;
  Map<int, TextEditingController> shareControllers = {};
  Set<int> selectedParticipants = {};
  bool isLoading = false;

  ExpenseFormLogic({
    required this.ref,
    required this.eventId,
    required this.formKey,
    required this.amountController,
  });

  /// Dispose des contrôleurs
  void dispose() {
    amountController.dispose();
    shareControllers.values.forEach((controller) => controller.dispose());
  }

  /// Met à jour les parts égales quand le montant change
  void updateShares(double totalAmount) {
    if (shareControllers.isEmpty) return;
    
    final equalShare = (totalAmount / shareControllers.length).toStringAsFixed(2);
    shareControllers.forEach((_, controller) {
      controller.text = equalShare;
    });
  }

  /// Gère le changement d'ingrédient sélectionné
  void onIngredientChanged(int? ingredientId, VoidCallback setState) {
    selectedIngredientId = ingredientId;
    
    // Reset des contrôleurs de parts
    shareControllers.clear();
    selectedParticipants.clear();
    
    if (ingredientId != null) {
      // Initialiser avec les participants assignés à l'ingrédient
      final assignedParticipants = getAssignedParticipants();
      for (final participant in assignedParticipants) {
        selectedParticipants.add(participant['userId']);
        shareControllers[participant['userId']] = TextEditingController();
      }
    }
    
    setState();
  }

  /// Gère le toggle d'un participant
  void onParticipantToggle(int userId, bool isSelected, VoidCallback setState) {
    if (isSelected) {
      selectedParticipants.add(userId);
      shareControllers[userId] = TextEditingController();
      
      // Recalculer les parts égales
      final amount = double.tryParse(amountController.text) ?? 0;
      if (amount > 0 && selectedParticipants.isNotEmpty) {
        final equalShare = (amount / selectedParticipants.length).toStringAsFixed(2);
        for (final userId in selectedParticipants) {
          shareControllers[userId]?.text = equalShare;
        }
      }
    } else {
      selectedParticipants.remove(userId);
      shareControllers[userId]?.dispose();
      shareControllers.remove(userId);
    }
    
    setState();
  }

  /// Distribue les parts également
  void distributeEqualShares() {
    final amount = double.tryParse(amountController.text) ?? 0;
    if (selectedParticipants.isNotEmpty) {
      final equalShare = (amount / selectedParticipants.length).toStringAsFixed(2);
      for (final userId in selectedParticipants) {
        shareControllers[userId]?.text = equalShare;
      }
    }
  }

  /// Récupère les participants assignés à l'ingrédient sélectionné
  List<Map<String, dynamic>> getAssignedParticipants() {
    if (selectedIngredientId == null) return [];
    
    final selectedIngredient = ref.read(ingredientsStateProvider(eventId).notifier)
        .ingredients.firstWhere((i) => i.id == selectedIngredientId);
    
    final Set<int> assignedUserIds = {};
    final List<Map<String, dynamic>> assignedParticipants = [];

    // Ajouter les utilisateurs assignés à l'ingrédient
    for (final assignment in selectedIngredient.assignments ?? []) {
      if (!assignedUserIds.contains(assignment.userId)) {
        assignedUserIds.add(assignment.userId);
        assignedParticipants.add({
          'userId': assignment.userId,
          'name': assignment.user?.name ?? 'Utilisateur inconnu',
          'isOrganizer': false,
        });
      }
    }

    return assignedParticipants;
  }

  /// Récupère tous les participants de l'événement
  List<Map<String, dynamic>> getAllEventParticipants() {
    final participants = ref.watch(participants_provider.eventParticipantsProvider(eventId));
    final eventAsync = ref.watch(event_provider.eventProvider(eventId));
    
    final List<Map<String, dynamic>> allParticipants = [];
    
    // Ajouter l'organisateur
    eventAsync.whenData((event) {
      if (event.organizer != null) {
        allParticipants.add({
          'userId': event.organizer!.id,
          'name': event.organizer!.name,
          'isOrganizer': true,
        });
      }
    });
    
    // Ajouter les participants (en évitant les doublons avec l'organisateur)
    participants.whenData((participantsList) {
      for (final participant in participantsList) {
        if (participant.user != null && 
            !allParticipants.any((p) => p['userId'] == participant.user!.id)) {
          allParticipants.add({
            'userId': participant.user!.id,
            'name': participant.user!.name,
            'isOrganizer': false,
          });
        }
      }
    });
    
    return allParticipants;
  }

  /// Valide le formulaire avant la sauvegarde
  ValidationResult validateForm() {
    if (!formKey.currentState!.validate() || 
        selectedIngredientId == null || 
        selectedPayerId == null) {
      return ValidationResult(
        isValid: false,
        message: 'Veuillez remplir tous les champs requis',
      );
    }

    // Vérifier qu'au moins un participant est sélectionné
    if (selectedParticipants.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Veuillez sélectionner au moins un participant',
      );
    }

    // Vérifier que la somme des parts égale le montant total
    final totalAmount = double.parse(amountController.text);
    final sumOfShares = selectedParticipants
        .map((userId) => double.tryParse(shareControllers[userId]?.text ?? '0') ?? 0)
        .reduce((a, b) => a + b);

    if ((sumOfShares - totalAmount).abs() > 0.01) {
      return ValidationResult(
        isValid: false,
        message: 'La somme des parts doit être égale au montant total',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Sauvegarde la dépense
  Future<void> saveExpense(BuildContext context, VoidCallback setState) async {
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

    isLoading = true;
    setState();

    try {
      final createExpense = ref.read(createExpenseProvider(eventId));
      final totalAmount = double.parse(amountController.text);
      
      // Créer la dépense
      final expense = {
        'ingredient_id': selectedIngredientId,
        'payer_id': selectedPayerId,
        'amount': totalAmount,
        'shares': Map.fromEntries(selectedParticipants.map((userId) => 
          MapEntry(userId.toString(), double.parse(shareControllers[userId]?.text ?? '0')))),
      };

      // Envoyer la dépense au backend
      await createExpense(expense);

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense enregistrée avec succès'),
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
        isLoading = false;
        setState();
      }
    }
  }
}

/// Classe pour le résultat de validation
class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({
    required this.isValid,
    this.message,
  });
}
