import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

class ProfileRepository extends GetxService {
  static const _profileKey = 'profile';
  static const supportEmail = 'support@sitehq.com';

  final Rx<Profile> _profile = const Profile().obs;

  Profile get profile => _profile.value;

  Future<ProfileRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_profileKey);
    if (stored != null) {
      try {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        _profile.value = Profile.fromJson(json);
      } catch (_) {
        _profile.value = const Profile();
      }
    }
    return this;
  }

  Future<void> updateProfile(Profile profile) async {
    _profile.value = profile;
    await _persist();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _profile.value = _profile.value.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profile.value.toJson()));
  }
}
