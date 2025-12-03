import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:checklistapp/app/data/models/todo.dart';
import 'package:checklistapp/app/i18n/app_translations.dart';
import 'package:checklistapp/app/modules/home/views/home_view.dart';

import 'helpers/test_setup.dart';

void main() {
  late TestScope scope;

  setUp(() async {
    scope = await setupTestScope(seed: []);
  });

  tearDown(scope.dispose);

  Future<void> pumpHomeView(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: AppTranslations.en,
        home: const HomeView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard shows completed item actions', (tester) async {
    await pumpHomeView(tester);
    final doneTodo = Todo(
      id: 'done',
      title: 'Completed Task',
      isCompleted: true,
      createdAt: DateTime.now(),
      priority: TodoPriority.high,
    );
    scope.todoRepository.rawTodos.add(doneTodo);
    scope.homeController.changeTab(0);
    await tester.pumpAndSettle();

    expect(find.text(doneTodo.title), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Move to bin'), findsOneWidget);
  });

  testWidgets('Empty state visible when no tasks', (tester) async {
    await pumpHomeView(tester);
    scope.todoRepository.rawTodos.clear();
    scope.homeController.changeTab(0);
    await tester.pumpAndSettle();
    expect(find.text('No site checks yet'), findsOneWidget);
  });

  testWidgets('Archive tab shows deleted items and can restore', (tester) async {
    await pumpHomeView(tester);
    final deleted = Todo(
      id: 'del',
      title: 'Deleted Task',
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
    scope.todoRepository.rawTodos
      ..clear()
      ..add(deleted);
    scope.homeController.changeTab(2);
    await tester.pumpAndSettle();

    expect(find.text(deleted.title), findsOneWidget);
    scope.homeController.restoreTodo(deleted.id);
    await tester.pumpAndSettle();
    expect(scope.todoRepository.sortedBin, isEmpty);
  });
}
