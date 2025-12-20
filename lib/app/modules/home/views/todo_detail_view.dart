import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../controllers/home_controller.dart';

class TodoDetailView extends GetView<HomeController> {
  const TodoDetailView({super.key, required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todo = controller.todos.firstWhereOrNull((t) => t.id == todoId);
      if (todo == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Task detail')),
          body: const Center(child: Text('Task not found')),
        );
      }
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(todo.title.isEmpty ? 'Task detail' : todo.title),
          actions: [
            IconButton(
              icon: Icon(
                todo.completedSubtasks == todo.totalSubtasks && todo.totalSubtasks > 0
                    ? Icons.check_circle
                    : Icons.task_alt_outlined,
              ),
              tooltip: 'Mark all sub-tasks done',
              onPressed: () {
                if (todo.subtasks.isEmpty) {
                  controller.toggleCompleted(todo.id);
                } else {
                  for (final sub in todo.subtasks) {
                    if (!sub.isDone) {
                      controller.toggleSubtask(todo.id, sub.id);
                    }
                  }
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addSubtask(context),
          icon: const Icon(Icons.add_task),
          label: Text('todo.subtasks.add'.tr),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(todo.title.isEmpty ? 'Untitled task' : todo.title,
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.flag_outlined, size: 18),
                          label: Text(todo.priority.label),
                        ),
                        if (todo.dueDate != null)
                          Chip(
                            avatar: const Icon(Icons.event, size: 18),
                            label: Text(
                                'Due ${_formatDate(todo.dueDate!)}'),
                          ),
                        if (todo.reminderAt != null)
                          Chip(
                            avatar: const Icon(Icons.alarm, size: 18),
                            label: Text(
                                'Reminder ${_formatDate(todo.reminderAt!)}'),
                          ),
                        if (todo.category != null &&
                            todo.category!.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.folder_open, size: 18),
                            label: Text(todo.category!),
                          ),
                      ],
                    ),
                    if (todo.description != null &&
                        todo.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(todo.description!,
                            style: theme.textTheme.bodyMedium),
                      ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: todo.progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${todo.completedSubtasks} of ${todo.totalSubtasks} sub-tasks complete',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sub-tasks',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
                    if (todo.subtasks.isEmpty)
                      Text(
                        'todo.subtasks.empty'.tr,
                        style: theme.textTheme.bodyMedium,
                      )
            else
              ...todo.subtasks.map(
                (sub) => Card(
                  child: CheckboxListTile(
                    value: sub.isDone,
                    title: Text(sub.title.isEmpty ? 'Untitled' : sub.title),
                    onChanged: (_) =>
                        controller.toggleSubtask(todo.id, sub.id),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _addSubtask(BuildContext context) async {
    final textController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('todo.subtasks.add'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'todo.subtasks.hint'.tr,
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('form.cancel'.tr),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(textController.text.trim()),
            child: Text('form.save'.tr),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      controller.addSubtask(todoId, SubTask(title: title));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
