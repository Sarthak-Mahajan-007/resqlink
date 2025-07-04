import 'dart:convert';

// BLE message model and encoding/decoding
class BleMessage {
  final String id;
  final String type; // e.g. 'SOS', 'RESOURCE', 'GROUP', etc.
  final String senderId;
  final int timestamp;
  final Map<String, dynamic> payload;

  BleMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.timestamp,
    required this.payload,
  });

  // Encode to JSON string for BLE transmission
  String toPayload() {
    final map = {
      'id': id,
      'type': type,
      'sender': senderId,
      'ts': timestamp,
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
      payload: Map<String, dynamic>.from(map['payload']),
    );
  }
} 