import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

class BinController extends GetxController {
  BinController(this._repository);

  final TodoRepository _repository;
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  static const _pageSize = 8;
  final RxInt _page = 1.obs;

  List<Todo> get binTodos {
    final list = _repository.sortedBin;
    final end = (_page.value * _pageSize).clamp(0, list.length);
    return list.take(end).toList();
  }

  bool get hasBinItems => _repository.hasBinItems;
  bool get hasMore => _page.value * _pageSize < _repository.sortedBin.length;

  @override
  Future<void> refresh() async {
    _page.value = 1;
    await _repository.reloadFromSource();
  }

  void loadMore() {
    if (hasMore) {
      _page.value += 1;
    }
  }

  void restoreTodo(String id) => _repository.restoreTodo(id);
  void deleteForever(String id) => _repository.deleteForever(id);
  void emptyBin() => _repository.emptyBin();

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }
}
