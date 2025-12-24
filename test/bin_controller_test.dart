import 'package:safelist/app/data/models/todo.dart';
import 'package:safelist/app/data/repositories/todo_repository.dart';
import 'package:safelist/app/modules/bin/controllers/bin_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BinController restores and empties bin', () {
    final repo = TodoRepository(seed: [
      Todo.create(title: 'Keep'),
      Todo.create(title: 'Delete').copyWith(isDeleted: true),
    ]);
    final controller = BinController(repo);

    expect(controller.binTodos.length, 1);
    controller.restoreTodo(controller.binTodos.first.id);
    expect(controller.binTodos, isEmpty);

    repo.deleteTodo(repo.sortedActive.first.id);
    controller.emptyBin();
    expect(controller.binTodos, isEmpty);
  });
}
