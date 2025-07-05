import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/group.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart' as my_local;
import 'group_manager.dart';
import '../../core/utils/location_utils.dart';

class GroupLinkingScreen extends StatefulWidget {
  const GroupLinkingScreen({Key? key}) : super(key: key);

  @override
  State<GroupLinkingScreen> createState() => _GroupLinkingScreenState();
}

class _GroupLinkingScreenState extends State<GroupLinkingScreen> {
  List<Group> groups = [];
  UserProfile? userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      userProfile = my_local.LocalStorage.getUserProfile();
      if (userProfile != null) {
        await GroupManager.initialize(userProfile!);
        final userGroups = GroupManager.getActiveGroups();
        setState(() {
          groups = userGroups;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading group data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _quickSos() async {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No groups available. Create or join a group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Send SOS to all groups
    for (final group in groups) {
      try {
        await GroupManager.sendGroupSos(
          group.id,
          'Emergency SOS from ${userProfile?.name ?? 'Group member'} - Need immediate help!',
        );
      } catch (e) {
        print('Error sending SOS to group ${group.name}: $e');
      }
    }

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 SOS sent to all groups!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _quickStatusUpdate() async {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No groups available. Create or join a group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Send "I'm OK" status to all groups
    for (final group in groups) {
      try {
        await GroupManager.sendGroupStatus(group.id, 'OK');
      } catch (e) {
        print('Error sending status to group ${group.name}: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Status sent to all groups'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _quickHelpRequest() async {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No groups available. Create or join a group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final helpType = await _showHelpTypeDialog();
    if (helpType != null) {
      for (final group in groups) {
        try {
          await GroupManager.sendGroupResource(
            group.id,
            'NEED',
            helpType,
            description: 'Urgent need for $helpType',
          );
        } catch (e) {
          print('Error sending help request to group ${group.name}: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🆘 Help request sent: $helpType'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<String?> _showHelpTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What do you need?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpOption('Water', Icons.water_drop),
            _buildHelpOption('First Aid', Icons.medical_services),
            _buildHelpOption('Transport', Icons.directions_car),
            _buildHelpOption('Shelter', Icons.home),
            _buildHelpOption('Food', Icons.restaurant),
            _buildHelpOption('Medicine', Icons.medication),
            _buildHelpOption('Other', Icons.help),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
      onTap: () => Navigator.of(context).pop(text),
    );
  }

  void _showGroupStatus() {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No groups available. Create or join a group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...groups.map((group) => _buildGroupStatusCard(group)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatusCard(Group group) {
    final hasSosMembers = group.members.any((m) => m.status == 'SOS');
    final onlineMembers = group.members.where((m) => m.isOnline).length;
    final sosCount = group.members.where((m) => m.status == 'SOS').length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
              Text(
                '🚨 $sosCount members need help!',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showGroupDetails(group),
        ),
      ),
    );
  }

  void _showGroupDetails(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Members (${group.members.length}):'),
              const SizedBox(height: 8),
              ...group.members.map((member) => _buildMemberTile(member)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
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
        backgroundColor: member.isOnline ? Colors.green : Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading groups...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Quick Actions'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No groups available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create or join a group to use quick actions',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Emergency SOS Button
                  ElevatedButton.icon(
                    onPressed: _quickSos,
                    icon: const Icon(Icons.emergency, color: Colors.white, size: 28),
                    label: const Text(
                      'EMERGENCY SOS',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // I'm OK Button
                  ElevatedButton.icon(
                    onPressed: _quickStatusUpdate,
                    icon: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    label: const Text(
                      'I\'M OK',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Need Help Button
                  ElevatedButton.icon(
                    onPressed: _quickHelpRequest,
                    icon: const Icon(Icons.help, color: Colors.white, size: 24),
                    label: const Text(
                      'NEED HELP',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Group Status Button
                  ElevatedButton.icon(
                    onPressed: _showGroupStatus,
                    icon: const Icon(Icons.info, color: Colors.white, size: 24),
                    label: const Text(
                      'GROUP STATUS',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Group Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Group Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Active Groups: ${groups.length}'),
                          Text('Total Members: ${groups.fold(0, (sum, group) => sum + group.members.length)}'),
                          Text('Online Members: ${groups.fold(0, (sum, group) => sum + group.members.where((m) => m.isOnline).length)}'),
                          Text('SOS Alerts: ${groups.fold(0, (sum, group) => sum + group.members.where((m) => m.status == 'SOS').length)}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 