import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/utils/location_utils.dart';
import '../../core/storage/local_storage.dart';
import '../../core/models/group.dart';
import '../../core/models/sos_message.dart';
import '../../core/models/resource_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map state
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  bool _isOffline = false;
  
  // Navigation state
  RouteInfo? _currentRoute;
  LatLng? _selectedDestination;
  bool _isCalculatingRoute = false;
  LatLng? _tappedLocation; // Temporary marker for tapped location
  
  // Data
  List<GroupMember> _groupMembers = [];
  List<SosMessage> _sosMessages = [];
  List<ResourceModel> _resources = [];
  
  // Controllers
  MapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _dataTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    print('[MAP] Initializing map...');
    
    // Get initial location
    await _getCurrentLocation();
    
    // Start location updates
    _startLocationUpdates();
    
    // Load data
    _loadMapData();
    
    // Start periodic data refresh
    _dataTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadMapData());
  }

  Future<void> _getCurrentLocation() async {
    print('[MAP] Getting current location...');
    setState(() => _isLoadingLocation = true);
    
    try {
      final position = await LocationUtils.getCurrentLocation();
      if (position != null) {
        print('[MAP] Location obtained: ${position.latitude}, ${position.longitude}');
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      } else {
        print('[MAP] Failed to get location, using default');
        setState(() {
          _userLocation = const LatLng(28.6139, 77.2090); // Default location
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('[MAP] Error getting location: $e');
      setState(() {
        _userLocation = const LatLng(28.6139, 77.2090);
        _isLoadingLocation = false;
      });
    }
  }

  void _startLocationUpdates() {
    print('[MAP] Starting location updates...');
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      print('[MAP] Location update: ${position.latitude}, ${position.longitude}');
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }, onError: (error) {
      print('[MAP] Location stream error: $error');
    });
  }

  void _loadMapData() {
    print('[MAP] Loading map data...');
    
    try {
      // Load groups
      final groups = LocalStorage.getAllGroups();
      _groupMembers = groups.expand((g) => g.members).toList();
      
      // Load SOS messages
      _sosMessages = LocalStorage.getSosLog();
      
      // Load resources
      _resources = LocalStorage.getAllResources();
      
      print('[MAP] Loaded: ${_groupMembers.length} group members, ${_sosMessages.length} SOS messages, ${_resources.length} resources');
      
      setState(() {});
    } catch (e) {
      print('[MAP] Error loading data: $e');
    }
  }

  Future<void> _calculateRoute(LatLng destination) async {
    print('[MAP] Calculating route to: ${destination.latitude}, ${destination.longitude}');
    
    if (_userLocation == null) {
      print('[MAP] Cannot calculate route: user location is null');
      _showSnackBar('Cannot calculate route: location not available', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _selectedDestination = destination;
    });

    try {
      // Try OSRM routing
      final route = await LocationUtils.calculateRoute(
        _userLocation!.latitude,
        _userLocation!.longitude,
        destination.latitude,
        destination.longitude,
      );

      if (route != null) {
        print('[MAP] Route calculated: ${route.points.length} points, ${route.formattedDistance}, ${route.formattedDuration}');
        setState(() {
          _currentRoute = route;
          _isCalculatingRoute = false;
        });
        _showSnackBar('Route calculated successfully');
      } else {
        print('[MAP] OSRM failed, using straight line route');
        final fallbackRoute = LocationUtils.calculateStraightLineRoute(
          _userLocation!.latitude,
          _userLocation!.longitude,
          destination.latitude,
          destination.longitude,
        );
        
        setState(() {
          _currentRoute = fallbackRoute;
          _isCalculatingRoute = false;
        });
        _showSnackBar('Using straight-line route (detailed routing unavailable)', isWarning: true);
      }
    } catch (e) {
      print('[MAP] Route calculation error: $e');
      setState(() => _isCalculatingRoute = false);
      _showSnackBar('Failed to calculate route: $e', isError: true);
    }
  }

  void _clearRoute() {
    print('[MAP] Clearing route');
    setState(() {
      _currentRoute = null;
      _selectedDestination = null;
      _tappedLocation = null; // Clear the tapped location marker too
    });
  }

  void _showMarkerDetails(String type, String title, String subtitle, LatLng location) {
    print('[MAP] Showing marker details: $type at ${location.latitude}, ${location.longitude}');
    
    final distance = _userLocation != null 
        ? LocationUtils.calculateDistance(
            _userLocation!.latitude, 
            _userLocation!.longitude, 
            location.latitude, 
            location.longitude
          )
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle),
            if (distance != null) ...[
              const SizedBox(height: 16),
              Text(
                'Distance: ${LocationUtils.formatDistance(distance)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_userLocation != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _calculateRoute(location);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : isWarning ? Colors.orange : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Header with legend
          _buildHeader(),
          
          // Map
          Expanded(
            child: _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Legend
              Row(
                children: [
                  _buildLegendItem(Colors.red, 'Rescue'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.orange, 'Resource'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.blue, 'Group'),
                ],
              ),
              
              // Status indicators
              Row(
                children: [
                  Icon(
                    _userLocation != null ? Icons.location_on : Icons.location_off,
                    color: _userLocation != null ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isOffline ? Icons.cloud_off : Icons.cloud,
                    color: _isOffline ? Colors.red : Colors.blue,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation ?? const LatLng(28.6139, 77.2090),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
                onTap: (tapPosition, point) {
                  print('[MAP] Map tapped at: ${point.latitude}, ${point.longitude}');
                  // Set tapped location marker
                  setState(() {
                    _tappedLocation = point;
                  });
                  // Calculate route to tapped location
                  _calculateRoute(point);
                },
              ),
              children: [
                // Tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.resqlink',
                  errorTileCallback: (_, __, ___) {
                    setState(() => _isOffline = true);
                  },
                ),
                
                // Route polyline
                if (_currentRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _currentRoute!.points,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                
                // Markers
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            ),
            
            // Loading overlay
            if (_isCalculatingRoute)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Calculating route...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // Route info panel
            if (_currentRoute != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildRouteInfoPanel(),
              ),
            
            // Control buttons
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Center on location button
                  if (_userLocation != null)
                    FloatingActionButton(
                      heroTag: "centerLocation",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      onPressed: () {
                        _mapController?.move(_userLocation!, 15.0);
                        _showSnackBar('Centered on your location');
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Clear route button
                  if (_currentRoute != null)
                    FloatingActionButton(
                      heroTag: "clearRoute",
                      mini: true,
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      onPressed: _clearRoute,
                      child: const Icon(Icons.clear),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // User location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              print('[MAP] User location marker tapped');
              _showSnackBar('This is your current location');
            },
            child: _buildUserMarker(),
          ),
        ),
      );
    }
    
    // Tapped location marker (destination)
    if (_tappedLocation != null) {
      markers.add(
        Marker(
          point: _tappedLocation!,
          width: 40,
          height: 40,
          child: _buildTappedLocationMarker(),
        ),
      );
    }
    
    // Group member markers
    for (final member in _groupMembers) {
      if (member.latitude != null && member.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(member.latitude!, member.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                print('[MAP] Group member marker tapped: ${member.name}');
                _showMarkerDetails(
                  'Group Member',
                  member.name,
                  member.status,
                  LatLng(member.latitude!, member.longitude!),
                );
              },
              child: _buildMarker(Colors.blue, Icons.groups),
            ),
          ),
        );
      }
    }
    
    // SOS markers
    for (final sos in _sosMessages) {
      if (sos.latitude != null && sos.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(sos.latitude!, sos.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                print('[MAP] SOS marker tapped: ${sos.message}');
                _showMarkerDetails(
                  'Rescue',
                  sos.message,
                  sos.timestamp.toString(),
                  LatLng(sos.latitude!, sos.longitude!),
                );
              },
              child: _buildMarker(Colors.red, Icons.location_on),
            ),
          ),
        );
      }
    }
    
    // Resource markers
    for (final resource in _resources) {
      if (resource.latitude != null && resource.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(resource.latitude!, resource.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                print('[MAP] Resource marker tapped: ${resource.title}');
                _showMarkerDetails(
                  resource.typeName,
                  resource.title,
                  resource.categoryName,
                  LatLng(resource.latitude!, resource.longitude!),
                );
              },
              child: _buildMarker(Colors.orange, Icons.local_drink),
            ),
          ),
        );
      }
    }
    
    return markers;
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
    );
  }

  Widget _buildMarker(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildTappedLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.place, color: Colors.white, size: 24),
    );
  }

  Widget _buildRouteInfoPanel() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Route to Destination',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance: ${_currentRoute!.formattedDistance}'),
                Text('Duration: ${_currentRoute!.formattedDuration}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Tap the X button to clear route',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 