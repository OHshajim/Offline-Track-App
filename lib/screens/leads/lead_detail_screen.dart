import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/lead_model.dart';
import '../../providers/lead_provider.dart';
import '../../widgets/common_widgets.dart';
import 'lead_form_screen.dart';

class LeadDetailScreen extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    // Watch provider to get updated lead instance if edited
    final leadProvider = context.watch<LeadProvider>();
    final currentLead = leadProvider.leads.firstWhere(
      (l) => l.id == lead.id,
      orElse: () => lead,
    );

    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final isOverdue = currentLead.isFollowupOverdue;
    final isDueToday = currentLead.isFollowupDueToday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Lead',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadFormScreen(lead: currentLead),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose),
            tooltip: 'Delete Lead',
            onPressed: () => _confirmDelete(context, currentLead),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Lead Header Card
          GlowCard(
            margin: EdgeInsets.zero,
            glowColor: AppTheme.accentEmerald,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accentEmerald.withValues(alpha: 0.2),
                  child: Text(
                    currentLead.name.isNotEmpty ? currentLead.name[0].toUpperCase() : 'L',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  currentLead.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (currentLead.contactInfo != null && currentLead.contactInfo!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    currentLead.contactInfo!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 14),
                StatusBadge(status: currentLead.status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Follow-up Alert Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isOverdue
                    ? AppTheme.accentRose.withValues(alpha: 0.5)
                    : (isDueToday
                        ? AppTheme.accentAmber.withValues(alpha: 0.5)
                        : AppTheme.cardBorderDark),
                width: (isOverdue || isDueToday) ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Next Follow-up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (isOverdue)
                      const PulsingBadge(text: 'Overdue', color: AppTheme.accentRose)
                    else if (isDueToday)
                      const PulsingBadge(text: 'Due Today', color: AppTheme.accentAmber),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.alarm_on_rounded,
                      size: 22,
                      color: isOverdue
                          ? AppTheme.accentRose
                          : (isDueToday ? AppTheme.accentAmber : AppTheme.accentCyan),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentLead.nextFollowup != null
                            ? dateFormat.format(currentLead.nextFollowup!)
                            : 'No next follow-up date set',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: currentLead.nextFollowup != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentLead.lastContacted != null) ...[
                  const Divider(color: AppTheme.cardBorderDark, height: 24),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Last contacted: ${dateFormat.format(currentLead.lastContacted!)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Change Status Section
          const Text(
            'Update Status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['New', 'Contacted', 'Follow-up Due', 'Closed'].map((st) {
              final isCurrent = currentLead.status.toLowerCase() == st.toLowerCase();
              final color = AppTheme.getStatusColor(st);
              return ChoiceChip(
                label: Text(st),
                selected: isCurrent,
                onSelected: (_) {
                  leadProvider.updateLeadStatus(currentLead, st);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lead status updated to "$st"')),
                  );
                },
                selectedColor: color.withValues(alpha: 0.25),
                backgroundColor: AppTheme.surfaceDark,
                labelStyle: TextStyle(
                  color: isCurrent ? color : AppTheme.textSecondary,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrent ? color : AppTheme.cardBorderDark,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Notes Section
          const Text(
            'Notes & Interaction History',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorderDark),
            ),
            child: Text(
              currentLead.notes != null && currentLead.notes!.isNotEmpty
                  ? currentLead.notes!
                  : 'No notes recorded for this lead yet. Tap Edit to add client requirements or discussion notes.',
              style: TextStyle(
                fontSize: 14,
                color: currentLead.notes != null && currentLead.notes!.isNotEmpty
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LeadModel lead) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to remove "${lead.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && lead.id != null) {
      if (context.mounted) {
        context.read<LeadProvider>().deleteLead(lead.id!);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${lead.name}"')),
        );
      }
    }
  }
}
