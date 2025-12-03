import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usersKey = 'auth_users'; // json map of email -> {name,email,password}
  static const _userKey = 'auth_user'; // current user email
  static const _loggedInKey = 'auth_logged_in';

  String? _email;
  String? _password;
  String? _name;
  bool _loggedIn = false;
  String? _userId;

  String? get email => _email;
  String? get name => _name;
  bool get isLoggedIn => _loggedIn;
  String? get userId => _userId ?? _email;

  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_loggedInKey) ?? false;
    _userId = prefs.getString(_userKey);
    final users = _loadUsers(prefs);
    if (_userId != null && users.containsKey(_userId)) {
      final user = users[_userId]!;
      _email = user['email'] as String?;
      _password = user['password'] as String?;
      _name = user['name'] as String?;
    }
    return this;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    if (users.containsKey(email)) {
      return false; // user already exists
    }
    users[email] = {
      'name': name,
      'email': email,
      'password': password,
    };
    await _saveUsers(prefs, users);
    _name = name;
    _email = email;
    _password = password;
    _userId = email;
    _loggedIn = true;
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, _userId!);
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    final user = users[email];
    if (user == null) return false;
    if (user['password'] != password) return false;
    _name = user['name'] as String?;
    _email = user['email'] as String?;
    _password = user['password'] as String?;
    _userId = email;
    _loggedIn = true;
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, _userId!);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = false;
    _userId = null;
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    final currentId = _userId ?? _email;
    if (currentId == null) return;
    users.remove(currentId);
    users[email] = {
      'name': name,
      'email': email,
      'password': _password ?? '',
    };
    await _saveUsers(prefs, users);
    _name = name;
    _email = email;
    _userId = email;
    await prefs.setString(_userKey, email);
  }

  Map<String, Map<String, dynamic>> _loadUsers(SharedPreferences prefs) {
    final jsonString = prefs.getString(_usersKey);
    if (jsonString == null) return {};
    try {
      final raw = jsonDecode(jsonString) as Map<String, dynamic>;
      return raw.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsers(
    SharedPreferences prefs,
    Map<String, Map<String, dynamic>> users,
  ) async {
    await prefs.setString(_usersKey, jsonEncode(users));
  }
}
