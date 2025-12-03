import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class BinController extends GetxController {
  BinController(this._repository);

  final TodoRepository _repository;

  List<Todo> get binTodos => _repository.sortedBin;
  bool get hasBinItems => _repository.hasBinItems;

  void restoreTodo(String id) => _repository.restoreTodo(id);
  void deleteForever(String id) => _repository.deleteForever(id);
  void emptyBin() => _repository.emptyBin();
}
