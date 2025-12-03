import 'package:checklistapp/app/data/models/todo.dart';
import 'package:checklistapp/app/data/repositories/todo_repository.dart';
import 'package:checklistapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeController (GetX)', () {
    test('adds todos and updates counts', () {
      final repository = TodoRepository(seed: []);
      final controller = HomeController(repository: repository);
      expect(controller.totalCount, 0);

      controller.addTodo(
        Todo.create(title: 'Write docs', priority: TodoPriority.high),
      );
      expect(controller.totalCount, 1);
      expect(controller.completedCount, 0);
    });

    test('toggle completed flips status', () {
      final repository = TodoRepository(seed: [
        Todo.create(title: 'Focus block'),
      ]);
      final controller = HomeController(repository: repository);

      final todoId = controller.todos.first.id;
      controller.toggleCompleted(todoId);
      expect(controller.todos.first.isCompleted, isTrue);
      controller.toggleCompleted(todoId);
      expect(controller.todos.first.isCompleted, isFalse);
    });

    test('sorting by priority high and low', () {
      final repository = TodoRepository(seed: [
        Todo.create(title: 'Low', priority: TodoPriority.low),
        Todo.create(title: 'High', priority: TodoPriority.high),
        Todo.create(title: 'Medium', priority: TodoPriority.medium),
      ]);
      final controller = HomeController(repository: repository);

      controller.changeSort(SortOption.priorityHighFirst);
      expect(controller.todos.first.title, 'High');

      controller.changeSort(SortOption.priorityLowFirst);
      expect(controller.todos.first.title, 'Low');
    });

    test('deleteTodo moves item into bin, restoreTodo brings it back', () {
      final repository = TodoRepository(seed: [
        Todo.create(title: 'Temp item'),
      ]);
      final controller = HomeController(repository: repository);

      final todoId = controller.todos.first.id;
      controller.deleteTodo(todoId);

      expect(controller.todos, isEmpty);
      expect(controller.binTodos.length, 1);
      expect(controller.hasBinItems, isTrue);

      controller.restoreTodo(todoId);
      expect(controller.todos.length, 1);
      expect(controller.binTodos, isEmpty);
    });

    test('emptyBin deletes all soft-deleted items permanently', () {
      final repository = TodoRepository(seed: [
        Todo.create(title: 'Task A'),
        Todo.create(title: 'Task B'),
      ]);
      final controller = HomeController(repository: repository);

      final ids = controller.todos.map((todo) => todo.id).toList();
      for (final id in ids) {
        controller.deleteTodo(id);
      }

      expect(controller.binTodos.length, 2);
      controller.emptyBin();
      expect(controller.binTodos, isEmpty);
      expect(controller.todos, isEmpty);
      expect(controller.hasBinItems, isFalse);
    });

    test('changeTab updates active tab index', () {
      final controller = HomeController(repository: TodoRepository(seed: []));
      expect(controller.tabIndex, 0);
      controller.changeTab(1);
      expect(controller.tabIndex, 1);
      controller.changeTab(0);
      expect(controller.tabIndex, 0);
    });

    test('doneTodos reflects completed items', () {
      final repository = TodoRepository(
        seed: [
          Todo.create(title: 'Complete me'),
        ],
      );
      final controller = HomeController(repository: repository);

      expect(controller.doneTodos, isEmpty);

      final id = controller.todos.first.id;
      controller.toggleCompleted(id);
      expect(controller.doneTodos.length, 1);

      controller.toggleCompleted(id);
      expect(controller.doneTodos, isEmpty);
    });
  });
}
