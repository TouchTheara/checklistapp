import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AppNotificationType {
  general,
  taskInvite,
  subtaskCompleted,
  taskCompleted,
  reminderDue,
}

class AppNotification {
  AppNotification({
    String? id,
    required this.title,
    required this.body,
    required this.type,
    this.todoId,
    DateTime? createdAt,
    this.read = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? todoId;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    AppNotificationType? type,
    String? todoId,
    DateTime? createdAt,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      todoId: todoId ?? this.todoId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'todoId': todoId,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AppNotificationType.general,
      ),
      todoId: json['todoId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }
}
