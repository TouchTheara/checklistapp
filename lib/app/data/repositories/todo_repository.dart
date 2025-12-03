import 'package:get/get.dart';

import '../models/todo.dart';
import '../services/storage_service.dart';

class TodoRepository extends GetxService {
  TodoRepository({StorageService? storageService, List<Todo>? seed})
      : _storageService = storageService ?? StorageService(),
        _todos = RxList<Todo>(seed ?? _defaultSeed);

  final StorageService _storageService;
  final RxList<Todo> _todos;
  final Rx<SortOption> _sortOption = SortOption.priorityHighFirst.obs;

  RxList<Todo> get rawTodos => _todos;

  static final _defaultSeed = <Todo>[];

  Future<TodoRepository> init() async {
    await loadForUser(null);
    return this;
  }

  Future<void> loadForUser(String? userId) async {
    _storageService.setUser(userId);
    final hasData = await _storageService.hasSavedData();
    if (hasData) {
      final savedTodos = await _storageService.loadTodos();
      _todos.assignAll(_normalized(savedTodos));
    } else {
      _todos.assignAll(_defaultSeed);
      await _saveTodos();
    }

    final savedSortOption = await _storageService.loadSortOption();
    if (savedSortOption != null) {
      _sortOption.value = savedSortOption;
    }
    _todos.refresh();
  }

  SortOption get sortOption => _sortOption.value;
  bool get hasBinItems => _todos.any((todo) => todo.isDeleted);
  StorageService get storageService => _storageService;

  int get totalCount => _activeTodos.length;
  int get completedCount =>
      _activeTodos.where((item) => item.isCompleted).length;
  double get completionRate =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  Map<TodoPriority, int> get priorityBreakdown => {
        for (final priority in TodoPriority.values)
          priority:
              _activeTodos.where((todo) => todo.priority == priority).length,
      };

  List<Todo> get sortedActive {
    final sorted = [..._activeTodos];
    sorted.sort((a, b) {
      switch (_sortOption.value) {
        case SortOption.priorityHighFirst:
          final priorityCompare = b.priority.weight.compareTo(a.priority.weight);
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.priorityLowFirst:
          final priorityCompare = a.priority.weight.compareTo(b.priority.weight);
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.recentlyAdded:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return sorted;
  }

  List<Todo> get sortedDone {
    final done = _activeTodos.where((todo) => todo.isCompleted).toList();
    done.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return done;
  }

  List<Todo> get sortedBin {
    final sorted = _todos.where((todo) => todo.isDeleted).toList();
    sorted.sort((a, b) {
      final aDate = a.deletedAt ?? a.createdAt;
      final bDate = b.deletedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  void addTodo(Todo todo) {
    _todos.add(todo.copyWith(isDeleted: false, deletedAt: null));
    _saveTodos();
  }

  void updateTodo(Todo todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = todo.copyWith(
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: current.isDeleted,
      deletedAt: current.deletedAt,
      isCompleted: current.isCompleted,
    );
    _todos.refresh();
    _saveTodos();
  }

  void deleteTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
  }

  void restoreTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(isDeleted: false, deletedAt: null);
    _todos.refresh();
    _saveTodos();
  }

  void emptyBin() {
    _todos.removeWhere((todo) => todo.isDeleted);
    _todos.refresh();
    _saveTodos();
  }

  void deleteForever(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    _todos.refresh();
    _saveTodos();
  }

  void toggleCompleted(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    if (current.isDeleted) return;
    _todos[index] = current.copyWith(isCompleted: !current.isCompleted);
    _todos.refresh();
    _saveTodos();
  }

  void addSubtask(String todoId, SubTask subtask) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final updatedSubtasks = [...current.subtasks, subtask];
    _todos[index] = current.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
      isCompleted: updatedSubtasks.every((s) => s.isDone),
    );
    _todos.refresh();
    _saveTodos();
  }

  void toggleSubtask(String todoId, String subtaskId) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final updatedSubtasks = current.subtasks
        .map(
          (s) => s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s,
        )
        .toList();
    _todos[index] = current.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: updatedSubtasks.isNotEmpty &&
          updatedSubtasks.every((s) => s.isDone),
      updatedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
  }

  void changeSort(SortOption option) {
    if (_sortOption.value == option) return;
    _sortOption.value = option;
    _todos.refresh();
    _saveSortOption();
  }

  List<Todo> _normalized(List<Todo> todos) {
    return todos
        .map(
          (todo) => todo.copyWith(
            isCompleted: todo.isCompleted ||
                (todo.subtasks.isNotEmpty &&
                    todo.subtasks.every((sub) => sub.isDone)),
          ),
        )
        .toList();
  }

  List<Todo> get _activeTodos =>
      _todos.where((todo) => !todo.isDeleted).toList();

  Future<void> _saveTodos() async {
    await _storageService.saveTodos(_todos.toList());
  }

  Future<void> _saveSortOption() async {
    await _storageService.saveSortOption(_sortOption.value);
  }
}
