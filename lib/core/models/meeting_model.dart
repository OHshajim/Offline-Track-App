class MeetingModel {
  final int? id;
  final String title;
  final String? notes;
  final DateTime datetime;
  final String recurrence; // None, Daily, Weekly, Monthly
  final DateTime createdAt;

  MeetingModel({
    this.id,
    required this.title,
    this.notes,
    required this.datetime,
    this.recurrence = 'None',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPast => datetime.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return datetime.year == now.year &&
        datetime.month == now.month &&
        datetime.day == now.day;
  }

  bool get isUpcoming => datetime.isAfter(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'datetime': datetime.toIso8601String(),
      'recurrence': recurrence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      datetime: DateTime.parse(map['datetime'] as String),
      recurrence: map['recurrence'] as String? ?? 'None',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MeetingModel copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? datetime,
    String? recurrence,
    DateTime? createdAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      datetime: datetime ?? this.datetime,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
