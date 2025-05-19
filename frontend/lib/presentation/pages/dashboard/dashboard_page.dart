import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/pages/events/event_detail_page.dart';
import 'package:meal_planner/presentation/widgets/loading_screen.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../widgets/event_card.dart';
import '../events/create_event_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEventPage()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(eventsState, ref),
    );
  }

  Widget _buildBody(EventsState state, WidgetRef ref) {
    switch (state) {
      case EventsState.initial:
      case EventsState.loading:
        return const LoadingScreen();

      case EventsState.loaded:
        final events = ref.watch(eventsStateProvider.notifier).events;
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun événement trouvé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return EventCard(
              event: events[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailPage(eventId: events[index].id),
                  ),
                );
              },
            );
          },
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
                onPressed: () =>
                    ref.read(eventsStateProvider.notifier).loadEvents(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
    }
  }
}