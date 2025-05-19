import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final dynamic preferences; 
  final bool isActive;
  final String? avatarUrl;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.avatar,
    this.preferences,
    this.isActive = true,
    this.avatarUrl,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
      preferences: json['preferences'],
      isActive: json['is_active'] ?? true,
      avatarUrl: json['avatar_url'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'preferences': preferences,
      'is_active': isActive,
      'avatar_url': avatarUrl,
    };
  }
  
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}