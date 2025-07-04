import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ble/ble_mesh_service.dart';
import '../../core/models/sos_message.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/location_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class SosSender extends StatefulWidget {
  const SosSender({Key? key}) : super(key: key);

  @override
  State<SosSender> createState() => _SosSenderState();
}

class _SosSenderState extends State<SosSender> {
  final BleMeshService _bleMeshService = BleMeshService();
  bool _sending = false;
  String? _status;
  double? _latitude;
  double? _longitude;
  bool _attachHealthCard = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Glowing SOS Button
              Center(
                child: GestureDetector(
                  onTap: _sending ? null : _sendSos,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade700,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(_sending ? 0.2 : 0.5),
                          blurRadius: _sending ? 10 : 40,
                          spreadRadius: _sending ? 2 : 12,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: _sending
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 6,
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
            ],
          ),
        ),
      ),
    );
  }
} 