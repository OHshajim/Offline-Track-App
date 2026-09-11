class LeadModel {
  final int? id;
  final String name;
  final String? contactInfo;
  final DateTime? lastContacted;
  final DateTime? nextFollowup;
  final String status; // New, Contacted, Follow-up Due, Closed
  final String? notes;
  final DateTime createdAt;

  LeadModel({
    this.id,
    required this.name,
    this.contactInfo,
    this.lastContacted,
    this.nextFollowup,
    this.status = 'New',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFollowupOverdue {
    if (nextFollowup == null || status.toLowerCase() == 'closed') return false;
    return nextFollowup!.isBefore(DateTime.now());
  }

  bool get isFollowupDueToday {
    if (nextFollowup == null || status.toLowerCase() == 'closed') return false;
    final now = DateTime.now();
    return nextFollowup!.year == now.year &&
        nextFollowup!.month == now.month &&
        nextFollowup!.day == now.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
      'last_contacted': lastContacted?.toIso8601String(),
      'next_followup': nextFollowup?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LeadModel.fromMap(Map<String, dynamic> map) {
    return LeadModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      contactInfo: map['contact_info'] as String?,
      lastContacted: map['last_contacted'] != null
          ? DateTime.parse(map['last_contacted'] as String)
          : null,
      nextFollowup: map['next_followup'] != null
          ? DateTime.parse(map['next_followup'] as String)
          : null,
      status: map['status'] as String? ?? 'New',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LeadModel copyWith({
    int? id,
    String? name,
    String? contactInfo,
    DateTime? lastContacted,
    DateTime? nextFollowup,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      lastContacted: lastContacted ?? this.lastContacted,
      nextFollowup: nextFollowup ?? this.nextFollowup,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
