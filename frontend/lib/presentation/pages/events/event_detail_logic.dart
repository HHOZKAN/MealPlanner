import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/event_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/expense_provider_new.dart';
import '../../providers/event_share_link_provider.dart';
import '../../../data/models/event_model.dart';

/// Classe pour gérer la logique de la page de détail d'événement
class EventDetailLogic {
  final WidgetRef ref;
  final int eventId;
  
  int _selectedTabIndex = 0;

  int get selectedTabIndex => _selectedTabIndex;

  EventDetailLogic({
    required this.ref,
    required this.eventId,
  });

  /// Initialise les données nécessaires
  void initialize() {
    Future.microtask(() {
      final notifier = ref.read(ingredientsStateProvider(eventId).notifier);
      notifier.loadIngredients();
    });
  }

  /// Change l'onglet sélectionné et charge les données appropriées
  void changeTab(int index, VoidCallback setState) {
    _selectedTabIndex = index;
    setState();

    // Charger les données selon l'onglet sélectionné
    switch (index) {
      case 0: // Ingrédients
        final ingredientsNotifier = ref.read(ingredientsStateProvider(eventId).notifier);
        ingredientsNotifier.loadIngredients();
        break;
      case 1: // Dépenses
      case 2: // Soldes
        final expensesNotifier = ref.read(expensesStateProvider(eventId).notifier);
        expensesNotifier.loadExpenses();
        break;
    }
  }

  /// Gère le partage du lien d'invitation
  Future<String> getShareableLink() async {
    final shareableLinkAsync = ref.read(eventShareLinkProvider(eventId).future);
    return await shareableLinkAsync;
  }

  /// Gère la modification d'un événement
  Future<bool> editEvent(BuildContext context, EventModel event) async {
    // Cette méthode sera appelée depuis la page de détail
    // Le résultat indique si l'événement a été modifié
    return false; // Placeholder - sera implémenté dans la page
  }

  /// Gère la suppression d'un événement
  Future<bool> deleteEvent(BuildContext context, EventModel event) async {
    try {
      await ref.read(eventsStateProvider.notifier).deleteEvent(event.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Rafraîchit les données après ajout d'ingrédient/dépense
  Future<void> refreshAfterAdd() async {
    ref.refresh(eventProvider(eventId));
    await ref.read(ingredientsStateProvider(eventId).notifier).loadIngredients();
  }

  /// Détermine le texte du bouton d'action selon l'onglet
  String getActionButtonText() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Ajouter un ingrédient';
      case 1:
        return 'Ajouter une dépense';
      default:
        return '';
    }
  }

  /// Détermine si le bouton d'action doit être affiché
  bool shouldShowActionButton() {
    return _selectedTabIndex == 0 || _selectedTabIndex == 1;
  }

  /// Valide si l'utilisateur peut modifier l'événement
  bool canEditEvent(EventModel event, dynamic currentUser) {
    return currentUser != null && event.organizerId == currentUser.id;
  }
}

/// Énumération pour les onglets de la page de détail
enum EventDetailTab {
  ingredients,
  expenses,
  balances;

  String get label {
    switch (this) {
      case EventDetailTab.ingredients:
        return 'Ingrédients';
      case EventDetailTab.expenses:
        return 'Dépenses';
      case EventDetailTab.balances:
        return 'Soldes';
    }
  }

  int get tabIndex {
    switch (this) {
      case EventDetailTab.ingredients:
        return 0;
      case EventDetailTab.expenses:
        return 1;
      case EventDetailTab.balances:
        return 2;
    }
  }

  static List<String> get labels => EventDetailTab.values.map((tab) => tab.label).toList();
}
