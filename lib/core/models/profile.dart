import 'package:meta/meta.dart';
import 'health_card.dart';

class Profile {
  final int id;
  final int userId;
  final int? healthCardId;
  final String? bio;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final HealthCard? healthCard;

  Profile({
    required this.id,
    required this.userId,
    this.healthCardId,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    this.healthCard,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        healthCardId: json['health_card_id'] as int?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
        gender: json['gender'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        healthCard: json['health_card'] != null ? HealthCard.fromJson(json['health_card']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'health_card_id': healthCardId,
        'bio': bio,
        'avatar_url': avatarUrl,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'created_at': createdAt.toIso8601String(),
        'health_card': healthCard?.toJson(),
      };
} 