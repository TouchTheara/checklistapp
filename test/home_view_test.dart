import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:checklistapp/app/modules/home/views/home_view.dart';
import 'package:checklistapp/app/modules/home/controllers/home_controller.dart';
import 'package:checklistapp/app/data/models/todo.dart';

import 'mock_storage_service.dart';

void main() {
  late HomeController controller;
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    controller = HomeController(storageService: mockStorageService);
    Get.put<HomeController>(controller);
  });

  tearDown(() {
    Get.delete<HomeController>();
  });

  Future<void> pumpHomeView(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: HomeView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Dashboard tab shows checked todo with title, priority, and delete option',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final doneTodo = Todo(
      id: 'test1',
      title: 'Completed Task',
      description: 'Description',
      isCompleted: true,
      createdAt: DateTime.now(),
      priority: TodoPriority.high,
    );
    controller.todos.clear();
    controller.todos.addAll([doneTodo]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    final titleFinder = find.text(doneTodo.title);
    expect(titleFinder, findsOneWidget);

    final chipFinder = find.byType(Chip);
    expect(chipFinder, findsWidgets);

    final popupButtons = find.byType(PopupMenuButton);
    expect(popupButtons, findsWidgets);

    await tester.tap(popupButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Move to bin'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets(
      'Done tab shows checked todo with only delete option in popup menu',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final doneTodo = Todo(
      id: 'done1',
      title: 'Done Task',
      description: 'Done description',
      isCompleted: true,
      createdAt: DateTime.now(),
      priority: TodoPriority.medium,
    );

    controller.doneTodos.clear();
    controller.doneTodos.addAll([doneTodo]);
    controller.changeTab(1);
    await tester.pumpAndSettle();

    expect(find.text(doneTodo.title), findsOneWidget);

    final popupButtons = find.byType(PopupMenuButton);
    expect(popupButtons, findsWidgets);

    await tester.tap(popupButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Move to bin'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets(
      'Unchecked todo displays full card and allows editing on dashboard',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final todo = Todo(
      id: 'unchecked1',
      title: 'Unchecked Task',
      description: 'Some description',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.low,
    );

    controller.todos.clear();
    controller.todos.addAll([todo]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    expect(find.text(todo.title), findsOneWidget);
    expect(find.text(todo.description!), findsOneWidget);

    final popupButtons = find.byType(PopupMenuButton);
    await tester.tap(popupButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Move to bin'), findsOneWidget);
  });

  testWidgets('Empty todo list shows empty state', (WidgetTester tester) async {
    await pumpHomeView(tester);

    controller.todos.clear();
    controller.changeTab(0);
    await tester.pumpAndSettle();

    expect(find.text('Your checklist is empty'), findsOneWidget);
    expect(
        find.text('Tap “Add task” to create your first item.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('Toggle completion via checkbox updates todo state',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final todo = Todo(
      id: 'toggle1',
      title: 'Toggle Task',
      description: 'Toggle description',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.low,
    );

    controller.todos.clear();
    controller.todos.addAll([todo]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);

    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(controller.todos.first.isCompleted, true);
  });

  testWidgets('Popup menu actions trigger callbacks appropriately',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final todo = Todo(
      id: 'callback1',
      title: 'Popup Test',
      description: 'Test popup menu',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.medium,
    );

    controller.todos.clear();
    controller.todos.addAll([todo]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    final popupButtonFinder = find.byType(PopupMenuButton);
    expect(popupButtonFinder, findsWidgets);

    await tester.tap(popupButtonFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Move to bin'), findsOneWidget);

    await tester.tap(find.text('Move to bin'));
    await tester.pumpAndSettle();

    expect(controller.todos.first.isDeleted, true);
  });

  testWidgets('Sorting option changes reorder todos',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final todo1 = Todo(
      id: '1',
      title: 'A Task',
      description: 'Low priority',
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      priority: TodoPriority.low,
    );

    final todo2 = Todo(
      id: '2',
      title: 'B Task',
      description: 'High priority',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.high,
    );

    controller.todos.clear();
    controller.todos.addAll([todo1, todo2]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    // Default sort is priority high first: B Task should appear before A Task
    final textFinders = find.textContaining('Task');
    expect(textFinders, findsNWidgets(2));
    final firstText = tester.widget<Text>(textFinders.first);
    expect(firstText.data, 'B Task');

    // Change to alphabetical sort
    controller.changeSort(SortOption.alphabetical);
    await tester.pumpAndSettle();

    final firstTextAlpha = tester.widget<Text>(textFinders.first);
    expect(firstTextAlpha.data, 'A Task');
  });

  testWidgets(
      'Bin tab shows deleted todos and allows restore and delete forever',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final deletedTodo = Todo(
      id: 'del1',
      title: 'Deleted Task',
      description: 'Deleted description',
      isCompleted: false,
      isDeleted: true,
      deletedAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      priority: TodoPriority.medium,
    );

    controller.todos.clear();
    controller.todos.addAll([deletedTodo]);
    controller.changeTab(2);
    await tester.pumpAndSettle();

    expect(find.text(deletedTodo.title), findsOneWidget);

    // Simulate restore action
    controller.restoreTodo(deletedTodo.id);
    await tester.pumpAndSettle();

    expect(controller.binTodos, isEmpty);
    expect(controller.todos.any((t) => t.id == deletedTodo.id && !t.isDeleted),
        isTrue);

    // Simulate delete forever
    controller.deleteForever(deletedTodo.id);
    await tester.pumpAndSettle();

    expect(controller.todos.any((t) => t.id == deletedTodo.id), isFalse);
  });

  testWidgets('Todos with empty title and long title display correctly',
      (WidgetTester tester) async {
    await pumpHomeView(tester);

    final emptyTitleTodo = Todo(
      id: 'emptyTitle',
      title: '',
      description: 'Empty title description',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.low,
    );

    final longTitleTodo = Todo(
      id: 'longTitle',
      title: 'L' * 200, // very long title
      description: 'Long title description',
      isCompleted: false,
      createdAt: DateTime.now(),
      priority: TodoPriority.high,
    );

    controller.todos.clear();
    controller.todos.addAll([emptyTitleTodo, longTitleTodo]);
    controller.changeTab(0);
    await tester.pumpAndSettle();

    expect(find.text(''), findsOneWidget);
    expect(find.text('L' * 200), findsOneWidget);
  });
}
