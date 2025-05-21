import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/event_card.dart';
import '../events/create_event_page.dart';
import 'dart:math' show min;

class DashboardHomeTab extends ConsumerStatefulWidget {
  const DashboardHomeTab({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends ConsumerState<DashboardHomeTab> {
  @override
  void initState() {
    super.initState();
    // Charger les événements au chargement de la page
    Future.microtask(() => ref.read(eventsStateProvider.notifier).loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final eventsState = ref.watch(eventsStateProvider);
    final events = ref.watch(eventsStateProvider.notifier).events;
    
    // Filtrer les événements à venir
    final upcomingEvents = events
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Prendre les 3 premiers événements à venir
    final nextEvents = upcomingEvents.take(3).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(eventsStateProvider.notifier).loadEvents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte de bienvenue
              if (currentUser != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              radius: 30,
                              child: currentUser.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        currentUser.avatarUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 30),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenue, ${currentUser.name}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currentUser.email,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateEventPage()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un événement'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              
              // Prochains événements
              Text(
                'Prochains événements',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (eventsState == EventsState.loading)
                const LoadingIndicator(message: 'Chargement des événements...')
              else if (eventsState == EventsState.error)
                ErrorMessage(
                  message: 'Erreur lors du chargement des événements: ${ref.read(eventsStateProvider.notifier).errorMessage}',
                  onRetry: () => ref.read(eventsStateProvider.notifier).loadEvents(),
                )
              else if (nextEvents.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun événement à venir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Créez votre premier événement ou rejoignez un événement existant',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateEventPage()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un événement'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nextEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      event: nextEvents[index],
                      onTap: () => Navigator.pushNamed(context, '/events/${nextEvents[index].id}'),
                    );
                  },
                ),
              
              if (nextEvents.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Utiliser le provider pour changer l'onglet
                    ref.read(selectedTabIndexProvider.notifier).state = 1;
                  },
                  child: const Text('Voir tous les événements'),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Statistiques
              Text(
                'Statistiques',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatisticRow(
                        context,
                        icon: Icons.event,
                        title: 'Événements organisés',
                        value: events.where((e) => e.organizerId == currentUser?.id).length.toString(),
                      ),
                      const Divider(),
                      _buildStatisticRow(
                        context,
                        icon: Icons.people,
                        title: 'Événements participés',
                        value: events.where((e) => e.organizerId != currentUser?.id).length.toString(),
                      ),
                      const Divider(),
                      _buildStatisticRow(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Événements à venir',
                        value: upcomingEvents.length.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Activité récente
              Text(
                'Activité récente',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.isNotEmpty ? min(events.length, 3) : 1,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    if (events.isEmpty) {
                      return const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Aucune activité récente'),
                      );
                    }
                    
                    final event = events[index];
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getEventTypeColor(event.type),
                        child: Icon(
                          _getEventTypeIcon(event.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(event.title),
                      subtitle: Text('${dateFormat.format(event.date)} - ${event.status}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/events/${event.id}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildStatisticRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'dinner':
        return Icons.dinner_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'brunch':
        return Icons.brunch_dining;
      case 'breakfast':
        return Icons.free_breakfast;
      default:
        return Icons.restaurant;
    }
  }
  
  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'dinner':
        return Colors.deepOrange;
      case 'lunch':
        return Colors.amber;
      case 'brunch':
        return Colors.lightGreen;
      case 'breakfast':
        return Colors.brown;
      default:
        return Colors.purple;
    }
  }
}