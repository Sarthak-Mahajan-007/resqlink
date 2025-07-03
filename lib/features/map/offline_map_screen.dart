import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/location_utils.dart';
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
  bool loading = true;
  String? errorMsg;

  // Mock rescue/resource/group markers
  final List<_MapMarker> markers = [
    _MapMarker(LatLng(28.6145, 77.2100), 'Rescue', Colors.red),
    _MapMarker(LatLng(28.6120, 77.2080), 'Resource', Colors.orange),
    _MapMarker(LatLng(28.6150, 77.2110), 'Group', Colors.blue),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final position = await LocationUtils.getCurrentLocation();
    if (position != null) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        loading = false;
      });
    } else {
      setState(() {
        errorMsg = 'Location permission denied or unavailable.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (errorMsg != null || userLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(errorMsg ?? 'Location unavailable', style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed: _initLocation,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _LegendDot(color: Colors.red),
                  const SizedBox(width: 4),
                  const Text('Rescue', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  _LegendDot(color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text('Resource', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  _LegendDot(color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Group', style: TextStyle(color: Colors.white)),
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
        Expanded(
          child: Card(
            color: const Color(0xFF232323),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: userLocation!,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
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
                          // User location marker
                          Marker(
                            point: userLocation!,
                            width: 48,
                            height: 48,
                            child: _UserMarker(),
                          ),
                          // Other markers
                          ...markers.map((m) => Marker(
                            point: m.position,
                            width: 40,
                            height: 40,
                            child: _MapTypeMarker(type: m.type, color: m.color),
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

class _MapMarker {
  final LatLng position;
  final String type;
  final Color color;
  _MapMarker(this.position, this.type, this.color);
}

// Offline map UI
// class OfflineMapScreen {
//   // TODO: Implement offline map display and rescue points
// } 