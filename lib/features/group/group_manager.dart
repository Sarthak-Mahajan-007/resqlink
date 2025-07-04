import 'package:uuid/uuid.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart' as my_local;
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await my_local.LocalStorage.saveGroup(group);
    print('Group saved locally');
    // Save to Supabase
    try {
      final supabase = Supabase.instance.client;
      final groupInsert = await supabase.from('groups').insert({
        'name': group.name,
        'admin_id': int.tryParse(group.adminId) ?? -1,
        'description': group.description,
        'created_at': group.createdAt.toIso8601String(),
      }).select().single();
      final groupId = groupInsert['id'];
      // Insert creator as admin member
      await supabase.from('members').insert({
        'group_id': groupId,
        'user_id': int.tryParse(adminProfile.id) ?? -1,
        'role': 'admin',
      });
      print('✅ Group and admin member saved in Supabase');
    } catch (e) {
      print('❌ Error saving group or member in Supabase: $e');
    }
    return group;
  }

  // Fetch group by ID from Supabase
  static Future<Group?> fetchGroupFromSupabase(String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('groups').select().eq('id', groupId).single();
      if (response != null) {
        // You may need to adjust this if your Group.fromJson expects a different structure
        return Group.fromJson(response);
      }
    } catch (e) {
      print('Error fetching group from Supabase: $e');
    }
    return null;
  }

  // Get all groups from Supabase
  static Future<List<Group>> fetchAllGroupsFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('groups').select();
      if (response != null && response is List) {
        return response.map((json) => Group.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching all groups from Supabase: $e');
    }
    return [];
  }

  // Join an existing group (add member locally, optionally update Supabase if you have a members table)
  static Future<Group?> joinGroup({
    required Group group,
    required UserProfile userProfile,
  }) async {
    // Prevent duplicate join (local check)
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
    await my_local.LocalStorage.saveGroup(updatedGroup);
    // Insert into Supabase members table
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('members').insert({
        'group_id': int.tryParse(group.id) ?? -1,
        'user_id': int.tryParse(userProfile.id) ?? -1,
        'role': 'member',
      });
      print('✅ Member added to group in Supabase');
    } catch (e) {
      print('❌ Error adding member to group in Supabase: $e');
    }
    return updatedGroup;
  }

  // Local-only methods remain unchanged
  static List<Group> getAllGroups() {
    final groups = my_local.LocalStorage.getAllGroups();
    print('GroupManager.getAllGroups() called, found ${groups.length} groups');
    for (var group in groups) {
      print('  - ${group.name} (${group.id}) with ${group.members.length} members');
    }
    return groups;
  }

  static Group? getGroup(String groupId) {
    return my_local.LocalStorage.getGroup(groupId);
  }

  static Future<void> deleteGroup(String groupId) async {
    await my_local.LocalStorage.deleteGroup(groupId);
  }
}

void testLocalGroup() async {
  final group = Group(
    id: 'test123',
    name: 'Test Group',
    adminId: 'admin1',
    members: [],
    createdAt: DateTime.now(),
    description: 'desc',
  );
  await my_local.LocalStorage.saveGroup(group);
  final loaded = my_local.LocalStorage.getGroup('test123');
  print('DEBUG: Loaded group: ${loaded?.name}');
} 