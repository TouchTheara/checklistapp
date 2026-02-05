import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/notifications_controller.dart';
import 'notification_detail_view.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

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
    final repo = Get.find<TodoRepository>();
    return Scaffold(
        appBar: AppBar(
          title: Text('notifications.title'.tr),
          actions: [
            IconButton(
              tooltip: 'notifications.markAll'.tr,
              onPressed: controller.markAllRead,
              icon: const Icon(Icons.mark_email_read_outlined),
            ),
          ],
        ),
        body: controller.notifications.isEmpty
            ? GetBuilder(
                init: controller,
                builder: (_) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              'notifications.empty.title'.tr,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: theme.colorScheme.outline),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'notifications.empty.desc'.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                })
            : SmartRefresher(
                controller: controller.refreshController,
                enablePullDown: true,
                enablePullUp: controller.hasMore,
                onRefresh: controller.onRefresh,
                onLoading: controller.onLoading,
                child: ListView.separated(
                  itemCount: controller.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final n = controller.notifications[index];
                    final todo = n.todoId == null
                        ? null
                        : repo.rawTodos
                            .firstWhereOrNull((t) => t.id == n.todoId);
                    final subtitle = () {
                      if (todo == null) return n.body;
                      final member = todo.members.firstWhereOrNull(
                          (m) => m.userId == Get.find<AuthService>().userId);
                      if (member == null) return todo.title;
                      switch (member.status) {
                        case InviteStatus.pending:
                          return '${todo.title} • Pending invite';
                        case InviteStatus.accepted:
                          return todo.title;
                        case InviteStatus.cancelled:
                          return '${todo.title} • Cancelled';
                      }
                    }();
                    return ListTile(
                      leading: Icon(
                        _iconFor(n.type),
                        color: n.read
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                      ),
                      title: Text(
                        n.title,
                        style: n.read
                            ? theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.outline)
                            : theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(subtitle),
                      trailing: n.read
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.done_all),
                              onPressed: () => controller.markRead(n.id),
                            ),
                      onTap: () {
                        controller.markRead(n.id);
                        Get.to(() => NotificationDetailView(notification: n));
                      },
                    );
                  },
                ),
              ));
  }
}
