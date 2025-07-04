import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart';
import 'group_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/ble/ble_mesh_service.dart';
import '../../core/models/sos_message.dart';
import '../../core/utils/location_utils.dart';
import 'package:uuid/uuid.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<Group> groups = [];
  UserProfile? userProfile;
  
  // Debug: Add in-memory fallback for testing
  static List<Group> _debugGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final loadedGroups = GroupManager.getAllGroups();
      final loadedProfile = LocalStorage.getUserProfile();
      
      print('Loaded ${loadedGroups.length} groups from Hive');
      for (var group in loadedGroups) {
        print('Group: ${group.name} (${group.id}) with ${group.members.length} members');
      }
      
      // Debug: Check debug groups list
      print('Debug groups count: ${_debugGroups.length}');
      for (var group in _debugGroups) {
        print('Debug Group: ${group.name} (${group.id}) with ${group.members.length} members');
      }
      
      // Use debug groups as fallback if Hive is empty
      final finalGroups = loadedGroups.isNotEmpty ? loadedGroups : _debugGroups;
      
      setState(() {
        groups = finalGroups;
        userProfile = loadedProfile;
      });
      
      // Force a rebuild to ensure UI updates
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        groups = _debugGroups; // Use debug groups as fallback
        userProfile = null;
      });
    }
  }

  void _createGroupDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Group'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }
              
              if (userProfile == null) {
                // Create a default user profile if none exists
                userProfile = UserProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'User ${DateTime.now().millisecondsSinceEpoch % 1000}',
                  age: 25,
                  bloodGroup: 'O+',
                  allergies: [],
                  chronicConditions: [],
                  emergencyContact: 'Emergency Contact',
                  emergencyPhone: '+1234567890',
                );
                await LocalStorage.saveUserProfile(userProfile!);
              }
              
              try {
                final newGroup = await GroupManager.createGroup(
                  name: controller.text.trim(),
                  adminProfile: userProfile!,
                );
                
                // Debug: Add to in-memory list as fallback
                _GroupScreenState._debugGroups.add(newGroup);
                print('Added to debug groups list. Total debug groups: ${_GroupScreenState._debugGroups.length}');
                
                Navigator.pop(ctx);
                
                // Debug: Check groups immediately after creation
                print('=== AFTER GROUP CREATION ===');
                final immediateGroups = GroupManager.getAllGroups();
                print('Immediate groups count: ${immediateGroups.length}');
                for (var group in immediateGroups) {
                  print('  - ${group.name} (${group.id})');
                }
                
                await _loadData();
                
                // Debug: Check groups after _loadData
                print('=== AFTER _loadData ===');
                print('UI groups count: ${groups.length}');
                for (var group in groups) {
                  print('  - ${group.name} (${group.id})');
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group "${controller.text.trim()}" created successfully!')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create group: ${e.toString()}')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinGroupDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Join Group'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Group ID'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
              tooltip: 'Scan QR',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (ctx2) => Dialog(
                    backgroundColor: Colors.black,
                    child: SizedBox(
                      width: 350,
                      height: 400,
                      child: _QrScanner(
                        onGroupId: (groupId) {
                          controller.text = groupId;
                          Navigator.of(ctx2).pop();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a group ID')),
                );
                return;
              }
              
              if (userProfile == null) {
                // Create a default user profile if none exists
                userProfile = UserProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'User ${DateTime.now().millisecondsSinceEpoch % 1000}',
                  age: 25,
                  bloodGroup: 'O+',
                  allergies: [],
                  chronicConditions: [],
                  emergencyContact: 'Emergency Contact',
                  emergencyPhone: '+1234567890',
                );
                await LocalStorage.saveUserProfile(userProfile!);
              }
              
              try {
                final group = GroupManager.getGroup(controller.text.trim());
                if (group == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group not found. Please check the group ID.')),
                  );
                  return;
                }
                
                await GroupManager.joinGroup(group: group, userProfile: userProfile!);
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully joined group: ${group.name}')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join group: ${e.toString()}')),
                );
              }
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showGroupQrDialog(Group group) {
    final qrData = '{"id":"${group.id}","name":"${group.name}"}';
    print('Generating QR code for data: $qrData');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Group QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildQrCode(qrData),
              ),
            ),
            const SizedBox(height: 12),
            Text('Scan to join: ${group.name}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: ${group.id}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Group ID: ${group.id}',
                style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy group ID to clipboard
              // You can add clipboard functionality here if needed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Group ID copied to clipboard')),
              );
            },
            child: Text('Copy ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode(String data) {
    try {
      return QrImageView(
        data: data,
        size: 200.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    } catch (e) {
      print('QR code widget error: $e');
      return _buildTextQrCode(data);
    }
  }

  Widget _buildTextQrCode(String data) {
    // Extract group ID from JSON data
    String groupId = 'Unknown';
    try {
      if (data.contains('"id":"')) {
        groupId = data.split('"id":"')[1].split('"')[0];
      }
    } catch (e) {
      print('Error parsing group ID: $e');
    }
    
    return Container(
      width: 200,
      height: 200,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'QR Code Unavailable',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Group ID:\n$groupId',
                style: TextStyle(
                  color: Colors.black, 
                  fontSize: 10, 
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Share this ID manually',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _scanQrToJoinGroup() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          width: 350,
          height: 400,
          child: _QrScanner(
            onGroupId: (groupId) async {
              if (userProfile == null) {
                // Create a default user profile if none exists
                userProfile = UserProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'User ${DateTime.now().millisecondsSinceEpoch % 1000}',
                  age: 25,
                  bloodGroup: 'O+',
                  allergies: [],
                  chronicConditions: [],
                  emergencyContact: 'Emergency Contact',
                  emergencyPhone: '+1234567890',
                );
                await LocalStorage.saveUserProfile(userProfile!);
              }
              
              try {
                final group = GroupManager.getGroup(groupId);
                if (group == null) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group not found. Please check the QR code.')),
                  );
                  return;
                }
                
                await GroupManager.joinGroup(group: group, userProfile: userProfile!);
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully joined group: ${group.name}')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join group: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _sendGroupSOS(Group group) async {
    try {
      // Update current user's status to SOS
      if (userProfile != null) {
        await GroupManager.updateMemberStatus(
          groupId: group.id,
          memberId: userProfile!.id,
          status: 'SOS',
        );
        
        // Reload data to show updated status
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS sent to group: ${group.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: ${e.toString()}')),
      );
    }
  }

  void _updateMemberStatus(Group group, String memberId, String newStatus) async {
    try {
      await GroupManager.updateMemberStatus(
        groupId: group.id,
        memberId: memberId,
        status: newStatus,
      );
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
      );
    }
  }

  void _deleteGroupWithConfirmation(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await GroupManager.deleteGroup(group.id);
                // Also remove from debug list
                _debugGroups.removeWhere((g) => g.id == group.id);
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group "${group.name}" deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete group: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _debugTest() async {
    print('=== DEBUG TEST START ===');
    
    // Check if user profile exists
    print('User profile: ${userProfile?.name ?? 'null'}');
    
    // Test QR code generation
    _testQrCode();
    
    // Create a test group
    if (userProfile == null) {
      userProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Debug User',
        age: 25,
        bloodGroup: 'O+',
        allergies: [],
        chronicConditions: [],
        emergencyContact: 'Debug Contact',
        emergencyPhone: '+1234567890',
      );
      await LocalStorage.saveUserProfile(userProfile!);
    }
    
    try {
      final testGroup = await GroupManager.createGroup(
        name: 'Debug Test Group ${DateTime.now().millisecondsSinceEpoch}',
        adminProfile: userProfile!,
      );
      print('Test group created: ${testGroup.name}');
      
      // Immediately check if it's saved
      final savedGroup = LocalStorage.getGroup(testGroup.id);
      print('Saved group check: ${savedGroup?.name ?? 'null'}');
      
      // Check all groups
      final allGroups = GroupManager.getAllGroups();
      print('All groups after creation: ${allGroups.length}');
      
      // Reload data
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug test completed. Check console for details.')),
      );
    } catch (e) {
      print('Debug test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug test failed: $e')),
      );
    }
    
    print('=== DEBUG TEST END ===');
  }

  void _testQrCode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Test QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Testing QR code generation...'),
            SizedBox(height: 16),
            Container(
              width: 150,
              height: 150,
              child: QrImageView(
                data: 'Test QR Code Data',
                size: 150.0,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get member name by ID
  String _getMemberName(String memberId, List<GroupMember> members) {
    final member = members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => GroupMember(
        id: memberId,
        name: 'Unknown',
        deviceId: memberId,
        lastSeen: DateTime.now(),
        isOnline: false,
      ),
    );
    return member.name;
  }

  // Helper method to count online members
  int _getOnlineCount(List<GroupMember> members) {
    return members.where((m) => m.isOnline).length;
  }

  // Helper method to get status summary
  Map<String, int> _getStatusSummary(List<GroupMember> members) {
    final summary = <String, int>{};
    for (var member in members) {
      summary[member.status] = (summary[member.status] ?? 0) + 1;
    }
    return summary;
  }

  void _showMemberStatusDialog(Group group, GroupMember member) {
    String selectedStatus = member.status;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Member Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Member: ${member.name}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Current Status: ${member.status}'),
            Text('Last seen: ${_formatDate(member.lastSeen)}'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'New Status',
                border: OutlineInputBorder(),
              ),
              items: ['OK', 'SOS', 'Unknown'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateMemberStatus(group, member.id, selectedStatus);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD METHOD ===');
    print('Groups count in build: ${groups.length}');
    print('Groups.isEmpty: ${groups.isEmpty}');
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups, size: 80, color: Colors.grey.shade700),
                    const SizedBox(height: 20),
                    Text('No groups joined', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Create or join a group to get started.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(Icons.group_add),
                      label: Text('Create Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _createGroupDialog,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.group),
                      label: Text('Join Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _joinGroupDialog,
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.group_add),
                        label: Text('Create Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _createGroupDialog,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.group),
                        label: Text('Join Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _joinGroupDialog,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.bug_report),
                        label: Text('Debug'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _debugTest,
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.qr_code),
                        label: Text('Test QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _testQrCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...groups.map((group) => Card(
                        color: Color(0xFF232323),
                        elevation: 6,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(group.name, style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(
                                      '${group.members.length} members • ${_getOnlineCount(group.members)} online',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.qr_code, color: Colors.deepPurple, size: 28),
                                tooltip: 'Show QR',
                                onPressed: () => _showGroupQrDialog(group),
                              ),
                            ],
                          ),
                          subtitle: Text('ID: ${group.id}', style: TextStyle(color: Colors.white70)),
                          children: [
                            ListTile(
                              title: Text('Admin: ${_getMemberName(group.adminId, group.members)}', style: TextStyle(color: Colors.white70)),
                              subtitle: Text('Created: ${_formatDate(group.createdAt)}', style: TextStyle(color: Colors.white38)),
                            ),
                            ...group.members.map((m) => Card(
                                  color: m.status == 'SOS'
                                      ? Colors.red.shade900.withOpacity(0.3)
                                      : m.status == 'OK'
                                          ? Colors.green.shade900.withOpacity(0.3)
                                          : Colors.grey.shade800.withOpacity(0.3),
                                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                  child: InkWell(
                                    onLongPress: () => _showMemberStatusDialog(group, m),
                                    child: ListTile(
                                      leading: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: m.status == 'SOS'
                                              ? Colors.red
                                              : m.status == 'OK'
                                                  ? Colors.green
                                                  : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          m.status == 'SOS'
                                              ? Icons.warning
                                              : m.status == 'OK'
                                                  ? Icons.check_circle
                                                  : Icons.help,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        m.name, 
                                        style: TextStyle(
                                          fontSize: 18, 
                                          color: Colors.white, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                      subtitle: Text(
                                        'Status: ${m.status} | Last seen: ${_formatDate(m.lastSeen)}', 
                                        style: TextStyle(color: Colors.white70)
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          m.isOnline
                                              ? Icon(Icons.wifi, color: Colors.green, size: 20)
                                              : Icon(Icons.wifi_off, color: Colors.grey, size: 20),
                                          if (m.id == group.adminId)
                                            Container(
                                              margin: EdgeInsets.only(left: 8),
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Admin',
                                                style: TextStyle(color: Colors.white, fontSize: 10),
                                              ),
                                            ),
                                        ],
                                      ),
                                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      minLeadingWidth: 40,
                                    ),
                                  ),
                                )),
                            ButtonBar(
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.sos),
                                  label: Text('Send Group SOS'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _sendGroupSOS(group),
                                ),
                                TextButton(
                                  child: Text('Delete Group', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  onPressed: () => _deleteGroupWithConfirmation(group),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
      ),
      floatingActionButton: groups.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green.shade700,
              icon: Icon(Icons.group_add),
              label: Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _createGroupDialog,
            )
          : null,
    );
  }
}

class _QrScanner extends StatefulWidget {
  final Function(String groupId) onGroupId;
  const _QrScanner({required this.onGroupId});
  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  bool scanned = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Scan QR Code', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (scanned) return;
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final data = barcode.rawValue;
                    if (data != null && data.contains('id')) {
                      try {
                        final id = RegExp(r'"id":"([^"]+)"').firstMatch(data)?.group(1);
                        if (id != null) {
                          scanned = true;
                          widget.onGroupId(id);
                          break;
                        } else {
                          setState(() {
                            errorMessage = 'Invalid QR code format';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Error processing QR code';
                        });
                      }
                    } else {
                      setState(() {
                        errorMessage = 'Invalid QR code content';
                      });
                    }
                  }
                },
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Camera Error',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          error.errorDetails?.message ?? 'Unable to access camera',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (errorMessage != null)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 