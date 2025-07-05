import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink/core/models/group.dart';
import 'package:resqlink/core/models/user_profile.dart';
import 'package:resqlink/core/ble/ble_message.dart';

void main() {
  group('Group Tests', () {
    test('Group creation and member management', () {
      final user = UserProfile(
        id: '1',
        name: 'Test User',
        age: 25,
        bloodGroup: 'O+',
        allergies: [],
        chronicConditions: [],
        emergencyContact: 'Emergency Contact',
        emergencyPhone: '+1234567890',
      );

      final group = Group(
        id: '1',
        name: 'Test Group',
        adminId: user.id,
        members: [
          GroupMember(
            id: user.id,
            name: user.name,
            deviceId: user.id,
            lastSeen: DateTime.now(),
            isOnline: true,
            status: 'OK',
          ),
        ],
        createdAt: DateTime.now(),
        description: 'Test group description',
      );

      expect(group.name, 'Test Group');
      expect(group.members.length, 1);
      expect(group.adminId, user.id);
    });

    test('Group member status update', () {
      final member = GroupMember(
        id: '1',
        name: 'Test Member',
        deviceId: '1',
        lastSeen: DateTime.now(),
        isOnline: true,
        status: 'OK',
      );

      final group = Group(
        id: '1',
        name: 'Test Group',
        adminId: '1',
        members: [member],
        createdAt: DateTime.now(),
      );

      final updatedGroup = group.updateMemberStatus('1', 'SOS');
      final updatedMember = updatedGroup.members.first;

      expect(updatedMember.status, 'SOS');
      expect(updatedMember.isOnline, true);
    });

    test('BLE message creation for groups', () {
      final groupSos = BleMessage.groupSos(
        senderId: '1',
        groupId: '1',
        message: 'Test SOS message',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(groupSos.type, 'GROUP_SOS');
      expect(groupSos.payload['groupId'], '1');
      expect(groupSos.payload['message'], 'Test SOS message');
      expect(groupSos.ttl, 10);
    });

    test('BLE message group status', () {
      final statusMessage = BleMessage.groupStatus(
        senderId: '1',
        groupId: '1',
        status: 'OK',
        latitude: 40.7128,
        longitude: -74.0060,
        customMessage: 'I am safe',
      );

      expect(statusMessage.type, 'GROUP_STATUS');
      expect(statusMessage.payload['status'], 'OK');
      expect(statusMessage.payload['message'], 'I am safe');
      expect(statusMessage.ttl, 3);
    });

    test('BLE message group resource', () {
      final resourceMessage = BleMessage.groupResource(
        senderId: '1',
        groupId: '1',
        resourceType: 'NEED',
        resourceName: 'Water',
        description: 'Need clean water',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(resourceMessage.type, 'GROUP_RESOURCE');
      expect(resourceMessage.payload['resourceType'], 'NEED');
      expect(resourceMessage.payload['resourceName'], 'Water');
      expect(resourceMessage.payload['description'], 'Need clean water');
    });

    test('BLE message serialization and deserialization', () {
      final originalMessage = BleMessage.groupSos(
        senderId: '1',
        groupId: '1',
        message: 'Test message',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      final payload = originalMessage.toPayload();
      final deserializedMessage = BleMessage.fromPayload(payload);

      expect(deserializedMessage.type, originalMessage.type);
      expect(deserializedMessage.senderId, originalMessage.senderId);
      expect(deserializedMessage.payload['groupId'], originalMessage.payload['groupId']);
      expect(deserializedMessage.payload['message'], originalMessage.payload['message']);
    });

    test('Group message filtering', () {
      final message = BleMessage.groupSos(
        senderId: '1',
        groupId: 'group1',
        message: 'Test message',
      );

      expect(message.isForGroup('group1'), true);
      expect(message.isForGroup('group2'), false);
      expect(message.groupId, 'group1');
    });

    test('Message expiration check', () {
      final oldMessage = BleMessage(
        id: '1',
        type: 'GROUP_STATUS',
        senderId: '1',
        timestamp: DateTime.now().millisecondsSinceEpoch - (10 * 60000), // 10 minutes ago
        payload: {'groupId': '1', 'status': 'OK'},
        ttl: 5,
      );

      final newMessage = BleMessage(
        id: '2',
        type: 'GROUP_STATUS',
        senderId: '1',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: {'groupId': '1', 'status': 'OK'},
        ttl: 5,
      );

      expect(oldMessage.isExpired, true);
      expect(newMessage.isExpired, false);
    });
  });
} 