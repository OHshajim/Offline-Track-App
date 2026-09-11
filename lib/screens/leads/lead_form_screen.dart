import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/lead_model.dart';
import '../../providers/lead_provider.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;

  const LeadFormScreen({super.key, this.lead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _notesController;

  DateTime? _lastContacted;
  DateTime? _nextFollowup;
  String _status = 'New';

  final List<String> _statuses = ['New', 'Contacted', 'Follow-up Due', 'Closed'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead?.name ?? '');
    _contactController = TextEditingController(text: widget.lead?.contactInfo ?? '');
    _notesController = TextEditingController(text: widget.lead?.notes ?? '');

    if (widget.lead != null) {
      _lastContacted = widget.lead!.lastContacted;
      _nextFollowup = widget.lead!.nextFollowup;
      _status = widget.lead!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNextFollowup}) async {
    final now = DateTime.now();
    final initialDate = isNextFollowup
        ? (_nextFollowup ?? now.add(const Duration(days: 2)))
        : (_lastContacted ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentEmerald,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isNextFollowup) {
          _nextFollowup = picked;
        } else {
          _lastContacted = picked;
        }
      });
    }
  }

  void _saveLead() {
    if (!_formKey.currentState!.validate()) return;

    final leadProvider = context.read<LeadProvider>();

    if (widget.lead == null) {
      final newLead = LeadModel(
        name: _nameController.text.trim(),
        contactInfo: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        lastContacted: _lastContacted,
        nextFollowup: _nextFollowup,
        status: _status,
      );
      leadProvider.addLead(newLead);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead added successfully!')),
      );
    } else {
      final updated = widget.lead!.copyWith(
        name: _nameController.text.trim(),
        contactInfo: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        lastContacted: _lastContacted,
        nextFollowup: _nextFollowup,
        status: _status,
      );
      leadProvider.updateLead(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead updated successfully!')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lead != null;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lead' : 'Add Lead'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !isEditing,
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Lead / Client Name *',
                hintText: 'e.g. Johnathan Miller (FinTech Corp)',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.accentEmerald),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _contactController,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Contact Information',
                hintText: 'e.g. john@fintech.io | +1 555-4321',
                prefixIcon: Icon(Icons.contact_phone_outlined, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 22),

            // Status Selector
            const Text(
              'Lead Status',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _statuses.map((st) {
                final isSelected = _status == st;
                final color = AppTheme.getStatusColor(st);
                return ChoiceChip(
                  label: Text(st),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _status = st),
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

            const SizedBox(height: 22),

            // Date Pickers: Last Contacted & Next Follow-up
            const Text(
              'Follow-up Schedule',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Next Follow-up (Key Field!)
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isNextFollowup: true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _nextFollowup != null
                              ? AppTheme.accentEmerald.withValues(alpha: 0.4)
                              : AppTheme.cardBorderDark,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.alarm_add_rounded, size: 16, color: AppTheme.accentEmerald),
                              SizedBox(width: 6),
                              Text(
                                'Next Follow-up',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentEmerald,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _nextFollowup != null ? dateFormat.format(_nextFollowup!) : 'Set Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: _nextFollowup != null ? AppTheme.textPrimary : AppTheme.textMuted,
                              fontWeight: _nextFollowup != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Last Contacted
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isNextFollowup: false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: AppTheme.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'Last Contacted',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _lastContacted != null ? dateFormat.format(_lastContacted!) : 'Set Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: _lastContacted != null ? AppTheme.textPrimary : AppTheme.textMuted,
                              fontWeight: _lastContacted != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_nextFollowup != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 14, color: AppTheme.accentEmerald),
                    const SizedBox(width: 6),
                    const Text(
                      'An offline follow-up reminder will fire on this date.',
                      style: TextStyle(fontSize: 11, color: AppTheme.accentEmerald),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _nextFollowup = null),
                      child: const Text('Clear', style: TextStyle(fontSize: 11, color: AppTheme.accentRose)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            TextFormField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes / Client Requirements',
                hintText: 'Discussion summary, budget estimates, or follow-up agenda...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textMuted),
              ),
            ),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _saveLead,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: Text(
                isEditing ? 'Update Lead' : 'Create Lead',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
