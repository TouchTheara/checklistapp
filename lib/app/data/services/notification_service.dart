import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../models/app_notification.dart';
import '../models/todo.dart';

class NotificationPage {
  NotificationPage(
      {required this.items, required this.lastDoc, required this.hasMore});
  final List<AppNotification> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
}

class NotificationService extends GetxService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  String? _userId;
  bool _timezoneInitialized = false;

  Future<NotificationService> init() async {
    await _configureLocal();
    tz.initializeTimeZones();
    _timezoneInitialized = true;
    await _messaging.setAutoInitEnabled(true);
    await _requestPermissions();
    _messaging.onTokenRefresh.listen((token) {
      final uid = _userId;
      if (uid != null) {
        _saveFcmToken(uid, providedToken: token);
      }
    });
    return this;
  }

  Future<bool> _ensureExactAlarmPermission() async {
    final androidImpl = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    // Fall back to notification permission; plugin version may not expose exact alarm checks.
    final allowed = await androidImpl.areNotificationsEnabled() ?? true;
    return allowed;
  }

  Future<void> onLogin(String? userId) async {
    _userId = userId;
    if (_userId != null) {
      await _saveFcmToken(_userId!);
    }
  }

  Future<void> onLogout() async {
    String? token;
    try {
      token = await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code != 'apns-token-not-set') {
        rethrow;
      }
      // Ignore missing APNs token on simulators / before registration.
    }
    if (token != null && _userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tokens')
          .doc(token)
          .delete()
          .catchError((_) {});
    }
    _userId = null;
    await _local.cancelAll();
  }

  Stream<List<AppNotification>> stream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromJson(d.data()))
              .toList(),
        );
  }

  Future<NotificationPage> fetchPage(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final items = snap.docs.map((d) => AppNotification.fromJson(d.data())).toList();
    final last = snap.docs.isNotEmpty ? snap.docs.last : null;
    final hasMore = snap.docs.length == limit;
    return NotificationPage(items: items, lastDoc: last, hasMore: hasMore);
  }

  Future<void> addNotification({
    required String userId,
    required AppNotification notification,
    bool alsoLocal = false,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id);
    await ref.set(notification.toJson());
    if (alsoLocal && userId == _auth.currentUser?.uid) {
      await _showLocal(notification);
    }
  }

  Future<void> markAllRead(String userId) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> markRead(String userId, String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(id)
        .update({'read': true}).catchError((_) {});
  }

  Future<void> notifyInvite({
    required String inviterName,
    required TaskMember member,
    required Todo todo,
  }) async {
    if (member.userId == null) return;
    final n = AppNotification(
      title: 'Task invite',
      body: '$inviterName invited you to "${todo.title}".',
      type: AppNotificationType.taskInvite,
      todoId: todo.id,
    );
    await addNotification(userId: member.userId!, notification: n);
  }

  Future<void> notifySubtaskCompleted({
    required Todo todo,
    required SubTask subtask,
  }) async {
    final targets = todo.members.where((m) => m.userId != null).toList();
    if (targets.isEmpty) return;
    final n = AppNotification(
      title: 'Sub-task completed',
      body: '"${subtask.title.isEmpty ? 'Sub-task' : subtask.title}" completed in "${todo.title}".',
      type: AppNotificationType.subtaskCompleted,
      todoId: todo.id,
    );
    for (final member in targets) {
      await addNotification(userId: member.userId!, notification: n);
    }
  }

  Future<void> notifyAssignment({
    required TaskMember member,
    required Todo todo,
  }) async {
    if (member.userId == null) return;
    final n = AppNotification(
      title: 'Assigned to a task',
      body: 'You were assigned "${todo.title}".',
      type: AppNotificationType.taskInvite,
      todoId: todo.id,
    );
    await addNotification(userId: member.userId!, notification: n);
  }

  Future<void> notifyTaskCompleted(Todo todo) async {
    final targets = todo.members.where((m) => m.userId != null).toList();
    if (targets.isEmpty) return;
    final n = AppNotification(
      title: 'Task completed',
      body: '"${todo.title}" is now complete.',
      type: AppNotificationType.taskCompleted,
      todoId: todo.id,
    );
    for (final member in targets) {
      await addNotification(userId: member.userId!, notification: n);
    }
  }

  Future<void> scheduleReminder(Todo todo) async {
    if (todo.reminderAt == null) return;
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }
    if (!kIsWeb && Platform.isAndroid) {
      final allowed = await _ensureExactAlarmPermission();
      if (!allowed) return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime.from(todo.reminderAt!, tz.local);
    if (!when.isAfter(now)) {
      // Do not schedule reminders in the past or now.
      return;
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Task reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _local.zonedSchedule(
        todo.id.hashCode,
        todo.title,
        'Reminder: ${todo.title}',
        when,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: todo.id,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // On Android 12+ without exact alarm permission: skip scheduling.
        return;
      }
      rethrow;
    }
    if (_userId != null) {
      final n = AppNotification(
        title: 'Reminder set',
        body: 'Reminder scheduled for "${todo.title}".',
        type: AppNotificationType.reminderDue,
        todoId: todo.id,
      );
      await addNotification(
        userId: _userId!,
        notification: n,
        alsoLocal: false,
      );
    }
  }

  Future<void> _configureLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(initSettings);
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );
    } catch (_) {
      // ignore permission errors; service can still operate with limited capability.
    }
  }

  Future<void> _saveFcmToken(String userId, {String? providedToken}) async {
    String? token = providedToken;
    try {
      token ??= await _messaging.getToken();
    } on FirebaseException catch (e) {
      // On iOS simulators or before APNs is ready, this can throw.
      if (e.code == 'apns-token-not-set') return;
      rethrow;
    }
    if (token == null) return;
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('tokens')
        .doc(token);
    await ref.set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showLocal(AppNotification notification) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'in_app',
        'In-app',
        channelDescription: 'Foreground notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _local.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.todoId,
    );
  }
}
