import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  final LanguageService _languageService = LanguageService();
  
  Locale get locale => _locale;
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  /// Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await _languageService.getSavedLanguage();
    if (savedLanguage != null && _languageService.isLanguageSupported(savedLanguage)) {
      _locale = Locale(savedLanguage);
      notifyListeners();
    }
  }
  
  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (!_languageService.isLanguageSupported(languageCode)) {
      print('Language not supported: $languageCode');
      return;
    }
    
    _locale = Locale(languageCode);
    await _languageService.saveLanguage(languageCode);
    notifyListeners();
  }
  
  /// Get current language code
  String get currentLanguageCode => _locale.languageCode;
  
  /// Get current language name
  String get currentLanguageName => _languageService.getLanguageName(_locale.languageCode);
  
  /// Get current language native name
  String get currentLanguageNativeName => _languageService.getLanguageNativeName(_locale.languageCode);
}


































































