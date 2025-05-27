import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/event_model.dart';

class EventRepository {
  final DioClient _dioClient;

  EventRepository(this._dioClient);

  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _dioClient.get(ApiConstants.events);

      final data = response.data;

      if (data['status'] == 'success') {
        return List<EventModel>.from(
            data['data'].map((x) => EventModel.fromJson(x)));
      } else {
        throw Exception(
            data['message'] ?? 'Erreur lors de la récupération des événements');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ??
            'Erreur lors de la récupération des événements');
      }
      throw Exception('Erreur lors de la récupération des événements');
    }
  }

 Future<EventModel> getEvent(int id) async {
  try {
    final url = '${ApiConstants.events}/$id';
    print('Fetching event details from: ${ApiConstants.baseUrl}$url');
    
    final response = await _dioClient.get(url);

    final data = response.data;
    
    if (data['status'] == 'success') {
      return EventModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Erreur lors de la récupération de l\'événement');
    }
  } catch (e) {
    if (e is DioException) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      final data = e.response?.data;
      if (e.response?.statusCode == 404) {
        throw Exception('Événement non trouvé. Vérifiez l\'identifiant de l\'événement.');
      }
      throw Exception(data?['message'] ?? 'Erreur lors de la récupération de l\'événement');
    }
    print('Error fetching event: $e');
    throw Exception('Erreur lors de la récupération de l\'événement: ${e.toString()}');
  }
}

  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime date,
    String? location,
    required String type,
    String? emoji,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.events,
        data: {
          'title': title,
          'description': description,
          'date': date.toIso8601String(),
          'location': location,
          'type': type,
          'emoji': emoji,
        },
      );

      final data = response.data;

      if (data['status'] == 'success') {
        return EventModel.fromJson(data['data']);
      } else {
        throw Exception(
            data['message'] ?? 'Erreur lors de la création de l\'événement');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(
            data?['message'] ?? 'Erreur lors de la création de l\'événement');
      }
      throw Exception('Erreur lors de la création de l\'événement');
    }
  }

  Future<EventModel> updateEvent({
    required int id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? type,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (date != null) data['date'] = date.toIso8601String();
      if (location != null) data['location'] = location;
      if (type != null) data['type'] = type;
      if (status != null) data['status'] = status;

      final response = await _dioClient.put(
        '${ApiConstants.events}/$id',
        data: data,
      );

      final responseData = response.data;

      if (responseData['status'] == 'success') {
        return EventModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ??
            'Erreur lors de la mise à jour de l\'événement');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ??
            'Erreur lors de la mise à jour de l\'événement');
      }
      throw Exception('Erreur lors de la mise à jour de l\'événement');
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final response = await _dioClient.delete('${ApiConstants.events}/$id');

      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(
            data['message'] ?? 'Erreur lors de la suppression de l\'événement');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ??
            'Erreur lors de la suppression de l\'événement');
      }
      throw Exception('Erreur lors de la suppression de l\'événement');
    }
  }

  Future<List<ParticipantModel>> getEventParticipants(int eventId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.eventParticipants.replaceAll('{id}', eventId.toString()),
      );

      final data = response.data;

      if (data['status'] == 'success') {
        return List<ParticipantModel>.from(data['data']['participants']
            .map((x) => ParticipantModel.fromJson(x)));
      } else {
        throw Exception(data['message'] ??
            'Erreur lors de la récupération des participants');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(data?['message'] ??
            'Erreur lors de la récupération des participants');
      }
      throw Exception('Erreur lors de la récupération des participants');
    }
  }

  Future<void> inviteParticipant({
    required int eventId,
    required String email,
    String? message,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.eventParticipants.replaceAll('{id}', eventId.toString()) +
            '/invite',
        data: {
          'email': email,
          'message': message,
        },
      );

      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(
            data['message'] ?? 'Erreur lors de l\'invitation du participant');
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        throw Exception(
            data?['message'] ?? 'Erreur lors de l\'invitation du participant');
      }
      throw Exception(
          'Erreur lors de l\'invitation du participant: ${e.toString()}');
    }
  }
}
