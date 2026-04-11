// ============================================================
// service: directions_service.dart
// Calls Google Directions API to get real drive-time, distance,
// and an encoded polyline for the fastest route.
// Falls back gracefully (returns null) on any network error.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── paste your Google Maps API key here ───────────────────────
const String kGoogleMapsApiKey = 'AIzaSyDE2n9sQdYqugM7DmcBou_B0qCpVxN6JLg';

/// Result returned by [DirectionsService.getRoute].
class DirectionsResult {
  /// Estimated drive time in seconds.
  final int durationSecs;

  /// Route distance in metres.
  final int distanceMeters;

  /// Google-encoded polyline string (for drawing on map).
  final String encodedPolyline;

  const DirectionsResult({
    required this.durationSecs,
    required this.distanceMeters,
    required this.encodedPolyline,
  });

  /// Duration converted to whole minutes (ceiling).
  int get durationMinutes => (durationSecs / 60).ceil();
}

class DirectionsService {
  DirectionsService._();
  static final DirectionsService instance = DirectionsService._();

  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetches the fastest driving route from [originLat],[originLng]
  /// to [destLat],[destLng].
  ///
  /// Returns null on any error so callers can fall back to haversine.
  Future<DirectionsResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String apiKey = kGoogleMapsApiKey,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': 'driving',
        'key': apiKey,
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status != 'OK') return null;

      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final legs = (routes[0]['legs'] as List?) ?? [];
      if (legs.isEmpty) return null;

      final leg = legs[0] as Map<String, dynamic>;
      final durationSecs =
          (leg['duration']['value'] as num).toInt();
      final distanceMeters =
          (leg['distance']['value'] as num).toInt();
      final polyline =
          routes[0]['overview_polyline']['points'] as String? ?? '';

      return DirectionsResult(
        durationSecs: durationSecs,
        distanceMeters: distanceMeters,
        encodedPolyline: polyline,
      );
    } catch (_) {
      // Network error, timeout, JSON parse error → caller falls back
      return null;
    }
  }
}
