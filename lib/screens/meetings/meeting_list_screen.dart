import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/meeting_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../screens/settings/settings_screen.dart';
import 'meeting_form_screen.dart';

class MeetingListScreen extends StatelessWidget {
  const MeetingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetingProvider = context.watch<MeetingProvider>();
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => meetingProvider.loadMeetings(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Meeting', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorderDark),
            ),
            child: Row(
              children: ['All', 'Today', 'Upcoming', 'Past'].map((filter) {
                final isSelected = meetingProvider.filter == filter;
                return Expanded(
                  child: InkWell(
                    onTap: () => meetingProvider.setFilter(filter),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)) : null,
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Meeting List
          Expanded(
            child: meetingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : meetingProvider.filteredMeetings.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => meetingProvider.loadMeetings(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: EmptyStateView(
                              icon: Icons.calendar_month_rounded,
                              title: 'No Meetings Found',
                              message: meetingProvider.filter == 'Today'
                                  ? 'No meetings scheduled for today.'
                                  : 'No meetings found in this view. Schedule one to receive offline alerts.',
                              buttonText: 'Schedule Meeting',
                              onButtonPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MeetingFormScreen()),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => meetingProvider.loadMeetings(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: meetingProvider.filteredMeetings.length,
                          itemBuilder: (context, index) {
                          final meeting = meetingProvider.filteredMeetings[index];
                          final isToday = meeting.isToday;
                          final isPast = meeting.isPast;

                          return AnimatedEntrance(
                            index: index,
                            child: Dismissible(
                              key: Key('meeting_${meeting.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRose,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (_) => _showDeleteConfirmDialog(context, meeting.title),
                              onDismissed: (_) {
                                if (meeting.id != null) {
                                  meetingProvider.deleteMeeting(meeting.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted "${meeting.title}"')),
                                  );
                                }
                              },
                              child: GlowCard(
                                glowColor: isToday ? AppTheme.accentCyan : null,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MeetingFormScreen(meeting: meeting)),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Date & Time Box
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentCyan.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                timeFormat.format(meeting.datetime),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.accentCyan,
                                                ),
                                              ),
                                              Text(
                                                isToday ? 'Today' : DateFormat('MMM d').format(meeting.datetime),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Title & Date info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                meeting.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: isPast ? AppTheme.textMuted : AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dateFormat.format(meeting.datetime),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Recurrence Badge
                                        if (meeting.recurrence != 'None')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.repeat_rounded, size: 12, color: AppTheme.primaryGlow),
                                                const SizedBox(width: 4),
                                                Text(
                                                  meeting.recurrence,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.primaryGlow,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceDark.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.notes_rounded, size: 14, color: AppTheme.textMuted),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                meeting.notes!,
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to cancel and delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
