import 'dart:convert';

class GroupMember {
  final String id;
  final String name;
  final String deviceId;
  final DateTime lastSeen;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final String status; // "OK", "SOS", "Unknown"

  GroupMember({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.lastSeen,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.status = "Unknown",
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      name: json['name'],
      deviceId: json['deviceId'],
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen']),
      isOnline: json['isOnline'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      status: json['status'],
    );
  }
}

class Group {
  final String id;
  final String name;
  final String adminId;
  final List<GroupMember> members;
  final DateTime createdAt;
  final String description;

  Group({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
    required this.createdAt,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'description': description,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      adminId: json['adminId'],
      members: (json['members'] as List)
          .map((m) => GroupMember.fromJson(m))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      description: json['description'] ?? '',
    );
  }

  // Add member to group
  Group addMember(GroupMember member) {
    final updatedMembers = List<GroupMember>.from(members);
    updatedMembers.add(member);
    return Group(
      id: id,
      name: name,
      adminId: adminId,
      members: updatedMembers,
      createdAt: createdAt,
      description: description,
    );
  }

  // Update member status
  Group updateMemberStatus(String memberId, String status, {double? lat, double? lng}) {
    final updatedMembers = members.map((member) {
      if (member.id == memberId) {
        return GroupMember(
          id: member.id,
          name: member.name,
          deviceId: member.deviceId,
          lastSeen: DateTime.now(),
          isOnline: true,
          latitude: lat ?? member.latitude,
          longitude: lng ?? member.longitude,
          status: status,
        );
      }
      return member;
    }).toList();

    return Group(
      id: id,
      name: name,
      adminId: adminId,
      members: updatedMembers,
      createdAt: createdAt,
      description: description,
    );
  }
} 