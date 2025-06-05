import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/event_provider.dart';
import '../../data/models/event_model.dart';

final eventParticipantsProvider = FutureProvider.family<List<ParticipantModel>, int>((ref, eventId) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return eventRepository.getEventParticipants(eventId);
});

// Provider to cache participant counts
final participantCountProvider = StateProvider.family<AsyncValue<int>, int>((ref, eventId) {
  return ref.watch(eventParticipantsProvider(eventId)).whenData((participants) => participants.length + 1);
});
