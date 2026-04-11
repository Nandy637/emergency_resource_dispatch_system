// ============================================================
// service: geocoding_service.dart
// Reverse geocodes a lat/lng → human-readable location name
// using Google Maps Geocoding API.
// Returns the most useful short label (road + area / city).
// Falls back to coordinate string on any error.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'directions_service.dart'; // shares the same API key const

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Returns a short, human-readable location label for [lat],[lng].
  ///
  /// Priority (first found wins):
  ///   1. route + sublocality (e.g. "MG Road, Indiranagar")
  ///   2. sublocality_level_1 (e.g. "Indiranagar")
  ///   3. locality / city         (e.g. "Bengaluru")
  ///   4. Formatted address first component
  ///   5. Fallback → "12.9716, 77.5946"
  Future<String> reverseGeocode({
    required double lat,
    required double lng,
    String apiKey = kGoogleMapsApiKey,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latlng': '$lat,$lng',
        'key': apiKey,
        'result_type': 'street_address|route|sublocality|locality',
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return _fallback(lat, lng);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((body['status'] as String?) != 'OK') return _fallback(lat, lng);

      final results = body['results'] as List?;
      if (results == null || results.isEmpty) return _fallback(lat, lng);

      // Parse the first result's address_components
      final components =
          (results[0]['address_components'] as List?) ?? [];

      String? route;
      String? sublocality;
      String? locality;

      for (final comp in components) {
        final types = List<String>.from(comp['types'] as List? ?? []);
        final short = comp['short_name'] as String? ?? '';
        if (types.contains('route') && route == null) route = short;
        if (types.contains('sublocality_level_1') && sublocality == null) {
          sublocality = short;
        }
        if (types.contains('locality') && locality == null) locality = short;
      }

      // Build the best short label
      if (route != null && sublocality != null) {
        return '$route, $sublocality';
      }
      if (route != null && locality != null) {
        return '$route, $locality';
      }
      if (sublocality != null) return sublocality;
      if (locality != null) return locality;

      // Last resort: first part of formatted_address
      final formatted = results[0]['formatted_address'] as String? ?? '';
      if (formatted.isNotEmpty) {
        return formatted.split(',').take(2).join(',').trim();
      }

      return _fallback(lat, lng);
    } catch (_) {
      return _fallback(lat, lng);
    }
  }

  static String _fallback(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}
