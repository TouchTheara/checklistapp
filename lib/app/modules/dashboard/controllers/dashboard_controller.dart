import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository);

  final TodoRepository _repository;

  List<Todo> get todos => _repository.sortedActive;
  SortOption get sortOption => _repository.sortOption;
  int get totalCount => _repository.totalCount;
  int get completedCount => _repository.completedCount;
  double get completionRate => _repository.completionRate;
  Map<TodoPriority, int> get priorityBreakdown => _repository.priorityBreakdown;

  void addTodo(Todo todo) => _repository.addTodo(todo);
  void updateTodo(Todo todo) => _repository.updateTodo(todo);
  void deleteTodo(String id) => _repository.deleteTodo(id);
  void toggleCompleted(String id) => _repository.toggleCompleted(id);
  void changeSort(SortOption option) => _repository.changeSort(option);
}
