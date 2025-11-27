import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TodoPriority { low, medium, high }

extension TodoPriorityX on TodoPriority {
  String get label {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  int get weight {
    switch (this) {
      case TodoPriority.low:
        return 0;
      case TodoPriority.medium:
        return 1;
      case TodoPriority.high:
        return 2;
    }
  }
}

enum SortOption {
  priorityHighFirst,
  priorityLowFirst,
  alphabetical,
  recentlyAdded,
}

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.priorityHighFirst:
        return 'Priority (High → Low)';
      case SortOption.priorityLowFirst:
        return 'Priority (Low → High)';
      case SortOption.alphabetical:
        return 'Alphabetical';
      case SortOption.recentlyAdded:
        return 'Recently Added';
    }
  }
}

class Todo {
  Todo({
    String? id,
    required this.title,
    this.description,
    this.priority = TodoPriority.medium,
    this.isCompleted = false,
    DateTime? createdAt,
    this.isDeleted = false,
    DateTime? deletedAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        deletedAt = deletedAt,
        updatedAt = updatedAt;

  factory Todo.create({
    required String title,
    String? description,
    TodoPriority priority = TodoPriority.medium,
  }) {
    return Todo(
      title: title.trim(),
      description: description?.trim(),
      priority: priority,
    );
  }

  final String id;
  final String title;
  final String? description;
  final TodoPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? updatedAt;

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    TodoPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int comparePriorityTo(Todo other) => priority.weight - other.priority.weight;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
    );
  }
}
