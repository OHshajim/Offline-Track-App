import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/models/meeting_model.dart';
import '../core/models/reminder_model.dart';
import '../core/services/notification_service.dart';

class MeetingProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<MeetingModel> _meetings = [];
  bool _isLoading = false;
  String _filter = 'All'; // All, Today, Upcoming, Past

  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;
  String get filter => _filter;

  List<MeetingModel> get todayMeetings => _meetings.where((m) => m.isToday).toList();
  List<MeetingModel> get upcomingMeetings => _meetings.where((m) => m.isUpcoming).toList();
  List<MeetingModel> get pastMeetings => _meetings.where((m) => m.isPast).toList();

  List<MeetingModel> get filteredMeetings {
    switch (_filter) {
      case 'Today':
        return todayMeetings;
      case 'Upcoming':
        return upcomingMeetings;
      case 'Past':
        return pastMeetings;
      case 'All':
      default:
        return _meetings;
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadMeetings() async {
    _isLoading = true;
    notifyListeners();

    _meetings = await _db.getAllMeetings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMeeting(MeetingModel meeting) async {
    final id = await _db.insertMeeting(meeting);
    final saved = meeting.copyWith(id: id);

    // Schedule notification if in the future
    if (saved.datetime.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: 20000 + id,
        title: 'Meeting Alert: ${saved.title}',
        body: 'Scheduled at ${saved.datetime.hour.toString().padLeft(2, '0')}:${saved.datetime.minute.toString().padLeft(2, '0')} (${saved.recurrence} recurrence)',
        scheduledDate: saved.datetime,
      );

      await _db.insertReminder(ReminderModel(
        refType: 'meeting',
        refId: id,
        remindAt: saved.datetime,
      ));
    }

    await loadMeetings();
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    await _db.updateMeeting(meeting);

    if (meeting.id != null) {
      await _notificationService.cancelNotification(20000 + meeting.id!);
      if (meeting.datetime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: 20000 + meeting.id!,
          title: 'Meeting Alert: ${meeting.title}',
          body: 'Scheduled at ${meeting.datetime.hour.toString().padLeft(2, '0')}:${meeting.datetime.minute.toString().padLeft(2, '0')} (${meeting.recurrence} recurrence)',
          scheduledDate: meeting.datetime,
        );
      }
    }

    await loadMeetings();
  }

  Future<void> deleteMeeting(int id) async {
    await _notificationService.cancelNotification(20000 + id);
    await _db.deleteMeeting(id);
    await loadMeetings();
  }
}
