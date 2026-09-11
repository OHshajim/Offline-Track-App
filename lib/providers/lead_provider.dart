import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/models/lead_model.dart';
import '../core/models/reminder_model.dart';
import '../core/services/notification_service.dart';

class LeadProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<LeadModel> _leads = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, New, Contacted, Follow-up Due, Closed

  List<LeadModel> get leads => _leads;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<LeadModel> get filteredLeads {
    return _leads.where((lead) {
      final matchesSearch = _searchQuery.isEmpty ||
          lead.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (lead.contactInfo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (lead.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesStatus = _statusFilter == 'All' ||
          lead.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get totalCount => _leads.length;
  int get followUpDueCount => _leads.where((l) => l.isFollowupDueToday || l.isFollowupOverdue).length;
  int get overdueCount => _leads.where((l) => l.isFollowupOverdue).length;
  int get dueTodayCount => _leads.where((l) => l.isFollowupDueToday).length;
  int get closedCount => _leads.where((l) => l.status.toLowerCase() == 'closed').length;

  Future<void> loadLeads() async {
    _isLoading = true;
    notifyListeners();

    _leads = await _db.getAllLeads();
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

  Future<void> addLead(LeadModel lead) async {
    final id = await _db.insertLead(lead);
    final saved = lead.copyWith(id: id);

    // Schedule notification if follow up is in future
    if (saved.nextFollowup != null && saved.nextFollowup!.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: 30000 + id,
        title: 'Lead Follow-up: ${saved.name}',
        body: 'Follow-up is scheduled now. Status: ${saved.status}',
        scheduledDate: saved.nextFollowup!,
      );

      await _db.insertReminder(ReminderModel(
        refType: 'lead',
        refId: id,
        remindAt: saved.nextFollowup!,
      ));
    }

    await loadLeads();
  }

  Future<void> updateLead(LeadModel lead) async {
    await _db.updateLead(lead);

    if (lead.id != null) {
      await _notificationService.cancelNotification(30000 + lead.id!);
      if (lead.status.toLowerCase() != 'closed' &&
          lead.nextFollowup != null &&
          lead.nextFollowup!.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: 30000 + lead.id!,
          title: 'Lead Follow-up: ${lead.name}',
          body: 'Follow-up is scheduled now. Status: ${lead.status}',
          scheduledDate: lead.nextFollowup!,
        );
      }
    }

    await loadLeads();
  }

  Future<void> updateLeadStatus(LeadModel lead, String newStatus) async {
    final updated = lead.copyWith(status: newStatus);
    await updateLead(updated);
  }

  Future<void> deleteLead(int id) async {
    await _notificationService.cancelNotification(30000 + id);
    await _db.deleteLead(id);
    await loadLeads();
  }
}
