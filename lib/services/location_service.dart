import 'package:geolocator/geolocator.dart';

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}

/// Location Service - Handles GPS permission gatekeeping and location fetching
/// Part of the microservice architecture for the Emergency Resource Dispatch System
class LocationService {
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() => _instance;
  
  LocationService._internal();
  /// Check permissions and get current position
  /// Returns Position if successful, throws error if permissions denied or GPS disabled
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled; don't continue.
      throw LocationServiceException('Location services are disabled. Please enable GPS in settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permissions are denied. Emergency will be sent without location.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permissions are permanently denied. Emergency will be sent without location.'
      );
    } 

    // 2. When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 15),
    );
  }
}
