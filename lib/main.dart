import 'package:flutter/material.dart';
import 'screens/sos_home_screen.dart';

void main() {
  runApp(const EmergencyDispatchApp());
}

class EmergencyDispatchApp extends StatelessWidget {
  const EmergencyDispatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Dispatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF3B30),
          primary: const Color(0xFFFF3B30),
        ),
        fontFamily: 'Roboto',
      ),
      home: SOSHomeScreen(),
    );
  }
}
