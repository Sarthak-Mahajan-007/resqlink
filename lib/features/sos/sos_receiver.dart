import 'package:flutter/material.dart';
import '../../core/ble/ble_mesh_service.dart';
import '../../core/models/sos_message.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/location_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class SosReceiver extends StatefulWidget {
  const SosReceiver({Key? key}) : super(key: key);

  @override
  State<SosReceiver> createState() => _SosReceiverState();
}

class _SosReceiverState extends State<SosReceiver> {
  final BleMeshService _bleMeshService = BleMeshService();
  final List<SosMessage> _received = [];
  bool _scanning = false;
  final Set<String> _responded = {};

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
    });
    try {
      // Request permissions before scanning
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
        Permission.locationAlways,
      ].request();
      if (statuses.values.any((status) => !status.isGranted)) {
        setState(() {
          _scanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissions required for SOS scan not granted.'), backgroundColor: Colors.red),
        );
        return;
      }
      await _bleMeshService.startScanning((SosMessage msg) async {
        await LocalStorage.addSosToLog(msg);
        setState(() {
          _received.insert(0, msg);
        });
        _showSosNotification(msg);
      });
    } catch (e) {
      print('Error starting scan: $e');
    }
    setState(() {
      _scanning = false;
    });
  }

  void _showSosNotification(SosMessage msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('SOS received: ${msg.message}'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bleMeshService.stop();
    super.dispose();
  }

  void _markAsResponded(String id) {
    setState(() {
      _responded.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _received.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _received.length,
                  itemBuilder: (context, index) {
                    final msg = _received[index];
                    return _buildSosCard(msg);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.call_received, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Received SOS Messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Spacer(),
          if (_scanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          const SizedBox(width: 8),
          Text(
            '${_received.length} messages',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_received,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No SOS messages received',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scanning for nearby emergency alerts...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosCard(SosMessage msg) {
    final isRelayed = msg.ttl < 5 && msg.ttl > 0;
    final isResponded = _responded.contains(msg.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isResponded
          ? Colors.green.shade100
          : isRelayed
              ? Colors.orange.shade100
              : Colors.red.shade100,
      elevation: 6,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRelayed ? Colors.orange : Colors.red,
          child: Icon(
            isRelayed ? Icons.repeat : Icons.call_received,
            color: Colors.white,
            size: 32,
            semanticLabel: isRelayed ? 'Relayed SOS' : 'Direct SOS',
          ),
        ),
        title: Text(
          msg.message,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(_formatTimestamp(msg.timestamp), style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  msg.latitude != null && msg.longitude != null
                      ? LocationUtils.formatCoordinates(msg.latitude, msg.longitude)
                      : 'Unknown',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            if (isRelayed)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Relayed via mesh', style: TextStyle(color: Colors.orange.shade900, fontSize: 13)),
              ),
            if (isResponded)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Marked as responded', style: TextStyle(color: Colors.green.shade900, fontSize: 13)),
              ),
          ],
        ),
        trailing: isResponded
            ? Icon(Icons.check_circle, color: Colors.green, size: 32)
            : ElevatedButton.icon(
                icon: Icon(Icons.check, color: Colors.white),
                label: Text('Respond', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _markAsResponded(msg.id),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        minVerticalPadding: 18,
        minLeadingWidth: 48,
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }
} 