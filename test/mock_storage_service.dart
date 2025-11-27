import 'package:checklistapp/app/data/models/todo.dart';
import 'package:checklistapp/app/data/services/storage_service.dart';

class MockStorageService extends StorageService {
  List<Todo> _todos = [];
  SortOption _sortOption = SortOption.priorityHighFirst;

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    _todos = List.from(todos);
  }

  @override
  Future<List<Todo>> loadTodos() async {
    return List.from(_todos);
  }

  @override
  Future<bool> hasSavedData() async {
    return _todos.isNotEmpty;
  }

  @override
  Future<void> saveSortOption(SortOption sortOption) async {
    _sortOption = sortOption;
  }

  @override
  Future<SortOption?> loadSortOption() async {
    return _sortOption;
  }

  @override
  Future<void> clearAll() async {
    _todos.clear();
  }
}
