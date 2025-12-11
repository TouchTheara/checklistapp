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
  dueDateSoon,
  manual,
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
      case SortOption.dueDateSoon:
        return 'Due date (Soonest first)';
      case SortOption.manual:
        return 'Custom order';
    }
  }
}

class Todo {
  Todo({
    String? id,
    required this.title,
    this.description,
    this.priority = TodoPriority.medium,
    this.dueDate,
    this.reminderAt,
    this.category,
    List<String>? attachments,
    int? order,
    this.isCompleted = false,
    DateTime? createdAt,
    this.isDeleted = false,
    this.deletedAt,
    this.updatedAt,
    List<SubTask>? subtasks,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        order = order ?? DateTime.now().microsecondsSinceEpoch,
        attachments = List.unmodifiable(attachments ?? const []),
        subtasks = List.unmodifiable(subtasks ?? const []);

  factory Todo.create({
    required String title,
    String? description,
    TodoPriority priority = TodoPriority.medium,
    DateTime? dueDate,
    DateTime? reminderAt,
    String? category,
    List<String>? attachments,
    List<SubTask>? subtasks,
  }) {
    return Todo(
      title: title.trim(),
      description: description?.trim(),
      priority: priority,
      dueDate: dueDate,
      category: category?.trim().isEmpty == true ? null : category?.trim(),
      attachments: attachments,
      subtasks: subtasks,
    );
  }

  final String id;
  final String title;
  final String? description;
  final TodoPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final String? category;
  final List<String> attachments;
  final bool isCompleted;
  final DateTime createdAt;
  final int order;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? updatedAt;
  final List<SubTask> subtasks;

  int get totalSubtasks => subtasks.length;
  int get completedSubtasks => subtasks.where((sub) => sub.isDone).length;
  double get progress => totalSubtasks == 0
      ? (isCompleted ? 1 : 0)
      : completedSubtasks / totalSubtasks;

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    TodoPriority? priority,
    DateTime? dueDate,
    DateTime? reminderAt,
    String? category,
    List<String>? attachments,
    int? order,
    bool? isCompleted,
    DateTime? createdAt,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
    List<SubTask>? subtasks,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  int comparePriorityTo(Todo other) => priority.weight - other.priority.weight;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'category': category,
      'attachments': attachments,
      'order': order,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'subtasks': subtasks.map((sub) => sub.toJson()).toList(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    final subtasks = (json['subtasks'] as List?)
            ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final isCompleted = (json['isCompleted'] as bool? ?? false) ||
        (subtasks.isNotEmpty && subtasks.every((s) => s.isDone));
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      category: json['category'] as String?,
      attachments:
          (json['attachments'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      order: json['order'] as int?,
      reminderAt: json['reminderAt'] != null
          ? DateTime.tryParse(json['reminderAt'] as String)
          : null,
      isCompleted: isCompleted,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      subtasks: subtasks,
    );
  }
}

class SubTask {
  SubTask({
    String? id,
    required this.title,
    this.isDone = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String title;
  final bool isDone;

  SubTask copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}
