import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/locale_service.dart';
import '../data/services/onboarding_service.dart';
import '../data/services/theme_service.dart';

class AppController extends GetxController {
  AppController(
    this._themeService,
    this._onboardingService,
    this._localeService,
  );

  final ThemeService _themeService;
  final OnboardingService _onboardingService;
  final LocaleService _localeService;

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  final RxBool _onboardingComplete = false.obs;
  final Rx<Locale> _locale = const Locale('en', 'US').obs;

  ThemeMode get themeMode => _themeMode.value;
  bool get showOnboarding => !_onboardingComplete.value;
  Locale get locale => _locale.value;

  @override
  void onInit() {
    super.onInit();
    _themeMode.value = _themeService.mode;
    _onboardingComplete.value = _onboardingService.isCompleted;
    _locale.value = _localeService.locale;
    Get.updateLocale(_locale.value);
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
}
