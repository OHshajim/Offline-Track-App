import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class UnifiedDashboardItem {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'Task', 'Meeting', 'Lead'
  final DateTime datetime;
  final String statusOrPriority;
  final dynamic rawItem;

  UnifiedDashboardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.datetime,
    required this.statusOrPriority,
    required this.rawItem,
  });
}

class DashboardProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = false;
  List<UnifiedDashboardItem> _todayItems = [];
  List<UnifiedDashboardItem> _overdueItems = [];
  List<UnifiedDashboardItem> _upcomingItems = [];

  bool get isLoading => _isLoading;
  List<UnifiedDashboardItem> get todayItems => _todayItems;
  List<UnifiedDashboardItem> get overdueItems => _overdueItems;
  List<UnifiedDashboardItem> get upcomingItems => _upcomingItems;

  int get totalAlertsCount => _overdueItems.length + _todayItems.length;

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();

    final tasks = await _db.getAllTasks();
    final meetings = await _db.getAllMeetings();
    final leads = await _db.getAllLeads();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final sevenDaysLater = todayEnd.add(const Duration(days: 7));

    final List<UnifiedDashboardItem> todayList = [];
    final List<UnifiedDashboardItem> overdueList = [];
    final List<UnifiedDashboardItem> upcomingList = [];

    // Process Tasks
    for (final task in tasks) {
      if (task.dueDate == null) continue;

      if (!task.isCompleted && task.dueDate!.isBefore(todayStart)) {
        overdueList.add(UnifiedDashboardItem(
          id: 'task_${task.id}',
          title: task.title,
          subtitle: task.description ?? 'Priority: ${task.priority}',
          type: 'Task',
          datetime: task.dueDate!,
          statusOrPriority: task.priority,
          rawItem: task,
        ));
      } else if (!task.isCompleted &&
          task.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          task.dueDate!.isBefore(todayEnd.add(const Duration(seconds: 1)))) {
        todayList.add(UnifiedDashboardItem(
          id: 'task_${task.id}',
          title: task.title,
          subtitle: task.description ?? 'Category: ${task.category}',
          type: 'Task',
          datetime: task.dueDate!,
          statusOrPriority: task.priority,
          rawItem: task,
        ));
      } else if (!task.isCompleted &&
          task.dueDate!.isAfter(todayEnd) &&
          task.dueDate!.isBefore(sevenDaysLater)) {
        upcomingList.add(UnifiedDashboardItem(
          id: 'task_${task.id}',
          title: task.title,
          subtitle: 'Category: ${task.category}',
          type: 'Task',
          datetime: task.dueDate!,
          statusOrPriority: task.priority,
          rawItem: task,
        ));
      }
    }

    // Process Meetings
    for (final meeting in meetings) {
      if (meeting.datetime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          meeting.datetime.isBefore(todayEnd.add(const Duration(seconds: 1)))) {
        todayList.add(UnifiedDashboardItem(
          id: 'meeting_${meeting.id}',
          title: meeting.title,
          subtitle: meeting.notes ?? 'Recurrence: ${meeting.recurrence}',
          type: 'Meeting',
          datetime: meeting.datetime,
          statusOrPriority: meeting.recurrence,
          rawItem: meeting,
        ));
      } else if (meeting.datetime.isAfter(todayEnd) && meeting.datetime.isBefore(sevenDaysLater)) {
        upcomingList.add(UnifiedDashboardItem(
          id: 'meeting_${meeting.id}',
          title: meeting.title,
          subtitle: meeting.notes ?? 'Recurrence: ${meeting.recurrence}',
          type: 'Meeting',
          datetime: meeting.datetime,
          statusOrPriority: meeting.recurrence,
          rawItem: meeting,
        ));
      }
    }

    // Process Leads
    for (final lead in leads) {
      if (lead.nextFollowup == null || lead.status.toLowerCase() == 'closed') continue;

      if (lead.nextFollowup!.isBefore(todayStart)) {
        overdueList.add(UnifiedDashboardItem(
          id: 'lead_${lead.id}',
          title: lead.name,
          subtitle: lead.notes ?? 'Follow-up was due',
          type: 'Lead',
          datetime: lead.nextFollowup!,
          statusOrPriority: lead.status,
          rawItem: lead,
        ));
      } else if (lead.nextFollowup!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          lead.nextFollowup!.isBefore(todayEnd.add(const Duration(seconds: 1)))) {
        todayList.add(UnifiedDashboardItem(
          id: 'lead_${lead.id}',
          title: lead.name,
          subtitle: lead.notes ?? 'Scheduled follow-up',
          type: 'Lead',
          datetime: lead.nextFollowup!,
          statusOrPriority: lead.status,
          rawItem: lead,
        ));
      } else if (lead.nextFollowup!.isAfter(todayEnd) &&
          lead.nextFollowup!.isBefore(sevenDaysLater)) {
        upcomingList.add(UnifiedDashboardItem(
          id: 'lead_${lead.id}',
          title: lead.name,
          subtitle: lead.notes ?? 'Pipeline: ${lead.status}',
          type: 'Lead',
          datetime: lead.nextFollowup!,
          statusOrPriority: lead.status,
          rawItem: lead,
        ));
      }
    }

    // Sort items chronologically
    todayList.sort((a, b) => a.datetime.compareTo(b.datetime));
    overdueList.sort((a, b) => a.datetime.compareTo(b.datetime));
    upcomingList.sort((a, b) => a.datetime.compareTo(b.datetime));

    _todayItems = todayList;
    _overdueItems = overdueList;
    _upcomingItems = upcomingList;

    _isLoading = false;
    notifyListeners();
  }
}
