import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:Chamak/generated/l10n/app_localizations_en.dart';

/// Custom localization service that handles Hinglish translations
/// Loads Hinglish translations from ARB file at runtime
class HinglishLocalizationService {
  static Map<String, dynamic>? _hinglishTranslations;
  static bool _isLoading = false;

  /// Load Hinglish translations from ARB file
  static Future<void> loadHinglishTranslations() async {
    if (_hinglishTranslations != null || _isLoading) return;
    
    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('lib/l10n/app_hng.arb');
      _hinglishTranslations = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading Hinglish translations: $e');
      _hinglishTranslations = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Get Hinglish translation for a key
  static String? getHinglishTranslation(String key) {
    if (_hinglishTranslations == null) return null;
    return _hinglishTranslations![key] as String?;
  }

  /// Check if Hinglish translations are loaded
  static bool get isLoaded => _hinglishTranslations != null;
}

/// Wrapper for AppLocalizations that supports Hinglish
class AppLocalizationsWithHinglish {
  final AppLocalizations base;
  final bool isHinglish;

  AppLocalizationsWithHinglish(this.base, this.isHinglish);

  // Wrapper methods for all translations
  String get appTitle => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('appTitle') ?? base.appTitle
      : base.appTitle;

  String get home => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('home') ?? base.home
      : base.home;

  String get explore => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('explore') ?? base.explore
      : base.explore;

  String get live => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('live') ?? base.live
      : base.live;

  String get profile => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('profile') ?? base.profile
      : base.profile;

  String get settings => isHinglish 
      ? HinglishLocalizationService.getHinglishTranslation('settings') ?? base.settings
      : base.settings;

  // Add all other getters similarly...
  // Note: This is a simplified approach. For full implementation, 
  // we need to create app_localizations_hng.dart manually.
}
