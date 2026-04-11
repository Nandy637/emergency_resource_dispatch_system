// ============================================================
// screen: responder_map_screen.dart  (RESPONDER side)
// • Broadcasts responder GPS every 5 s to Firestore
// • GoogleMap showing user pin (destination) + self marker
// • Status action buttons: On the Way → Arrived → Completed
// • "Navigate" button opens Google Maps deep-link
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency.dart';
import '../../models/responder.dart';
import '../../services/firebase_service.dart';
import '../../services/location_service.dart';
import '../../services/directions_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_banner.dart';

class ResponderMapScreen extends StatefulWidget {
  final Emergency emergency;
  final String responderId;
  final double responderLat;
  final double responderLng;

  const ResponderMapScreen({
    super.key,
    required this.emergency,
    required this.responderId,
    required this.responderLat,
    required this.responderLng,
  });

  @override
  State<ResponderMapScreen> createState() => _ResponderMapScreenState();
}

class _ResponderMapScreenState extends State<ResponderMapScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Current responder position
  late double _myLat;
  late double _myLng;

  // Current emergency status
  late EmergencyStatus _currentStatus;

  // Location broadcast subscription
  StreamSubscription<Position>? _locationSub;

  // Emoji marker icons (loaded once)
  BitmapDescriptor? _selfIcon;
  BitmapDescriptor? _destIcon;

  // Live ETA from Directions API
  String? _liveEta;
  DateTime? _lastEtaQuery;

  @override
  void initState() {
    super.initState();
    _myLat = widget.responderLat;
    _myLng = widget.responderLng;
    _currentStatus = widget.emergency.status;
    _loadIconsThenBuildMarkers();
    _startLocationBroadcast();
  }

  void _loadIconsThenBuildMarkers() {
    _selfIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _destIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    
    // Build initial markers
    _addUserMarker();
    _addSelfMarker(_myLat, _myLng);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  // ── markers ───────────────────────────────────────────────

  void _addUserMarker() {
    final userPos = LatLng(
      widget.emergency.userLocation.latitude,
      widget.emergency.userLocation.longitude,
    );
    _markers.removeWhere((m) => m.markerId.value == 'user');
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: userPos,
        icon: _destIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '🆘 Emergency Location'),
      ),
    );
  }

  void _addSelfMarker(double lat, double lng) {
    _markers.removeWhere((m) => m.markerId.value == 'self');
    _markers.add(
      Marker(
        markerId: const MarkerId('self'),
        position: LatLng(lat, lng),
        icon: _selfIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'You',
          snippet: _liveEta != null ? 'ETA: $_liveEta' : null,
        ),
        zIndex: 1,
      ),
    );
  }

  // ── live location broadcast ────────────────────────────────

  void _startLocationBroadcast() {
    _locationSub =
        LocationService.instance.getLocationStream().listen((pos) async {
      setState(() {
        _myLat = pos.latitude;
        _myLng = pos.longitude;
        _addSelfMarker(_myLat, _myLng);
      });

      // Push to Firestore
      await FirebaseService.instance.updateResponderLocationOnEmergency(
        widget.emergency.id,
        GeoPoint(pos.latitude, pos.longitude),
      );
      await FirebaseService.instance.updateResponderLocation(
        widget.responderId,
        GeoPoint(pos.latitude, pos.longitude),
      );

      // Refresh ETA from Directions API (throttled every 30 s)
      await _refreshEta(pos.latitude, pos.longitude);
    });
  }

  // ── Live ETA refresh (Directions API, throttled) ───────────
  Future<void> _refreshEta(double fromLat, double fromLng) async {
    final now = DateTime.now();
    if (_lastEtaQuery != null &&
        now.difference(_lastEtaQuery!).inSeconds < 30) return;
    _lastEtaQuery = now;

    final result = await DirectionsService.instance.getRoute(
      originLat: fromLat,
      originLng: fromLng,
      destLat: widget.emergency.userLocation.latitude,
      destLng: widget.emergency.userLocation.longitude,
    );

    if (result != null && mounted) {
      setState(() => _liveEta = '~${result.durationMinutes} min');
      // Update Firestore with fresh ETA
      await FirebaseService.instance.updateRouteData(
        emergencyId: widget.emergency.id,
        etaSeconds: result.durationSecs,
        encodedPolyline: result.encodedPolyline,
      );
    }
  }

  // ── status controls ───────────────────────────────────────

  Future<void> _updateStatus(EmergencyStatus newStatus) async {
    await FirebaseService.instance.updateEmergencyStatus(
      widget.emergency.id,
      newStatus,
    );
    setState(() => _currentStatus = newStatus);

    if (newStatus == EmergencyStatus.completed) {
      // Mark responder available again
      await FirebaseService.instance.setResponderStatus(
        widget.responderId,
        ResponderStatus.available,
      );
      _locationSub?.cancel();
    }
  }

  // ── Google Maps deep-link navigation ─────────────────────

  Future<void> _openNavigation() async {
    final destLat = widget.emergency.userLocation.latitude;
    final destLng = widget.emergency.userLocation.longitude;

    // Try Google Maps app first, fallback to browser
    final appUri = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destLat,$destLng&travelmode=driving',
    );

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_myLat, _myLng),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),

          // Top overlay — AppBar + status banner
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
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'En Route',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigation,
                              color: AppTheme.info),
                          tooltip: 'Open Navigation',
                          onPressed: _openNavigation,
                        ),
                      ],
                    ),
                  ),
                  StatusBanner(
                    status: _currentStatus.name,
                    eta: _liveEta,
                  ),
                ],
              ),
            ),
          ),

          // Bottom action sheet
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildActionSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2A40)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.muted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '${widget.emergency.type.emoji}  '
            '${widget.emergency.type.name.toUpperCase()} EMERGENCY',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Destination: '
            '${widget.emergency.userLocation.latitude.toStringAsFixed(4)}, '
            '${widget.emergency.userLocation.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Status actions
          ..._buildStatusButtons(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openNavigation,
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Navigate in Google Maps'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusButtons() {
    switch (_currentStatus) {
      case EmergencyStatus.assigned:
      case EmergencyStatus.pending:
        return [
          ElevatedButton.icon(
            onPressed: () => _updateStatus(EmergencyStatus.onTheWay),
            icon: const Icon(Icons.directions_car),
            label: const Text('Mark: On the Way'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case EmergencyStatus.onTheWay:
        return [
          ElevatedButton.icon(
            onPressed: () => _updateStatus(EmergencyStatus.arrived),
            icon: const Icon(Icons.location_on),
            label: const Text('Mark: Arrived at Scene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case EmergencyStatus.arrived:
        return [
          ElevatedButton.icon(
            onPressed: () => _updateStatus(EmergencyStatus.completed),
            icon: const Icon(Icons.task_alt),
            label: const Text('Mark: Incident Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      default:
        return [
          const Center(
            child: Text(
              '✓ Incident resolved',
              style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700),
            ),
          ),
        ];
    }
  }
}
