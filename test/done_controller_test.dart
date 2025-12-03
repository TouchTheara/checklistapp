import 'package:checklistapp/app/data/models/todo.dart';
import 'package:checklistapp/app/data/repositories/todo_repository.dart';
import 'package:checklistapp/app/modules/done/controllers/done_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DoneController returns only completed todos', () {
    final repo = TodoRepository(seed: [
      Todo.create(title: 'Complete', priority: TodoPriority.high)
          .copyWith(isCompleted: true),
      Todo.create(title: 'Active', priority: TodoPriority.low),
    ]);
    final controller = DoneController(repo);

    expect(controller.doneTodos.length, 1);
    expect(controller.doneTodos.first.title, 'Complete');

    controller.toggleCompleted(controller.doneTodos.first.id);
    expect(controller.doneTodos, isEmpty);
  });
}
