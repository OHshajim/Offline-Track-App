import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/lead_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/dashboard_provider.dart';

class VoiceCommandResult {
  final String speechResponse;
  final String actionTitle;
  final String? details;
  final bool isSuccess;

  VoiceCommandResult({
    required this.speechResponse,
    required this.actionTitle,
    this.details,
    this.isSuccess = true,
  });
}

class VoiceCommandProcessor {
  /// Parse natural language voice or text commands completely offline
  static Future<VoiceCommandResult> processCommand({
    required String rawCommand,
    required TaskProvider taskProvider,
    required MeetingProvider meetingProvider,
    required LeadProvider leadProvider,
    required DashboardProvider dashboardProvider,
  }) async {
    final text = rawCommand.toLowerCase().trim();
    if (text.isEmpty) {
      return VoiceCommandResult(
        speechResponse: "I didn't catch that. Please tell me what you need to do.",
        actionTitle: "No Input",
        isSuccess: false,
      );
    }

    // ==========================================
    // 1. OBSERVE WHAT I DID / ACCOMPLISHMENTS
    // ==========================================
    if (text.contains('observe') ||
        text.contains('what did i do') ||
        text.contains('what i did') ||
        text.contains('completed') ||
        text.contains('accomplish') ||
        text.contains('progress')) {
      final completedTasks = taskProvider.tasks.where((t) => t.isCompleted).toList();
      final totalTasks = taskProvider.totalCount;
      final closedLeads = leadProvider.closedCount;

      if (completedTasks.isEmpty && closedLeads == 0) {
        return VoiceCommandResult(
          speechResponse: "You haven't marked any tasks as completed yet today. Let's get started on your pending priorities!",
          actionTitle: "Activity Observation",
          details: "Total Tasks: $totalTasks | Completed: 0",
        );
      }

      final taskTitles = completedTasks.take(3).map((t) => t.title).join(', ');
      final response = "Here is what you have accomplished: You completed ${completedTasks.length} out of $totalTasks tasks, including $taskTitles.${closedLeads > 0 ? ' You also closed $closedLeads client leads.' : ''} Excellent work!";

      return VoiceCommandResult(
        speechResponse: response,
        actionTitle: "Activity Summary",
        details: "${completedTasks.length} Tasks Finished • $closedLeads Deals Closed",
      );
    }

    // ==========================================
    // 2. DAILY BRIEFING / WHAT DO I HAVE TO DO TODAY
    // ==========================================
    if (text.contains('today') ||
        text.contains('brief') ||
        text.contains('schedule') ||
        text.contains('what do i have') ||
        text.contains('my plan') ||
        text.contains('overview')) {
      final todayTasks = taskProvider.tasks.where((t) => t.isDueToday && !t.isCompleted).toList();
      final todayMeetings = meetingProvider.todayMeetings;
      final todayLeads = leadProvider.leads.where((l) => l.isFollowupDueToday).toList();
      final overdueCount = taskProvider.overdueCount + leadProvider.overdueCount;

      final buffer = StringBuffer();
      buffer.write("Good day! ");

      if (overdueCount > 0) {
        buffer.write("Attention: You have $overdueCount overdue items requiring immediate action. ");
      }

      buffer.write("For today, you have ${todayTasks.length} pending tasks, ");
      buffer.write("${todayMeetings.length} meetings, and ");
      buffer.write("${todayLeads.length} client follow-ups due. ");

      if (todayMeetings.isNotEmpty) {
        final nextMeeting = todayMeetings.first;
        final timeStr = DateFormat('h:mm a').format(nextMeeting.datetime);
        buffer.write("Your next meeting is '${nextMeeting.title}' at $timeStr. ");
      }

      return VoiceCommandResult(
        speechResponse: buffer.toString(),
        actionTitle: "Daily Briefing",
        details: "${todayTasks.length} Tasks • ${todayMeetings.length} Meetings • ${todayLeads.length} Follow-ups",
      );
    }

    // ==========================================
    // 3. CHECK OVERDUE / ALERTS
    // ==========================================
    if (text.contains('alert') ||
        text.contains('overdue') ||
        text.contains('urgent') ||
        text.contains('warn')) {
      final overdueTasks = taskProvider.tasks.where((t) => t.isOverdue).toList();
      final overdueLeads = leadProvider.leads.where((l) => l.isFollowupOverdue).toList();

      if (overdueTasks.isEmpty && overdueLeads.isEmpty) {
        return VoiceCommandResult(
          speechResponse: "All clear! You have zero overdue tasks or follow-ups.",
          actionTitle: "Alert Check",
          details: "No overdue alerts.",
        );
      }

      final count = overdueTasks.length + overdueLeads.length;
      final response = "Alert! You have $count overdue items. ${overdueTasks.isNotEmpty ? 'Tasks: ${overdueTasks.first.title}. ' : ''}${overdueLeads.isNotEmpty ? 'Lead follow-up: ${overdueLeads.first.name}.' : ''}";

      return VoiceCommandResult(
        speechResponse: response,
        actionTitle: "Urgent Alerts",
        details: "${overdueTasks.length} Overdue Tasks • ${overdueLeads.length} Overdue Leads",
      );
    }

    // ==========================================
    // 4. SCHEDULE MEETING
    // ==========================================
    if (text.contains('meeting') && (text.contains('schedule') || text.contains('add') || text.contains('set') || text.contains('create'))) {
      String title = text
          .replaceAll(RegExp(r'^(schedule|add|set|create)\s+(a\s+)?meeting(\s+with)?', caseSensitive: false), '')
          .trim();

      DateTime meetingTime = DateTime.now().add(const Duration(hours: 2));

      if (title.contains('tomorrow')) {
        meetingTime = DateTime.now().add(const Duration(days: 1));
        title = title.replaceAll('tomorrow', '').trim();
      }

      if (title.isEmpty) title = "Important Discussion";

      final newMeeting = MeetingModel(
        title: _capitalize(title),
        datetime: meetingTime,
        recurrence: 'None',
      );

      await meetingProvider.addMeeting(newMeeting);
      final timeStr = DateFormat('h:mm a, MMM d').format(meetingTime);
      final response = "Meeting '${newMeeting.title}' has been scheduled for $timeStr. An offline reminder is set.";

      return VoiceCommandResult(
        speechResponse: response,
        actionTitle: "Meeting Scheduled",
        details: "${newMeeting.title} at $timeStr",
      );
    }

    // ==========================================
    // 5. ADD CLIENT LEAD
    // ==========================================
    if (text.contains('lead') || text.contains('client') || text.contains('prospect')) {
      String name = text
          .replaceAll(RegExp(r'^(add|create|new)\s+(a\s+)?(client|lead|prospect)(\s+named|\s+for)?', caseSensitive: false), '')
          .trim();

      if (name.isEmpty) name = "New Client Prospect";

      final newLead = LeadModel(
        name: _capitalize(name),
        status: 'New',
        nextFollowup: DateTime.now().add(const Duration(days: 2)),
      );

      await leadProvider.addLead(newLead);
      final response = "Client lead '${newLead.name}' has been added to your offline pipeline with a follow-up scheduled in two days.";

      return VoiceCommandResult(
        speechResponse: response,
        actionTitle: "Lead Created",
        details: "${newLead.name} (Status: New)",
      );
    }

    // ==========================================
    // 6. COMPLETE / FINISH TASK
    // ==========================================
    if (text.contains('mark') || text.contains('finish') || text.contains('done') || text.contains('complete')) {
      final clean = text
          .replaceAll(RegExp(r'^(mark|finish|complete)\s+(task\s+)?', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+(as\s+)?(done|finished|completed)$', caseSensitive: false), '')
          .trim();

      TaskModel? match;
      for (final t in taskProvider.tasks) {
        if (clean.isNotEmpty && t.title.toLowerCase().contains(clean)) {
          match = t;
          break;
        }
      }

      if (match != null) {
        await taskProvider.toggleTaskStatus(match);
        final response = "Task '${match.title}' marked as completed. Well done!";
        return VoiceCommandResult(
          speechResponse: response,
          actionTitle: "Task Completed",
          details: match.title,
        );
      }
    }

    // ==========================================
    // 7. DEFAULT: CREATE TASK / REMINDER
    // ==========================================
    String taskTitle = text
        .replaceAll(RegExp(r'^(remind me to|add task|create task|remember to|todo|to do)\s+', caseSensitive: false), '')
        .trim();

    if (taskTitle.isEmpty) taskTitle = rawCommand;

    DateTime dueTime = DateTime.now().add(const Duration(hours: 3));
    String priority = 'Medium';

    if (text.contains('urgent') || text.contains('high priority') || text.contains('important')) {
      priority = 'High';
      taskTitle = taskTitle.replaceAll(RegExp(r'(urgent|high priority|important)', caseSensitive: false), '').trim();
    }

    if (text.contains('tomorrow')) {
      dueTime = DateTime.now().add(const Duration(days: 1));
      taskTitle = taskTitle.replaceAll('tomorrow', '').trim();
    }

    final newTask = TaskModel(
      title: _capitalize(taskTitle),
      dueDate: dueTime,
      priority: priority,
      category: 'Work',
      status: 'Pending',
    );

    await taskProvider.addTask(newTask);
    final dueFormatted = DateFormat('h:mm a, MMM d').format(dueTime);
    final response = "I've created the task '${newTask.title}', due $dueFormatted with $priority priority. Saved offline.";

    return VoiceCommandResult(
      speechResponse: response,
      actionTitle: "Task Created",
      details: "${newTask.title} (Due $dueFormatted)",
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
