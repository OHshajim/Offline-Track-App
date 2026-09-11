import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'providers/task_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark-first aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline local notifications safely
  try {
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Notification initialization warning: $e');
  }

  // Initial database check: seed sample data if clean launch for immediate evaluation
  try {
    final db = DatabaseHelper.instance;
    final initialTasks = await db.getAllTasks();
    if (initialTasks.isEmpty) {
      await db.seedSampleData();
    }
  } catch (e) {
    debugPrint('Initial database seeding warning: $e');
  }

  runApp(const OfflineTrackApp());
}

class OfflineTrackApp extends StatelessWidget {
  const OfflineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()..loadMeetings()),
        ChangeNotifierProvider(create: (_) => LeadProvider()..loadLeads()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..refreshDashboard()),
      ],
      child: MaterialApp(
        title: 'OfflineTrack',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.darkTheme, // Default to gorgeous dark mode
        home: const MainNavigationScreen(),
      ),
    );
  }
}
