import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common_widgets.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final dateFormat = DateFormat('MMM d, h:mm a');

    final completionRate = taskProvider.totalCount > 0
        ? (taskProvider.completedCount / taskProvider.totalCount)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => taskProvider.loadTasks(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (val) => taskProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search tasks by title or description...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                suffixIcon: taskProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                        onPressed: () => taskProvider.setSearchQuery(''),
                      )
                    : null,
              ),
            ),
          ),

          // Completion Progress Bar Widget
          if (taskProvider.totalCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task Progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${taskProvider.completedCount}/${taskProvider.totalCount} completed (${(completionRate * 100).toInt()}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completionRate,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentEmerald),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Filter Chips Horizontal Scroll
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  isSelected: taskProvider.statusFilter == 'All',
                  onSelected: () => taskProvider.setStatusFilter('All'),
                ),
                _buildFilterChip(
                  context,
                  label: 'Pending',
                  isSelected: taskProvider.statusFilter == 'Pending',
                  onSelected: () => taskProvider.setStatusFilter('Pending'),
                ),
                _buildFilterChip(
                  context,
                  label: 'Completed',
                  isSelected: taskProvider.statusFilter == 'Completed',
                  onSelected: () => taskProvider.setStatusFilter('Completed'),
                ),
                const VerticalDivider(color: AppTheme.cardBorderDark, indent: 4, endIndent: 4),
                _buildFilterChip(
                  context,
                  label: 'Work',
                  isSelected: taskProvider.categoryFilter == 'Work',
                  onSelected: () => taskProvider.setCategoryFilter(
                    taskProvider.categoryFilter == 'Work' ? 'All' : 'Work',
                  ),
                ),
                _buildFilterChip(
                  context,
                  label: 'Meeting',
                  isSelected: taskProvider.categoryFilter == 'Meeting',
                  onSelected: () => taskProvider.setCategoryFilter(
                    taskProvider.categoryFilter == 'Meeting' ? 'All' : 'Meeting',
                  ),
                ),
                _buildFilterChip(
                  context,
                  label: 'Lead',
                  isSelected: taskProvider.categoryFilter == 'Lead',
                  onSelected: () => taskProvider.setCategoryFilter(
                    taskProvider.categoryFilter == 'Lead' ? 'All' : 'Lead',
                  ),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : taskProvider.filteredTasks.isEmpty
                    ? EmptyStateView(
                        icon: Icons.assignment_turned_in_rounded,
                        title: 'No Tasks Found',
                        message: taskProvider.searchQuery.isNotEmpty
                            ? 'No tasks match your search filters.'
                            : 'No tasks yet. Create one to stay organized offline!',
                        buttonText: 'Add First Task',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 80),
                        itemCount: taskProvider.filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = taskProvider.filteredTasks[index];

                          return AnimatedEntrance(
                            index: index,
                            child: Dismissible(
                              key: Key('task_${task.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRose,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (dir) async {
                                return await _showDeleteConfirmDialog(context, task.title);
                              },
                              onDismissed: (_) {
                                if (task.id != null) {
                                  taskProvider.deleteTask(task.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted "${task.title}"')),
                                  );
                                }
                              },
                              child: GlowCard(
                                glowColor: task.isOverdue ? AppTheme.accentRose : null,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: BouncyCheckbox(
                                        isChecked: task.isCompleted,
                                        onChanged: (_) => taskProvider.toggleTaskStatus(task),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: task.isCompleted
                                                        ? AppTheme.textMuted
                                                        : AppTheme.textPrimary,
                                                    decoration: task.isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              PriorityBadge(priority: task.priority),
                                            ],
                                          ),
                                          if (task.description != null &&
                                              task.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              task.description!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceDark,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: AppTheme.cardBorderDark),
                                                ),
                                                child: Text(
                                                  task.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (task.dueDate != null) ...[
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 13,
                                                  color: task.isOverdue
                                                      ? AppTheme.accentRose
                                                      : AppTheme.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dateFormat.format(task.dueDate!),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: task.isOverdue
                                                        ? AppTheme.accentRose
                                                        : AppTheme.textMuted,
                                                    fontWeight: task.isOverdue
                                                        ? FontWeight.w700
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                              const Spacer(),
                                              if (task.isOverdue)
                                                const PulsingBadge(
                                                    text: 'Overdue', color: AppTheme.accentRose),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppTheme.primaryViolet,
        backgroundColor: AppTheme.surfaceDark,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryViolet : AppTheme.cardBorderDark,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
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
  }
}
