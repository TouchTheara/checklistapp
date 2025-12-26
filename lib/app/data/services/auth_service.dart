import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _userKey = 'auth_user'; // current user email
  static const _loggedInKey = 'auth_logged_in';

  String? _email;
  String? _name;
  bool _loggedIn = false;
  String? _userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get email => _email;
  String? get name => _name;
  bool get isLoggedIn => _loggedIn;
  String? get userId => _userId ?? _email;

  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final current = _auth.currentUser;
    if (current != null) {
      _loggedIn = true;
      _userId = current.uid;
      _email = current.email;
      _name = current.displayName;
    } else {
      _loggedIn = prefs.getBool(_loggedInKey) ?? false;
      _userId = prefs.getString(_userKey);
      // If offline and we had a stored user id, keep basic session
    }
    return this;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      _name = name;
      _email = email;
      _userId = cred.user?.uid;
      _loggedIn = true;
      await _persistSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _name = cred.user?.displayName;
      _email = cred.user?.email;
      _userId = cred.user?.uid;
      _loggedIn = true;
      await _persistSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = false;
    _userId = null;
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_userKey);
    await _auth.signOut();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(name);
      } on FirebaseAuthException {
        // If requires recent login or fails, keep existing values to avoid crash.
      }
    }
    _name = name;
    _email = email.isNotEmpty ? email : _email;
    _userId = user?.uid ?? _userId;
    await _persistSession();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, _loggedIn);
    if (_userId != null) {
      await prefs.setString(_userKey, _userId!);
    }
  }
}
