import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/voice_assistant_service.dart';
import '../../providers/task_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final VoiceAssistantService _voiceService = VoiceAssistantService.instance;
  bool _isExporting = false;
  bool _voiceAlertsEnabled = true;
  double _speechRate = 0.5;

  @override
  void initState() {
    super.initState();
    _speechRate = _voiceService.speechRate;
  }

  void _reloadAllData() {
    context.read<TaskProvider>().loadTasks();
    context.read<MeetingProvider>().loadMeetings();
    context.read<LeadProvider>().loadLeads();
    context.read<DashboardProvider>().refreshDashboard();
  }

  Future<void> _triggerTestNotification() async {
    await _notificationService.showInstantNotification(
      id: 99999,
      title: 'OfflineTrack Alert Test',
      body: 'Offline local notifications are fully active and working!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent! Check your notification bar.')),
      );
    }
  }

  Future<void> _exportDatabase() async {
    setState(() => _isExporting = true);
    try {
      final jsonString = await _db.exportDatabaseToJson();
      if (mounted) {
        _showExportDialog(jsonString);
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportDialog(String jsonString) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppTheme.accentCyan),
            SizedBox(width: 10),
            Text('JSON Database Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This JSON dump represents all SQLite tables (Tasks, Meetings, Leads, Reminders) demonstrating local-first data portability:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorderDark),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database JSON copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoData() async {
    await _db.seedSampleData();
    _reloadAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample demo data loaded successfully!')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Database'),
        content: const Text(
          'Are you sure you want to erase all tasks, meetings, and leads? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            child: const Text('Erase All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.clearAllData();
      await _notificationService.cancelAll();
      _reloadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Architecture'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Offline Notifications
          const Text(
            'Notifications & Alerts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          GlowCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryViolet),
                  ),
                  title: const Text('Local Notification Engine', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Scheduled via exact alarms (no internet required)', style: TextStyle(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: _triggerTestNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Test Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Voice Assistant
          const Text(
            'Voice Assistant',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          GlowCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.record_voice_over_rounded, color: AppTheme.accentCyan),
                  ),
                  title: const Text('Voice Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Speak alerts & reminders out loud', style: TextStyle(fontSize: 12)),
                  value: _voiceAlertsEnabled,
                  activeThumbColor: AppTheme.accentCyan,
                  onChanged: (val) {
                    setState(() => _voiceAlertsEnabled = val);
                    if (val) {
                      _voiceService.speak('Voice alerts enabled.');
                    }
                  },
                ),
                const Divider(color: AppTheme.cardBorderDark, height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      const Text('Speech Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        _speechRate < 0.35 ? 'Slow' : (_speechRate > 0.65 ? 'Fast' : 'Normal'),
                        style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accentCyan,
                    inactiveTrackColor: AppTheme.cardBorderDark,
                    thumbColor: AppTheme.accentCyan,
                    overlayColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (val) {
                      setState(() => _speechRate = val);
                      _voiceService.setSpeechRate(val);
                    },
                  ),
                ),
                const Divider(color: AppTheme.cardBorderDark, height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_circle_rounded, color: AppTheme.primaryViolet),
                  ),
                  title: const Text('Test Voice', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Hear a sample daily briefing', style: TextStyle(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _voiceService.speak(
                        'Good morning! You have 3 tasks due today and 1 meeting at 2 PM. '
                        'Don\'t forget to follow up with the Acme Corp lead.',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Speak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Data Sovereignty & Portability
          const Text(
            'Local-First Data Management',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          GlowCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.backup_rounded, color: AppTheme.accentCyan),
                  ),
                  title: const Text('Export Database (JSON)', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Full export of SQLite tables for backup/sync', style: TextStyle(fontSize: 12)),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onPressed: _exportDatabase,
                        ),
                ),
                const Divider(color: AppTheme.cardBorderDark, height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.accentEmerald),
                  ),
                  title: const Text('Load Demo Sample Data', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Fills database with realistic tasks, meetings, & leads', style: TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentEmerald),
                    onPressed: _seedDemoData,
                  ),
                ),
                const Divider(color: AppTheme.cardBorderDark, height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: AppTheme.accentRose),
                  ),
                  title: const Text('Reset All Data', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentRose)),
                  subtitle: const Text('Erase all local SQLite tables', style: TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.accentRose),
                    onPressed: _clearAllData,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Architecture Specification
          const Text(
            'Architectural Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorderDark),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, size: 20, color: AppTheme.accentCyan),
                    SizedBox(width: 8),
                    Text(
                      'Zero-Cloud Privacy Guarantee',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'OfflineTrack operates strictly on-device using SQLite (`sqflite`). There are no telemetry servers, external cloud dependencies, or latency bottlenecks. All queries execute instantaneously in local memory.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.sync_alt_rounded, size: 20, color: AppTheme.primaryGlow),
                    SizedBox(width: 8),
                    Text(
                      'Future Sync Readiness',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Every record carries an immutable timestamp and structured ID, paving the way for eventual consistency models like CRDTs (Conflict-Free Replicated Data Types) or differential SQLite syncing when cloud features are introduced.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Version Footer
          const Center(
            child: Text(
              'OfflineTrack v1.0.0 (Local-First Edition)\nBuilt with Flutter & SQLite',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
