import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/auth_service.dart';
import '../data/services/locale_service.dart';
import '../data/services/onboarding_service.dart';
import '../data/services/theme_service.dart';
import '../data/services/sample_data_service.dart';
import '../data/repositories/todo_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/home/bindings/home_binding.dart';
import '../data/services/notification_service.dart';
import '../modules/notifications/controllers/notifications_controller.dart';

class AppController extends GetxController {
  AppController(
    this._themeService,
    this._onboardingService,
    this._localeService,
    this._authService,
  );

  final ThemeService _themeService;
  final OnboardingService _onboardingService;
  final LocaleService _localeService;
  final AuthService _authService;
  final TodoRepository _todoRepository = Get.find<TodoRepository>();
  final ProfileRepository _profileRepository = Get.find<ProfileRepository>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  final RxBool _onboardingComplete = false.obs;
  final Rx<Locale> _locale = const Locale('en', 'US').obs;
  final RxBool _loggedIn = false.obs;
  final RxString _userName = ''.obs;
  final RxString _userEmail = ''.obs;
  final RxBool _startOnProfile = false.obs;

  ThemeMode get themeMode => _themeMode.value;
  bool get showOnboarding => !_onboardingComplete.value;
  bool get needsLocaleSelection => !_localeService.hasSavedLocale;
  Locale get locale => _locale.value;
  bool get isLoggedIn => _loggedIn.value;
  String? get userName => _userName.value.isEmpty ? null : _userName.value;
  String? get userEmail => _userEmail.value.isEmpty ? null : _userEmail.value;
  bool get shouldShowAuth => !_loggedIn.value && !_onboardingComplete.value;
  bool get startOnProfile => _startOnProfile.value;

  @override
  void onInit() {
    super.onInit();
    _themeMode.value = _themeService.mode;
    _onboardingComplete.value = _onboardingService.isCompleted;
    _locale.value = _localeService.locale;
    Get.updateLocale(_locale.value);
    _loggedIn.value = _authService.isLoggedIn;
    _userName.value = _authService.name ?? '';
    _userEmail.value = _authService.email ?? '';
    _notificationService.onLogin(_authService.userId);
    _refreshNotificationsForUser();
    _syncUserData();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    _themeMode.value = mode;
    await _themeService.setMode(mode);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete.value = true;
    await _onboardingService.markCompleted();
  }

  Future<void> changeLocale(Locale locale) async {
    _locale.value = locale;
    await _localeService.setLocale(locale);
    Get.updateLocale(locale);
  }

  Future<bool> login(String email, String password) async {
    final ok = await _authService.login(email: email, password: password);
    _loggedIn.value = ok;
    if (ok) {
      _startOnProfile.value = false;
      _ensureHomeBindings();
      await _syncUserData();
      await _seedDemoIfEmpty();
      _resetHomeTab();
      _notificationService.onLogin(_authService.userId);
      _refreshNotificationsForUser();
    }
    return ok;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final ok = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
    _loggedIn.value = ok;
    if (ok) {
      _startOnProfile.value = false;
      _ensureHomeBindings();
      await _syncUserData();
      await _seedDemoIfEmpty();
      _resetHomeTab();
      _notificationService.onLogin(_authService.userId);
      _refreshNotificationsForUser();
    }
    return ok;
  }

  Future<void> logout() async {
    // Handle notification cleanup before signing out (requires auth).
    await _notificationService.onLogout();
    _clearNotifications();
    await _authService.logout();
    _loggedIn.value = false;
    await _todoRepository.clearForLogout();
    await _syncUserData();
    _resetHomeTab();
  }

  Future<void> updateAuthProfile({
    required String name,
    required String email,
  }) async {
    await _authService.updateProfile(name: name, email: email);
    _userName.value = name;
    _userEmail.value = email;
  }

  Future<bool> loginWithGoogle() async {
    final (ok, error) = await _authService.signInWithGoogle();
    _loggedIn.value = ok;
    if (ok) {
      _startOnProfile.value = false;
      _ensureHomeBindings();
      await _syncUserData();
      await _seedDemoIfEmpty();
      _resetHomeTab();
      _notificationService.onLogin(_authService.userId);
      _refreshNotificationsForUser();
    } else if (error != null && error.isNotEmpty) {
      Get.snackbar('auth.failed'.tr, error,
          snackPosition: SnackPosition.BOTTOM);
      // Also log for diagnostics
      // ignore: avoid_print
      print('Google sign-in failed: $error');
    }
    return ok;
  }

  Future<void> _syncUserData() async {
    final userId = _authService.userId;
    _userName.value = _authService.name ?? '';
    _userEmail.value = _authService.email ?? '';
    await _todoRepository.loadForUser(userId);
    await _profileRepository.loadForUser(userId);
    await _hydrateProfileFromAuth();
  }

  void _resetHomeTab() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(0);
    }
  }

  void _refreshNotificationsForUser() {
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().reloadForCurrentUser();
    }
  }

  void _clearNotifications() {
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().clearForLogout();
    }
  }

  void _ensureHomeBindings() {
    if (!Get.isRegistered<HomeController>()) {
      HomeBinding().dependencies();
    }
  }

  Future<void> _seedDemoIfEmpty() async {
    final seeder = Get.find<SampleDataService>();
    await seeder.seedForCurrentUser();
    await _todoRepository.loadForUser(_authService.userId);
  }

  Future<void> _hydrateProfileFromAuth() async {
    final authName = _authService.name;
    final authEmail = _authService.email;
    if (authEmail == null || authEmail.isEmpty) return;
    final profile = _profileRepository.profile;
    final isDefaultName =
        profile.name == 'Site Safety Lead' || profile.name.isEmpty;
    final isDefaultEmail =
        profile.email == 'safety@sitehq.com' || profile.email.isEmpty;
    if (isDefaultName || isDefaultEmail) {
      await _profileRepository.updateProfile(
        profile.copyWith(
          name: authName?.isNotEmpty == true ? authName : profile.name,
          email: authEmail,
        ),
      );
    }
  }
}
