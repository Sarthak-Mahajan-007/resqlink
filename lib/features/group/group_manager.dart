import 'package:uuid/uuid.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart';

class GroupManager {
  static final Uuid _uuid = Uuid();

  // Create a new group
  static Future<Group> createGroup({
    required String name,
    required UserProfile adminProfile,
    String description = '',
  }) async {
    final group = Group(
      id: _uuid.v4(),
      name: name,
      adminId: adminProfile.id,
      members: [
        GroupMember(
          id: adminProfile.id,
          name: adminProfile.name,
          deviceId: adminProfile.id, // Use device/user id
          lastSeen: DateTime.now(),
          isOnline: true,
          latitude: null,
          longitude: null,
          status: 'OK',
        ),
      ],
      createdAt: DateTime.now(),
      description: description,
    );
    
    print('Creating group: ${group.name} (${group.id})');
    await LocalStorage.saveGroup(group);
    print('Group saved successfully');
    
    // Verify the group was saved
    final savedGroup = LocalStorage.getGroup(group.id);
    if (savedGroup != null) {
      print('Group verified in storage: ${savedGroup.name}');
    } else {
      print('ERROR: Group not found in storage after saving!');
    }
    
    return group;
  }

  // Join an existing group
  static Future<Group?> joinGroup({
    required Group group,
    required UserProfile userProfile,
  }) async {
    // Prevent duplicate join
    if (group.members.any((m) => m.id == userProfile.id)) {
      return group;
    }
    final updatedGroup = group.addMember(
      GroupMember(
        id: userProfile.id,
        name: userProfile.name,
        deviceId: userProfile.id,
        lastSeen: DateTime.now(),
        isOnline: true,
        latitude: null,
        longitude: null,
        status: 'OK',
      ),
    );
    await LocalStorage.saveGroup(updatedGroup);
    return updatedGroup;
  }

  // Get all groups
  static List<Group> getAllGroups() {
    final groups = LocalStorage.getAllGroups();
    print('GroupManager.getAllGroups() called, found ${groups.length} groups');
    for (var group in groups) {
      print('  - ${group.name} (${group.id}) with ${group.members.length} members');
    }
    return groups;
  }

  // Get a group by ID
  static Group? getGroup(String groupId) {
    return LocalStorage.getGroup(groupId);
  }

  // Update member status in a group
  static Future<Group?> updateMemberStatus({
    required String groupId,
    required String memberId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    final group = LocalStorage.getGroup(groupId);
    if (group == null) return null;
    final updatedGroup = group.updateMemberStatus(
      memberId,
      status,
      lat: latitude,
      lng: longitude,
    );
    await LocalStorage.saveGroup(updatedGroup);
    return updatedGroup;
  }

  // Remove a group
  static Future<void> deleteGroup(String groupId) async {
    await LocalStorage.deleteGroup(groupId);
  }
} 