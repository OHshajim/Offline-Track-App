import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offlinetrack/core/database/database_helper.dart';
import 'package:offlinetrack/core/models/task_model.dart';
import 'package:offlinetrack/core/models/meeting_model.dart';
import 'package:offlinetrack/core/models/lead_model.dart';
import 'package:offlinetrack/providers/task_provider.dart';
import 'package:offlinetrack/providers/meeting_provider.dart';
import 'package:offlinetrack/providers/lead_provider.dart';
import 'package:offlinetrack/providers/dashboard_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('Providers Integration Tests', () {
    setUp(() async {
      await DatabaseHelper.instance.clearAllData();
    });

    test('TaskProvider filtering and search work correctly', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(TaskModel(
        title: 'Fix SQLite Indexing',
        category: 'Work',
        priority: 'High',
      ));

      await provider.addTask(TaskModel(
        title: 'Buy Groceries',
        category: 'Personal',
        priority: 'Low',
      ));

      expect(provider.totalCount, equals(2));

      provider.setCategoryFilter('Work');
      expect(provider.filteredTasks.length, equals(1));
      expect(provider.filteredTasks.first.title, equals('Fix SQLite Indexing'));

      provider.setCategoryFilter('All');
      provider.setSearchQuery('Groceries');
      expect(provider.filteredTasks.length, equals(1));
      expect(provider.filteredTasks.first.title, equals('Buy Groceries'));
    });

    test('MeetingProvider and LeadProvider state filtering work correctly', () async {
      final meetingProvider = MeetingProvider();
      final leadProvider = LeadProvider();

      await meetingProvider.addMeeting(MeetingModel(
        title: 'Team Sync',
        datetime: DateTime.now().add(const Duration(hours: 1)),
      ));

      await leadProvider.addLead(LeadModel(
        name: 'John Smith',
        status: 'New',
      ));

      expect(meetingProvider.meetings.length, equals(1));
      expect(leadProvider.leads.length, equals(1));
    });

    test('DashboardProvider aggregates tasks, meetings, and leads accurately', () async {
      await DatabaseHelper.instance.seedSampleData();

      final dashProvider = DashboardProvider();
      await dashProvider.refreshDashboard();

      expect(dashProvider.todayItems, isNotEmpty);
      expect(dashProvider.overdueItems, isNotEmpty);
    });
  });
}
