// ============================================================
// screen: emergency_map_screen.dart  (CITIZEN side)
// • Real-time Firestore listener (StreamBuilder)
// • Animated emoji marker 🚑/🚒/🚓 updating every 3–5 s
// • Polyline route drawn from Directions API encoded polyline
// • Real ETA from Directions API (falls back to haversine estimate)
// • StatusBanner + bottom info card
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/emergency.dart';
import '../../services/firebase_service.dart';
import '../../services/location_service.dart';
import '../../services/directions_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/emoji_marker_utils.dart';

class EmergencyTrackingScreen extends StatefulWidget {
  final String emergencyId;
  final double userLat;
  final double userLng;

  const EmergencyTrackingScreen({
    super.key,
    required this.emergencyId,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<EmergencyTrackingScreen> createState() =>
      _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState
    extends State<EmergencyTrackingScreen> {
  GoogleMapController? _mapController;

  // Cached emoji BitmapDescriptors (loaded once per type)
  final Map<String, BitmapDescriptor> _emojiIcons = {};

  // Polyline drawn on the map
  final Set<Polyline> _polylines = {};

  // Last known polyline string (avoid redrawing if unchanged)
  String? _lastPolyline;

  // Live ETA from Directions API (updated as responder moves)
  String? _liveEta;
  // Throttle: only re-query Directions API every 30 s
  DateTime? _lastEtaQuery;

  Future<BitmapDescriptor> _getIcon(String emergencyType, String? etaLabel) async {
    final emoji = responderEmoji(emergencyType == 'medical'
        ? 'ambulance'
        : emergencyType);
    final cacheKey = '${emoji}_$etaLabel';
    if (_emojiIcons.containsKey(cacheKey)) return _emojiIcons[cacheKey]!;
    
    // Generates a 60px Zomato-style map marker with dynamic ETA pill
    final icon = await emojiToBitmapDescriptor(
      emoji, 
      size: 60, 
      etaLabel: etaLabel,
    );
    _emojiIcons[cacheKey] = icon;
    return icon;
  }

  // ── Build markers ─────────────────────────────────────────
  Future<Set<Marker>> _buildMarkersAsync(
      Emergency emergency, String? displayEta) async {
    final markers = <Marker>{};

    // User location — blue marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(
          emergency.userLocation.latitude,
          emergency.userLocation.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '🆘 Your Location'),
      ),
    );

    // Responder — animated emoji marker
    if (emergency.responderLocation != null) {
      final icon = await _getIcon(emergency.type.name, displayEta);
      markers.add(
        Marker(
          markerId: const MarkerId('responder'),
          position: LatLng(
            emergency.responderLocation!.latitude,
            emergency.responderLocation!.longitude,
          ),
          icon: icon,
          infoWindow: InfoWindow(
            title:
                '${responderEmoji(emergency.type.name == 'medical' ? 'ambulance' : emergency.type.name)} On the way',
            snippet: displayEta != null ? 'ETA: $displayEta' : null,
          ),
          zIndex: 1,
        ),
      );
    }

    return markers;
  }

