import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/pages/events/event_ingredients_page.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'edit_event_page.dart';
import 'add_ingredient_page.dart';

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
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          eventAsync.when(
            data: (event) {
              if (currentUser != null && event.organizerId == currentUser.id) {
                return IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
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
                            leading: const Icon(Icons.edit),
                            title: const Text('Modifier'),
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
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            onTap: () async {
                              Navigator.pop(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Supprimer l\'événement'),
                                  content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref.read(eventsStateProvider.notifier).deleteEvent(event.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Événement supprimé')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text(
                    event.emoji ?? '🏖️',
                    style: const TextStyle(fontSize: 48),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Custom Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(0, 'Ingrédients'),
                    _buildSegmentButton(1, 'Soldes'),
                    _buildSegmentButton(2, 'Photos'),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  EventIngredientsPage(eventId: event.id),
                  const Center(child: Text('Soldes - à implémenter')),
                  const Center(child: Text('Photos - à implémenter')),
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
          if (_selectedIndex == 0) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddIngredientPage(eventId: event.id),
                  ),
                ).then((_) => ref.refresh(eventProvider(widget.eventId)));
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(4),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
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
