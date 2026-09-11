import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/task_model.dart';
import '../../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Work';
  String _selectedStatus = 'Pending';

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _categories = ['Work', 'Meeting', 'Lead', 'Personal'];
  final List<String> _statuses = ['Pending', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');

    if (widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedCategory = widget.task!.category;
      _selectedStatus = widget.task!.status;
      if (widget.task!.dueDate != null) {
        _selectedDueDate = widget.task!.dueDate;
        _selectedDueTime = TimeOfDay.fromDateTime(widget.task!.dueDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryViolet,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
        _selectedDueTime ??= const TimeOfDay(hour: 17, minute: 0);
      });
    }
  }

  Future<void> _pickDueTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryViolet,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDueTime = pickedTime;
      });
    }
  }

  DateTime? _combineDateAndTime() {
    if (_selectedDueDate == null) return null;
    final time = _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
      time.hour,
      time.minute,
    );
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final combinedDue = _combineDateAndTime();
    final taskProvider = context.read<TaskProvider>();

    if (widget.task == null) {
      final newTask = TaskModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dueDate: combinedDue,
        priority: _selectedPriority,
        category: _selectedCategory,
        status: _selectedStatus,
      );
      taskProvider.addTask(newTask);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added and saved locally!')),
      );
    } else {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dueDate: combinedDue,
        priority: _selectedPriority,
        category: _selectedCategory,
        status: _selectedStatus,
      );
      taskProvider.updateTask(updatedTask);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully!')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              autofocus: !isEditing,
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'e.g. Finish UX mockup or Review contract',
                prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primaryViolet),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description / Notes (Optional)',
                hintText: 'Add extra details, checklist links, or context...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 22),

            // Due Date & Time Pickers
            const Text(
              'Due Date & Reminder',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDueDate,
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
                              _selectedDueDate != null
                                  ? dateFormat.format(_selectedDueDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedDueDate != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontWeight: _selectedDueDate != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
                    onTap: _selectedDueDate != null ? _pickDueTime : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedDueDate != null
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorderDark),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: _selectedDueDate != null ? AppTheme.accentCyan : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDueTime != null
                                  ? _selectedDueTime!.format(context)
                                  : 'Select Time',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedDueTime != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontWeight: _selectedDueTime != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
            if (_selectedDueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 14, color: AppTheme.accentCyan),
                    const SizedBox(width: 6),
                    const Text(
                      'An offline local notification will alert you at this time.',
                      style: TextStyle(fontSize: 11, color: AppTheme.accentCyan),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDueDate = null;
                          _selectedDueTime = null;
                        });
                      },
                      child: const Text('Clear Date', style: TextStyle(fontSize: 11, color: AppTheme.accentRose)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            // Priority Segmented Selector
            const Text(
              'Priority',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = AppTheme.getPriorityColor(priority);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = priority),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color : AppTheme.cardBorderDark,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: isSelected ? color : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Category Selection
            const Text(
              'Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryViolet : AppTheme.cardBorderDark,
                    ),
                  ),
                );
              }).toList(),
            ),

            if (isEditing) ...[
              const SizedBox(height: 22),
              const Text(
                'Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _statuses.map((status) {
                  final isSelected = _selectedStatus == status;
                  final color = AppTheme.getStatusColor(status);
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                    selectedColor: color.withValues(alpha: 0.25),
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: TextStyle(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? color : AppTheme.cardBorderDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 36),

            // Save Action Button
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: Text(
                isEditing ? 'Save Changes' : 'Create Task',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
