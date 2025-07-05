import 'dart:convert';

// User health card/profile model
class UserProfile {
  final String id;
  final String name;
  final int age;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String emergencyContact;
  final String emergencyPhone;
  final String? email;
  final String notes;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.email,
    this.notes = '',
  });

  // Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'email': email,
      'notes': notes,
    };
  }

  // Deserialize from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      bloodGroup: json['bloodGroup'],
      allergies: List<String>.from(json['allergies'] ?? []),
      chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
      emergencyContact: json['emergencyContact'],
      emergencyPhone: json['emergencyPhone'],
      email: json['email'],
      notes: json['notes'] ?? '',
    );
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? name,
    int? age,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? emergencyContact,
    String? emergencyPhone,
    String? email,
    String? notes,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }
} 