import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/lead_provider.dart';
import '../../widgets/common_widgets.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';

class LeadListScreen extends StatelessWidget {
  const LeadListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leadProvider = context.watch<LeadProvider>();
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => leadProvider.loadLeads(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeadFormScreen()),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.accentEmerald,
      ),
      body: Column(
        children: [
          // Pipeline Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildLeadMetric(
                  label: 'Total Leads',
                  count: leadProvider.totalCount,
                  color: AppTheme.accentCyan,
                ),
                const SizedBox(width: 8),
                _buildLeadMetric(
                  label: 'Follow-ups Due',
                  count: leadProvider.followUpDueCount,
                  color: AppTheme.accentRose,
                  isAlert: leadProvider.followUpDueCount > 0,
                ),
                const SizedBox(width: 8),
                _buildLeadMetric(
                  label: 'Closed / Won',
                  count: leadProvider.closedCount,
                  color: AppTheme.accentEmerald,
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (val) => leadProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search leads by name, contact, notes...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                suffixIcon: leadProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                        onPressed: () => leadProvider.setSearchQuery(''),
                      )
                    : null,
              ),
            ),
          ),

          // Status Filters
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'New', 'Contacted', 'Follow-up Due', 'Closed'].map((st) {
                final isSelected = leadProvider.statusFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(st),
                    selected: isSelected,
                    onSelected: (_) => leadProvider.setStatusFilter(st),
                    selectedColor: AppTheme.accentEmerald.withValues(alpha: 0.2),
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppTheme.accentEmerald : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppTheme.accentEmerald : AppTheme.cardBorderDark,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // Leads List
          Expanded(
            child: leadProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : leadProvider.filteredLeads.isEmpty
                    ? EmptyStateView(
                        icon: Icons.person_search_rounded,
                        title: 'No Leads Found',
                        message: leadProvider.searchQuery.isNotEmpty
                            ? 'No leads matching your current search query.'
                            : 'Start tracking client leads and follow-up reminders offline.',
                        buttonText: 'Add First Lead',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LeadFormScreen()),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: leadProvider.filteredLeads.length,
                        itemBuilder: (context, index) {
                          final lead = leadProvider.filteredLeads[index];
                          final isOverdue = lead.isFollowupOverdue;
                          final isDueToday = lead.isFollowupDueToday;

                          return AnimatedEntrance(
                            index: index,
                            child: GlowCard(
                              glowColor: isOverdue ? AppTheme.accentRose : null,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Avatar Circle
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.accentEmerald.withValues(alpha: 0.18),
                                        child: Text(
                                          lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                                          style: const TextStyle(
                                            color: AppTheme.accentEmerald,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Lead Name & Contact Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lead.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (lead.contactInfo != null && lead.contactInfo!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                lead.contactInfo!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Status Badge
                                      StatusBadge(status: lead.status),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Follow-up Footer
                                  Row(
                                    children: [
                                      if (lead.nextFollowup != null) ...[
                                        Icon(
                                          Icons.notification_important_rounded,
                                          size: 14,
                                          color: isOverdue
                                              ? AppTheme.accentRose
                                              : (isDueToday ? AppTheme.accentAmber : AppTheme.textMuted),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Next: ${dateFormat.format(lead.nextFollowup!)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOverdue
                                                ? AppTheme.accentRose
                                                : (isDueToday ? AppTheme.accentAmber : AppTheme.textMuted),
                                            fontWeight: (isOverdue || isDueToday)
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ] else
                                        const Text(
                                          'No follow-up scheduled',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      const Spacer(),
                                      if (isOverdue)
                                        const PulsingBadge(text: 'Due Now', color: AppTheme.accentRose)
                                      else if (isDueToday)
                                        const PulsingBadge(text: 'Today', color: AppTheme.accentAmber),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadMetric({
    required String label,
    required int count,
    required Color color,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isAlert ? 0.4 : 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
