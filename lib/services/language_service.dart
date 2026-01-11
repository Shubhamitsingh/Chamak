import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  // Supported languages
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'nativeName': 'English'},
    'hi': {'name': 'Hindi', 'nativeName': 'हिंदी'},
    'ta': {'name': 'Tamil', 'nativeName': 'தமிழ்'},
    'te': {'name': 'Telugu', 'nativeName': 'తెలుగు'},
    'ml': {'name': 'Malayalam', 'nativeName': 'മലയാളം'},
    'mr': {'name': 'Marathi', 'nativeName': 'मराठी'},
    'kn': {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
  };
  
  /// Get saved language code from SharedPreferences
  Future<String?> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      print('Error getting saved language: $e');
      return null;
    }
  }
  
  /// Save language code to SharedPreferences
  Future<bool> saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language: $e');
      return false;
    }
  }
  
  /// Get Locale from language code
  Locale getLocaleFromLanguageCode(String languageCode) {
    return Locale(languageCode);
  }
  
  /// Check if language code is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }
  
  /// Get display name for language code
  String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode]?['name'] ?? 'Unknown';
  }
  
  /// Get native name for language code
  String getLanguageNativeName(String languageCode) {
    return supportedLanguages[languageCode]?['nativeName'] ?? 'Unknown';
  }
}






































