import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/notifications_controller.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class NotificationDetailView extends StatelessWidget {
  const NotificationDetailView({super.key, required this.notification});

  final AppNotification notification;

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.general:
        return Icons.notifications_none;
      case AppNotificationType.taskInvite:
        return Icons.person_add_alt;
      case AppNotificationType.subtaskCompleted:
        return Icons.check_circle_outline;
      case AppNotificationType.taskCompleted:
        return Icons.verified;
      case AppNotificationType.reminderDue:
        return Icons.alarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<NotificationsController>();
    final repo = Get.find<TodoRepository>();
    final auth = Get.find<AuthService>();

    Todo? todo;
    TaskMember? member;
    if (notification.todoId != null) {
      todo = repo.rawTodos.firstWhereOrNull((t) => t.id == notification.todoId);
      if (todo != null && auth.userId != null) {
        member = todo.members.firstWhereOrNull((m) => m.userId == auth.userId);
      }
    }

    // Build a lightweight fallback task if not yet loaded so user can respond.
    final effectiveTodo = todo ??
        Todo(
          id: notification.todoId ?? _uuid.v4(),
          title: notification.title.isNotEmpty
              ? notification.title
              : (notification.body.isNotEmpty
                  ? notification.body
                  : 'notifications.task'.trParams({'title': ''})),
          members: auth.userId == null
              ? const []
              : [
                  TaskMember(
                    userId: auth.userId,
                    name: auth.name ?? '',
                    email: auth.email ?? '',
                    status: InviteStatus.pending,
                  )
                ],
        );
    member ??=
        effectiveTodo.members.firstWhereOrNull((m) => m.userId == auth.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr),
        actions: [
          TextButton(
            onPressed: () => controller.markRead(notification.id),
            child: Text('notifications.markRead'.tr),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    _iconFor(notification.type),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.body,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'notifications.task'.trParams({'title': effectiveTodo.title}),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (member != null) ...[
              const SizedBox(height: 8),
              Text(
                'Status: ${member.status.label}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
            const SizedBox(height: 16),
            if (notification.type == AppNotificationType.taskInvite &&
                notification.todoId != null &&
                (member == null || member.status == InviteStatus.pending))
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final uid = member?.userId ?? auth.userId ?? '';
                      if (uid.isEmpty) return;
                      repo.updateMemberStatus(
                          effectiveTodo.id, uid, InviteStatus.cancelled);
                      controller.markRead(notification.id);
                    },
                    child: Text('notifications.decline'.tr),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final uid = member?.userId ?? auth.userId ?? '';
                      if (uid.isEmpty) return;
                      repo.updateMemberStatus(
                          effectiveTodo.id, uid, InviteStatus.accepted);
                      controller.markRead(notification.id);
                      if (!repo.rawTodos.any((t) => t.id == effectiveTodo.id)) {
                        repo.addTodo(effectiveTodo.copyWith());
                      }
                    },
                    child: Text('notifications.accept'.tr),
                  ),
                ],
              ),
            if (notification.todoId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () {
                    controller.markRead(notification.id);
                    Get.toNamed('/todo', arguments: notification.todoId);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text('notifications.openTask'.tr),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
