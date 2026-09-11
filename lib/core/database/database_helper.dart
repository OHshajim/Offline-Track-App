import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/lead_model.dart';
import '../models/reminder_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offlinetrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB,
      );
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tasks Table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        priority TEXT NOT NULL DEFAULT 'Medium',
        category TEXT NOT NULL DEFAULT 'Work',
        status TEXT NOT NULL DEFAULT 'Pending',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Meetings Table
    await db.execute('''
      CREATE TABLE meetings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT,
        datetime TEXT NOT NULL,
        recurrence TEXT NOT NULL DEFAULT 'None',
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Leads Table
    await db.execute('''
      CREATE TABLE leads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_info TEXT,
        last_contacted TEXT,
        next_followup TEXT,
        status TEXT NOT NULL DEFAULT 'New',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Reminders Table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref_type TEXT NOT NULL,
        ref_id INTEGER NOT NULL,
        remind_at TEXT NOT NULL,
        fired INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes for fast querying in offline conditions
    await db.execute('CREATE INDEX idx_tasks_status ON tasks (status);');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks (due_date);');
    await db.execute('CREATE INDEX idx_meetings_datetime ON meetings (datetime);');
    await db.execute('CREATE INDEX idx_leads_next_followup ON leads (next_followup);');
    await db.execute('CREATE INDEX idx_reminders_remind_at ON reminders (remind_at, fired);');
  }

  // ===================== TASK OPERATIONS =====================

  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    await deleteReminderByRef('task', id);
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'due_date ASC, created_at DESC');
    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  // ===================== MEETING OPERATIONS =====================

  Future<int> insertMeeting(MeetingModel meeting) async {
    final db = await database;
    return await db.insert('meetings', meeting.toMap());
  }

  Future<int> updateMeeting(MeetingModel meeting) async {
    final db = await database;
    return await db.update(
      'meetings',
      meeting.toMap(),
      where: 'id = ?',
      whereArgs: [meeting.id],
    );
  }

  Future<int> deleteMeeting(int id) async {
    final db = await database;
    await deleteReminderByRef('meeting', id);
    return await db.delete(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MeetingModel>> getAllMeetings() async {
    final db = await database;
    final result = await db.query('meetings', orderBy: 'datetime ASC');
    return result.map((json) => MeetingModel.fromMap(json)).toList();
  }

  // ===================== LEAD OPERATIONS =====================

  Future<int> insertLead(LeadModel lead) async {
    final db = await database;
    return await db.insert('leads', lead.toMap());
  }

  Future<int> updateLead(LeadModel lead) async {
    final db = await database;
    return await db.update(
      'leads',
      lead.toMap(),
      where: 'id = ?',
      whereArgs: [lead.id],
    );
  }

  Future<int> deleteLead(int id) async {
    final db = await database;
    await deleteReminderByRef('lead', id);
    return await db.delete(
      'leads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LeadModel>> getAllLeads() async {
    final db = await database;
    final result = await db.query('leads', orderBy: 'next_followup ASC, created_at DESC');
    return result.map((json) => LeadModel.fromMap(json)).toList();
  }

  // ===================== REMINDER OPERATIONS =====================

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<int> updateReminderFired(int id, bool fired) async {
    final db = await database;
    return await db.update(
      'reminders',
      {'fired': fired ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminderByRef(String refType, int refId) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'ref_type = ? AND ref_id = ?',
      whereArgs: [refType, refId],
    );
  }

  Future<List<ReminderModel>> getPendingReminders() async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'fired = 0',
      orderBy: 'remind_at ASC',
    );
    return result.map((json) => ReminderModel.fromMap(json)).toList();
  }

  // ===================== EXPORT & BACKUP =====================

  Future<String> exportDatabaseToJson() async {
    final db = await database;
    final tasks = await db.query('tasks');
    final meetings = await db.query('meetings');
    final leads = await db.query('leads');
    final reminders = await db.query('reminders');

    final backup = {
      'app': 'OfflineTrack',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'tasks': tasks,
        'meetings': meetings,
        'leads': leads,
        'reminders': reminders,
      }
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('meetings');
    await db.delete('leads');
    await db.delete('reminders');
  }

  Future<void> seedSampleData() async {
    await clearAllData();

    final now = DateTime.now();

    // Sample Tasks
    await insertTask(TaskModel(
      title: 'Review Client Proposal',
      description: 'Review SLA terms and deliverables before signing off.',
      dueDate: now.add(const Duration(hours: 4)),
      priority: 'High',
      category: 'Work',
      status: 'Pending',
    ));

    await insertTask(TaskModel(
      title: 'Send Weekly Invoices',
      description: 'Invoice Q3 sprint work to Acme Corp.',
      dueDate: now.subtract(const Duration(days: 1)),
      priority: 'High',
      category: 'Work',
      status: 'Pending',
    ));

    await insertTask(TaskModel(
      title: 'Prepare Presentation Slides',
      description: 'Outline offline architecture diagram and DB schema.',
      dueDate: now.add(const Duration(days: 2)),
      priority: 'Medium',
      category: 'Work',
      status: 'Pending',
    ));

    await insertTask(TaskModel(
      title: 'Setup Database Migration Tests',
      description: 'Verify SQLite indexes and table integrity.',
      dueDate: now.subtract(const Duration(days: 2)),
      priority: 'Low',
      category: 'Work',
      status: 'Completed',
    ));

    // Sample Meetings
    await insertMeeting(MeetingModel(
      title: 'Sprint Planning & Standup',
      notes: 'Review user stories for offline notification reliability.',
      datetime: DateTime(now.year, now.month, now.day, 14, 0),
      recurrence: 'Daily',
    ));

    await insertMeeting(MeetingModel(
      title: 'Client Demo: Mobile Offline Sync',
      notes: 'Demonstrate zero-latency queries and local alerts.',
      datetime: now.add(const Duration(days: 1, hours: 2)),
      recurrence: 'None',
    ));

    await insertMeeting(MeetingModel(
      title: 'Architecture Review with Lead Architect',
      notes: 'Discuss future CRDT-based multi-device synchronization.',
      datetime: now.add(const Duration(days: 3, hours: 5)),
      recurrence: 'Weekly',
    ));

    // Sample Leads
    await insertLead(LeadModel(
      name: 'Sarah Connor (Cyberdyne Systems)',
      contactInfo: 'sarah.connor@cyberdyne.io | +1 555-0192',
      status: 'Follow-up Due',
      notes: 'Interested in bespoke offline inventory software. Needs pricing sheet.',
      lastContacted: now.subtract(const Duration(days: 4)),
      nextFollowup: now.subtract(const Duration(hours: 2)), // overdue
    ));

    await insertLead(LeadModel(
      name: 'Marcus Vance (Nexus Logistics)',
      contactInfo: 'm.vance@nexuscorp.com',
      status: 'Contacted',
      notes: 'Sent initial pitch deck. Follow up about pilot contract.',
      lastContacted: now.subtract(const Duration(days: 1)),
      nextFollowup: DateTime(now.year, now.month, now.day, 16, 30), // today
    ));

    await insertLead(LeadModel(
      name: 'Elena Rostova (Apex Ventures)',
      contactInfo: 'elena@apexvc.com | +44 20 7946 0912',
      status: 'New',
      notes: 'Met at FinTech expo. Wants demo next week.',
      lastContacted: now,
      nextFollowup: now.add(const Duration(days: 4)),
    ));

    await insertLead(LeadModel(
      name: 'David Kim (Horizon Tech)',
      contactInfo: 'dkim@horizon.dev',
      status: 'Closed',
      notes: 'Contract signed! Onboarding scheduled for next month.',
      lastContacted: now.subtract(const Duration(days: 7)),
      nextFollowup: null,
    ));
  }
}
