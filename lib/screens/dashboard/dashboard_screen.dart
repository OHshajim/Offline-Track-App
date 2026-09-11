import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/lead_provider.dart';
import '../../core/services/voice_assistant_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/voice_orb_widget.dart';
import '../../widgets/voice_assistant_modal.dart';
import '../tasks/task_form_screen.dart';
import '../meetings/meeting_form_screen.dart';
import '../leads/lead_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  void _refreshData() {
    context.read<DashboardProvider>().refreshDashboard();
    context.read<TaskProvider>().loadTasks();
    context.read<MeetingProvider>().loadMeetings();
    context.read<LeadProvider>().loadLeads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openVoiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  void _showQuickAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.cardBorderDark, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Quick Create',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Everything saves locally — 100% offline.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _buildQuickOption(
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.primaryCyan,
              title: 'New Task',
              subtitle: 'Add a to-do with due date & priority',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TaskFormScreen()))
                    .then((_) => _refreshData());
              },
            ),
            const SizedBox(height: 12),
            _buildQuickOption(
              icon: Icons.calendar_today_rounded,
              color: AppTheme.accentViolet,
              title: 'Schedule Meeting',
              subtitle: 'Set a meeting with offline reminder',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MeetingFormScreen()))
                    .then((_) => _refreshData());
              },
            ),
            const SizedBox(height: 12),
            _buildQuickOption(
              icon: Icons.people_alt_rounded,
              color: AppTheme.accentEmerald,
              title: 'Add Client Lead',
              subtitle: 'Track contacts and next follow-up',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LeadFormScreen()))
                    .then((_) => _refreshData());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryCyan, AppTheme.accentViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.offline_bolt_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OfflineTrack',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text(DateFormat('EEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          // Single voice orb — the only voice entry on dashboard
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openVoiceModal,
              child: const VoiceOrbWidget(size: 34),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddModal(context),
        backgroundColor: AppTheme.primaryCyan,
        foregroundColor: const Color(0xFF060B14),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Add', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 8,
      ),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              color: AppTheme.primaryCyan,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Metric Cards Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _buildMetricCard(
                          label: 'Today',
                          count: dashboard.todayItems.length,
                          color: AppTheme.primaryCyan,
                          icon: Icons.today_rounded,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricCard(
                          label: 'Overdue',
                          count: dashboard.overdueItems.length,
                          color: AppTheme.accentRose,
                          icon: Icons.warning_amber_rounded,
                          isPulsing: dashboard.overdueItems.isNotEmpty,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricCard(
                          label: 'Upcoming',
                          count: dashboard.upcomingItems.length,
                          color: AppTheme.accentEmerald,
                          icon: Icons.date_range_rounded,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Overdue voice alert bar — only when overdue items exist
                  if (dashboard.overdueItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          final voice = VoiceAssistantService.instance;
                          final n = dashboard.overdueItems.length;
                          voice.speakAlert(
                            'Attention! You have $n overdue item${n > 1 ? "s" : ""} requiring immediate action. '
                            'Please review your overdue list.',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_up_rounded, color: AppTheme.accentRose, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${dashboard.overdueItems.length} overdue — tap to hear voice alert',
                                  style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentRose),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.accentRose, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (dashboard.overdueItems.isNotEmpty) const SizedBox(height: 10),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorderDark),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryCyan, AppTheme.cyanDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: const Color(0xFF060B14),
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Today (${dashboard.todayItems.length})'),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text('Overdue (${dashboard.overdueItems.length})',
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (dashboard.overdueItems.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentRose, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(text: 'Next 7d (${dashboard.upcomingItems.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItemsList(
                          items: dashboard.todayItems,
                          emptyTitle: 'All Clear Today!',
                          emptyMessage: 'No tasks, meetings, or follow-ups due today.',
                          accentColor: AppTheme.primaryCyan,
                        ),
                        _buildItemsList(
                          items: dashboard.overdueItems,
                          emptyTitle: 'No Overdue Items',
                          emptyMessage: 'Great! All tasks and leads are on schedule.',
                          accentColor: AppTheme.accentRose,
                        ),
                        _buildItemsList(
                          items: dashboard.upcomingItems,
                          emptyTitle: 'Nothing Upcoming',
                          emptyMessage: 'Tap Quick Add to plan the next 7 days.',
                          accentColor: AppTheme.accentEmerald,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    bool isPulsing = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isPulsing ? 0.5 : 0.18), width: isPulsing ? 1.5 : 1),
        boxShadow: [
          if (isPulsing)
            BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              isPulsing
                  ? PulsingBadge(text: 'Alert', color: color)
                  : Text(count.toString(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          if (isPulsing) ...[
            const SizedBox(height: 2),
            Text('$count pending',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList({
    required List<UnifiedDashboardItem> items,
    required String emptyTitle,
    required String emptyMessage,
    required Color accentColor,
  }) {
    if (items.isEmpty) {
      return EmptyStateView(icon: Icons.done_all_rounded, title: emptyTitle, message: emptyMessage);
    }

    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 90),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        Color typeColor;
        IconData typeIcon;
        if (item.type == 'Task') {
          typeColor = AppTheme.primaryCyan;
          typeIcon = Icons.task_alt_rounded;
        } else if (item.type == 'Meeting') {
          typeColor = AppTheme.accentViolet;
          typeIcon = Icons.video_camera_front_rounded;
        } else {
          typeColor = AppTheme.accentEmerald;
          typeIcon = Icons.person_search_rounded;
        }

        final isTodayItem = item.datetime.day == DateTime.now().day &&
            item.datetime.month == DateTime.now().month &&
            item.datetime.year == DateTime.now().year;
        final displayDate = isTodayItem
            ? 'Today at ${timeFormat.format(item.datetime)}'
            : dateFormat.format(item.datetime);

        return AnimatedEntrance(
          index: index,
          child: GlowCard(
            glowColor: accentColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: typeColor.withValues(alpha: 0.28)),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(item.type.toUpperCase(),
                                style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(displayDate,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.subtitle,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: item.statusOrPriority),
              ],
            ),
          ),
        );
      },
    );
  }
}
