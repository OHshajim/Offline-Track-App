import 'dart:async';
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _greeted = false;
  Timer? _greetingTimer;

  late AnimationController _orbPulse;
  late Animation<double> _orbScale;
  late AnimationController _orbGlow;
  late Animation<double> _orbGlowAnim;

  // 5 real screens; the center slot (index 2) is the voice button — not a screen
  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskListScreen(),
    SizedBox.shrink(), // placeholder for center voice slot
    MeetingListScreen(),
    LeadListScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _orbPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _orbScale = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _orbPulse, curve: Curves.easeInOutSine));

    _orbGlow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _orbGlowAnim = Tween<double>(begin: 0.3, end: 0.8)
        .animate(CurvedAnimation(parent: _orbGlow, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _greetingTimer = Timer(const Duration(milliseconds: 1800), _triggerStartupGreeting);
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _orbPulse.dispose();
    _orbGlow.dispose();
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

    final hour = DateTime.now().hour;
    final timeGreet = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    String greeting;
    if (overdue > 0) {
      greeting =
          '$timeGreet! Welcome to OfflineTrack. You have $overdue overdue item${overdue > 1 ? "s" : ""} '
          'that need attention, and $todayCount item${todayCount != 1 ? "s" : ""} scheduled for today. '
          'Would you like to add a new task or set a reminder?';
    } else if (pending > 0) {
      greeting =
          '$timeGreet! You have $pending pending task${pending > 1 ? "s" : ""} '
          'and $todayCount item${todayCount != 1 ? "s" : ""} due today. '
          'Tap the voice button to tell me what you need.';
    } else {
      greeting =
          '$timeGreet! OfflineTrack is ready. $todayCount item${todayCount != 1 ? "s" : ""} '
          'scheduled today. Tap the voice button in the nav bar anytime!';
    }

    await VoiceAssistantService.instance.speak(greeting);
  }

  void _openVoiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  void _onNavTap(int index) {
    if (index == 2) {
      // Center slot = voice button
      _openVoiceModal();
      return;
    }
    setState(() => _currentIndex = index);
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
      bottomNavigationBar: _buildNavBar(
        taskProvider: taskProvider,
        leadProvider: leadProvider,
        dashProvider: dashProvider,
        meetingProvider: meetingProvider,
      ),
    );
  }

  Widget _buildNavBar({
    required TaskProvider taskProvider,
    required LeadProvider leadProvider,
    required DashboardProvider dashProvider,
    required MeetingProvider meetingProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.primaryCyan.withValues(alpha: 0.15), width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(index: 0, icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded, label: 'Home',
                  badgeCount: dashProvider.overdueItems.length, badgeColor: AppTheme.accentRose),
              _buildNavItem(index: 1, icon: Icons.check_circle_outline_rounded,
                  selectedIcon: Icons.check_circle_rounded, label: 'Tasks',
                  badgeCount: taskProvider.pendingCount, badgeColor: AppTheme.primaryCyan),
              // Center Voice Button
              _buildCenterVoiceButton(),
              _buildNavItem(index: 3, icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today_rounded, label: 'Meetings',
                  badgeCount: meetingProvider.todayMeetings.length, badgeColor: AppTheme.accentViolet),
              _buildNavItem(index: 4, icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded, label: 'Leads',
                  badgeCount: leadProvider.followUpDueCount, badgeColor: AppTheme.accentEmerald),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterVoiceButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbPulse, _orbGlow]),
      builder: (context, _) {
        return GestureDetector(
          onTap: _openVoiceModal,
          child: Transform.translate(
            offset: const Offset(0, -10), // lifts above the nav bar
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    AppTheme.primaryCyan,
                    AppTheme.cyanDark,
                  ],
                  stops: [0.3, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withValues(alpha: _orbGlowAnim.value * 0.7),
                    blurRadius: 22,
                    spreadRadius: _orbScale.value > 1.0 ? 4 : 2,
                  ),
                  BoxShadow(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: AppTheme.cyanGlow.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Transform.scale(
                scale: _orbScale.value,
                child: const Center(
                  child: Icon(Icons.mic_rounded, color: Color(0xFF060B14), size: 28),
                ),
              ),
            ),
          ),
        );
      },
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
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCyan.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
                    top: -4, right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
