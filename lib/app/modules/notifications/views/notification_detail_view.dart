import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/notifications_controller.dart';

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
        member =
            todo.members.firstWhereOrNull((m) => m.userId == auth.userId);
      }
    }

    if (todo == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('notifications.title'.tr),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 72, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'notifications.empty.detail'.tr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              if (notification.todoId != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    controller.markRead(notification.id);
                    Get.toNamed('/todo', arguments: notification.todoId);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text('notifications.openTask'.tr),
                ),
              ],
            ],
          ),
        ),
      );
    }

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
              'notifications.task'.trParams({'title': todo!.title}),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (notification.type == AppNotificationType.taskInvite &&
                todo != null &&
                member != null)
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      repo.updateMemberStatus(
                          todo!.id, member!.userId!, InviteStatus.cancelled);
                      controller.markRead(notification.id);
                    },
                    child: Text('notifications.decline'.tr),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      repo.updateMemberStatus(
                          todo!.id, member!.userId!, InviteStatus.accepted);
                      controller.markRead(notification.id);
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
