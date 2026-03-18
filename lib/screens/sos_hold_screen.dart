import 'package:flutter/material.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (maxHoldTime * 1000).toInt()),
    );

    // Auto-start for demo purposes; in reality, triggered by the previous screen's long-press
    _controller.forward();
  }

  @override
  void dispose() {
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
                  AnimatedBuilder(
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
                                "Keep holding to send SOS\n— release to cancel",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconLabel(Icons.volume_up, "Sound: Soft"),
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
            _statCard("Progress", "${(_controller.value * maxHoldTime).toStringAsFixed(2)}s / 2.00s"),
            _statCard("Mode", "SOS Hold"),
            _statCard("Cancel", "Release to stop"),
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
