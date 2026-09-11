import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/models/task_model.dart';
import '../core/models/reminder_model.dart';
import '../core/services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Pending, Completed
  String _categoryFilter = 'All'; // All, Work, Meeting, Lead, Personal
  String _priorityFilter = 'All'; // All, High, Medium, Low

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get categoryFilter => _categoryFilter;
  String get priorityFilter => _priorityFilter;

  // Filtered List
  List<TaskModel> get filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Completed' && task.isCompleted) ||
          (_statusFilter == 'Pending' && !task.isCompleted);

      final matchesCategory = _categoryFilter == 'All' ||
          task.category.toLowerCase() == _categoryFilter.toLowerCase();

      final matchesPriority = _priorityFilter == 'All' ||
          task.priority.toLowerCase() == _priorityFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesCategory && matchesPriority;
    }).toList();
  }

  // Summary Metrics
  int get totalCount => _tasks.length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  int get dueTodayCount => _tasks.where((t) => t.isDueToday && !t.isCompleted).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _db.getAllTasks();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(String filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  void setPriorityFilter(String filter) {
    _priorityFilter = filter;
    notifyListeners();
  }

  Future<void> addTask(TaskModel task) async {
    final id = await _db.insertTask(task);
    final savedTask = task.copyWith(id: id);

    // Schedule notification if task has a future due date
    if (savedTask.dueDate != null && savedTask.dueDate!.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: 10000 + id,
        title: 'Task Due: ${savedTask.title}',
        body: 'Priority: ${savedTask.priority} | Category: ${savedTask.category}',
        scheduledDate: savedTask.dueDate!,
      );

      await _db.insertReminder(ReminderModel(
        refType: 'task',
        refId: id,
        remindAt: savedTask.dueDate!,
      ));
    }

    await loadTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.updateTask(task);

    if (task.id != null) {
      await _notificationService.cancelNotification(10000 + task.id!);
      if (!task.isCompleted && task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: 10000 + task.id!,
          title: 'Task Due: ${task.title}',
          body: 'Priority: ${task.priority} | Category: ${task.category}',
          scheduledDate: task.dueDate!,
        );
      }
    }

    await loadTasks();
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final newStatus = task.isCompleted ? 'Pending' : 'Completed';
    final updated = task.copyWith(status: newStatus);
    await updateTask(updated);
  }

  Future<void> deleteTask(int id) async {
    await _notificationService.cancelNotification(10000 + id);
    await _db.deleteTask(id);
    await loadTasks();
  }
}
