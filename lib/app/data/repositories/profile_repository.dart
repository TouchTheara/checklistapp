import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/profile.dart';

class ProfileRepository extends GetxService {
  static const _profileKey = 'profile';
  static const supportEmail = 'support@sitehq.com';

  final Rx<Profile> _profile = const Profile().obs;
  String? _userId;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

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
    if (userId != null) {
      await _ensureRemoteProfile();
    }
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
    if (_userId == null) return;
    String? url = path;
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        final ref = _storage.ref().child('users/$_userId/avatar.jpg');
        await ref.putFile(file);
        url = await ref.getDownloadURL();
      } catch (_) {
        // ignore upload errors
      }
    }
    _profile.value = _profile.value.copyWith(avatarPath: url);
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

  Future<void> _ensureRemoteProfile() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (!doc.exists) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .set(_profile.value.toJson(), SetOptions(merge: true));
      }
    } catch (_) {
      // ignore
    }
  }

  String get _key =>
      _userId == null ? _profileKey : '${_profileKey}_$_userId';
}
