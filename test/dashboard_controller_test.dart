import 'package:safelist/app/data/models/todo.dart';
import 'package:safelist/app/data/repositories/todo_repository.dart';
import 'package:safelist/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardController exposes stats and sorted todos', () {
    final repo = TodoRepository(seed: [
      Todo.create(title: 'High', priority: TodoPriority.high),
      Todo.create(title: 'Low', priority: TodoPriority.low),
    ]);
    final controller = DashboardController(repo);

    expect(controller.totalCount, 2);
    expect(controller.completedCount, 0);
    expect(controller.todos.first.priority, TodoPriority.high);

    controller.changeSort(SortOption.alphabetical);
    expect(controller.todos.first.title, 'High');
  });
}
