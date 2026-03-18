import 'package:flutter/material.dart';
import 'screens/sos_home_screen.dart';

void main() {
  runApp(SafeCallApp());
}

class SafeCallApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'SF Pro Display',
      ),
      home: SOSHomeScreen(),
    );
  }
}
