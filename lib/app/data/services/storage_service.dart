import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

class StorageService {
  static const String _todosKey = 'todos';
  static const String _sortOptionKey = 'sort_option';

  String? _userId;

  void setUser(String? userId) {
    _userId = userId?.trim().isEmpty == true ? null : userId;
  }

  String _key(String base) => _userId == null ? base : '${base}_$_userId';

  Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = todos.map((todo) => todo.toJson()).toList();
    await prefs.setString(_key(_todosKey), jsonEncode(todosJson));
  }

  Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJsonString = prefs.getString(_key(_todosKey));
    
    if (todosJsonString == null) {
      return [];
    }

    try {
      final todosJson = jsonDecode(todosJsonString) as List<dynamic>;
      return todosJson.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  Future<bool> hasSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(_todosKey));
  }

  Future<void> saveSortOption(SortOption sortOption) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_sortOptionKey), sortOption.name);
  }

  Future<SortOption?> loadSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    final sortOptionName = prefs.getString(_key(_sortOptionKey));
    
    if (sortOptionName == null) {
      return null;
    }

    try {
      return SortOption.values.firstWhere(
        (option) => option.name == sortOptionName,
        orElse: () => SortOption.priorityHighFirst,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_todosKey));
    await prefs.remove(_key(_sortOptionKey));
  }
}
