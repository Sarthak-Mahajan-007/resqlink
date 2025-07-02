import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ble/ble_mesh_service.dart';
import '../../core/models/sos_message.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/location_utils.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void dispose() {
    super.dispose();
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

    // Request permissions before sending SOS
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
        _status = 'Permissions required for SOS not granted.';
        _sending = false;
      });
      return;
    }

    // Get fresh location
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
      // Visual feedback: flash
      await _flashScreen();
      // Audio/vibration feedback
      HapticFeedback.heavyImpact();
      // Clear status after 3 seconds
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

  Future<void> _flashScreen() async {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(color: Colors.red.withOpacity(0.7)),
      ),
    );
    Overlay.of(context)?.insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 200));
    overlayEntry?.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                GestureDetector(
                  onTap: _sending ? null : _sendSos,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
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
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFCCCCCC), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _latitude != null && _longitude != null
                        ? LocationUtils.formatCoordinates(_latitude, _longitude)
                        : 'Getting location...',
                    style: const TextStyle(color: Color(0xFFEEEEEE), fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFCCCCCC), size: 20),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Refresh location',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: 8),
                const Text('Attach Health Card', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF444444),
                  ),
                ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 