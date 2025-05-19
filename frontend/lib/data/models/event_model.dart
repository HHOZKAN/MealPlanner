import 'dart:convert';
import 'user_model.dart';

class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? emoji;
  final DateTime date;
  final String? location;
  final String type;
  final String status;
  final int organizerId;
  final UserModel? organizer;
  final List<ParticipantModel>? participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  EventModel({
    required this.id,
    required this.title,
        required this.emoji, 
    this.description,
    required this.date,
    this.location,
    required this.type,
    required this.status,
    required this.organizerId,
    this.organizer,
    this.participants,
    this.createdAt,
    this.updatedAt,
  });
  
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      emoji: json['emoji'] ?? '🍽️',
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      type: json['type'],
      status: json['status'],
      organizerId: json['organizer_id'],
      organizer: json['organizer'] != null 
          ? UserModel.fromJson(json['organizer']) 
          : null,
      participants: json['participants'] != null 
          ? List<ParticipantModel>.from(
              json['participants'].map((x) => ParticipantModel.fromJson(x))
            )
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'type': type,
      'status': status,
      'organizer_id': organizerId,
      'organizer': organizer?.toJson(),
      'participants': participants?.map((x) => x.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class ParticipantModel {
  final int id;
  final int eventId;
  final int userId;
  final String status;
  final DateTime? respondedAt;
  final String? note;
  final UserModel? user;
  
  ParticipantModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.respondedAt,
    this.note,
    this.user,
  });
  
  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      status: json['status'],
      respondedAt: json['responded_at'] != null 
          ? DateTime.parse(json['responded_at']) 
          : null,
      note: json['note'],
      user: json['user'] != null 
          ? UserModel.fromJson(json['user']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'status': status,
      'responded_at': respondedAt?.toIso8601String(),
      'note': note,
      'user': user?.toJson(),
    };
  }
}