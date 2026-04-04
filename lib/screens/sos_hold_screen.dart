import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tracking_screen.dart';
import '../services/location_service.dart';

const String _baseUrl = 'http://192.168.31.25:8000/api/v1';

/// SOS Active Hold Screen
/// Displays the glowing circular progress effect during SOS activation
class SOSHoldScreen extends StatefulWidget {
  @override
  _SOSHoldScreenState createState() => _SOSHoldScreenState();
}

class _SOSHoldScreenState extends State<SOSHoldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double maxHoldTime = 2.0;
  late AnimationStatusListener _animationListener;
  Position? _userPosition;
  String _locationStatus = "Loading...";
  String? _incidentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Store listener reference to properly clean up
    _animationListener = (status) {
      if (status == AnimationStatus.completed) {
        _navigateToTracking();
      }
    };
    _controller.addStatusListener(_animationListener);

    // Start fetching location in background while countdown plays
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );
      // ignore: invalid_use_of_visible_for_testing_member
      if (mounted) {
        setState(() {
          _userPosition = position;
          _locationStatus = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      // Location fetch failed - user can still proceed with emergency
      // ignore: invalid_use_of_visible_for_testing_member
      if (mounted) {
        setState(() {
          _locationStatus = "Unavailable";
        });
      }
    }
  }

  void _cancelSOS() {
    _controller.stop();
    Navigator.pop(context);
  }

  Future<String?> _submitSOS(Position position) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'user_${position.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['incident_id'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _navigateToTracking() async {
    String? incidentId;

    if (_userPosition != null && !_isSubmitting) {
      _isSubmitting = true;
      incidentId = await _submitSOS(_userPosition!);
    }

    if (incidentId == null) {
      incidentId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingScreen(
          incidentId: incidentId!,
          userLocation: _userPosition,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_animationListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar (Sound/Haptic info)
            _buildTopSettings(),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    // Use onTapDown + onTapUp instead of onLongPress to prevent accidental triggers
                    onTapDown: (_) {
                      _controller.forward();
                    },
                    onTapUp: (_) {
                      if (!_controller.isCompleted) {
                        _controller.stop();
                        _controller.reset();
                      }
                    },
                    onTapCancel: () {
                      if (!_controller.isCompleted) {
                        _controller.stop();
                        _controller.reset();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double progress = _controller.value;
                        double currentTime = progress * maxHoldTime;
                        
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing Ring
                            Container(
                              width: 260,
                              height: 260,
                              child: CustomPaint(
                                painter: RingPainter(progress: progress),
                              ),
                            ),
                            // Center Text
                            Column(
                              children: [
                                Text(
                                  currentTime.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  progress > 0 
                                    ? "Keep pressing to send SOS\n— release to cancel"
                                    : "Press and hold to activate SOS",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info Cards
            _buildBottomStats(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSettings() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconLabel(Icons.volume_up, "Sound: Soft"),
          // Cancel button - visible during hold
          TextButton(
            onPressed: _cancelSOS,
            child: Text(
              "CANCEL",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          _iconLabel(Icons.vibration, "Haptic: Strong pulse"),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _statCard("Progress", "${(_controller.value * maxHoldTime).toStringAsFixed(2)}s / 2.00s")),
            Expanded(child: _statCard("Mode", "SOS Hold")),
            Expanded(child: _statCard("Location", _locationStatus)),
            Expanded(child: _statCard("Cancel", "Release to stop")),
          ],
        );
      }
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _iconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

// Custom Painter for the glowing red ring
class RingPainter extends CustomPainter {
  final double progress;
  RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    // Background Shadow/Glow
    Paint shadowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 10
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(center, radius, shadowPaint);

    // Dark Background Ring
    Paint bgPaint = Paint()
      ..color = Color(0xFF1C1C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Red Progress Arc
    Paint progressPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => oldDelegate.progress != progress;
}
