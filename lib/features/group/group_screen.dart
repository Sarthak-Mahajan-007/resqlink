import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart' as my_local;
import 'group_manager.dart';
import '../../core/ble/ble_message.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../core/utils/location_utils.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<Group> groups = [];
  UserProfile? userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // Debug: Add in-memory fallback for testing
  static List<Group> _debugGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupGroupManager();
  }

  void _setupGroupManager() {
    // Set up callbacks for real-time updates
    GroupManager.setCallbacks(
      onGroupUpdated: (group) {
        setState(() {
          final index = groups.indexWhere((g) => g.id == group.id);
          if (index != -1) {
            groups[index] = group;
          }
        });
      },
      onGroupMessage: (message) {
        _showGroupMessageNotification(message);
      },
      onGroupSos: (message) {
        _showGroupSosAlert(message);
      },
    );
  }

  void _showGroupMessageNotification(BleMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group message: ${message.payload['message'] ?? 'Status update'}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showGroupSosAlert(BleMessage message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 GROUP SOS ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group: ${message.payload['groupId']}'),
            const SizedBox(height: 8),
            Text('Message: ${message.payload['message']}'),
            if (message.payload['latitude'] != null && message.payload['longitude'] != null)
              Text('Location: ${message.payload['latitude']}, ${message.payload['longitude']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendGroupSosResponse(message.payload['groupId']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Respond with SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    // Trigger haptic feedback and sound
    HapticFeedback.heavyImpact();
  }

  void _sendGroupSosResponse(String? groupId) {
    if (groupId != null) {
      GroupManager.sendGroupSos(groupId, 'Responding to group SOS - I\'m coming to help!');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      userProfile = my_local.LocalStorage.getUserProfile();
      if (userProfile == null) {
        setState(() {
          groups = _debugGroups;
          _isLoading = false;
        });
        return;
      }

      // Initialize GroupManager with user profile
      await GroupManager.initialize(userProfile!);
      
      // Load groups from GroupManager
      final userGroups = GroupManager.getActiveGroups();
      
      setState(() {
        groups = userGroups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        groups = _debugGroups;
        _isLoading = false;
        _errorMessage = 'Failed to load groups: $e';
      });
    }
  }

  void _createGroupDialog() async {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final groupName = controller.text.trim();
              if (groupName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }
              Navigator.pop(ctx);
              
              try {
                userProfile ??= UserProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'User ${DateTime.now().millisecondsSinceEpoch % 1000}',
                  age: 25,
                  bloodGroup: 'O+',
                  allergies: [],
                  chronicConditions: [],
                  emergencyContact: 'Emergency Contact',
                  emergencyPhone: '+1234567890',
                );
                await my_local.LocalStorage.saveUserProfile(userProfile!);
                
                final group = await GroupManager.createGroup(
                  name: groupName,
                  adminProfile: userProfile!,
                  description: descriptionController.text.trim(),
                );
                
                await _loadData();
                if (mounted) setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group "${group.name}" created!')),
                );
              } catch (e) {
                print('❌ Error creating group: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create group: $e')),
                );
              }
            },
            child: const Text('Create'),
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
        title: const Text('Join Group'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Group ID'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group ID')),
                );
                return;
              }
              
              if (userProfile == null) {
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
                await my_local.LocalStorage.saveUserProfile(userProfile!);
              }
              
              try {
                final supabase = Supabase.instance.client;
                
                // Ensure user exists in users table
                final existingUser = await supabase
                    .from('users')
                    .select()
                    .eq('id', int.tryParse(userProfile!.id) ?? -1)
                    .maybeSingle();
                if (existingUser == null) {
                  await supabase.from('users').insert({
                    'id': int.tryParse(userProfile!.id) ?? -1,
                    'name': userProfile!.name,
                  });
                }
                
                // Check if group exists
                final response = await supabase.from('groups').select().eq('id', controller.text.trim());
                if (response.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group not found. Please check the group ID.')),
                  );
                  return;
                }
                
                // Join group via GroupManager
                final group = Group(
                  id: response[0]['id'].toString(),
                  name: response[0]['name'] ?? '',
                  adminId: response[0]['admin_id']?.toString() ?? '',
                  members: [],
                  createdAt: DateTime.now(),
                  description: response[0]['description'] ?? '',
                );
                
                await GroupManager.joinGroup(
                  group: group,
                  userProfile: userProfile!,
                );
                
                await _loadData();
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully joined group: ${response[0]['name']}')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join group: ${e.toString()}')),
                );
              }
            },
            child: const Text('Join'),
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
        title: const Text('Group QR Code'),
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
            Text('Scan to join: ${group.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: ${group.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Group ID: ${group.id}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: group.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group ID copied to clipboard')),
              );
            },
            child: const Text('Copy ID'),
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
            const Icon(Icons.qr_code, size: 64, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'QR Code Unavailable',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Group ID: $groupId',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupDetails(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(group.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Members (${group.members.length}):'),
              const SizedBox(height: 8),
              ...group.members.map((member) => _buildMemberTile(member)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendGroupSos(group.id, 'Emergency SOS from ${userProfile?.name ?? 'Group member'}');
                      },
                      icon: const Icon(Icons.emergency, color: Colors.white),
                      label: const Text('Send SOS', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendGroupStatus(group.id, 'OK');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('I\'m OK'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showResourceDialog(group.id);
                      },
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Need Help'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showResourceDialog(group.id, isOffer: true);
                      },
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Can Help'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
    final isOnline = member.isOnline;
    final status = member.status;
    Color statusColor = Colors.grey;
    
    switch (status) {
      case 'OK':
        statusColor = Colors.green;
        break;
      case 'SOS':
        statusColor = Colors.red;
        break;
      case 'HELP':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOnline ? Colors.green : Colors.grey,
        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
      ),
      title: Text(member.name),
      subtitle: Text('Last seen: ${_formatTime(member.lastSeen)}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _sendGroupSos(String groupId, String message) async {
    try {
      await GroupManager.sendGroupSos(groupId, message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group SOS sent!'), backgroundColor: Colors.red),
      );
      HapticFeedback.heavyImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: $e')),
      );
    }
  }

  void _sendGroupStatus(String groupId, String status) async {
    try {
      await GroupManager.sendGroupStatus(groupId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status sent: $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send status: $e')),
      );
    }
  }

  void _showResourceDialog(String groupId, {bool isOffer = false}) {
    final resourceController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isOffer ? 'Offer Help' : 'Need Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: resourceController,
              decoration: InputDecoration(
                labelText: isOffer ? 'What can you offer?' : 'What do you need?',
                hintText: isOffer ? 'e.g., Water, First Aid, Transport' : 'e.g., Water, Medicine, Shelter',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Additional details...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final resource = resourceController.text.trim();
              if (resource.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter what you need or can offer')),
                );
                return;
              }
              
              Navigator.pop(ctx);
              
              try {
                await GroupManager.sendGroupResource(
                  groupId,
                  isOffer ? 'OFFER' : 'NEED',
                  resource,
                  description: descriptionController.text.trim(),
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${isOffer ? 'Offer' : 'Need'} sent to group')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send ${isOffer ? 'offer' : 'need'}: $e')),
                );
              }
            },
            child: Text(isOffer ? 'Offer Help' : 'Request Help'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading groups...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create or join a group to stay connected',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _createGroupDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Group'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _joinGroupDialog,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Group'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupCard(group);
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _createGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
              heroTag: 'newGroupBtn',
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              onPressed: _joinGroupDialog,
              icon: const Icon(Icons.group_add),
              label: const Text('Join Group'),
              heroTag: 'joinGroupBtn',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final hasSosMembers = group.members.any((m) => m.status == 'SOS');
    final onlineMembers = group.members.where((m) => m.isOnline).length;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: hasSosMembers ? 8 : 2,
      color: hasSosMembers ? Colors.red.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasSosMembers ? Colors.red : Colors.blue,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          group.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasSosMembers ? Colors.red.shade800 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${group.members.length} members • $onlineMembers online'),
            if (hasSosMembers)
              const Text(
                '🚨 SOS ALERT - Members need help!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showGroupQrDialog(group),
              tooltip: 'Show QR Code',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showGroupDetails(group),
              tooltip: 'Group Details',
            ),
          ],
        ),
        onTap: () => _showGroupDetails(group),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _QrScanner extends StatefulWidget {
  final Function(String) onGroupId;

  const _QrScanner({required this.onGroupId});

  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                return Icon(
                  state == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                );
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final code = barcode.rawValue;
            if (code != null) {
              try {
                final data = jsonDecode(code);
                if (data['id'] != null) {
                  widget.onGroupId(data['id']);
                  return;
                }
              } catch (e) {
                print('Error parsing QR code data: $e');
              }
            }
          }
        },
      ),
    );
  }
} 