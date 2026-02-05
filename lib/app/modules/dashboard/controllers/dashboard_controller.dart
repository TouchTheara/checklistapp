import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository);

  final TodoRepository _repository;
  final RxString _search = ''.obs;
  final Rx<TodoPriority?> _priorityFilter = Rx<TodoPriority?>(null);
  final RxString _categoryFilter = ''.obs;
  final RxBool _urgentOnly = false.obs;
  final RxBool _isLoading = false.obs;
  static const _pageSize = 10;
  final RxInt _page = 1.obs;
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  List<Todo> get todos {
    final list = _repository.sortedActive;
    final filtered = list.where((todo) {
      if (_urgentOnly.value &&
          !((todo.priority == TodoPriority.high) ||
              (todo.dueDate != null &&
                  todo.dueDate!.isBefore(DateTime.now().add(const Duration(days: 2)))))) {
        return false;
      }
      final search = _search.value.toLowerCase();
      if (search.isNotEmpty &&
          !('${todo.title} ${todo.description ?? ''}'
                  .toLowerCase()
                  .contains(search))) {
        return false;
      }
      final priority = _priorityFilter.value;
      if (priority != null && todo.priority != priority) return false;
      final category = _categoryFilter.value.trim();
      if (category.isNotEmpty &&
          (todo.category ?? '').toLowerCase() != category.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
    return filtered;
  }

  List<Todo> get pagedTodos {
    final list = todos;
    final end = (_page.value * _pageSize).clamp(0, list.length);
    return list.take(end).toList();
  }

  SortOption get sortOption => _repository.sortOption;
  int get totalCount => _repository.totalCount;
  int get completedCount => _repository.completedCount;
  double get completionRate => _repository.completionRate;
  Map<TodoPriority, int> get priorityBreakdown => _repository.priorityBreakdown;
  List<String> get categories => _repository.rawTodos
      .map((t) => t.category)
      .whereType<String>()
      .where((c) => c.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  void addTodo(Todo todo) => _repository.addTodo(todo);
  void updateTodo(Todo todo) => _repository.updateTodo(todo);
  void deleteTodo(String id) => _repository.deleteTodo(id);
  void toggleCompleted(String id) => _repository.toggleCompleted(id);
  void changeSort(SortOption option) => _repository.changeSort(option);

  void updateSearch(String value) => _search.value = value;
  void updatePriorityFilter(TodoPriority? priority) =>
      _priorityFilter.value = priority;
  void updateCategoryFilter(String? category) =>
      _categoryFilter.value = category ?? '';
  void toggleUrgentOnly() => _urgentOnly.value = !_urgentOnly.value;
  bool get urgentOnly => _urgentOnly.value;
  bool get isLoading => _isLoading.value;
  bool get hasMore => _page.value * _pageSize < todos.length;

  void reorder(int oldIndex, int newIndex) =>
      _repository.moveTodo(oldIndex, newIndex);

  Todo addSmartTask(String input) {
    final parsed = _parseSmartInput(input);
    _repository.addTodo(parsed);
    return parsed;
  }

  Todo _parseSmartInput(String input) {
    final lower = input.toLowerCase();
    TodoPriority priority = TodoPriority.medium;
    if (lower.contains('urgent') || lower.contains('high')) {
      priority = TodoPriority.high;
    } else if (lower.contains('low')) {
      priority = TodoPriority.low;
    }

    DateTime? dueDate;
    if (lower.contains('today')) {
      final now = DateTime.now();
      dueDate = DateTime(now.year, now.month, now.day);
    } else if (lower.contains('tomorrow')) {
      final now = DateTime.now().add(const Duration(days: 1));
      dueDate = DateTime(now.year, now.month, now.day);
    } else if (lower.contains('next week')) {
      final now = DateTime.now().add(const Duration(days: 7));
      dueDate = DateTime(now.year, now.month, now.day);
    }

    String? category;
    if (lower.contains('work')) category = 'Work';
    if (lower.contains('home') || lower.contains('personal')) {
      category = 'Personal';
    }
    if (lower.contains('safety')) category = 'Safety';

    final cleaned = input.trim();
    return Todo.create(
      title: cleaned.isEmpty ? 'New task' : cleaned,
      priority: priority,
      dueDate: dueDate,
      category: category,
    );
  }

  @override
  Future<void> refresh() async {
    _isLoading.value = true;
    try {
      _page.value = 1;
      await _repository.reloadFromSource();
      refreshController.resetNoData();
      refreshController.refreshCompleted();
    } finally {
      _isLoading.value = false;
    }
  }

  void loadMore() {
    if (hasMore) {
      _page.value += 1;
      refreshController.loadComplete();
    } else {
      refreshController.loadNoData();
    }
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }
}
