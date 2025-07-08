import 'package:uuid/uuid.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart' as my_local;
import '../../core/ble/ble_mesh_service.dart';
import '../../core/ble/ble_message.dart';
import '../../core/utils/location_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class GroupManager {
  static final Uuid _uuid = Uuid();
  static final BleMeshService _bleMeshService = BleMeshService();
  
  // Callbacks for UI updates
  static Function(Group)? _onGroupUpdated;
  static Function(BleMessage)? _onGroupMessage;
  static Function(BleMessage)? _onGroupSos;
  
  // Timer for periodic health checks
  static Timer? _healthCheckTimer;
  
  // User's active groups
  static List<Group> _activeGroups = [];
  static UserProfile? _currentUser;

  // Initialize group manager with user profile
  static Future<void> initialize(UserProfile userProfile) async {
    _currentUser = userProfile;
    _activeGroups = await _loadUserGroups(userProfile.id);
    
    // Set up BLE mesh service
    _bleMeshService.setUserProfile(
      userProfile, 
      _activeGroups.map((g) => g.id).toList()
    );
    
    // Set up group message callbacks
    _bleMeshService.setGroupCallbacks(
      onGroupMessage: _onGroupMessage,
      onGroupSos: _onGroupSos,
      onGroupStatus: (message) => _handleGroupStatusUpdate(message),
      onGroupResource: (message) => _handleGroupResourceUpdate(message),
    );
    
    // Start periodic health checks
    _startHealthChecks();
  }

  // Set callbacks for UI updates
  static void setCallbacks({
    Function(Group)? onGroupUpdated,
    Function(BleMessage)? onGroupMessage,
    Function(BleMessage)? onGroupSos,
  }) {
    _onGroupUpdated = onGroupUpdated;
    _onGroupMessage = onGroupMessage;
    _onGroupSos = onGroupSos;
  }

  // Create a new group
  static Future<Group> createGroup({
    required String name,
    required UserProfile adminProfile,
    String description = '',
  }) async {
    final groupUuid = _uuid.v4();
    final group = Group(
      id: groupUuid,
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
    
    // Add to active groups
    _activeGroups.add(group);
    _updateBleMeshGroups();
    
    // Save to Supabase
    try {
      final supabase = Supabase.instance.client;
      final userId = int.tryParse(adminProfile.id) ?? -1;
      // Insert user if not exists
      try {
        final existingUser = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (existingUser == null) {
          await supabase.from('users').insert({
            'id': userId,
            'name': adminProfile.name,
            'email': adminProfile.email ?? '',
            'created_at': DateTime.now().toIso8601String(),
          });
          print('[DEBUG] Inserted new user $userId');
        }
      } catch (e) {
        print('[ERROR] Failed to insert/check user: $e');
      }
      // Insert group
      final groupInsert = await supabase.from('groups').insert({
        'id': groupUuid,
        'name': group.name,
        'admin_id': adminProfile.id,
        'description': group.description,
        'created_at': group.createdAt.toIso8601String(),
        'encryption_key': '',
      }).select().single();
      // Insert creator as admin member
      try {
        await supabase.from('members').insert({
          'user_id': userId,
          'group_id': groupUuid,
          'role': 'admin',
          'status': 'OK',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('[DEBUG] Inserted admin member $userId for group $groupUuid');
      } catch (e) {
        print('[ERROR] Failed to insert admin member: $e');
      }
      print('✅ Group and admin member saved in Supabase');
    } catch (e) {
      print('❌ Error saving group or member in Supabase: $e');
    }
    return group;
  }

  // Send SOS to all group members
  static Future<void> sendGroupSos(String groupId, String message) async {
    if (_currentUser == null) {
      print('Error: User not initialized for group SOS');
      return;
    }
    
    try {
      // Get current location
      final position = await LocationUtils.getCurrentLocation();
      
      // Send via BLE mesh (for local/offline use)
      await _bleMeshService.sendGroupSos(
        groupId,
        message,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      
      // Update local group status
      final group = _activeGroups.firstWhere((g) => g.id == groupId);
      final updatedGroup = group.updateMemberStatus(
        _currentUser!.id,
        'SOS',
        lat: position?.latitude,
        lng: position?.longitude,
      );
      _updateGroup(updatedGroup);
      
      // --- Supabase: Send SOS to all group members ---
      final supabase = Supabase.instance.client;
      final senderId = int.tryParse(_currentUser!.id) ?? -1;
      final now = DateTime.now();
      for (final member in group.members) {
        if (member.id == _currentUser!.id) continue; // Don't send to self
        await supabase.from('sos_messages').insert({
          'group_id': groupId,
          'sender_id': senderId,
          'recipient_id': int.tryParse(member.id) ?? -1,
          'message': message,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'timestamp': now.toIso8601String(),
        });
      }
      print('✅ Group SOS sent to all group members via Supabase');
    } catch (e) {
      print('❌ Error sending group SOS: $e');
    }
  }

  // Send status update to group
  static Future<void> sendGroupStatus(String groupId, String status, {String? customMessage}) async {
    if (_currentUser == null) {
      print('Error: User not initialized for group status');
      return;
    }
    
    try {
      // Get current location
      final position = await LocationUtils.getCurrentLocation();
      
      // Send via BLE mesh
      await _bleMeshService.sendGroupStatus(
        groupId,
        status,
        lat: position?.latitude,
        lng: position?.longitude,
        customMessage: customMessage,
      );
      
      // Update local group status
      final group = _activeGroups.firstWhere((g) => g.id == groupId);
      final updatedGroup = group.updateMemberStatus(
        _currentUser!.id,
        status,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      
      _updateGroup(updatedGroup);
      
      print('✅ Group status sent: $status');
    } catch (e) {
      print('❌ Error sending group status: $e');
    }
  }

  // Send resource offer/need to group
  static Future<void> sendGroupResource(String groupId, String resourceType, String resourceName, {String? description}) async {
    if (_currentUser == null) {
      print('Error: User not initialized for group resource');
      return;
    }
    
    try {
      // Get current location
      final position = await LocationUtils.getCurrentLocation();
      
      // Send via BLE mesh
      await _bleMeshService.sendGroupResource(
        groupId,
        resourceType,
        resourceName,
        description: description,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      
      print('✅ Group resource sent: $resourceType $resourceName');
    } catch (e) {
      print('❌ Error sending group resource: $e');
    }
  }

  // Handle incoming group status updates
  static void _handleGroupStatusUpdate(BleMessage message) {
    try {
      final groupId = message.groupId;
      if (groupId == null) return;
      
      final group = _activeGroups.firstWhere((g) => g.id == groupId);
      final senderId = message.senderId;
      final status = message.payload['status'] as String? ?? 'Unknown';
      final lat = message.payload['latitude'] as double?;
      final lng = message.payload['longitude'] as double?;
      
      // Update member status
      final updatedGroup = group.updateMemberStatus(
        senderId,
        status,
        lat: lat,
        lng: lng,
      );
      
      _updateGroup(updatedGroup);
      
      // Notify UI
      _onGroupMessage?.call(message);
    } catch (e) {
      print('❌ Error handling group status update: $e');
    }
  }

  // Handle incoming group resource updates
  static void _handleGroupResourceUpdate(BleMessage message) {
    try {
      // Store resource message in local storage for UI display
      // This could be used in a resource feed or notifications
      print('Received group resource: ${message.payload['resourceType']} ${message.payload['resourceName']}');
      
      // Notify UI
      _onGroupMessage?.call(message);
    } catch (e) {
      print('❌ Error handling group resource update: $e');
    }
  }

  // Start periodic health checks for all groups
  static void _startHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendHealthChecks();
    });
  }

  // Send health checks to all active groups
  static Future<void> _sendHealthChecks() async {
    if (_currentUser == null) return;
    
    for (final group in _activeGroups) {
      try {
        await _bleMeshService.sendGroupHealthCheck(group.id);
        print('Health check sent to group: ${group.name}');
      } catch (e) {
        print('Error sending health check to group ${group.name}: $e');
      }
    }
  }

  // Update group in local storage and notify UI
  static void _updateGroup(Group updatedGroup) {
    // Update in active groups list
    final index = _activeGroups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      _activeGroups[index] = updatedGroup;
    }
    
    // Save to local storage
    my_local.LocalStorage.saveGroup(updatedGroup);
    
    // Notify UI
    _onGroupUpdated?.call(updatedGroup);
  }

  // Update BLE mesh service with current group list
  static void _updateBleMeshGroups() {
    if (_currentUser != null) {
      _bleMeshService.setUserProfile(
        _currentUser!,
        _activeGroups.map((g) => g.id).toList(),
      );
    }
  }

  // Load user's groups from local storage and Supabase
  static Future<List<Group>> _loadUserGroups(String userId) async {
    try {
      print('[DEBUG] Loading user groups for userId: $userId');
      final supabase = Supabase.instance.client;
      // 1. Get all group_ids for this user from members table
      final memberRows = await supabase
          .from('members')
          .select('group_id')
          .eq('user_id', int.tryParse(userId) ?? -1);
      print('[DEBUG] memberRows: ' + memberRows.toString());
      final groupIds = memberRows.map((row) => row['group_id'].toString()).toList();
      print('[DEBUG] groupIds: ' + groupIds.toString());
      List<Group> userGroups = [];
      if (groupIds.isNotEmpty) {
        // 2. Only fetch groups where id is in groupIds
        final groupsResponse = await supabase
            .from('groups')
            .select()
            .inFilter('id', groupIds);
        print('[DEBUG] groupsResponse: ' + groupsResponse.toString());
        userGroups = await Future.wait(groupsResponse.map<Future<Group>>((g) async {
          // Fetch members for this group
          final memberList = await supabase
            .from('members')
            .select('user_id, role, status, latitude, longitude, created_at')
            .eq('group_id', g['id']);
          List<GroupMember> members = [];
          if (memberList.isNotEmpty) {
            final userIds = memberList.map((m) => m['user_id']).toList();
            final usersResponse = await supabase
              .from('users')
              .select()
              .inFilter('id', userIds);
            members = usersResponse.map<GroupMember>((u) {
              final memberRow = memberList.firstWhere((m) => m['user_id'] == u['id'], orElse: () => {});
              return GroupMember(
                id: u['id'].toString(),
                name: u['name'] ?? '',
                deviceId: u['id'].toString(),
                lastSeen: memberRow['created_at'] != null ? DateTime.tryParse(memberRow['created_at']) ?? DateTime.now() : DateTime.now(),
                isOnline: false,
                latitude: memberRow['latitude'],
                longitude: memberRow['longitude'],
                status: memberRow['status'] ?? 'Unknown',
              );
            }).toList();
          }
          return Group(
            id: g['id'].toString(),
            name: g['name'] ?? '',
            adminId: g['admin_id']?.toString() ?? '',
            members: members,
            createdAt: g['created_at'] != null && g['created_at'] != 'NULL'
                ? DateTime.tryParse(g['created_at']) ?? DateTime.now()
                : DateTime.now(),
            description: g['description'] ?? '',
          );
        }));
      }
      print('[DEBUG] userGroups loaded: ' + userGroups.length.toString());
      return userGroups;
    } catch (e) {
      print('Error loading user groups: $e');
      // fallback: return empty list, do not fetch all groups
      return [];
    }
  }

  // Get all active groups
  static List<Group> getActiveGroups() {
    return List.from(_activeGroups);
  }

  // Get specific group
  static Group? getGroup(String groupId) {
    try {
      return _activeGroups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
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
    
    await my_local.LocalStorage.saveGroup(updatedGroup);
    
    // Add to active groups if not already there
    if (!_activeGroups.any((g) => g.id == group.id)) {
      _activeGroups.add(updatedGroup);
      _updateBleMeshGroups();
    }
    
    // Insert into Supabase users and members table
    try {
      final supabase = Supabase.instance.client;
      final userId = int.tryParse(userProfile.id) ?? -1;
      // Insert user if not exists
      try {
        final existingUser = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (existingUser == null) {
          await supabase.from('users').insert({
            'id': userId,
            'name': userProfile.name,
            'email': userProfile.email ?? '',
            'created_at': DateTime.now().toIso8601String(),
          });
          print('[DEBUG] Inserted new user $userId');
        }
      } catch (e) {
        print('[ERROR] Failed to insert/check user: $e');
      }
      // Insert member
      try {
        await supabase.from('members').insert({
          'group_id': group.id, // UUID
          'user_id': userId,
          'role': 'member',
          'status': 'OK',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('[DEBUG] Inserted member $userId for group ${group.id}');
      } catch (e) {
        print('[ERROR] Failed to insert member: $e');
      }
      print('✅ Member added to group in Supabase');
    } catch (e) {
      print('❌ Error adding member to group in Supabase: $e');
    }
    
    return updatedGroup;
  }

  // Leave a group
  static Future<void> leaveGroup(String groupId) async {
    try {
      // Remove from active groups
      _activeGroups.removeWhere((g) => g.id == groupId);
      _updateBleMeshGroups();
      
      // Remove from Supabase
      if (_currentUser != null) {
        final supabase = Supabase.instance.client;
        await supabase
            .from('members')
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', int.tryParse(_currentUser!.id) ?? -1);
      }
      
      print('✅ Left group: $groupId');
    } catch (e) {
      print('❌ Error leaving group: $e');
    }
  }

  // Delete a group (admin only)
  static Future<void> deleteGroup(String groupId) async {
    try {
      // Remove from active groups
      _activeGroups.removeWhere((g) => g.id == groupId);
      _updateBleMeshGroups();
      
      // Delete from local storage
      await my_local.LocalStorage.deleteGroup(groupId);
      
      // Delete from Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('groups').delete().eq('id', groupId);
      await supabase.from('members').delete().eq('group_id', groupId);
      
      print('✅ Deleted group: $groupId');
    } catch (e) {
      print('❌ Error deleting group: $e');
    }
  }

  // Get BLE mesh service for direct access
  static BleMeshService get bleMeshService => _bleMeshService;

  // Cleanup resources
  static void dispose() {
    _healthCheckTimer?.cancel();
    _bleMeshService.stop();
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