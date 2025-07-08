import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

// Location helpers
class LocationUtils {
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Format coordinates for display
  static String formatCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return 'Location unavailable';
    }
    
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Calculate distance between two points in meters
  static double calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get last known position
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  // Get address from coordinates (reverse geocoding)
  static Future<String> getAddressFromCoordinates(
    double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Route calculation using OSRM (Open Source Routing Machine)
  static Future<RouteInfo?> calculateRoute(
    double startLat, double startLng, 
    double endLat, double endLng) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          // Convert coordinates to LatLng points
          final points = coordinates.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
          
          return RouteInfo(
            points: points,
            distance: route['distance'] as double,
            duration: route['duration'] as double,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error calculating route: $e');
      return null;
    }
  }

  // Calculate a simple straight-line route (fallback when API is unavailable)
  static RouteInfo calculateStraightLineRoute(
    double startLat, double startLng, 
    double endLat, double endLng) {
    
    final startPoint = LatLng(startLat, startLng);
    final endPoint = LatLng(endLat, endLng);
    final distance = calculateDistance(startLat, startLng, endLat, endLng);
    
    // Estimate duration (assuming average walking speed of 1.4 m/s)
    final estimatedDuration = distance / 1.4;
    
    return RouteInfo(
      points: [startPoint, endPoint],
      distance: distance,
      duration: estimatedDuration,
    );
  }
}

// Route information model
class RouteInfo {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
  });

  String get formattedDistance => LocationUtils.formatDistance(distance);
  
  String get formattedDuration {
    final hours = (duration / 3600).floor();
    final minutes = ((duration % 3600) / 60).round();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
} 