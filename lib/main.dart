import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/data/auth_service.dart';
import 'features/notifications/data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initializeConnection();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: StudentPlannerApp()));
}
