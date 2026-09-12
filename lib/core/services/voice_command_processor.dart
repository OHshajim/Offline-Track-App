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
    if (text == 'today' ||
        text.contains('daily briefing') ||
        text.contains('briefing') ||
        text == 'my schedule' ||
        text.contains('what do i have to do') ||
        text.contains('my plan') ||
        text.contains('daily overview')) {
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
    // 3. SEARCH COMMANDS
    // ==========================================
    if (text.startsWith('find') || text.startsWith('search')) {
      final query = text
          .replaceAll(RegExp(r'^(find|search)\s+(task|lead|meeting|client)?\s*', caseSensitive: false), '')
          .trim();

      final taskMatches = taskProvider.tasks.where((t) =>
          t.title.toLowerCase().contains(query) || (t.description?.toLowerCase().contains(query) ?? false)).toList();
      final leadMatches = leadProvider.leads.where((l) =>
          l.name.toLowerCase().contains(query) || (l.notes?.toLowerCase().contains(query) ?? false)).toList();
      final meetingMatches = meetingProvider.meetings.where((m) =>
          m.title.toLowerCase().contains(query) || (m.notes?.toLowerCase().contains(query) ?? false)).toList();

      final totalMatches = taskMatches.length + leadMatches.length + meetingMatches.length;

      if (totalMatches == 0) {
        return VoiceCommandResult(
          speechResponse: "No items matching '$query' were found in your offline records.",
          actionTitle: "Search Results",
          details: "Query: '$query' • 0 matches",
        );
      }

      return VoiceCommandResult(
        speechResponse: "Found $totalMatches matching record${totalMatches != 1 ? 's' : ''} for '$query': ${taskMatches.length} tasks, ${meetingMatches.length} meetings, and ${leadMatches.length} client leads.",
        actionTitle: "Search Results",
        details: "${taskMatches.length} Tasks • ${meetingMatches.length} Meetings • ${leadMatches.length} Leads",
      );
    }

    // ==========================================
    // 4. CHECK OVERDUE / ALERTS
    // ==========================================
    if (text == 'alerts' ||
        text == 'overdue' ||
        text.contains('check alert') ||
        text.contains('show overdue') ||
        text.contains('check overdue') ||
        text.contains('urgent alerts')) {
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
    // 5. EXPLICIT TASK CREATION
    // ==========================================
    final isExplicitTask = text.startsWith('remind me to') ||
        text.startsWith('add task') ||
        text.startsWith('create task') ||
        text.startsWith('remember to') ||
        text.startsWith('todo') ||
        text.startsWith('to do');

    if (isExplicitTask) {
      return await _createTaskFromText(
        rawCommand: rawCommand,
        text: text,
        taskProvider: taskProvider,
      );
    }

    // ==========================================
    // 6. SCHEDULE MEETING
    // ==========================================
    if (text.contains('meeting') && (text.contains('schedule') || text.contains('add') || text.contains('set') || text.contains('create'))) {
      String title = text
          .replaceAll(RegExp(r'^(schedule|add|set|create)\s+(a\s+)?meeting(\s+with)?', caseSensitive: false), '')
          .trim();

      DateTime meetingTime = _parseRelativeDate(text, defaultOffset: const Duration(hours: 2));
      title = _cleanDateKeywords(title);

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
    // 7. ADD CLIENT LEAD
    // ==========================================
    if (text.contains('lead') || text.contains('client') || text.contains('prospect')) {
      String name = text
          .replaceAll(RegExp(r'^(add|create|new)\s+(a\s+)?(client|lead|prospect)(\s+named|\s+for)?', caseSensitive: false), '')
          .trim();

      DateTime followupTime = _parseRelativeDate(text, defaultOffset: const Duration(days: 2));
      name = _cleanDateKeywords(name);

      if (name.isEmpty) name = "New Client Prospect";

      final newLead = LeadModel(
        name: _capitalize(name),
        status: 'New',
        nextFollowup: followupTime,
      );

      await leadProvider.addLead(newLead);
      final response = "Client lead '${newLead.name}' has been added to your offline pipeline with a follow-up scheduled.";

      return VoiceCommandResult(
        speechResponse: response,
        actionTitle: "Lead Created",
        details: "${newLead.name} (Status: New)",
      );
    }

    // ==========================================
    // 7. COMPLETE / FINISH TASK
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
    // 9. DEFAULT: CREATE TASK / REMINDER
    // ==========================================
    return await _createTaskFromText(
      rawCommand: rawCommand,
      text: text,
      taskProvider: taskProvider,
    );
  }

  static Future<VoiceCommandResult> _createTaskFromText({
    required String rawCommand,
    required String text,
    required TaskProvider taskProvider,
  }) async {
    String taskTitle = text
        .replaceAll(RegExp(r'^(remind me to|add task|create task|remember to|todo|to do)\s+', caseSensitive: false), '')
        .trim();

    if (taskTitle.isEmpty) taskTitle = rawCommand;

    DateTime dueTime = _parseRelativeDate(text, defaultOffset: const Duration(hours: 3));
    String priority = 'Medium';

    if (text.contains('urgent') || text.contains('high priority') || text.contains('important')) {
      priority = 'High';
      taskTitle = taskTitle.replaceAll(RegExp(r'(urgent|high priority|important)', caseSensitive: false), '').trim();
    } else if (text.contains('low priority')) {
      priority = 'Low';
      taskTitle = taskTitle.replaceAll(RegExp(r'(low priority)', caseSensitive: false), '').trim();
    }

    taskTitle = _cleanDateKeywords(taskTitle);
    if (taskTitle.isEmpty) taskTitle = "Untitled Offline Task";

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

  static DateTime _parseRelativeDate(String text, {required Duration defaultOffset}) {
    final now = DateTime.now();

    // Check "in X days"
    final daysMatch = RegExp(r'in (\d+) days?').firstMatch(text);
    if (daysMatch != null) {
      final d = int.parse(daysMatch.group(1)!);
      return now.add(Duration(days: d));
    }

    // Check "in X hours"
    final hoursMatch = RegExp(r'in (\d+) hours?').firstMatch(text);
    if (hoursMatch != null) {
      final h = int.parse(hoursMatch.group(1)!);
      return now.add(Duration(hours: h));
    }

    if (text.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }

    if (text.contains('tonight')) {
      return DateTime(now.year, now.month, now.day, 20, 0);
    }

    if (text.contains('next week')) {
      return now.add(const Duration(days: 7));
    }

    return now.add(defaultOffset);
  }

  static String _cleanDateKeywords(String input) {
    return input
        .replaceAll(RegExp(r'in \d+ days?', caseSensitive: false), '')
        .replaceAll(RegExp(r'in \d+ hours?', caseSensitive: false), '')
        .replaceAll(RegExp(r'(tomorrow|tonight|next week)', caseSensitive: false), '')
        .trim();
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
