import 'dart:convert';

// BLE message model and encoding/decoding
class BleMessage {
  final String id;
  final String type; // e.g. 'SOS', 'RESOURCE', 'GROUP_SOS', 'GROUP_STATUS', 'GROUP_RESOURCE', etc.
  final String senderId;
  final int timestamp;
  final Map<String, dynamic> payload;
  final int ttl; // Time-to-live for message propagation

  BleMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.timestamp,
    required this.payload,
    this.ttl = 5, // Default TTL for group messages
  });

  // Encode to JSON string for BLE transmission
  String toPayload() {
    final map = {
      'id': id,
      'type': type,
      'sender': senderId,
      'ts': timestamp,
      'ttl': ttl,
      'payload': payload,
    };
    return jsonEncode(map);
  }

  // Decode from JSON string
  factory BleMessage.fromPayload(String payloadStr) {
    final map = jsonDecode(payloadStr);
    return BleMessage(
      id: map['id'],
      type: map['type'],
      senderId: map['sender'],
      timestamp: map['ts'],
      ttl: map['ttl'] ?? 5,
      payload: Map<String, dynamic>.from(map['payload']),
    );
  }

  // Create a group SOS message
  factory BleMessage.groupSos({
    required String senderId,
    required String groupId,
    required String message,
    double? latitude,
    double? longitude,
    int ttl = 10, // Higher TTL for SOS messages
  }) {
    return BleMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${senderId}_group_sos',
      type: 'GROUP_SOS',
      senderId: senderId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: ttl,
      payload: {
        'groupId': groupId,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Create a group status update message
  factory BleMessage.groupStatus({
    required String senderId,
    required String groupId,
    required String status, // 'OK', 'SOS', 'HELP', 'OFFLINE'
    double? latitude,
    double? longitude,
    String? customMessage,
  }) {
    return BleMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${senderId}_status',
      type: 'GROUP_STATUS',
      senderId: senderId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: 3, // Lower TTL for status updates
      payload: {
        'groupId': groupId,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'message': customMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Create a group resource message
  factory BleMessage.groupResource({
    required String senderId,
    required String groupId,
    required String resourceType, // 'NEED', 'OFFER'
    required String resourceName,
    String? description,
    double? latitude,
    double? longitude,
  }) {
    return BleMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${senderId}_resource',
      type: 'GROUP_RESOURCE',
      senderId: senderId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: 5,
      payload: {
        'groupId': groupId,
        'resourceType': resourceType,
        'resourceName': resourceName,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Create a group health check message
  factory BleMessage.groupHealthCheck({
    required String senderId,
    required String groupId,
    required bool isAlive,
    String? status,
  }) {
    return BleMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${senderId}_health',
      type: 'GROUP_HEALTH',
      senderId: senderId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttl: 2, // Very low TTL for health checks
      payload: {
        'groupId': groupId,
        'isAlive': isAlive,
        'status': status ?? 'OK',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Check if message is for a specific group
  bool isForGroup(String groupId) {
    return payload['groupId'] == groupId;
  }

  // Get group ID from message
  String? get groupId => payload['groupId'];

  // Check if message is expired
  bool get isExpired {
    final messageAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    return messageAge > (ttl * 60000); // TTL in minutes
  }
} 