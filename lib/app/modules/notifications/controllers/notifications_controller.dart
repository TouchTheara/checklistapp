import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';

class NotificationsController extends GetxController {
  final _notificationService = Get.find<NotificationService>();
  final _authService = Get.find<AuthService>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  StreamSubscription<List<AppNotification>>? _sub;

  int get unreadCount =>
      notifications.where((n) => n.read == false).length.clamp(0, 999);

  @override
  void onInit() {
    super.onInit();
    _bindStream();
  }

  void _bindStream() {
    _sub?.cancel();
    final uid = _authService.userId;
    if (uid == null) return;
    _sub = _notificationService.stream(uid).listen((data) {
      notifications.assignAll(data);
    });
  }

  Future<void> markAllRead() async {
    final uid = _authService.userId;
    if (uid == null) return;
    await _notificationService.markAllRead(uid);
  }

  Future<void> markRead(String id) async {
    final uid = _authService.userId;
    if (uid == null) return;
    await _notificationService.markRead(uid, id);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
