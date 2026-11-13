import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final SharedPreferences _prefs;

  LocaleProvider(this._prefs) {
    final saved = _prefs.getString(AppConstants.languageKey) ?? 'en';
    _locale = Locale(saved);
  }

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await _prefs.setString(AppConstants.languageKey, languageCode);
    notifyListeners();
  }
}
