import 'dart:convert';

enum ResourceType {
  need,
  offer,
}

enum ResourceCategory {
  medical,
  food,
  water,
  shelter,
  transportation,
  communication,
  other,
}

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final ResourceCategory category;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final int ttl;
  final bool isUrgent;
  final Map<String, dynamic> metadata;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.ttl,
    this.isUrgent = false,
    this.metadata = const {},
  });

  // Serialize to compact JSON for BLE payload
  String toPayload() {
    final map = {
      'id': id,
      'title': title,
      'desc': description,
      'type': type.index,
      'cat': category.index,
      'uid': userId,
      'ts': timestamp.millisecondsSinceEpoch,
      'lat': latitude,
      'lng': longitude,
      'ttl': ttl,
      'urgent': isUrgent,
    };
    return jsonEncode(map);
  }

  // Deserialize from JSON string
  factory ResourceModel.fromPayload(String payload) {
    final map = jsonDecode(payload);
    return ResourceModel(
      id: map['id'],
      title: map['title'],
      description: map['desc'],
      type: ResourceType.values[map['type']],
      category: ResourceCategory.values[map['cat']],
      userId: map['uid'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts']),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      ttl: map['ttl'],
      isUrgent: map['urgent'] ?? false,
    );
  }

  // Create a copy with updated TTL for relay
  ResourceModel withDecrementedTtl() {
    return ResourceModel(
      id: id,
      title: title,
      description: description,
      type: type,
      category: category,
      userId: userId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      ttl: ttl - 1,
      isUrgent: isUrgent,
      metadata: metadata,
    );
  }

  // Get category display name
  String get categoryName {
    switch (category) {
      case ResourceCategory.medical:
        return 'Medical';
      case ResourceCategory.food:
        return 'Food';
      case ResourceCategory.water:
        return 'Water';
      case ResourceCategory.shelter:
        return 'Shelter';
      case ResourceCategory.transportation:
        return 'Transportation';
      case ResourceCategory.communication:
        return 'Communication';
      case ResourceCategory.other:
        return 'Other';
    }
  }

  // Get type display name
  String get typeName {
    return type == ResourceType.need ? 'Need' : 'Offer';
  }
} 