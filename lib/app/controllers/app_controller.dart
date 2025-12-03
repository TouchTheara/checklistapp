import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/auth_service.dart';
import '../data/services/locale_service.dart';
import '../data/services/onboarding_service.dart';
import '../data/services/theme_service.dart';
import '../data/repositories/todo_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/home/bindings/home_binding.dart';

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

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  final RxBool _onboardingComplete = false.obs;
  final Rx<Locale> _locale = const Locale('en', 'US').obs;
  final RxBool _loggedIn = false.obs;
  final RxString _userName = ''.obs;
  final RxString _userEmail = ''.obs;
  final RxBool _startOnProfile = false.obs;

  ThemeMode get themeMode => _themeMode.value;
  bool get showOnboarding => !_onboardingComplete.value;
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
      _resetHomeTab();
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
      _resetHomeTab();
    }
    return ok;
  }

  Future<void> logout() async {
    await _authService.logout();
    _loggedIn.value = false;
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

  Future<void> _syncUserData() async {
    final userId = _authService.userId;
    _userName.value = _authService.name ?? '';
    _userEmail.value = _authService.email ?? '';
    await _todoRepository.loadForUser(userId);
    await _profileRepository.loadForUser(userId);
  }

  void _resetHomeTab() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(0);
    }
  }

  void _ensureHomeBindings() {
    if (!Get.isRegistered<HomeController>()) {
      HomeBinding().dependencies();
    }
  }
}
