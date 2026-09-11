class ReminderModel {
  final int? id;
  final String refType; // 'task', 'meeting', 'lead'
  final int refId;
  final DateTime remindAt;
  final bool fired;

  ReminderModel({
    this.id,
    required this.refType,
    required this.refId,
    required this.remindAt,
    this.fired = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ref_type': refType,
      'ref_id': refId,
      'remind_at': remindAt.toIso8601String(),
      'fired': fired ? 1 : 0,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      refType: map['ref_type'] as String,
      refId: map['ref_id'] as int,
      remindAt: DateTime.parse(map['remind_at'] as String),
      fired: (map['fired'] as int) == 1,
    );
  }

  ReminderModel copyWith({
    int? id,
    String? refType,
    int? refId,
    DateTime? remindAt,
    bool? fired,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      remindAt: remindAt ?? this.remindAt,
      fired: fired ?? this.fired,
    );
  }
}
