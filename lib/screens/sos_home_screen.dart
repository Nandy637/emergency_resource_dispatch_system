import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics

class SOSHomeScreen extends StatefulWidget {
  @override
  _SOSHomeScreenState createState() => _SOSHomeScreenState();
}

class _SOSHomeScreenState extends State<SOSHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the background shapes
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleEmergencyTrigger() {
    HapticFeedback.vibrate(); // Haptic: complete
    print("Emergency Dispatch Triggered!");
    // Navigate to Incident Tracking Screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.accessibility, color: Colors.black), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Text(
              "Large tap target and alternative triggers available in Settings",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

          // Central SOS Trigger
          Center(
            child: GestureDetector(
              onLongPressStart: (_) {
                setState(() => _isHolding = true);
                HapticFeedback.mediumImpact(); // Haptic: start
              },
              onLongPressEnd: (_) => setState(() => _isHolding = false),
              onLongPress: _handleEmergencyTrigger,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Background Blobs
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Container(
                          width: 280,
                          height: 280,
                          child: Stack(
                            children: [
                              _buildBlob(Colors.purple.withOpacity(0.6), Alignment.topLeft),
                              _buildBlob(Colors.deepPurple, Alignment.bottomRight),
                              _buildBlob(Colors.purpleAccent, Alignment.topRight),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // The Main SOS Button
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF3B30), // Emergency Red
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Info
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Text("Settings & Help", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                SizedBox(height: 15),
                _footerText("Tip: You will feel a short vibration when the hold starts and another when the alert is sent."),
                _footerText("Alternative triggers (voice, shake) can be enabled in Settings."),
                SizedBox(height: 15),
                Text("SafeCall • Version 2.4.1", style: TextStyle(color: Colors.grey, fontSize: 12)),
                _footerText("Emergency services will be contacted and location shared with responders when SOS is activated."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(60),
        ),
      ),
    );
  }

  Widget _footerText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
    );
  }
}
