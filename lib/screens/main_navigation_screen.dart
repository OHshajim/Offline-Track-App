import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/voice_assistant_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/task_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/lead_provider.dart';
import '../widgets/voice_assistant_modal.dart';
import 'dashboard/dashboard_screen.dart';
import 'tasks/task_list_screen.dart';
import 'meetings/meeting_list_screen.dart';
import 'leads/lead_list_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _greeted = false;
  late AnimationController _fabPulse;
  late Animation<double> _fabScale;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskListScreen(),
    MeetingListScreen(),
    LeadListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fabScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabPulse, curve: Curves.easeInOut),
    );

    // Startup voice greeting after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1800), _triggerStartupGreeting);
    });
  }

  @override
  void dispose() {
    _fabPulse.dispose();
    super.dispose();
  }

  Future<void> _triggerStartupGreeting() async {
    if (_greeted || !mounted) return;
    _greeted = true;

    final dashboard = context.read<DashboardProvider>();
    final tasks = context.read<TaskProvider>();
    final overdue = dashboard.overdueItems.length;
    final todayCount = dashboard.todayItems.length;
    final pending = tasks.pendingCount;

    final voice = VoiceAssistantService.instance;
    String greeting;
    final hour = DateTime.now().hour;
    final timeGreet = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    if (overdue > 0) {
      greeting =
          '$timeGreet! Welcome to OfflineTrack. You have $overdue overdue item${overdue > 1 ? "s" : ""} '
          'that need attention, and $todayCount item${todayCount != 1 ? "s" : ""} scheduled for today. '
          'Would you like to add a new task or set a reminder?';
    } else if (pending > 0) {
      greeting =
          '$timeGreet! You have $pending pending task${pending > 1 ? "s" : ""} '
          'and $todayCount item${todayCount != 1 ? "s" : ""} due today. Everything is on track! '
          'Tap the microphone to tell me what you need.';
    } else {
      greeting =
          '$timeGreet! OfflineTrack is ready. You have $todayCount item${todayCount != 1 ? "s" : ""} '
          'scheduled today. Tap the voice button anytime to add tasks, set reminders, or get a briefing!';
    }

    await voice.speak(greeting);
  }

  void _openVoiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider    = context.watch<TaskProvider>();
    final leadProvider    = context.watch<LeadProvider>();
    final dashProvider    = context.watch<DashboardProvider>();
    final meetingProvider = context.watch<MeetingProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Global voice FAB — visible on every tab
      floatingActionButton: _currentIndex != 0
          ? ScaleTransition(
              scale: _fabScale,
              child: FloatingActionButton(
                onPressed: _openVoiceModal,
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: const Color(0xFF060B14),
                elevation: 10,
                tooltip: 'Voice Assistant',
                child: const Icon(Icons.mic_rounded, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(color: AppTheme.primaryCyan.withValues(alpha: 0.15), width: 1),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  badgeCount: dashProvider.overdueItems.length,
                  badgeColor: AppTheme.accentRose,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.check_circle_outline_rounded,
                  selectedIcon: Icons.check_circle_rounded,
                  label: 'Tasks',
                  badgeCount: taskProvider.pendingCount,
                  badgeColor: AppTheme.primaryCyan,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today_rounded,
                  label: 'Meetings',
                  badgeCount: meetingProvider.meetings.length,
                  badgeColor: AppTheme.accentViolet,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  label: 'Leads',
                  badgeCount: leadProvider.followUpDueCount,
                  badgeColor: AppTheme.accentEmerald,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  badgeCount: 0,
                  badgeColor: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    int badgeCount = 0,
    required Color badgeColor,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryCyan.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.35), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryCyan : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
