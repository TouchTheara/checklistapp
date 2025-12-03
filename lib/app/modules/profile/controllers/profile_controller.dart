import 'package:get/get.dart';

import '../../../data/models/profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/todo_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._todoRepository, this._profileRepository);

  final TodoRepository _todoRepository;
  final ProfileRepository _profileRepository;

  Profile get profile => _profileRepository.profile;
  bool get notificationsEnabled => _profileRepository.profile.notificationsEnabled;

  int get totalCount => _todoRepository.totalCount;
  int get completedCount => _todoRepository.completedCount;
  double get completionRate => _todoRepository.completionRate;

  Future<void> saveProfile({
    required String name,
    required String email,
  }) {
    return _profileRepository.updateProfile(
      _profileRepository.profile.copyWith(
        name: name.trim(),
        email: email.trim(),
      ),
    );
  }

  Future<void> toggleNotifications(bool enabled) {
    return _profileRepository.toggleNotifications(enabled);
  }

  String get supportEmail => ProfileRepository.supportEmail;
}
