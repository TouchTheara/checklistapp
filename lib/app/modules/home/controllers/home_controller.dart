import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/services/storage_service.dart';

class HomeController extends GetxController {
  HomeController({StorageService? storageService, List<Todo>? seed})
      : _storageService = storageService ?? StorageService(),
        _todos = RxList<Todo>(seed ?? _defaultSeed);

  static final _defaultSeed = [
    Todo(
      title: 'Prep project scope',
      description: 'Review backlog and outline sprint goals.',
      priority: TodoPriority.high,
    ),
    Todo(
      title: 'Deep work block',
      description: 'Focus for two hours on blockers.',
      priority: TodoPriority.medium,
    ),
    Todo(
      title: 'Walk outside',
      description: 'Short break to reset energy.',
      priority: TodoPriority.low,
    ),
  ];

  final StorageService _storageService;
  final RxList<Todo> _todos;
  final Rx<SortOption> _sortOption = SortOption.priorityHighFirst.obs;
  final RxInt _tabIndex = 0.obs;

  List<Todo> get todos => List.unmodifiable(_sortedActive);
  List<Todo> get doneTodos => List.unmodifiable(_sortedDone);
  List<Todo> get binTodos => List.unmodifiable(_sortedBin);
  SortOption get sortOption => _sortOption.value;
  bool get hasBinItems => _todos.any((todo) => todo.isDeleted);
  int get tabIndex => _tabIndex.value;

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

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    final hasData = await _storageService.hasSavedData();
    if (hasData) {
      final savedTodos = await _storageService.loadTodos();
      _todos.assignAll(savedTodos);
    } else {
      _todos.assignAll(_defaultSeed);
      await _saveTodos();
    }

    final savedSortOption = await _storageService.loadSortOption();
    if (savedSortOption != null) {
      _sortOption.value = savedSortOption;
    }
  }

  Future<void> _saveTodos() async {
    await _storageService.saveTodos(_todos.toList());
  }

  Future<void> _saveSortOption() async {
    await _storageService.saveSortOption(_sortOption.value);
  }

  void addTodo(Todo todo) {
    _todos.add(
      todo.copyWith(isDeleted: false, deletedAt: null),
    );
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

  void changeSort(SortOption option) {
    if (_sortOption.value == option) return;
    _sortOption.value = option;
    _todos.refresh();
    _saveSortOption();
  }

  void changeTab(int index) {
    if (index == _tabIndex.value) return;
    _tabIndex.value = index;
  }

  List<Todo> get _activeTodos =>
      _todos.where((todo) => !todo.isDeleted).toList();

  List<Todo> get _sortedActive {
    final sorted = [..._activeTodos];
    sorted.sort((a, b) {
      switch (_sortOption.value) {
        case SortOption.priorityHighFirst:
          final priorityCompare =
              b.priority.weight.compareTo(a.priority.weight);
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.priorityLowFirst:
          final priorityCompare =
              a.priority.weight.compareTo(b.priority.weight);
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

  List<Todo> get _sortedDone {
    final done = _activeTodos.where((todo) => todo.isCompleted).toList();
    done.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return done;
  }

  List<Todo> get _sortedBin {
    final sorted = _todos.where((todo) => todo.isDeleted).toList();
    sorted.sort((a, b) {
      final aDate = a.deletedAt ?? a.createdAt;
      final bDate = b.deletedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }
}
