import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/role_selector_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — safe even without google-services.json (shows warning).
  // Add your google-services.json to android/app/ for full functionality.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️  Firebase init failed: $e');
    debugPrint('    → Make sure google-services.json is in android/app/');
  }

  runApp(const SafeCallApp());
}

class SafeCallApp extends StatelessWidget {
  const SafeCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCall SOS',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      // Role selector is now the entry point
      home: const RoleSelectorScreen(),
    );
  }
}