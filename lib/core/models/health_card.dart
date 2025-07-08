import 'package:meta/meta.dart';

class HealthCard {
  final int id;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? emergencyContact;
  final DateTime createdAt;

  HealthCard({
    required this.id,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.emergencyContact,
    required this.createdAt,
  });

  factory HealthCard.fromJson(Map<String, dynamic> json) => HealthCard(
        id: json['id'] as int,
        bloodGroup: json['blood_group'] as String?,
        allergies: json['allergies'] as String?,
        medicalConditions: json['medical_conditions'] as String?,
        emergencyContact: json['emergency_contact'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'medical_conditions': medicalConditions,
        'emergency_contact': emergencyContact,
        'created_at': createdAt.toIso8601String(),
      };
} 