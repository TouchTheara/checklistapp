import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile.dart';

class ProfileRepository extends GetxService {
  static const _profileKey = 'profile';
  static const supportEmail = 'support@sitehq.com';

  final Rx<Profile> _profile = const Profile().obs;
  String? _userId;
  final _firestore = FirebaseFirestore.instance;

  Profile get profile => _profile.value;

  Future<ProfileRepository> init() async {
    await loadForUser(null);
    return this;
  }

  Future<void> loadForUser(String? userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    Profile? loaded;
    if (userId != null) {
      try {
        final doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          loaded = Profile.fromJson(doc.data()!);
        }
      } catch (_) {
        // ignore
      }
    }
    if (loaded == null) {
      final stored = prefs.getString(_key);
      if (stored != null) {
        try {
          final json = jsonDecode(stored) as Map<String, dynamic>;
          loaded = Profile.fromJson(json);
        } catch (_) {
          loaded = const Profile();
        }
      }
    }
    _profile.value = loaded ?? const Profile();
  }

  Future<void> updateProfile(Profile profile) async {
    _profile.value = profile;
    await _persist();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _profile.value = _profile.value.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  Future<void> updateAvatar(String? path) async {
    _profile.value = _profile.value.copyWith(avatarPath: path);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profile.value.toJson()));
    if (_userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .set(_profile.value.toJson(), SetOptions(merge: true));
      } catch (_) {
        // ignore sync failures offline
      }
    }
  }

  String get _key =>
      _userId == null ? _profileKey : '${_profileKey}_$_userId';
}
