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
  String? get avatarPath => _profileRepository.profile.avatarPath;

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

  Future<void> updateAvatar(String? path) async {
    await _profileRepository.updateProfile(
      _profileRepository.profile.copyWith(avatarPath: path),
    );
  }

  Future<void> loadForUser(String? userId) async {
    await _profileRepository.loadForUser(userId);
  }

  String get supportEmail => ProfileRepository.supportEmail;
}
