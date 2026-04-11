// ============================================================
// service: location_service.dart
// Handles GPS permission, single location fetch, and stream.
// Also provides haversine distance utility.
// ============================================================

import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ── Singleton ─────────────────────────────────────────────
  LocationService._privateConstructor();
  static final LocationService instance =
      LocationService._privateConstructor();

  // ── Permission + single fix ───────────────────────────────

  /// Checks permissions and returns the current GPS position.
  Future<Position> getCurrentLocation() async {
    // STEP 1: Check if location service is enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // STEP 2: Check / request runtime permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in the device settings.',
      );
    }

    // STEP 3: Return the current position
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ── Continuous stream (responder side) ────────────────────

  /// Returns a stream of [Position] updates every 5 seconds.
  /// Used by the responder map to broadcast live location to Firestore.
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres – only emit when moved ≥ 10 m
        // On Android, positions are emitted at least once / 5 s by default
      ),
    );
  }

  // ── Haversine distance ─────────────────────────────────────

  /// Computes great-circle distance in **kilometres** between two coordinates.
  /// Used by [DispatchService] to find the nearest responder.
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);

    final double a =
        pow(sin(dLat / 2), 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * pow(sin(dLon / 2), 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}