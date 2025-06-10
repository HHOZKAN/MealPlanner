import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/pages/events/event_ingredients_page.dart';
import 'package:meal_planner/presentation/pages/events/event_expenses_page.dart';
import 'package:meal_planner/presentation/pages/events/event_balances_page.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/add_ingredient_modal.dart';
import '../../widgets/add_expense_modal.dart';
import '../../widgets/common/event_widgets.dart';
import './event_detail_logic.dart';
import './edit_event_page.dart';
import '../../../core/theme/app_theme.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventDetailPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  late final EventDetailLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = EventDetailLogic(ref: ref, eventId: widget.eventId);
    _logic.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(eventAsync, currentUser),
      body: eventAsync.when(
        data: (event) => _buildContent(event),
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement: $error',
          onRetry: () => ref.refresh(eventProvider(widget.eventId)),
        ),
      ),
      floatingActionButton: eventAsync.when(
        data: (event) => _buildFloatingActionButton(event),
        loading: () => null,
        error: (_, __) => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Construit l'AppBar avec les actions appropriées
  PreferredSizeWidget _buildAppBar(AsyncValue eventAsync, dynamic currentUser) {
    return AppBar(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        eventAsync.when(
          data: (event) {
            if (_logic.canEditEvent(event, currentUser)) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: AppTheme.primaryColor),
                    onPressed: () => _handleShareLink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppTheme.primaryColor),
                    onPressed: () => _showOptionsBottomSheet(event),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Construit le contenu principal de la page
  Widget _buildContent(dynamic event) {
    return Column(
      children: [
        // En-tête de l'événement
        EventHeader(event: event),
        
        // Contrôle segmenté
        CustomSegmentedControl(
          selectedIndex: _logic.selectedTabIndex,
          segments: EventDetailTab.labels,
          onSegmentChanged: (index) => _logic.changeTab(index, () => setState(() {})),
        ),
        
        // Contenu basé sur l'onglet sélectionné
        Expanded(
          child: IndexedStack(
            index: _logic.selectedTabIndex,
            children: [
              EventIngredientsPage(eventId: event.id),
              EventExpensesPage(eventId: event.id),
              EventBalancesPage(eventId: event.id),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'action flottant
  Widget? _buildFloatingActionButton(dynamic event) {
    if (!_logic.shouldShowActionButton()) {
      return null;
    }

    return EventActionButton(
      text: _logic.getActionButtonText(),
      onPressed: () => _handleAddAction(event),
    );
  }

  /// Gère l'action d'ajout (ingrédient ou dépense)
  void _handleAddAction(dynamic event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _logic.selectedTabIndex == 0
          ? AddIngredientModal(eventId: event.id)
          : AddExpenseModal(eventId: event.id),
    ).then((result) async {
      if (result == true) {
        await _logic.refreshAfterAdd();
      }
    });
  }

  /// Gère le partage du lien d'invitation
  Future<void> _handleShareLink() async {
    try {
      final shareableLink = await _logic.getShareableLink();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ShareLinkDialog(shareableLink: shareableLink),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Affiche le menu d'options de l'événement
  void _showOptionsBottomSheet(dynamic event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EventOptionsBottomSheet(
        onEdit: () => _handleEditEvent(event),
        onDelete: () => _handleDeleteEvent(event),
      ),
    );
  }

  /// Gère la modification de l'événement
  Future<void> _handleEditEvent(dynamic event) async {
    Navigator.pop(context); // Fermer le bottom sheet
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: event),
      ),
    );
    
    if (result == true) {
      ref.refresh(eventProvider(widget.eventId));
      ref.refresh(ingredientsStateProvider(widget.eventId));
    }
  }

  /// Gère la suppression de l'événement
  Future<void> _handleDeleteEvent(dynamic event) async {
    Navigator.pop(context); // Fermer le bottom sheet
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Supprimer l\'événement',
        content: 'Êtes-vous sûr de vouloir supprimer cet événement ?',
        confirmText: 'Supprimer',
        cancelText: 'Annuler',
        confirmColor: AppTheme.errorColor,
      ),
    );
    
    if (confirm == true) {
      await _logic.deleteEvent(context, event);
    }
  }
}
