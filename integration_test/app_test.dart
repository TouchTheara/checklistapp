import 'package:checklistapp/app/modules/home/views/home_view.dart';
import 'package:checklistapp/app/modules/home/widgets/todo_form.dart';
import 'package:checklistapp/app/modules/home/widgets/todo_list.dart';
import 'package:checklistapp/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can add and complete a checklist item', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeView.addTodoFabKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(TodoForm.titleFieldKey),
      'Record demo',
    );
    await tester.enterText(
      find.byKey(TodoForm.descriptionFieldKey),
      'Capture walkthrough for stakeholders',
    );

    await tester.tap(find.byKey(TodoForm.priorityFieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TodoForm.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Record demo'), findsOneWidget);

    final todoTitleFinder = find.text('Record demo');
    final todoCardFinder = find.ancestor(
      of: todoTitleFinder,
      matching: find.byType(TodoCard),
    );
    final checkboxFinder = find.descendant(
      of: todoCardFinder,
      matching: find.byType(Checkbox),
    );

    await tester.tap(checkboxFinder.first);
    await tester.pumpAndSettle();

    final completedText = tester.widget<Text>(todoTitleFinder);
    expect(
      completedText.style?.decoration,
      TextDecoration.lineThrough,
    );
  });
}

