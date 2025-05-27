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
    Future.microtask(() => ref.read(eventsStateProvider.notifier).loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final eventsState = ref.watch(eventsStateProvider);
    final events = ref.watch(eventsStateProvider.notifier).events;
    
    final upcomingEvents = events
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final nextEvents = upcomingEvents.take(3).toList();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3142)),
            onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF2D3142)),
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
              if (currentUser != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFFF5722),
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
                                      color: const Color(0xFF2D3142),
                                    ),
                                  ),
                                  Text(
                                    currentUser.email,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
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
                            backgroundColor: const Color(0xFFFF5722),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Prochains événements',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (eventsState == EventsState.loading)
                const LoadingIndicator(message: 'Chargement des événements...')
              else if (eventsState == EventsState.error)
                ErrorMessage(
                  message: 'Erreur lors du chargement des événements: ${ref.read(eventsStateProvider.notifier).errorMessage}',
                  onRetry: () => ref.read(eventsStateProvider.notifier).loadEvents(),
                )
              else if (nextEvents.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun événement à venir',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre premier événement ou rejoignez un événement existant',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
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
                            backgroundColor: const Color(0xFFFF5722),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(selectedTabIndexProvider.notifier).state = 1;
                  },
                  child: Text(
                    'Voir tous les événements',
                    style: TextStyle(
                      color: const Color(0xFFFF5722),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Statistiques',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatisticRow(
                        context,
                        icon: Icons.event,
                        title: 'Événements organisés',
                        value: events.where((e) => e.organizerId == currentUser?.id).length.toString(),
                      ),
                      const Divider(height: 32),
                      _buildStatisticRow(
                        context,
                        icon: Icons.people,
                        title: 'Événements participés',
                        value: events.where((e) => e.organizerId != currentUser?.id).length.toString(),
                      ),
                      const Divider(height: 32),
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
              
              const SizedBox(height: 32),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Activité récente',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.isNotEmpty ? min(events.length, 3) : 1,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (events.isEmpty) {
                      return ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.grey[400]),
                        title: const Text('Aucune activité récente'),
                      );
                    }
                    
                    final event = events[index];
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: event.emoji != null
                              ? Text(
                                  event.emoji!,
                                  style: const TextStyle(fontSize: 20),
                                )
                              : Icon(
                                  _getEventTypeIcon(event.type),
                                  color: const Color(0xFFFF5722),
                                ),
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      subtitle: Text(
                        '${dateFormat.format(event.date)} - ${event.status}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFFF5722),
                          size: 20,
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/events/${event.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventPage()),
          );
        },
        backgroundColor: const Color(0xFFFF5722),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel événement'),
      ),
    );
  }
  
  Widget _buildStatisticRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF5722),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3142),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5722),
          ),
        ),
      ],
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
}
