import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/home/views/todo_detail_view.dart';
import '../modules/legal/views/terms_privacy_view.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/onboarding/views/language_select_view.dart';
import '../modules/support/views/support_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import 'app_routes.dart';

class AppPages {
  static String initialRoute(AppController app) {
    if (app.needsLocaleSelection) return Routes.language;
    if (app.showOnboarding) return Routes.onboarding;
    if (app.isLoggedIn) return Routes.home;
    return Routes.auth;
  }

  static final pages = <GetPage>[
    GetPage(
      name: Routes.language,
      page: () => const LanguageSelectView(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
    ),
    GetPage(
      name: Routes.auth,
      page: () => const AuthView(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.todoDetail,
      page: () {
        final todoId = Get.arguments as String? ?? '';
        return TodoDetailView(todoId: todoId);
      },
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchView(),
      bindings: [
        SearchBinding(),
      ],
    ),
    GetPage(
      name: Routes.support,
      page: () => const SupportView(),
    ),
    GetPage(
      name: Routes.terms,
      page: () => const TermsPrivacyView(),
    ),
  ];
}
