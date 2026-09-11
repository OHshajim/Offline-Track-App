import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/meeting_model.dart';
import '../../providers/meeting_provider.dart';

class MeetingFormScreen extends StatefulWidget {
  final MeetingModel? meeting;

  const MeetingFormScreen({super.key, this.meeting});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedRecurrence = 'None';

  final List<String> _recurrenceOptions = ['None', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting?.title ?? '');
    _notesController = TextEditingController(text: widget.meeting?.notes ?? '');

    if (widget.meeting != null) {
      _selectedDate = widget.meeting!.datetime;
      _selectedTime = TimeOfDay.fromDateTime(widget.meeting!.datetime);
      _selectedRecurrence = widget.meeting!.recurrence;
    } else {
      final now = DateTime.now();
      _selectedDate = now;
      _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentCyan,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentCyan,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime _getCombinedDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  void _saveMeeting() {
    if (!_formKey.currentState!.validate()) return;

    final combined = _getCombinedDateTime();
    final meetingProvider = context.read<MeetingProvider>();

    if (widget.meeting == null) {
      final newMeeting = MeetingModel(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        datetime: combined,
        recurrence: _selectedRecurrence,
      );
      meetingProvider.addMeeting(newMeeting);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled with offline reminder!')),
      );
    } else {
      final updated = widget.meeting!.copyWith(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        datetime: combined,
        recurrence: _selectedRecurrence,
      );
      meetingProvider.updateMeeting(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting updated successfully!')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meeting != null;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meeting' : 'Schedule Meeting'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: !isEditing,
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Meeting Title *',
                hintText: 'e.g. Design Sync with Product Team',
                prefixIcon: Icon(Icons.video_call_rounded, color: AppTheme.accentCyan),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a meeting title';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Meeting Agenda / Notes (Optional)',
                hintText: 'Meeting link, discussion agenda, or prep notes...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorderDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accentCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorderDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.accentCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.notifications_active_rounded, size: 14, color: AppTheme.accentCyan),
                SizedBox(width: 6),
                Text(
                  'Local notification fires on time even if phone is in Airplane mode.',
                  style: TextStyle(fontSize: 11, color: AppTheme.accentCyan),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Recurrence',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: _recurrenceOptions.map((rec) {
                final isSelected = _selectedRecurrence == rec;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedRecurrence = rec),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentCyan.withValues(alpha: 0.18)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentCyan : AppTheme.cardBorderDark,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            rec,
                            style: TextStyle(
                              color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _saveMeeting,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: Text(
                isEditing ? 'Update Meeting' : 'Schedule Meeting',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
