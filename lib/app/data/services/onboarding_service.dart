import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _onboardingKey = 'onboarding_complete';
  bool _completed = false;

  bool get isCompleted => _completed;

  Future<OnboardingService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_onboardingKey) ?? false;
    return this;
  }

  Future<void> markCompleted() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
