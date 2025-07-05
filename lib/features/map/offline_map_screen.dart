import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../../core/utils/location_utils.dart';
import '../../core/storage/local_storage.dart';
import '../../core/models/group.dart';
import '../../core/models/sos_message.dart';
import '../../core/models/resource_model.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({Key? key}) : super(key: key);

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class Hospital {
  final String name;
  final double lat;
  final double lon;
  final String? address;
  Hospital({required this.name, required this.lat, required this.lon, this.address});
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  LatLng? userLocation;
  bool meshActive = true;
  bool offline = false;
  List<GroupMember> groupMembers = [];
  List<SosMessage> sosMessages = [];
  List<ResourceModel> resources = [];
  List<Hospital> hospitals = [];
  StreamSubscription? _locationSub;
  Timer? _dataTimer;
  List<LatLng> routePolyline = [];
  String? distanceText;
  String? durationText;
  final String openRouteApiKey = 'Bearer eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImVjNTQ0YTk3NzU3ZTRhYmFhMDJkNmYxMDY1MjgxMGNlIiwiaCI6Im11cm11cjY0In0='; // <-- Set API key

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startDataPolling();
  }

  Future<void> _fetchNearbyHospitals() async {
    if (userLocation == null) return;
    
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=hospital&limit=50&lat=${userLocation!.latitude}&lon=${userLocation!.longitude}&radius=50000&addressdetails=1&countrycodes=in');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        var results = json.decode(response.body);
        print('DEBUG: Found ${results.length} hospitals with country filter');
        
        // If no results, try multiple search strategies
        if (results.isEmpty) {
          print('DEBUG: No hospitals found with country filter, trying multiple search strategies...');
          
          // Strategy 1: Search for medical facilities
          var fallbackUrl = Uri.parse(
              'https://nominatim.openstreetmap.org/search?format=json&q=medical+clinic&limit=30&lat=${userLocation!.latitude}&lon=${userLocation!.longitude}&radius=50000&addressdetails=1&countrycodes=in');
          var fallbackResponse = await http.get(fallbackUrl);
          
          if (fallbackResponse.statusCode == 200) {
            results = json.decode(fallbackResponse.body);
            print('DEBUG: Found ${results.length} medical clinics');
          }
          
          // Strategy 2: Search for hospitals in Maharashtra
          if (results.isEmpty) {
            fallbackUrl = Uri.parse(
                'https://nominatim.openstreetmap.org/search?format=json&q=hospital+Maharashtra&limit=30&lat=${userLocation!.latitude}&lon=${userLocation!.longitude}&radius=100000&addressdetails=1');
            fallbackResponse = await http.get(fallbackUrl);
            
            if (fallbackResponse.statusCode == 200) {
              results = json.decode(fallbackResponse.body);
              print('DEBUG: Found ${results.length} hospitals in Maharashtra');
            }
          }
          
          // Strategy 3: Search for hospitals in nearby cities
          if (results.isEmpty) {
            final nearbyCities = ['Aurangabad', 'Jalna', 'Beed', 'Parbhani', 'Nanded'];
            for (final city in nearbyCities) {
              fallbackUrl = Uri.parse(
                  'https://nominatim.openstreetmap.org/search?format=json&q=hospital+$city&limit=20&lat=${userLocation!.latitude}&lon=${userLocation!.longitude}&radius=100000&addressdetails=1');
              fallbackResponse = await http.get(fallbackUrl);
              
              if (fallbackResponse.statusCode == 200) {
                final cityResults = json.decode(fallbackResponse.body);
                if (cityResults.isNotEmpty) {
                  results = cityResults;
                  print('DEBUG: Found ${results.length} hospitals in $city');
                  break;
                }
              }
            }
          }
          
          // Strategy 4: Search for any medical facility without country restriction
          if (results.isEmpty) {
            fallbackUrl = Uri.parse(
                'https://nominatim.openstreetmap.org/search?format=json&q=hospital&limit=30&lat=${userLocation!.latitude}&lon=${userLocation!.longitude}&radius=100000&addressdetails=1');
            fallbackResponse = await http.get(fallbackUrl);
            
            if (fallbackResponse.statusCode == 200) {
              results = json.decode(fallbackResponse.body);
              print('DEBUG: Found ${results.length} hospitals worldwide');
            }
          }
        }
        
        setState(() {
          hospitals = results.map<Hospital>((item) {
            final hospital = Hospital(
              name: item['display_name'] ?? 'Hospital',
              lat: double.parse(item['lat']),
              lon: double.parse(item['lon']),
              address: item['address']?['road'] ?? item['address']?['suburb'] ?? item['address']?['city'],
            );
            
            // Calculate distance to user
            final hospitalPoint = LatLng(hospital.lat, hospital.lon);
            final distance = _calculateDistance(userLocation!, hospitalPoint);
            
            print('DEBUG: Hospital: ${hospital.name} at ${hospital.lat}, ${hospital.lon} (${distance.toStringAsFixed(0)}m away)');
            return hospital;
          }).where((hospital) {
            // Only show hospitals within 10km
            final hospitalPoint = LatLng(hospital.lat, hospital.lon);
            final distance = _calculateDistance(userLocation!, hospitalPoint);
            return distance <= 50000; // 50km
          }).toList();
        });
        print('DEBUG: Total hospitals loaded: ${hospitals.length}');
        
        if (hospitals.isEmpty && mounted) {
          print('DEBUG: No hospitals found from API.');
        }
      } else {
        print('DEBUG: Failed to fetch hospitals: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching hospitals: $e');
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to fetch nearby hospitals. Please check your internet connection.')),
        );
      }
    }
  }

  Future<void> _getRouteTo(Hospital hospital) async {
    print('DEBUG: _getRouteTo called for hospital: ${hospital.name}');
    print('DEBUG: User location: ${userLocation?.latitude}, ${userLocation?.longitude}');
    print('DEBUG: Hospital location: ${hospital.lat}, ${hospital.lon}');
    
    if (userLocation == null) {
      print('DEBUG: User location is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available. Please enable location services.')),
      );
      return;
    }

    // Try OpenRouteService first (paid service with better routing)
    try {
      print('DEBUG: Trying OpenRouteService...');
      final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');
      final body = json.encode({
        "coordinates": [
          [userLocation!.longitude, userLocation!.latitude],
          [hospital.lon, hospital.lat]
        ]
      });
      
      print('DEBUG: Request body: $body');
      print('DEBUG: API Key: ${openRouteApiKey.substring(0, 20)}...');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': openRouteApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      
      print('DEBUG: OpenRouteService response status: ${response.statusCode}');
      print('DEBUG: OpenRouteService response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['features'] != null && data['features'].isNotEmpty) {
          final route = data['features'][0]['geometry']['coordinates'] as List;
          final summary = data['features'][0]['properties']['summary'];
          setState(() {
            routePolyline = route
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
            distanceText = '${(summary['distance'] / 1000).toStringAsFixed(2)} km';
            durationText = '${(summary['duration'] / 60).toStringAsFixed(1)} min';
          });
          print('DEBUG: Route set successfully via OpenRouteService');
          return;
        }
      }
    } catch (e) {
      print('DEBUG: OpenRouteService failed: $e');
    }

    // Fallback to free OSRM service
    try {
      print('DEBUG: Trying OSRM fallback...');
      final start = '${userLocation!.longitude},${userLocation!.latitude}';
      final end = '${hospital.lon},${hospital.lat}';
      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson');
      
      print('DEBUG: OSRM URL: $url');
      
      final response = await http.get(url);
      print('DEBUG: OSRM response status: ${response.statusCode}');
      print('DEBUG: OSRM response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final distance = data['routes'][0]['distance'] as double;
          final duration = data['routes'][0]['duration'] as double;
          
          setState(() {
            routePolyline = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
            distanceText = '${(distance / 1000).toStringAsFixed(2)} km';
            durationText = '${(duration / 60).toStringAsFixed(1)} min';
          });
          print('DEBUG: Route set successfully via OSRM');
          return;
        }
      }
    } catch (e) {
      print('DEBUG: OSRM fallback failed: $e');
    }

    // If both services fail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to get route. Please check your internet connection.')),
    );
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          userLocation = null; // Don't default to New Delhi
        });
        // Optionally show a dialog/snackbar to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied. Please enable location services.')),
        );
        return;
      }
    }

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
      });
      _fetchNearbyHospitals();
    });
    // Get initial location
    final pos = await LocationUtils.getCurrentLocation();
    setState(() {
      userLocation = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    });
    _fetchNearbyHospitals();
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

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void _showHospitalListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nearby Hospitals (${hospitals.length})'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              final hospitalPoint = LatLng(hospital.lat, hospital.lon);
              final distance = _calculateDistance(userLocation!, hospitalPoint);
              
              return ListTile(
                leading: Icon(Icons.local_hospital, color: Colors.red),
                title: Text(hospital.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hospital.address != null) Text(hospital.address!),
                    Text('${(distance / 1000).toStringAsFixed(1)} km away'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _getRouteTo(hospital);
                  },
                  child: Text('Route'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to Hospitals'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('DEBUG: Manual refresh triggered');
              _fetchNearbyHospitals();
            },
            tooltip: 'Refresh Hospitals',
          ),
        ],
      ),
      body: userLocation == null
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: userLocation!,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, point) {
                  print('DEBUG: Map tapped at: $point');
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Navigate to Location'),
                      content: Text('Do you want directions to:\nLat: ${point.latitude.toStringAsFixed(6)},\nLng: ${point.longitude.toStringAsFixed(6)}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _routeToLatLng(point);
                          },
                          child: Text('Get Directions'),
                        ),
                      ],
                    ),
                  );
                },
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
                        child: Icon(Icons.my_location, color: Colors.blue, size: 32),
                      ),
                    // Group members
                    ...groupMembers.where((m) => m.latitude != null && m.longitude != null).map((m) => Marker(
                      point: LatLng(m.latitude!, m.longitude!),
                      width: 40,
                      height: 40,
                      child: _MapTypeMarker(type: 'Group', color: Colors.blue),
                    )),
                    // SOS messages
                    ...sosMessages.where((s) => s.latitude != null && s.longitude != null).map((s) => Marker(
                      point: LatLng(s.latitude!, s.longitude!),
                      width: 40,
                      height: 40,
                      child: _MapTypeMarker(type: 'Rescue', color: Colors.red),
                    )),
                    // Resources
                    ...resources.where((r) => r.latitude != null && r.longitude != null).map((r) => Marker(
                      point: LatLng(r.latitude!, r.longitude!),
                      width: 40,
                      height: 40,
                      child: _MapTypeMarker(type: 'Resource', color: Colors.orange),
                    )),
                    // Hospitals
                    ...hospitals.map((h) => Marker(
                      point: LatLng(h.lat, h.lon),
                      width: 48,
                      height: 48,
                      child: Icon(Icons.local_hospital, color: Colors.red, size: 32),
                    )),
                  ],
                ),
                if (routePolyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePolyline,
                        color: Colors.green,
                        strokeWidth: 5,
                      )
                    ],
                  ),
              ],
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (distanceText != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Distance: $distanceText | Time: $durationText',
                style: TextStyle(fontSize: 16),
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

  void _onHospitalTap(Hospital hospital) {
    print('Opening bottom sheet for hospital: \'${hospital.name}\'');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.pink, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Text(hospital.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              if (hospital.address != null) ...[
                SizedBox(height: 8),
                Text(hospital.address!, style: TextStyle(fontSize: 16)),
              ],
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.directions),
                label: Text('Get Directions'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDirectionsToHospital(hospital);
                },
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text('Open in Google Maps'),
                onPressed: () {
                  _openInGoogleMaps(hospital);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInGoogleMaps(Hospital hospital) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${hospital.lat},${hospital.lon}&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _showDirectionsToHospital(Hospital hospital) async {
    if (userLocation == null) return;
    final start = '${userLocation!.longitude},${userLocation!.latitude}';
    final end = '${hospital.lon},${hospital.lat}';
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        routePolyline = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  void _routeToLatLng(LatLng destination) async {
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available. Please enable location services.')),
      );
      return;
    }
    try {
      final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');
      final body = json.encode({
        "coordinates": [
          [userLocation!.longitude, userLocation!.latitude],
          [destination.longitude, destination.latitude]
        ]
      });
      final response = await http.post(
        url,
        headers: {
          'Authorization': openRouteApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['features'] != null && data['features'].isNotEmpty) {
          final route = data['features'][0]['geometry']['coordinates'] as List;
          final summary = data['features'][0]['properties']['summary'];
          setState(() {
            routePolyline = route.map((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
            distanceText = '${(summary['distance'] / 1000).toStringAsFixed(2)} km';
            durationText = '${(summary['duration'] / 60).toStringAsFixed(1)} min';
          });
          return;
        }
      }
    } catch (e) {
      print('OpenRouteService failed: $e');
    }
    // Fallback to OSRM
    try {
      final start = '${userLocation!.longitude},${userLocation!.latitude}';
      final end = '${destination.longitude},${destination.latitude}';
      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final distance = data['routes'][0]['distance'] as double;
          final duration = data['routes'][0]['duration'] as double;
          setState(() {
            routePolyline = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
            distanceText = '${(distance / 1000).toStringAsFixed(2)} km';
            durationText = '${(duration / 60).toStringAsFixed(1)} min';
          });
          return;
        }
      }
    } catch (e) {
      print('OSRM fallback failed: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to get route. Please check your internet connection.')),
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