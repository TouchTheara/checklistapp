import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class DoneController extends GetxController {
  DoneController(this._repository);

  final TodoRepository _repository;
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  static const _pageSize = 10;
  final RxInt _page = 1.obs;

  List<Todo> get doneTodos {
    final list = _repository.sortedDone;
    final end = (_page.value * _pageSize).clamp(0, list.length);
    return list.take(end).toList();
  }

  bool get hasMore => _page.value * _pageSize < _repository.sortedDone.length;

  @override
  Future<void> refresh() async {
    _page.value = 1;
    await _repository.reloadFromSource();
    refreshController.refreshCompleted();
    refreshController.resetNoData();
  }

  Future<void> loadMore() async {
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

  void deleteTodo(String id) => _repository.deleteTodo(id);
  void toggleCompleted(String id) => _repository.toggleCompleted(id);
  void updateTodo(Todo todo) => _repository.updateTodo(todo);
}
