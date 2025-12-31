import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
          body: const Center(child: Text('Task not found')),
        );
      }
      final theme = Theme.of(context);
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addSubtask(context),
          icon: const Icon(Icons.add_task),
          label: Text('todo.subtasks.add'.tr),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeaderImage(
              title: todo.title.isEmpty ? 'Untitled task' : todo.title,
              imageUrl: todo.attachments.isNotEmpty ? todo.attachments.first : null,
              completed: todo.completedSubtasks == todo.totalSubtasks &&
                  todo.totalSubtasks > 0,
              onBack: () => Get.back(),
              onToggleAll: () {
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          label: Text('Due ${_formatDate(todo.dueDate!)}'),
                        ),
                      if (todo.reminderAt != null)
                        Chip(
                          avatar: const Icon(Icons.alarm, size: 18),
                          label: Text('Reminder ${_formatDate(todo.reminderAt!)}'),
                        ),
                      if (todo.category != null && todo.category!.isNotEmpty)
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
                      child: Text(
                        todo.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: todo.progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'todo.subtasks.progress'.trParams({
                      'done': '${todo.completedSubtasks}',
                      'total': '${todo.totalSubtasks}',
                    }),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
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
                        child: ListTile(
                          title: Text(sub.title.isEmpty ? 'Untitled' : sub.title),
                          trailing: Checkbox(
                            value: sub.isDone,
                            shape: const CircleBorder(),
                            onChanged: (_) =>
                                controller.toggleSubtask(todo.id, sub.id),
                          ),
                          onTap: () =>
                              controller.toggleSubtask(todo.id, sub.id),
                        ),
                      ),
                    ),
                ],
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

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({
    required this.title,
    required this.imageUrl,
    required this.completed,
    required this.onBack,
    required this.onToggleAll,
  });

  final String title;
  final String? imageUrl;
  final bool completed;
  final VoidCallback onBack;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest),
              errorWidget: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: Icon(
                        completed
                            ? Icons.check_circle
                            : Icons.task_alt_outlined,
                        color: Colors.white,
                      ),
                      tooltip: 'Mark all sub-tasks done',
                      onPressed: onToggleAll,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
