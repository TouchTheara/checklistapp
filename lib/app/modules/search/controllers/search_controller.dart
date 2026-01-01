import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../routes/app_routes.dart';

class AppSearchController extends GetxController {
  final TodoRepository _repo = Get.find<TodoRepository>();

  final RxString query = ''.obs;
  final RxString appliedQuery = ''.obs;
  final RxInt tabIndex = 0.obs; // 0: active, 1: completed, 2: bin
  final RxBool isSearching = false.obs;
  Timer? _debounce;

  void updateQuery(String value) {
    _debounce?.cancel();
    isSearching.value = true;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      query.value = value.trim();
      appliedQuery.value = value.trim();
      isSearching.value = false;
    });
  }

  void changeTab(int index) {
    tabIndex.value = index;
  }

  List<Todo> get _todos => _repo.rawTodos;

  List<Todo> _filter(List<Todo> source) {
    final q = appliedQuery.value.toLowerCase();
    if (q.isEmpty) return source;
    return source.where((t) {
      final title = t.title.toLowerCase();
      return title.contains(q);
    }).toList();
  }

  List<Todo> get activeResults =>
      _filter(_todos.where((t) => !t.isDeleted && !t.isCompleted).toList());
  List<Todo> get doneResults =>
      _filter(_todos.where((t) => !t.isDeleted && t.isCompleted).toList());
  List<Todo> get binResults =>
      _filter(_todos.where((t) => t.isDeleted).toList());

  // Actions
  void toggleCompleted(String id) => _repo.toggleCompleted(id);
  void deleteTodo(String id) => _repo.deleteTodo(id);
  void restoreTodo(String id) => _repo.restoreTodo(id);
  void deleteForever(String id) => _repo.deleteForever(id);

  void openDetail(String id) => Get.toNamed(Routes.todoDetail, arguments: id);

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
