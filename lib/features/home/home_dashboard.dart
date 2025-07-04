import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../health_card/health_card_screen.dart';
import '../emergency_contacts_screen.dart';
import '../sos/sos_receiver.dart';
import '../../core/ble/ble_mesh_service.dart';
import '../../core/models/sos_message.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/location_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _receivedCount = 0;
  final BleMeshService _bleMeshService = BleMeshService();
  bool _sending = false;
  String? _status;
  double? _latitude;
  double? _longitude;
  bool _attachHealthCard = false;

  void _openHealthCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HealthCardScreen()),
    );
  }

  void _openContacts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    );
  }

  void _openSosReceived(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosReceivedScreen()),
    );
    // Optionally refresh count after returning
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadReceivedCount();
    _getCurrentLocation();
  }

  Future<void> _loadReceivedCount() async {
    // TODO: Load the actual count from storage or service
    // For now, set to 0
    setState(() {
      _receivedCount = 0;
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationUtils.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
  }

  Future<void> _sendSos() async {
    setState(() {
      _sending = true;
      _status = null;
    });
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ].request();
    final denied = statuses.entries.where((e) => !e.value.isGranted).map((e) => e.key).toList();
    if (denied.isNotEmpty) {
      setState(() {
        _status = 'Permissions not granted: ' + denied.map((p) => p.toString().split('.').last).join(', ') + '. Please grant all permissions.';
        _sending = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: Text('The following permissions are required: ' + denied.map((p) => p.toString().split('.').last).join(', ') + '\n\nPlease grant them in app settings.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }
    await _getCurrentLocation();
    final sos = SosMessage(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      latitude: _latitude,
      longitude: _longitude,
      message: _attachHealthCard ? 'SOS! Need help! [Health Card Attached]' : 'SOS! Need help!',
      ttl: 5,
    );
    try {
      await _bleMeshService.advertiseSos(sos);
      await LocalStorage.addSosToLog(sos);
      setState(() {
        _sending = false;
        _status = 'SOS sent successfully!';
      });
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _status = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _sending = false;
        _status = 'Error sending SOS: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        title: const Text('resQlink', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Row(
            children: [
              Icon(Icons.battery_4_bar, color: Colors.white),
              const SizedBox(width: 4),
              Text('85%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // SOS Button
            Center(
              child: GestureDetector(
                onTap: _sending ? null : _sendSos,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.danger, AppTheme.danger.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.danger.withOpacity(0.4),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _sending
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 6,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active, color: Colors.white, size: 48),
                              const SizedBox(height: 8),
                              Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 48)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tap to Send Emergency Alert', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            // Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _latitude != null && _longitude != null
                                  ? LocationUtils.formatCoordinates(_latitude, _longitude)
                                  : 'Getting location...',
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.redAccent),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Refresh location',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Switch(
                            value: _attachHealthCard,
                            onChanged: (val) {
                              setState(() {
                                _attachHealthCard = val;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                          const Text('Attach Health Card', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Status Message
            if (_status != null) ...[
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Card(
                  color: _status!.contains('Error') ? Colors.red.shade100 : Colors.green.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _status!.contains('Error') ? Icons.error : Icons.check_circle,
                          color: _status!.contains('Error') ? Colors.red : Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _status!,
                            style: TextStyle(
                              color: _status!.contains('Error') ? Colors.red : Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Location Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: AppTheme.success), // map-pin
                const SizedBox(width: 8),
                Text('Current Location: 28.6139, 77.2090', style: TextStyle(color: AppTheme.navy, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 32),
            // Quick Action Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  _QuickActionCard(
                    icon: Icons.favorite,
                    label: 'Health Card',
                    color: Colors.white,
                    iconColor: Colors.pink,
                    onTap: () => _openHealthCard(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.phone,
                    label: 'Contacts',
                    color: Colors.white,
                    iconColor: AppTheme.lightBlue,
                    onTap: () => _openContacts(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.bluetooth,
                    label: 'Mesh Status',
                    color: Colors.white,
                    iconColor: AppTheme.navy,
                  ),
                  _QuickActionCard(
                    icon: Icons.call_received,
                    label: 'SOS Received ($_receivedCount)',
                    color: Colors.white,
                    iconColor: AppTheme.danger,
                    onTap: () => _openSosReceived(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.iconColor, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 40),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class SosReceivedScreen extends StatelessWidget {
  const SosReceivedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received SOS Messages'),
      ),
      body: const SosReceiver(),
    );
  }
} 