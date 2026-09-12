import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offlinetrack/core/database/database_helper.dart';
import 'package:offlinetrack/core/models/task_model.dart';
import 'package:offlinetrack/core/models/meeting_model.dart';
import 'package:offlinetrack/core/models/lead_model.dart';
import 'package:offlinetrack/core/models/reminder_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('DatabaseHelper SQLite Unit Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();
    });

    test('Task CRUD operations persist correctly', () async {
      final task = TaskModel(
        title: 'Offline Architecture Testing',
        description: 'Verify local SQLite persistence',
        dueDate: DateTime.now().add(const Duration(hours: 5)),
        priority: 'High',
        category: 'Work',
        status: 'Pending',
      );

      final id = await dbHelper.insertTask(task);
      expect(id, isGreaterThan(0));

      final tasks = await dbHelper.getAllTasks();
      expect(tasks.length, equals(1));
      expect(tasks.first.title, equals('Offline Architecture Testing'));
      expect(tasks.first.priority, equals('High'));

      final updatedTask = tasks.first.copyWith(status: 'Completed');
      await dbHelper.updateTask(updatedTask);

      final reloadedTasks = await dbHelper.getAllTasks();
      expect(reloadedTasks.first.isCompleted, isTrue);

      await dbHelper.deleteTask(id);
      final finalTasks = await dbHelper.getAllTasks();
      expect(finalTasks, isEmpty);
    });

    test('Meeting CRUD operations persist correctly', () async {
      final meeting = MeetingModel(
        title: 'Client Standup',
        notes: 'Review Q4 deliverables',
        datetime: DateTime.now().add(const Duration(days: 1)),
        recurrence: 'Daily',
      );

      final id = await dbHelper.insertMeeting(meeting);
      expect(id, isGreaterThan(0));

      final meetings = await dbHelper.getAllMeetings();
      expect(meetings.length, equals(1));
      expect(meetings.first.title, equals('Client Standup'));

      await dbHelper.deleteMeeting(id);
      final finalMeetings = await dbHelper.getAllMeetings();
      expect(finalMeetings, isEmpty);
    });

    test('Lead CRUD operations persist correctly', () async {
      final lead = LeadModel(
        name: 'Jane Doe (Acme Corp)',
        contactInfo: 'jane@acme.org',
        status: 'New',
        notes: 'Interested in enterprise license',
        nextFollowup: DateTime.now().add(const Duration(days: 2)),
      );

      final id = await dbHelper.insertLead(lead);
      expect(id, isGreaterThan(0));

      final leads = await dbHelper.getAllLeads();
      expect(leads.length, equals(1));
      expect(leads.first.name, equals('Jane Doe (Acme Corp)'));

      await dbHelper.deleteLead(id);
      final finalLeads = await dbHelper.getAllLeads();
      expect(finalLeads, isEmpty);
    });

    test('Reminders table registration and queries work', () async {
      final reminder = ReminderModel(
        refType: 'task',
        refId: 42,
        remindAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final id = await dbHelper.insertReminder(reminder);
      expect(id, isGreaterThan(0));

      final pendingReminders = await dbHelper.getPendingReminders();
      expect(pendingReminders.length, equals(1));
      expect(pendingReminders.first.refId, equals(42));

      await dbHelper.updateReminderFired(pendingReminders.first.id!, true);
      final remainingPending = await dbHelper.getPendingReminders();
      expect(remainingPending, isEmpty);
    });

    test('Export database JSON dumps all tables accurately', () async {
      await dbHelper.seedSampleData();

      final jsonExport = await dbHelper.exportDatabaseToJson();
      expect(jsonExport, contains('"app": "OfflineTrack"'));
      expect(jsonExport, contains('"tasks"'));
      expect(jsonExport, contains('"meetings"'));
      expect(jsonExport, contains('"leads"'));
      expect(jsonExport, contains('"reminders"'));
    });
  });
}