  // ── Draw polyline from encoded string ─────────────────────
  void _updatePolyline(String? encoded) {
    if (encoded == null || encoded == _lastPolyline) return;
    _lastPolyline = encoded;
    final points = _decodePolyline(encoded);
    if (mounted) {
      setState(() {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: AppTheme.info,
            width: 5,
            patterns: [],
          ));
      });
    }
  }

  // ── Google-encoded polyline decoder ───────────────────────
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ── Refresh ETA from Directions API (throttled 30 s) ──────
  Future<void> _refreshEta(Emergency emergency) async {
    if (emergency.responderLocation == null) return;
    final now = DateTime.now();
    if (_lastEtaQuery != null &&
        now.difference(_lastEtaQuery!).inSeconds < 30) return;
    _lastEtaQuery = now;

    final result = await DirectionsService.instance.getRoute(
      originLat: emergency.responderLocation!.latitude,
      originLng: emergency.responderLocation!.longitude,
      destLat: emergency.userLocation.latitude,
      destLng: emergency.userLocation.longitude,
    );

    if (result != null && mounted) {
      setState(() {
        _liveEta = '~${result.durationMinutes} min';
      });
      // Also update polyline if we got a fresh one
      _updatePolyline(result.encodedPolyline);
    } else {
      // Fallback: haversine estimate
      final distKm = LocationService.haversineDistance(
        lat1: emergency.responderLocation!.latitude,
        lon1: emergency.responderLocation!.longitude,
        lat2: emergency.userLocation.latitude,
        lon2: emergency.userLocation.longitude,
      );
      final mins = (distKm / 60 * 60).ceil(); // 60 km/h
      if (mounted) setState(() => _liveEta = '~$mins min (est.)');
    }
  }

  // ── Smooth camera follow ───────────────────────────────────
  void _moveCameraToResponder(GeoPoint loc) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Emergency>(
        stream: FirebaseService.instance
            .listenToEmergency(widget.emergencyId),
        builder: (context, snap) {
          // ── Loading ────────────────────────────────────────
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Stream error: ${snap.error}',
                  style: const TextStyle(color: AppTheme.primary)),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: Text('Waiting for emergency data…',
                  style: TextStyle(color: AppTheme.muted)),
            );
          }

          final emergency = snap.data!;

          // Decode stored polyline when it changes
          if (emergency.routePolyline != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updatePolyline(emergency.routePolyline);
            });
          }

          // Refresh live ETA + camera follow
          if (emergency.responderLocation != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _moveCameraToResponder(emergency.responderLocation!);
              if (emergency.status == EmergencyStatus.onTheWay) {
                _refreshEta(emergency);
              }
            });
          }

          // Show stored ETA from Firestore if liveEta not yet loaded
          final displayEta = _liveEta ??
              (emergency.etaSeconds != null
                  ? '~${(emergency.etaSeconds! / 60).ceil()} min'
                  : null);

          return FutureBuilder<Set<Marker>>(
            future: _buildMarkersAsync(emergency, displayEta),
            builder: (context, markerSnap) {
              final markers = markerSnap.data ?? {};
              return Stack(
                children: [
                  // ── Full-screen Google Map ─────────────────
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.userLat, widget.userLng),
                      zoom: 14,
                    ),
                    markers: markers,
                    polylines: _polylines,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (ctrl) => _mapController = ctrl,
                  ),

                  // ── Top overlay ───────────────────────────
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Container(
                            color: AppTheme.surface.withOpacity(0.92),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                BackButton(
                                  color: AppTheme.onSurface,
                                  onPressed: () =>
                                      Navigator.pop(context),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Live Tracking',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface),
                                  ),
                                ),
                                if (emergency.responderId != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppTheme.success
                                              .withOpacity(0.5)),
                                    ),
                                    child: const Text('Assigned',
                                        style: TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ),
                          StatusBanner(
                            status: emergency.status.name,
                            eta: displayEta,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom info card ──────────────────────
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _buildInfoCard(emergency, displayEta),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Emergency emergency, String? eta) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF1E2A40))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.muted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Text(
                '${emergency.type.emoji}  '
                '${emergency.type.name.toUpperCase()} EMERGENCY',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.onSurface),
              ),
              const Spacer(),
              // ETA chip
              if (eta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.info.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: AppTheme.info, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'ETA $eta',
                        style: const TextStyle(
                            color: AppTheme.info,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.location_on,
            label: 'Your location',
            value:
                '${emergency.userLocation.latitude.toStringAsFixed(5)}, '
                '${emergency.userLocation.longitude.toStringAsFixed(5)}',
          ),
          if (emergency.responderLocation != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.directions_car,
              label: 'Responder',
              value:
                  '${emergency.responderLocation!.latitude.toStringAsFixed(5)}, '
                  '${emergency.responderLocation!.longitude.toStringAsFixed(5)}',
              valueColor: AppTheme.primary,
            ),
          ],
          if (emergency.responderId == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top,
                      color: AppTheme.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Searching for fastest available responder…',
                      style:
                          TextStyle(color: AppTheme.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable info row ─────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.muted, size: 15),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}