import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../data/models/event_model.dart';
import '../../widgets/event_card.dart';
import 'create_event_page.dart';

class EventListPage extends ConsumerStatefulWidget {
  const EventListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  @override
  void initState() {
    super.initState();
    // Charger les événements au chargement de la page
    Future.microtask(() => ref.read(eventsStateProvider.notifier).loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsStateProvider);
    final events = ref.watch(eventsStateProvider.notifier).events;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
          ),
        ],
      ),
      body: _buildBody(eventsState, events),
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
  
  Widget _buildBody(EventsState state, List<EventModel> events) {
    switch (state) {
      case EventsState.initial:
      case EventsState.loading:
        return const Center(child: CircularProgressIndicator());
      
      case EventsState.loaded:
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun événement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez votre premier événement en cliquant sur le bouton +',
                  textAlign: TextAlign.center,
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
                ),
              ],
            ),
          );
        }
        
        // Trier les événements par date
        final upcomingEvents = events.where((e) => e.date.isAfter(DateTime.now())).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        
        final pastEvents = events.where((e) => e.date.isBefore(DateTime.now())).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (upcomingEvents.isNotEmpty) ...[
                const Text(
                  'Événements à venir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      event: upcomingEvents[index],
                      onTap: () => context.go('/events/${upcomingEvents[index].id}'),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              if (pastEvents.isNotEmpty) ...[
                const Text(
                  'Événements passés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pastEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      event: pastEvents[index],
                      onTap: () => context.go('/events/${pastEvents[index].id}'),
                      isPast: true,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      
      case EventsState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur: ${ref.read(eventsStateProvider.notifier).errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
    }
  }
}