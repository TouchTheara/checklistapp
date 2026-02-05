import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class NotificationsController extends GetxController {
  final _notificationService = Get.find<NotificationService>();
  final _authService = Get.find<AuthService>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);
  StreamSubscription<List<AppNotification>>? _sub;
  static const _pageSize = 10;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loading = false;

  bool get hasMore => _hasMore;
  bool get isLoading => _loading;

  int get unreadCount =>
      notifications.where((n) => n.read == false).length.clamp(0, 999);

  @override
  void onInit() {
    super.onInit();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    _sub?.cancel();
    final uid = _authService.userId;
    if (uid == null) return;
    notifications.clear();
    _lastDoc = null;
    _hasMore = true;
    _loading = true;
    update();
    final page = await _notificationService.fetchPage(uid, limit: _pageSize);
    notifications.assignAll(page.items);
    _lastDoc = page.lastDoc;
    _hasMore = page.hasMore;
    _loading = false;
    refreshController.refreshCompleted();
    update();
  }

  Future<void> onRefresh() async {
    await _loadInitial();
  }

  Future<void> reloadForCurrentUser() async {
    await _loadInitial();
  }

  void clearForLogout() {
    _sub?.cancel();
    notifications.clear();
    _lastDoc = null;
    _hasMore = true;
    _loading = false;
    refreshController.refreshCompleted();
    refreshController.loadComplete();
    refreshController.resetNoData();
    update();
  }

  Future<void> onLoading() async {
    final uid = _authService.userId;
    if (!_hasMore || uid == null || _loading) {
      refreshController.loadComplete();
      return;
    }
    _loading = true;
    update();
    final page = await _notificationService.fetchPage(
      uid,
      limit: _pageSize,
      startAfter: _lastDoc,
    );
    notifications.addAll(page.items);
    _lastDoc = page.lastDoc;
    _hasMore = page.hasMore;
    _loading = false;
    refreshController.loadComplete();
    update();
  }

  Future<void> markAllRead() async {
    final uid = _authService.userId;
    if (uid == null) return;
    // Optimistically update local list so UI/badge react immediately.
    notifications.assignAll(
      notifications
          .map((n) => n.read ? n : n.copyWith(read: true))
          .toList(growable: false),
    );
    update(); // refresh GetBuilder consumers
    await _notificationService.markAllRead(uid);
  }

  Future<void> markRead(String id) async {
    final uid = _authService.userId;
    if (uid == null) return;
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && notifications[idx].read == false) {
      notifications[idx] = notifications[idx].copyWith(read: true);
      update();
    }
    await _notificationService.markRead(uid, id);
  }

  @override
  void onClose() {
    _sub?.cancel();
    refreshController.dispose();
    super.onClose();
  }
}
