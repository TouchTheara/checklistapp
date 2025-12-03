import 'package:checklistapp/app/data/repositories/profile_repository.dart';
import 'package:checklistapp/app/data/repositories/todo_repository.dart';
import 'package:checklistapp/app/modules/profile/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ProfileController saves profile and toggles notifications', () async {
    final todoRepo = TodoRepository(seed: []);
    final profileRepo = await ProfileRepository().init();
    final controller = ProfileController(todoRepo, profileRepo);

    expect(controller.profile.notificationsEnabled, isTrue);

    await controller.toggleNotifications(false);
    expect(controller.profile.notificationsEnabled, isFalse);

    await controller.saveProfile(name: 'Jane', email: 'jane@site.com');
    expect(controller.profile.name, 'Jane');
    expect(controller.profile.email, 'jane@site.com');
  });
}
