import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

// Provider pour le repository d'événements
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return EventRepository(dioClient);
});

// États possibles pour la liste d'événements
enum EventsState {
  initial,
  loading,
  loaded,
  error,
}

// État pour la liste d'événements
class EventsStateNotifier extends StateNotifier<EventsState> {
  final EventRepository _eventRepository;
  List<EventModel> _events = [];
  String? _errorMessage;
  
  EventsStateNotifier(this._eventRepository) : super(EventsState.initial);
  
  List<EventModel> get events => _events;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadEvents() async {
    try {
      state = EventsState.loading;
      _events = await _eventRepository.getEvents();
      state = EventsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = EventsState.error;
    }
  }
  
  Future<void> createEvent({
    required String title,
    String? description,
    required DateTime date,
    String? location,
    required String type,
  }) async {
    try {
      state = EventsState.loading;
      final event = await _eventRepository.createEvent(
        title: title,
        description: description,
        date: date,
        location: location,
        type: type,
      );
      _events = [event, ..._events];
      state = EventsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = EventsState.error;
    }
  }
  
  Future<void> updateEvent({
    required int id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? type,
    String? status,
  }) async {
    try {
      state = EventsState.loading;
      final updatedEvent = await _eventRepository.updateEvent(
        id: id,
        title: title,
        description: description,
        date: date,
        location: location,
        type: type,
        status: status,
      );
      _events = _events.map((event) {
        if (event.id == id) {
          return updatedEvent;
        }
        return event;
      }).toList();
      state = EventsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = EventsState.error;
    }
  }
  
  Future<void> deleteEvent(int id) async {
    try {
      state = EventsState.loading;
      await _eventRepository.deleteEvent(id);
      _events = _events.where((event) => event.id != id).toList();
      state = EventsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = EventsState.error;
    }
  }
}

// Provider pour l'état des événements
final eventsStateProvider = StateNotifierProvider<EventsStateNotifier, EventsState>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return EventsStateNotifier(eventRepository);
});

// Provider pour un événement spécifique
final eventProvider = FutureProvider.family<EventModel, int>((ref, id) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return eventRepository.getEvent(id);
});

// Provider pour les participants d'un événement
final eventParticipantsProvider = FutureProvider.family<List<ParticipantModel>, int>((ref, eventId) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return eventRepository.getEventParticipants(eventId);
});