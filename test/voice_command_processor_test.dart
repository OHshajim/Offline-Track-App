import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offlinetrack/core/database/database_helper.dart';
import 'package:offlinetrack/core/services/voice_command_processor.dart';
import 'package:offlinetrack/providers/task_provider.dart';
import 'package:offlinetrack/providers/meeting_provider.dart';
import 'package:offlinetrack/providers/lead_provider.dart';
import 'package:offlinetrack/providers/dashboard_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('VoiceCommandProcessor NLP Tests', () {
    late TaskProvider taskProvider;
    late MeetingProvider meetingProvider;
    late LeadProvider leadProvider;
    late DashboardProvider dashboardProvider;

    setUp(() async {
      await DatabaseHelper.instance.clearAllData();
      taskProvider = TaskProvider();
      meetingProvider = MeetingProvider();
      leadProvider = LeadProvider();
      dashboardProvider = DashboardProvider();

      await taskProvider.loadTasks();
      await meetingProvider.loadMeetings();
      await leadProvider.loadLeads();
      await dashboardProvider.refreshDashboard();
    });

    test('Parses task creation command with high priority and relative date', () async {
      final res = await VoiceCommandProcessor.processCommand(
        rawCommand: 'remind me to review client contract urgent in 2 days',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      expect(res.isSuccess, isTrue);
      expect(res.actionTitle, equals('Task Created'));
      expect(taskProvider.tasks.length, equals(1));
      expect(taskProvider.tasks.first.priority, equals('High'));
    });

    test('Parses meeting scheduling command', () async {
      final res = await VoiceCommandProcessor.processCommand(
        rawCommand: 'schedule meeting with Product Team tomorrow',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      expect(res.isSuccess, isTrue);
      expect(res.actionTitle, equals('Meeting Scheduled'));
      expect(meetingProvider.meetings.length, equals(1));
      expect(meetingProvider.meetings.first.title, contains('Product Team'));
    });

    test('Parses lead addition command', () async {
      final res = await VoiceCommandProcessor.processCommand(
        rawCommand: 'add new client lead named Cyberdyne Systems',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      expect(res.isSuccess, isTrue);
      expect(res.actionTitle, equals('Lead Created'));
      expect(leadProvider.leads.length, equals(1));
      expect(leadProvider.leads.first.name, contains('Cyberdyne Systems'));
    });

    test('Parses search command across offline data', () async {
      await VoiceCommandProcessor.processCommand(
        rawCommand: 'add task review pitch deck',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      final searchRes = await VoiceCommandProcessor.processCommand(
        rawCommand: 'find pitch',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.actionTitle, equals('Search Results'));
      expect(searchRes.speechResponse, contains('1 matching record'));
    });

    test('Parses daily briefing command', () async {
      final briefingRes = await VoiceCommandProcessor.processCommand(
        rawCommand: 'what do I have to do today',
        taskProvider: taskProvider,
        meetingProvider: meetingProvider,
        leadProvider: leadProvider,
        dashboardProvider: dashboardProvider,
      );

      expect(briefingRes.isSuccess, isTrue);
      expect(briefingRes.actionTitle, equals('Daily Briefing'));
    });
  });
}
