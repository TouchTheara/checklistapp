import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../routes/app_routes.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../home/widgets/todo_list.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({
    super.key,
    required this.onOpenForm,
  });

  final void Function(BuildContext context, {Todo? existing}) onOpenForm;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todos = controller.todos;
      final canReorder = controller.sortOption == SortOption.manual &&
          !controller.urgentOnly &&
          controller.categories.isNotEmpty;
      return Column(
        children: [
          _FilterBar(controller: controller),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardCard(
              total: controller.totalCount,
              completed: controller.completedCount,
              rate: controller.completionRate,
              priorityBreakdown: controller.priorityBreakdown,
            ),
          ),
          Expanded(
            child: canReorder
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: todos.length,
                    onReorder: controller.reorder,
                    itemBuilder: (_, index) {
                      final todo = todos[index];
                      return TodoCard(
                        key: ValueKey('todo_${todo.id}'),
                        todo: todo,
                        onToggle: () => controller.toggleCompleted(todo.id),
                        onDelete: () => controller.deleteTodo(todo.id),
                        onEdit: () => onOpenForm(context, existing: todo),
                        onOpenDetail: () => Get.toNamed(
                          Routes.todoDetail,
                          arguments: todo.id,
                        ),
                        isDashboard: true,
                      );
                    },
                  )
                : TodoListView(
                    todos: todos,
                    onToggle: controller.toggleCompleted,
                    onDelete: controller.deleteTodo,
                    onEdit: (todo) => onOpenForm(context, existing: todo),
                    isDashboard: true,
                  ),
          ),
        ],
      );
    });
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openSmartAdd(context),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Smart add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Voice to task (speak or type)',
                onPressed: () => _openSmartAdd(context, voiceMode: true),
                icon: const Icon(Icons.mic_none),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search tasks',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              isDense: true,
              filled: true,
            ),
            onChanged: controller.updateSearch,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Urgent'),
                  avatar: const Icon(Icons.priority_high, size: 18),
                  selected: controller.urgentOnly,
                  onSelected: (_) => controller.toggleUrgentOnly(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<TodoPriority?>(
                  tooltip: 'Filter priority',
                  onSelected: controller.updatePriorityFilter,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('Any priority'),
                    ),
                    ...TodoPriority.values.map(
                      (p) => PopupMenuItem(
                        value: p,
                        child: Text(p.label),
                      ),
                    ),
                  ],
                  child: Chip(
                    label: Text('Priority'),
                    avatar: const Icon(Icons.filter_alt, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  tooltip: 'Filter category',
                  onSelected: controller.updateCategoryFilter,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '',
                      child: Text('Any category'),
                    ),
                    ...controller.categories.map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    ),
                  ],
                  child: Chip(
                    label: const Text('Category'),
                    avatar: const Icon(Icons.folder_open, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortOption>(
                  tooltip: 'Sort',
                  onSelected: controller.changeSort,
                  initialValue: controller.sortOption,
                  itemBuilder: (_) => SortOption.values
                      .map(
                        (opt) => PopupMenuItem(
                          value: opt,
                          child: Text(opt.label),
                        ),
                      )
                      .toList(),
                  child: Chip(
                    label: const Text('Sort'),
                    avatar: const Icon(Icons.sort, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSmartAdd(BuildContext context, {bool voiceMode = false}) async {
    final controller = Get.find<DashboardController>();
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(voiceMode ? 'Voice to task' : 'Smart add'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: voiceMode
                ? 'Speak or type: "Inspect scaffolding tomorrow high priority"'
                : 'e.g. "Buy safety gloves tomorrow high priority"',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      controller.addSmartTask(result);
      Get.snackbar(
        'Task created',
        'Added using smart parsing',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
