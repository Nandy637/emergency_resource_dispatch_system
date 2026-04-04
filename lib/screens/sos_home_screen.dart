import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sos_hold_screen.dart';
import 'settings_screen.dart';

class SOSHomeScreen extends StatefulWidget {
  @override
  _SOSHomeScreenState createState() => _SOSHomeScreenState();
}

class _SOSHomeScreenState extends State<SOSHomeScreen> {
  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    debugPrint("Emergency hold started");
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    debugPrint("Emergency hold cancelled");
  }

  void _handleEmergencyTrigger() {
    HapticFeedback.vibrate();
    debugPrint("Emergency Dispatch Triggered!");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SOSHoldScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.accessibility, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to accessibility settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Accessibility settings coming soon')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to settings/help screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Text(
              "Large tap target and alternative triggers available in Settings",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onLongPressStart: _handleLongPressStart,
                onLongPressEnd: _handleLongPressEnd,
                onLongPress: _handleEmergencyTrigger,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3B30),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Text("Settings & Help", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Tip: You will feel a short vibration when the hold starts and another when the alert is sent.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
                Text("Emergency Dispatch • Version 2.4.1", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
