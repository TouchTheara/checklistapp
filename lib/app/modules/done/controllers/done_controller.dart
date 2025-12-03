import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class DoneController extends GetxController {
  DoneController(this._repository);

  final TodoRepository _repository;

  List<Todo> get doneTodos => _repository.sortedDone;

  void deleteTodo(String id) => _repository.deleteTodo(id);
  void toggleCompleted(String id) => _repository.toggleCompleted(id);
  void updateTodo(Todo todo) => _repository.updateTodo(todo);
}
