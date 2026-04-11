// ============================================================
// screen: responder_dashboard.dart  (RESPONDER side)
// • Unit type selector (Ambulance / Fire / Police)
// • Real-time list of pending emergencies (StreamBuilder)
// • Accept → navigate to responder map
// • Reject → snackbar dismiss (Firestore unchanged)
// • Seeder button: pre-populates Firestore with sample data
// • Graceful handling when Firebase is not yet configured
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/emergency.dart';
import '../../models/responder.dart';
import '../../services/firebase_service.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../theme/app_theme.dart';
import 'responder_map_screen.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  // ── State ─────────────────────────────────────────────────
  ResponderType _unitType = ResponderType.ambulance;
  bool _isOnline = true;
  bool _isSeeding = false;

  // Demo responder ID (in production, use Auth UID)
  static const String _myResponderId = 'responder_001';

  // ── Unit type tabs ────────────────────────────────────────
  static const _units = [
    (type: ResponderType.ambulance, label: 'Ambulance', emoji: '🚑'),
    (type: ResponderType.fire,      label: 'Fire',      emoji: '🚒'),
    (type: ResponderType.police,    label: 'Police',    emoji: '🚓'),
  ];

  // Maps responder type → emergency type string for Firestore query
  String get _emergencyTypeFilter {
    switch (_unitType) {
      case ResponderType.ambulance: return 'medical';
      case ResponderType.fire:      return 'fire';
      case ResponderType.police:    return 'police';
    }
  }

  // ── Toggle online status ───────────────────────────────────
  Future<void> _toggleOnline() async {
    try {
      final newStatus =
          _isOnline ? ResponderStatus.offline : ResponderStatus.available;
      await FirebaseService.instance.setResponderStatus(
        _myResponderId,
        newStatus,
      );
      setState(() => _isOnline = !_isOnline);
    } catch (e) {
      _showError('Could not update status: $e');
    }
  }

  // ── Accept emergency ───────────────────────────────────────
  Future<void> _acceptEmergency(Emergency emergency) async {
    try {
      // Get responder's current GPS position
      final position = await LocationService.instance.getCurrentLocation();

      // Assign in Firestore
      await FirebaseService.instance.assignResponder(
        emergency.id,
        _myResponderId,
      );
      await FirebaseService.instance.setResponderStatus(
        _myResponderId,
        ResponderStatus.busy,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResponderMapScreen(
              emergency: emergency,
              responderId: _myResponderId,
              responderLat: position.latitude,
              responderLng: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Could not accept emergency: $e');
    }
  }

  // ── Seed sample Firestore data ────────────────────────────
  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    try {
      final db = FirebaseFirestore.instance;

      // Seed THIS responder
      await db.collection('responders').doc(_myResponderId).set({
        'type': _emergencyTypeFilter == 'medical' ? 'ambulance' : _emergencyTypeFilter,
        'status': 'available',
        'location': const GeoPoint(12.9716, 77.5946), // Bangalore default
      });

      // Seed a sample emergency of the current type
      await db.collection('emergencies').add({
        'type': _emergencyTypeFilter,
        'status': 'pending',
        'user_location': const GeoPoint(12.9800, 77.6000),
        'responder_location': null,
        'responder_id': null,
        'timestamp': Timestamp.now(),
        'contact_phone': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Demo data seeded! You should see a ${_units.firstWhere((u) => u.type == _unitType).label} emergency now.',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _showError(
        'Seeding failed. Is Firebase configured?\n'
        'Add google-services.json to android/app/\nError: $e',
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildUnitSelector(),
            _buildStatusBar(),
            const Divider(color: Color(0xFF1E2A40), height: 1),
            Expanded(child: _buildEmergencyList()),
          ],
        ),
      ),
      // Seed demo data FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSeeding ? null : _seedDemoData,
        backgroundColor: AppTheme.info,
        icon: _isSeeding
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          _isSeeding ? 'Seeding…' : 'Add Test SOS',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          BackButton(
            color: AppTheme.onSurface,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const Expanded(
            child: Text(
              'Responder Dashboard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          // Online / offline toggle
          GestureDetector(
            onTap: _toggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isOnline
                    ? AppTheme.success.withValues(alpha: 0.2)
                    : AppTheme.muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnline ? AppTheme.success : AppTheme.muted,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOnline ? Icons.circle : Icons.circle_outlined,
                    color: _isOnline ? AppTheme.success : AppTheme.muted,
                    size: 10,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? AppTheme.success : AppTheme.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Unit selector tabs ────────────────────────────────────
  Widget _buildUnitSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _units.map((u) {
          final selected = _unitType == u.type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _unitType = u.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.muted.withValues(alpha: 0.2),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(u.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      u.label,
                      style: TextStyle(
                        color: selected ? AppTheme.primary : AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Status bar ────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.notifications_active,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Incoming — ${_units.firstWhere((u) => u.type == _unitType).label}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Hint text
          const Text(
            'Tap ➕ to add test SOS',
            style: TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Emergency list ────────────────────────────────────────
  Widget _buildEmergencyList() {
    return StreamBuilder<List<Emergency>>(
      stream: FirebaseService.instance
          .listenToNewEmergencies(_emergencyTypeFilter),
      builder: (context, snap) {
        // ── Loading ──────────────────────────────────────────
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to Firebase…',
                    style: TextStyle(color: AppTheme.muted)),
              ],
            ),
          );
        }

        // ── Firebase / Firestore error ────────────────────────
        if (snap.hasError) {
          final err = snap.error.toString();
          // Detect missing composite index — give helpful link
          final isIndexError = err.contains('indexes') || err.contains('index');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.cloud_off,
                    color: AppTheme.primary, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Firebase Error',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (isIndexError) ...[
                  const Text(
                    '⚠️ Firestore needs a composite index.\n'
                    'Check the error URL below and click it to auto-create the index in Firebase Console.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.warning, fontSize: 13),
                  ),
                ] else ...[
                  const Text(
                    '⚠️ Firebase is not configured.\n'
                    'Add google-services.json to android/app/\n'
                    'or use "Add Test SOS" button (bottom right) after configuring Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFF1E2A40))),
                  ),
                  child: SelectableText(
                    err,
                    style: const TextStyle(
                        color: AppTheme.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Empty state ───────────────────────────────────────
        final emergencies = snap.data ?? [];
        if (emergencies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    color: AppTheme.success.withValues(alpha: 0.5),
                    size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No pending emergencies',
                  style: TextStyle(color: AppTheme.muted, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap ➕ bottom-right to add a test SOS',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // ── List ──────────────────────────────────────────────
        return ListView.builder(
          itemCount: emergencies.length,
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemBuilder: (_, i) => _EmergencyCard(
            emergency: emergencies[i],
            onAccept: () => _acceptEmergency(emergencies[i]),
            onReject: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency skipped.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Emergency card (Stateful for async geocoding) ─────────────
class _EmergencyCard extends StatefulWidget {
  final Emergency emergency;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _EmergencyCard({
    required this.emergency,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard> {
  String _locationName = 'Locating…';
  String? _distanceLabel;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _loadLocationInfo();
  }

  Future<void> _loadLocationInfo() async {
    final em = widget.emergency;
    // Reverse geocode lat/lng → human address
    final name = await GeocodingService.instance.reverseGeocode(
      lat: em.userLocation.latitude,
      lng: em.userLocation.longitude,
    );
    if (!mounted) return;
    setState(() => _locationName = name);

    // Haversine distance from the responder's current GPS
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final dist = LocationService.haversineDistance(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: em.userLocation.latitude,
        lon2: em.userLocation.longitude,
      );
      if (!mounted) return;
      setState(() {
        _distanceLabel = dist < 1.0
            ? '${(dist * 1000).round()} m away'
            : '${dist.toStringAsFixed(1)} km away';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.emergency.timestamp.toDate();
    final time =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: emoji + type + PENDING badge ──────────
            Row(
              children: [
                Text(
                  widget.emergency.type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.emergency.type.name.toUpperCase()} EMERGENCY',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Received at $time',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Location name (reverse-geocoded) ──────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2A40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationName,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.emergency.userLocation.latitude.toStringAsFixed(5)}, '
                          '${widget.emergency.userLocation.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (_distanceLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.info.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _distanceLabel!,
                        style: const TextStyle(
                          color: AppTheme.info,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Action buttons ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.muted,
                      side: const BorderSide(color: AppTheme.muted),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            setState(() => _isAccepting = true);
                            widget.onAccept();
                          },
                    icon: _isAccepting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isAccepting ? 'Accepting…' : 'Accept'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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


