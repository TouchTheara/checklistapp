import 'dart:convert';

import 'package:safelist/app/modules/home/views/home_view.dart';
import 'package:safelist/app/modules/home/widgets/todo_form.dart';
import 'package:safelist/app/modules/home/widgets/todo_list.dart';
import 'package:safelist/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can add and complete a checklist item', (tester) async {
    SharedPreferences.setMockInitialValues({
      'locale': 'en_US',
      'locale_set': true,
      'onboarding_complete': true,
      'auth_logged_in': true,
      'auth_user': 'demo@safelist.app',
      'auth_users': jsonEncode({
        'demo@safelist.app': {
          'name': 'Demo',
          'email': 'demo@safelist.app',
          'password': 'password',
        }
      }),
    });

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
    final toggleFinder = find.descendant(
      of: todoCardFinder,
      matching: find.bySemanticsLabel('toggle_Record demo'),
    );

    await tester.tap(toggleFinder.first);
    await tester.pumpAndSettle(const Duration(seconds: 6));

    final completedText = tester.widget<Text>(todoTitleFinder);
    expect(
      completedText.style?.decoration,
      TextDecoration.lineThrough,
    );
  });
}
