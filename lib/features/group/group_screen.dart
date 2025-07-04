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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      groups = GroupManager.getAllGroups();
      userProfile = LocalStorage.getUserProfile();
    });
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
              if (controller.text.isNotEmpty && userProfile != null) {
                await GroupManager.createGroup(
                  name: controller.text,
                  adminProfile: userProfile!,
                );
                Navigator.pop(ctx);
                _loadData();
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
              final group = GroupManager.getGroup(controller.text);
              if (group != null && userProfile != null) {
                await GroupManager.joinGroup(group: group, userProfile: userProfile!);
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showGroupQrDialog(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Group QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: '{"id":"${group.id}","name":"${group.name}"}',
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text('Scan to join: ${group.name}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: ${group.id}', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              final group = GroupManager.getGroup(groupId);
              if (group != null && userProfile != null) {
                await GroupManager.joinGroup(group: group, userProfile: userProfile!);
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined group: ${group.name}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group not found.')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _sendGroupSOS(Group group) async {
    // TODO: Integrate with SOS sending logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group SOS sent for ${group.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null,
      body: groups.isEmpty
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
                              child: Text(group.name, style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
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
                            title: Text('Admin: ${group.adminId}', style: TextStyle(color: Colors.white70)),
                            subtitle: Text('Created: ${group.createdAt}', style: TextStyle(color: Colors.white38)),
                          ),
                          ...group.members.map((m) => Card(
                                color: m.status == 'SOS'
                                    ? Colors.red.shade100
                                    : m.status == 'OK'
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                child: ListTile(
                                  leading: Icon(
                                    m.status == 'SOS'
                                        ? Icons.warning
                                        : m.status == 'OK'
                                            ? Icons.check_circle
                                            : Icons.help,
                                    color: m.status == 'SOS'
                                        ? Colors.red
                                        : m.status == 'OK'
                                            ? Colors.green
                                            : Colors.grey,
                                    size: 32,
                                    semanticLabel: m.status,
                                  ),
                                  title: Text(m.name, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                                  subtitle: Text('Status: ${m.status} | Last seen: ${m.lastSeen}', style: TextStyle(color: Colors.black87)),
                                  trailing: m.isOnline
                                      ? Icon(Icons.wifi, color: Colors.blue, size: 28)
                                      : Icon(Icons.wifi_off, color: Colors.grey, size: 28),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  minLeadingWidth: 40,
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
                                onPressed: () async {
                                  await GroupManager.deleteGroup(group.id);
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
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

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        if (scanned) return;
        final barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final data = barcode.rawValue;
          if (data != null && data.contains('id')) {
            final id = RegExp(r'"id":"([^"]+)"').firstMatch(data)?.group(1);
            if (id != null) {
              scanned = true;
              widget.onGroupId(id);
              Navigator.of(context).pop();
              break;
            }
          }
        }
      },
    );
  }
} 