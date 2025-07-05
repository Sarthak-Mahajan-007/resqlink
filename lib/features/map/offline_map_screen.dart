import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/location_utils.dart';
import '../../core/storage/local_storage.dart';
import '../../core/models/group.dart';
import '../../core/models/sos_message.dart';
import '../../core/models/resource_model.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({Key? key}) : super(key: key);

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  LatLng? userLocation;
  bool meshActive = true;
  bool offline = false;
  List<GroupMember> groupMembers = [];
  List<SosMessage> sosMessages = [];
  List<ResourceModel> resources = [];
  StreamSubscription? _locationSub;
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startDataPolling();
  }

  void _startLocationUpdates() async {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
      });
    });
    // Get initial location
    final pos = await LocationUtils.getCurrentLocation();
    setState(() {
      userLocation = pos != null ? LatLng(pos.latitude, pos.longitude) : LatLng(28.6139, 77.2090);
    });
  }

  void _startDataPolling() {
    _dataTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData());
    _loadData();
  }

  Future<void> _loadData() async {
    // Get group members
    final groups = LocalStorage.getAllGroups();
    groupMembers = groups.expand((g) => g.members).toList();
    // Get SOS messages
    sosMessages = LocalStorage.getSosLog();
    // Get resources
    resources = LocalStorage.getAllResources();
    setState(() {});
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _dataTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _LegendDot(color: Colors.red),
                        const SizedBox(width: 4),
                        const Text('Rescue', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        _LegendDot(color: Colors.orange),
                        const SizedBox(width: 4),
                        const Text('Resource', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        _LegendDot(color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text('Group', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(meshActive ? Icons.wifi : Icons.wifi_off, color: meshActive ? Colors.green : Colors.red, size: 22),
                        const SizedBox(width: 8),
                        Icon(offline ? Icons.cloud_off : Icons.cloud, color: offline ? Colors.red : Colors.blue, size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: userLocation ?? LatLng(28.6139, 77.2090),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                        onTap: (tapPos, latlng) {},
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.resqlink',
                          errorTileCallback: (tile, error, stackTrace) {
                            setState(() {
                              offline = true;
                            });
                          },
                        ),
                        MarkerLayer(
                          markers: [
                            if (userLocation != null)
                              Marker(
                                point: userLocation!,
                                width: 48,
                                height: 48,
                                child: _UserMarker(),
                              ),
                            // Group members
                            ...groupMembers.where((m) => m.latitude != null && m.longitude != null).map((m) => Marker(
                              point: LatLng(m.latitude!, m.longitude!),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showMarkerDetails(context, 'Group Member', m.name, m.status),
                                child: _MapTypeMarker(type: 'Group', color: Colors.blue),
                              ),
                            )),
                            // SOS messages
                            ...sosMessages.where((s) => s.latitude != null && s.longitude != null).map((s) => Marker(
                              point: LatLng(s.latitude!, s.longitude!),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showMarkerDetails(context, 'Rescue', s.message, s.timestamp.toString()),
                                child: _MapTypeMarker(type: 'Rescue', color: Colors.red),
                              ),
                            )),
                            // Resources
                            ...resources.where((r) => r.latitude != null && r.longitude != null).map((r) => Marker(
                              point: LatLng(r.latitude!, r.longitude!),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showMarkerDetails(context, r.typeName, r.title, r.categoryName),
                                child: _MapTypeMarker(type: 'Resource', color: Colors.orange),
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                    if (offline)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off, color: Colors.red, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'Offline: Map tiles unavailable',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Connect to the internet to view map tiles, or use offline features.',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkerDetails(BuildContext context, String type, String title, String subtitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(subtitle),
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
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
    );
  }
}

class _UserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 4),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
    );
  }
}

class _MapTypeMarker extends StatelessWidget {
  final String type;
  final Color color;
  const _MapTypeMarker({required this.type, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Icon(
          type == 'Rescue'
              ? Icons.location_on
              : type == 'Resource'
                  ? Icons.local_drink
                  : Icons.groups,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// Offline map UI
// class OfflineMapScreen {
//   // TODO: Implement offline map display and rescue points
// } 