class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority; // Low, Medium, High
  final String category; // Work, Meeting, Lead, Personal
  final String status; // Pending, In Progress, Completed
  final DateTime createdAt;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'Medium',
    this.category = 'Work',
    this.status = 'Pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status.toLowerCase() == 'completed';

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      priority: map['priority'] as String? ?? 'Medium',
      category: map['category'] as String? ?? 'Work',
      status: map['status'] as String? ?? 'Pending',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? category,
    String? status,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
