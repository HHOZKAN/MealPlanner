import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'edit_event_page.dart';
import 'event_participants_page.dart';
import 'event_ingredients_page.dart';
import 'event_expenses_page.dart';

class EventDetailPage extends ConsumerWidget {
  final int eventId;
  
  const EventDetailPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'événement'),
        actions: [
          eventAsync.when(
            data: (event) {
              // Afficher les actions seulement si l'utilisateur est l'organisateur
              if (currentUser != null && event.organizerId == currentUser.id) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // Naviguer vers la page d'édition
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEventPage(event: event),
                        ),
                      );
                      
                      // Rafraîchir les données si l'événement a été modifié
                      if (result == true) {
                        ref.refresh(eventProvider(eventId));
                      }
                    } else if (value == 'delete') {
                      // Demander confirmation avant de supprimer
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer l\'événement'),
                          content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ? Cette action est irréversible.'),
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
                              const SnackBar(content: Text('Événement supprimé avec succès')),
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
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
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
        data: (event) => _buildEventDetails(context, event, ref),
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement de l\'événement: $error',
          onRetry: () => ref.refresh(eventProvider(eventId)),
        ),
      ),
    );
  }
  
  Widget _buildEventDetails(BuildContext context, EventModel event, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR');
    final currentUser = ref.watch(currentUserProvider);
    final isOrganizer = currentUser != null && event.organizerId == currentUser.id;
    
    // Déterminer l'icône et la couleur en fonction du type d'événement
    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    
    switch (event.type) {
      case 'dinner':
        typeIcon = Icons.dinner_dining;
        typeColor = Colors.deepOrange;
        typeLabel = 'Dîner';
        break;
      case 'lunch':
        typeIcon = Icons.lunch_dining;
        typeColor = Colors.amber;
        typeLabel = 'Déjeuner';
        break;
      case 'brunch':
        typeIcon = Icons.brunch_dining;
        typeColor = Colors.lightGreen;
        typeLabel = 'Brunch';
        break;
      case 'breakfast':
        typeIcon = Icons.free_breakfast;
        typeColor = Colors.brown;
        typeLabel = 'Petit-déjeuner';
        break;
      default:
        typeIcon = Icons.restaurant;
        typeColor = Colors.purple;
        typeLabel = 'Autre';
    }
    
    // Déterminer le statut
    String statusLabel;
    Color statusColor;
    
    switch (event.status) {
      case 'draft':
        statusLabel = 'Brouillon';
        statusColor = Colors.grey;
        break;
      case 'planning':
        statusLabel = 'En préparation';
        statusColor = Colors.blue;
        break;
      case 'confirmed':
        statusLabel = 'Confirmé';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusLabel = 'Annulé';
        statusColor = Colors.red;
        break;
      case 'completed':
        statusLabel = 'Terminé';
        statusColor = Colors.teal;
        break;
      default:
        statusLabel = event.status;
        statusColor = Colors.grey;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec le type et le statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Titre
          Text(
            event.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date et lieu
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateFormat.format(event.date),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          if (event.description != null && event.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  event.description!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Organisateur
          if (event.organizer != null) ...[
            Text(
              'Organisateur',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: event.organizer!.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            event.organizer!.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(event.organizer!.name),
                subtitle: Text(event.organizer!.email),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Actions
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                icon: Icons.people,
                title: 'Participants',
                subtitle: event.participants != null
                    ? '${event.participants!.length} participant${event.participants!.length > 1 ? 's' : ''}'
                    : 'Voir les participants',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventParticipantsPage(eventId: event.id),
                    ),
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.shopping_cart,
                title: 'Ingrédients',
                subtitle: 'Gérer la liste de courses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventIngredientsPage(eventId: event.id),
                    ),
                  );
                },
              ),
              _buildActionCard(
                context,
                icon: Icons.receipt_long,
                title: 'Dépenses',
                subtitle: 'Gérer les dépenses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventExpensesPage(eventId: event.id),
                    ),
                  );
                },
              ),
              if (isOrganizer)
                _buildActionCard(
                  context,
                  icon: Icons.edit,
                  title: 'Modifier',
                  subtitle: 'Modifier l\'événement',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventPage(event: event),
                      ),
                    );
                    
                    if (result == true) {
                      ref.refresh(eventProvider(eventId));
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}