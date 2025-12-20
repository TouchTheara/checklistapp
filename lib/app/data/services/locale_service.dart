import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _localeKey = 'locale';
  static const _hasLocaleKey = 'locale_set';
  Locale _locale = const Locale('en', 'US');
  bool _hasSavedLocale = false;

  Locale get locale => _locale;
  bool get hasSavedLocale => _hasSavedLocale;

  Future<LocaleService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      final parts = code.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
        _hasSavedLocale = true;
      }
    }
    return this;
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
    await prefs.setBool(_hasLocaleKey, true);
    _hasSavedLocale = true;
  }
}
