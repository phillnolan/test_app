import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/data/auth_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Allow the app to run without Firebase on unsupported platforms.
  }
  try {
    await AuthService().initializeGoogleSignIn();
  } catch (_) {
    // Keep the app running if Google Sign-In is unavailable.
  }
  await NotificationService.instance.initialize();
  runApp(const StudentPlannerApp());
}
