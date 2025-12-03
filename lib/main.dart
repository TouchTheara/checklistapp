import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/controllers/app_controller.dart';
import 'app/data/repositories/profile_repository.dart';
import 'app/data/repositories/todo_repository.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/data/services/onboarding_service.dart';
import 'app/data/services/theme_service.dart';
import 'app/i18n/app_translations.dart';
import 'app/modules/auth/views/auth_view.dart';
import 'app/modules/onboarding/views/onboarding_view.dart';
import 'app/modules/home/bindings/home_binding.dart';
import 'app/modules/home/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync<TodoRepository>(() => TodoRepository().init());
  await Get.putAsync<ProfileRepository>(() => ProfileRepository().init());
  await Get.putAsync<ThemeService>(() => ThemeService().init());
  await Get.putAsync<OnboardingService>(() => OnboardingService().init());
  await Get.putAsync<LocaleService>(() => LocaleService().init());
  await Get.putAsync<AuthService>(() => AuthService().init());
  // Pre-register home-related controllers so navigation always finds them.
  HomeBinding().dependencies();
  Get.put<AppController>(
    AppController(
      Get.find<ThemeService>(),
      Get.find<OnboardingService>(),
      Get.find<LocaleService>(),
      Get.find<AuthService>(),
    ),
  );
  runApp(const ChecklistApp());
}

class ChecklistApp extends StatelessWidget {
  const ChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Construction Checklist',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: appController.locale,
        fallbackLocale: AppTranslations.en,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        themeMode: appController.themeMode,
        initialBinding: HomeBinding(),
        home: appController.showOnboarding
            ? const OnboardingView()
            : appController.isLoggedIn
                ? const HomeView()
                : const AuthView(),
      ),
    );
  }
}
