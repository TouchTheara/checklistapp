import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'app/controllers/app_controller.dart';
import 'app/data/repositories/profile_repository.dart';
import 'app/data/repositories/todo_repository.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/data/services/onboarding_service.dart';
import 'app/data/services/theme_service.dart';
import 'app/data/services/sample_data_service.dart';
import 'app/data/services/notification_service.dart';
import 'app/i18n/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/modules/home/views/home_view.dart';
import 'app/modules/home/bindings/home_binding.dart';
import 'app/widgets/custom_loading_footer_widget.dart';
import 'app/widgets/custom_refresh_header_widget.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Get.putAsync<NotificationService>(() => NotificationService().init());
  await Get.putAsync<TodoRepository>(() => TodoRepository().init());
  await Get.putAsync<ProfileRepository>(() => ProfileRepository().init());
  await Get.putAsync<ThemeService>(() => ThemeService().init());
  await Get.putAsync<OnboardingService>(() => OnboardingService().init());
  await Get.putAsync<LocaleService>(() => LocaleService().init());
  await Get.putAsync<AuthService>(() => AuthService().init());
  Get.put<SampleDataService>(SampleDataService());
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
      () => RefreshConfiguration(
        headerBuilder: () => const CustomRefreshHeaderWidget(),
        footerBuilder: () => const CustomLoadingFooterWidget(),
        hideFooterWhenNotFull: true,
        child: GetMaterialApp(
          title: 'SafeList',
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          locale: appController.locale,
          fallbackLocale: AppTranslations.en,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
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
          initialRoute: AppPages.initialRoute(appController),
          getPages: AppPages.pages,
          unknownRoute: GetPage(
            name: Routes.home,
            page: () => const HomeView(),
            binding: HomeBinding(),
          ),
        ),
      ),
    );
  }
}
