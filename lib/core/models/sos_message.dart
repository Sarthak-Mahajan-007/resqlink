import 'dart:convert';

// SOS message data model
class SosMessage {
  final String id; // Unique hash/UUID
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String message;
  final int ttl; // Time-to-live (hops)

  SosMessage({
    required this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.message,
    required this.ttl,
  });

  // Serialize to a compact JSON string for BLE payload
  String toPayload() {
    final map = {
      'id': id,
      'ts': timestamp.millisecondsSinceEpoch,
      'lat': latitude,
      'lng': longitude,
      'msg': message,
      'ttl': ttl,
    };
    return jsonEncode(map);
  }

  // Deserialize from JSON string
  factory SosMessage.fromPayload(String payload) {
    final map = jsonDecode(payload);
    return SosMessage(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts']),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      message: map['msg'],
      ttl: map['ttl'],
    );
  }
} 