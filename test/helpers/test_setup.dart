import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safelist/app/data/models/todo.dart';
import 'package:safelist/app/data/repositories/profile_repository.dart';
import 'package:safelist/app/data/repositories/todo_repository.dart';
import 'package:safelist/app/data/services/onboarding_service.dart';
import 'package:safelist/app/data/services/theme_service.dart';
import 'package:safelist/app/modules/bin/controllers/bin_controller.dart';
import 'package:safelist/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:safelist/app/modules/done/controllers/done_controller.dart';
import 'package:safelist/app/modules/home/controllers/home_controller.dart';
import 'package:safelist/app/modules/profile/controllers/profile_controller.dart';

import '../mock_storage_service.dart';

class TestScope {
  TestScope({
    required this.todoRepository,
    required this.profileRepository,
    required this.homeController,
  });

  final TodoRepository todoRepository;
  final ProfileRepository profileRepository;
  final HomeController homeController;

  void dispose() {
    Get.reset();
  }
}

Future<TestScope> setupTestScope({List<Todo>? seed}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final todoRepository =
      TodoRepository(storageService: MockStorageService(), seed: seed ?? []);
  final profileRepository = await ProfileRepository().init();

  // Lightweight services needed by controllers in views
  Get.put<ThemeService>(ThemeService());
  Get.put<OnboardingService>(OnboardingService());

  // Register repositories
  Get.put<TodoRepository>(todoRepository);
  Get.put<ProfileRepository>(profileRepository);

  final homeController = HomeController(repository: todoRepository);

  // Controllers used by the views
  Get.put<HomeController>(homeController);
  Get.put<DashboardController>(DashboardController(todoRepository));
  Get.put<DoneController>(DoneController(todoRepository));
  Get.put<BinController>(BinController(todoRepository));
  Get.put<ProfileController>(
    ProfileController(todoRepository, profileRepository),
  );

  return TestScope(
    todoRepository: todoRepository,
    profileRepository: profileRepository,
    homeController: homeController,
  );
}
