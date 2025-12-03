import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../data/services/storage_service.dart';

class HomeController extends GetxController {
  HomeController({
    TodoRepository? repository,
    StorageService? storageService,
    List<Todo>? seed,
  }) : _repository = repository ??
            (Get.isRegistered<TodoRepository>()
                ? Get.find<TodoRepository>()
                : TodoRepository(storageService: storageService, seed: seed));

  final TodoRepository _repository;
  final RxInt _tabIndex = 0.obs;

  int get tabIndex => _tabIndex.value;
  List<Todo> get todos => _repository.rawTodos;
  List<Todo> get doneTodos => _repository.sortedDone;
  List<Todo> get binTodos => _repository.sortedBin;
  SortOption get sortOption => _repository.sortOption;
  bool get hasBinItems => _repository.hasBinItems;
  int get totalCount => _repository.totalCount;
  int get completedCount => _repository.completedCount;
  double get completionRate => _repository.completionRate;
  Map<TodoPriority, int> get priorityBreakdown =>
      _repository.priorityBreakdown;

  void changeTab(int index) {
    if (index == _tabIndex.value) return;
    _tabIndex.value = index;
  }

  void addTodo(Todo todo) => _repository.addTodo(todo);
  void updateTodo(Todo todo) => _repository.updateTodo(todo);
  void deleteTodo(String id) => _repository.deleteTodo(id);
  void restoreTodo(String id) => _repository.restoreTodo(id);
  void emptyBin() => _repository.emptyBin();
  void deleteForever(String id) => _repository.deleteForever(id);
  void toggleCompleted(String id) => _repository.toggleCompleted(id);
  void changeSort(SortOption option) => _repository.changeSort(option);
  void addSubtask(String todoId, SubTask subtask) =>
      _repository.addSubtask(todoId, subtask);
  void toggleSubtask(String todoId, String subtaskId) =>
      _repository.toggleSubtask(todoId, subtaskId);
}
