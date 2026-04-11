// ============================================================
// service: dispatch_service.dart
// Smart dispatch logic – finds the FASTEST-ROUTE responder
// (Google Directions API) and auto-assigns in Firestore.
// Falls back to haversine distance if Directions API fails.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency.dart';
import '../models/responder.dart';
import 'firebase_service.dart';
import 'location_service.dart';
import 'directions_service.dart';

class DispatchService {
  // ── singleton ────────────────────────────────────────────
  DispatchService._();
  static final DispatchService instance = DispatchService._();

  final _fb = FirebaseService.instance;
  final _directions = DirectionsService.instance;

  // ── type mapping ──────────────────────────────────────────
  static String _responderTypeFor(EmergencyType t) {
    switch (t) {
      case EmergencyType.medical: return 'ambulance';
      case EmergencyType.fire:    return 'fire';
      case EmergencyType.police:  return 'police';
    }
  }

  // ════════════════════════════════════════════════════════
  //  SMART PRIORITY ENGINE  (Directions API – fastest route)
  // ════════════════════════════════════════════════════════

  /// Find and assign the FASTEST-ROUTE available responder.
  ///
  /// Priority ranking:
  ///  1. Google Directions API drive-time (seconds) — most accurate
  ///  2. Haversine distance (km) fallback — if API fails
  ///
  /// Steps:
  ///  1. Fetch all available responders of the correct type.
  ///  2. Query Directions API for each; build a sorted list by ETA.
  ///  3. Write assignment + route data to Firestore atomically.
  ///
  /// Returns the assigned [Responder], or `null` if none available.
  Future<Responder?> assignFastestRouteResponder(Emergency emergency) async {
    final responderType = _responderTypeFor(emergency.type);

    // 1. Fetch candidates
    final candidates = await _fb.getAvailableResponders(responderType);
    if (candidates.isEmpty) return null;

    final userLat = emergency.userLocation.latitude;
    final userLng = emergency.userLocation.longitude;

    // 2a. Try Directions API for each candidate (parallel)
    final etaFutures = candidates.map((r) => _directions.getRoute(
          originLat: r.location.latitude,
          originLng: r.location.longitude,
          destLat: userLat,
          destLng: userLng,
        ));

    final results = await Future.wait(etaFutures);

    // 2b. Pair each candidate with its ETA result
    Responder? bestResponder;
    DirectionsResult? bestRoute;
    int bestEtaSecs = 999999;
    double bestDistKm = double.infinity;

    for (int i = 0; i < candidates.length; i++) {
      final r = candidates[i];
      final route = results[i];

      if (route != null) {
        // API succeeded → rank by drive-time
        if (route.durationSecs < bestEtaSecs) {
          bestEtaSecs = route.durationSecs;
          bestResponder = r;
          bestRoute = route;
        }
      } else {
        // API failed for this candidate → haversine fallback rank
        // Only use if no API result found yet for this iteration
        if (bestResponder == null) {
          final dist = LocationService.haversineDistance(
            lat1: userLat, lon1: userLng,
            lat2: r.location.latitude, lon2: r.location.longitude,
          );
          if (dist < bestDistKm) {
            bestDistKm = dist;
            bestResponder = r;
          }
        }
      }
    }

    if (bestResponder == null) return null;

    // 3. Write assignment to Firestore
    final writes = <Future<void>>[
      _fb.assignResponder(emergency.id, bestResponder.id),
      _fb.setResponderStatus(bestResponder.id, ResponderStatus.busy),
      _fb.updateResponderLocationOnEmergency(
        emergency.id,
        GeoPoint(bestResponder.location.latitude,
                 bestResponder.location.longitude),
      ),
    ];

    // Also persist route data if Directions API succeeded
    if (bestRoute != null) {
      writes.add(
        _fb.updateRouteData(
          emergencyId: emergency.id,
          etaSeconds: bestRoute.durationSecs,
          encodedPolyline: bestRoute.encodedPolyline,
        ),
      );
    }

    await Future.wait(writes);
    return bestResponder;
  }

  // ════════════════════════════════════════════════════════
  //  LEGACY HELPER (kept for backward compat)
  // ════════════════════════════════════════════════════════

  /// Estimate travel time in minutes given distance in km.
  /// Uses a conservative average speed of 60 km/h.
  static int estimateEtaMinutes(double distanceKm) {
    const avgSpeedKmH = 60.0;
    return ((distanceKm / avgSpeedKmH) * 60).ceil();
  }
}
