import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/pages/events/event_ingredients_page.dart';
import 'package:meal_planner/presentation/pages/events/event_expenses_page.dart';
import 'package:meal_planner/presentation/pages/events/event_balances_page.dart';
import 'package:meal_planner/presentation/providers/event_share_link_provider.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../../presentation/providers/expense_provider_new.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/add_ingredient_modal.dart';
import '../../widgets/add_expense_modal.dart';
import 'edit_event_page.dart';

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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Charger les ingrédients quand la page est montée
    Future.microtask(() {
      final notifier = ref.read(ingredientsStateProvider(widget.eventId).notifier);
      notifier.loadIngredients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF5722)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          eventAsync.when(
            data: (event) {
              if (currentUser != null && event.organizerId == currentUser.id) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Color(0xFFFF5722)),
                      onPressed: () async {
                        // Fetch shareable link and show dialog
                        final shareableLinkAsync = ref.read(eventShareLinkProvider(event.id).future);
                        final shareableLink = await shareableLinkAsync;
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                              'Lien d\'invitation partageable',
                              style: TextStyle(
                                color: Color(0xFF2D3142),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SelectableText(
                              shareableLink,
                              style: const TextStyle(color: Color(0xFF2D3142)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Fermer',
                                  style: TextStyle(color: Color(0xFFFF5722)),
                                ),
                              ),
                            ],
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Color(0xFFFF5722)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit, color: Color(0xFFFF5722)),
                                title: const Text(
                                  'Modifier',
                                  style: TextStyle(
                                    color: Color(0xFF2D3142),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
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
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text(
                                  'Supprimer',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Supprimer l\'événement',
                                        style: TextStyle(
                                          color: Color(0xFF2D3142),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        'Êtes-vous sûr de vouloir supprimer cet événement ?',
                                        style: TextStyle(color: Color(0xFF2D3142)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text(
                                            'Annuler',
                                            style: TextStyle(color: Color(0xFF2D3142)),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ref.read(eventsStateProvider.notifier).deleteEvent(event.id);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Événement supprimé'),
                                            backgroundColor: Color(0xFFFF5722),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur: $e'),
                                            backgroundColor: Color(0xFFFF5722),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
      ),
      body: eventAsync.when(
        data: (event) => Column(
          children: [
            // Event Title and Emoji
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    event.emoji ?? '🏖️',
                    style: const TextStyle(fontSize: 36),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Custom Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(0, 'Ingrédients'),
                    _buildSegmentButton(1, 'Dépenses'),
                    _buildSegmentButton(2, 'Soldes'),
                  ],
                ),
              ),
            ),
            
            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Ingredients Tab
                  EventIngredientsPage(eventId: event.id),
                  // Expenses Tab
                  EventExpensesPage(eventId: event.id),
                  // Balance Tab
                  EventBalancesPage(eventId: event.id),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement: $error',
          onRetry: () => ref.refresh(eventProvider(widget.eventId)),
        ),
      ),
      floatingActionButton: eventAsync.when(
        data: (event) {
          if (_selectedIndex == 0 || _selectedIndex == 1) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _selectedIndex == 0
                        ? AddIngredientModal(eventId: event.id)
                        : AddExpenseModal(eventId: event.id),
                  ).then((result) async {
                    if (result == true) {
                      // Refresh both event and ingredients data
                      ref.refresh(eventProvider(widget.eventId));
                      // Force reload ingredients
                      await ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _selectedIndex == 0 ? 'Ajouter un ingrédient' : 'Ajouter une dépense',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            final notifier = ref.read(ingredientsStateProvider(widget.eventId).notifier);
            notifier.loadIngredients();
          } else if (index == 1 || index == 2) {
            // Charger les dépenses pour l'onglet Dépenses et Soldes
            final notifier = ref.read(expensesStateProvider(widget.eventId).notifier);
            notifier.loadExpenses();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D3142),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
