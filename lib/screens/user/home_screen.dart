// ============================================================
// screen: home_screen.dart  (CITIZEN side)
// • Emergency type selector (Medical / Fire / Police)
// • Family contact phone input
// • Pulsing SOS button (SOSButton widget)
// • Online: saves to Firestore + runs smart dispatch + opens map
// • Offline: fires SMS with GPS coords + type as fallback
// • Family alert: sends SMS to contact with Google Maps link
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency.dart';
import '../../services/location_service.dart';
import '../../services/firebase_service.dart';
import '../../services/dispatch_service.dart';
import '../../services/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sos_button.dart';
import 'emergency_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ─────────────────────────────────────────────────
  EmergencyType _selectedType = EmergencyType.medical;
  bool _isLoading = false;
  bool _isOnline = true;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to connectivity changes for the live network banner
    ConnectivityService.instance.onlineStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    // Set initial connectivity state
    ConnectivityService.instance.isOnline
        .then((v) => mounted ? setState(() => _isOnline = v) : null);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ── Emergency type config ─────────────────────────────────
  static const _types = [
    (type: EmergencyType.medical, label: 'Medical',  emoji: '🏥', color: Color(0xFF43A047)),
    (type: EmergencyType.fire,    label: 'Fire',     emoji: '🔥', color: Color(0xFFE53935)),
    (type: EmergencyType.police,  label: 'Police',   emoji: '🚔', color: Color(0xFF1E88E5)),
  ];

  // ── Connectivity check ─────────────────────────────────────
  Future<bool> _checkOnline() => ConnectivityService.instance.isOnline;

  // ── SOS button handler ────────────────────────────────────
  Future<void> _onSOSPressed() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Get GPS location
      final position = await LocationService.instance.getCurrentLocation();
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      final online = await _checkOnline();

      if (!online) {
        // ── OFFLINE MODE: send SMS fallback ────────────────
        await _sendOfflineSMS(
          lat: position.latitude,
          lng: position.longitude,
          type: _selectedType.name,
        );
        return;
      }

      // ── ONLINE MODE: Firestore + dispatch ─────────────────
      // 2. Build emergency object
      final emergency = Emergency(
        id: '',   // will be set after Firestore creates the doc
        type: _selectedType,
        userLocation: geoPoint,
        status: EmergencyStatus.pending,
        timestamp: Timestamp.now(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // 3. Persist to Firestore
      final emergencyId =
          await FirebaseService.instance.createEmergency(emergency);

      // 4. Smart-dispatch: find FASTEST ROUTE responder (Directions API)
      final updatedEmergency = Emergency(
        id: emergencyId,
        type: emergency.type,
        userLocation: emergency.userLocation,
        status: emergency.status,
        timestamp: emergency.timestamp,
        contactPhone: emergency.contactPhone,
      );
      await DispatchService.instance
          .assignFastestRouteResponder(updatedEmergency);

      // 5. Send family SMS alert if contact provided
      if (emergency.contactPhone != null) {
        await _sendFamilyAlert(
          phone: emergency.contactPhone!,
          lat: position.latitude,
          lng: position.longitude,
        );
      }

      // 6. Navigate to live tracking screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyTrackingScreen(
              emergencyId: emergencyId,
              userLat: position.latitude,
              userLng: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Offline SMS ───────────────────────────────────────────
  Future<void> _sendOfflineSMS({
    required double lat,
    required double lng,
    required String type,
  }) async {
    final body = Uri.encodeComponent(
      'EMERGENCY ($type) at https://maps.google.com/?q=$lat,$lng — Sent via SafeCall SOS',
    );
    final smsUri = Uri.parse('sms:112?body=$body');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app')),
        );
      }
    }
  }

  // ── Family alert SMS ──────────────────────────────────────
  Future<void> _sendFamilyAlert({
    required String phone,
    required double lat,
    required double lng,
  }) async {
    final body = Uri.encodeComponent(
      '⚠️ EMERGENCY ALERT: Your contact pressed SOS!\n'
      'Live location: https://maps.google.com/?q=$lat,$lng\n'
      '— SafeCall SOS',
    );
    final smsUri = Uri.parse('sms:$phone?body=$body');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('SafeCall SOS'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
          color: AppTheme.onSurface,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline
                    ? AppTheme.success.withOpacity(0.15)
                    : AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOnline
                      ? AppTheme.success.withOpacity(0.5)
                      : AppTheme.warning.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: _isOnline ? AppTheme.success : AppTheme.warning,
                    size: 8,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'LIVE' : 'OFFLINE',
                    style: TextStyle(
                      color: _isOnline
                          ? AppTheme.success
                          : AppTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ── Emergency type selector ─────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Type',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _types.map((t) {
                final selected = _selectedType == t.type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? t.color.withOpacity(0.15)
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? t.color
                              : const Color(0xFF1E2A40),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(t.emoji,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            style: TextStyle(
                              color:
                                  selected ? t.color : AppTheme.muted,
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

            const SizedBox(height: 28),

            // ── SOS Button ──────────────────────────────────
            const Text(
              'Press to send SOS',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SOSButton(
              isLoading: _isLoading,
              onPressed: _onSOSPressed,
            ),
            const SizedBox(height: 30),

            // ── Status hint ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFF1E2A40))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your GPS location will be shared with emergency services. '
                      'If offline, an SMS will be sent automatically.',
                      style: const TextStyle(
                          color: AppTheme.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Family alert contact ────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Family Alert (optional)',
                style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter family member phone number',
                hintStyle: const TextStyle(color: AppTheme.muted),
                prefixIcon:
                    const Icon(Icons.phone, color: AppTheme.muted),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E2A40)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E2A40)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}