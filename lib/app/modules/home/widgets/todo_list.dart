import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../views/todo_detail_view.dart';

class TodoListView extends StatelessWidget {
  const TodoListView({
    super.key,
    required this.todos,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.emptyTitle = 'empty.title',
    this.emptyDescription = 'empty.desc',
    this.emptyIcon = Icons.check_circle_outline,
    this.isDashboard = false,
  });

  final List<Todo> todos;
  final void Function(String id) onToggle;
  final void Function(String id) onDelete;
  final void Function(Todo todo) onEdit;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;
  final bool isDashboard;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemBuilder: (_, index) {
        final todo = todos[index];
        return TodoCard(
          key: ValueKey('todo_${todo.id}'),
          todo: todo,
          onToggle: () => onToggle(todo.id),
          onDelete: () => onDelete(todo.id),
          onEdit: () => onEdit(todo),
          onOpenDetail: () => Get.to(() => TodoDetailView(todoId: todo.id)),
          isDashboard: isDashboard,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: todos.length,
    );
  }
}

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onOpenDetail,
    this.isDashboard = false,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onOpenDetail;
  final bool isDashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final priorityColor = _priorityColor(theme.colorScheme, todo.priority);

    if (isDashboard && todo.isCompleted) {
      // Show title, priority chip and created date at bottom right with delete option
      final priorityColor = _priorityColor(theme.colorScheme, todo.priority);
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(todo.priority.label),
                          backgroundColor: priorityColor.withAlpha(25),
                          labelStyle: TextStyle(color: priorityColor),
                          side: BorderSide(
                            color: priorityColor.withAlpha(70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_TodoAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _TodoAction.edit:
                          onEdit();
                          break;
                        case _TodoAction.delete:
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _TodoAction.delete,
                        child: Text('Move to bin'),
                      ),
                    ],
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: todo.isCompleted
                      ? const SizedBox.shrink()
                      : Text(
                          todo.updatedAt != null
                              ? 'Updated ${_formatTimestamp(todo.updatedAt!)}'
                              : 'Created ${_formatTimestamp(todo.createdAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onOpenDetail,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => onToggle(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title.isEmpty ? 'Untitled task' : todo.title,
                          style: textTheme.titleMedium?.copyWith(
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (todo.description != null &&
                            todo.description!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              todo.description!,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_TodoAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _TodoAction.edit:
                          onEdit();
                          break;
                        case _TodoAction.delete:
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) {
                      if (!isDashboard && todo.isCompleted) {
                        // On done screen checked todo: only show Move to bin
                        return const [
                          PopupMenuItem(
                            value: _TodoAction.delete,
                            child: Text('Move to bin'),
                          ),
                        ];
                      } else {
                        return const [
                          PopupMenuItem(
                            value: _TodoAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: _TodoAction.delete,
                            child: Text('Move to bin'),
                          ),
                        ];
                      }
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(todo.priority.label),
                      backgroundColor: priorityColor.withValues(alpha: .1),
                      labelStyle: TextStyle(color: priorityColor),
                      side: BorderSide(
                        color: priorityColor.withValues(alpha: .3),
                      ),
                    ),
                    todo.isCompleted
                        ? const SizedBox.shrink()
                        : Text(
                            todo.updatedAt != null
                                ? 'Updated ${_formatTimestamp(todo.updatedAt!)}'
                                : 'Created ${_formatTimestamp(todo.createdAt)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                  ],
                ),
              ),
              _buildProgress(context),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(ColorScheme scheme, TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return scheme.secondary;
      case TodoPriority.medium:
        return scheme.primary;
      case TodoPriority.high:
        return scheme.error;
    }
  }

  Widget _buildProgress(BuildContext context) {
    if (todo.subtasks.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final completed = todo.completedSubtasks;
    final total = todo.totalSubtasks;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: todo.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 4),
          Text(
            '$completed / $total sub-tasks completed',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        container: true,
        label: '$title. $description',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
          Text(
            title.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            description.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          ],
        ),
      ),
    );
  }
}

enum _TodoAction {
  edit,
  delete,
}
