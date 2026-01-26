import 'package:flutter/material.dart';

/// App-wide constants for UI elements
/// This ensures consistency and accessibility compliance
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // Touch Target Sizes (Accessibility)
  /// Minimum touch target size for accessibility (44x44 pixels)
  /// This is the minimum recommended by Material Design and iOS HIG
  static const double minTouchTarget = 44.0;
  
  /// Minimum touch target size as Size object
  static const Size minTouchTargetSize = Size(44.0, 44.0);
  
  /// Minimum button height
  static const double minButtonHeight = 44.0;
  
  /// Minimum button width (for full-width buttons)
  static const double minButtonWidth = double.infinity;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 30.0; // Used for buttons and inputs
  
  // Button Styles
  static const double buttonElevation = 0.0; // Flat design
  static const double buttonBorderRadius = 30.0; // Rounded buttons
  
  // Input Field Styles
  static const double inputBorderRadius = 30.0; // Rounded inputs
  static const double inputPaddingHorizontal = 24.0;
  static const double inputPaddingVertical = 20.0;
  
  // AppBar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;
  
  // Bottom Navigation
  static const double bottomNavHeight = 56.0;
  static const double bottomNavElevation = 8.0;
  static const double bottomNavIconSize = 28.0;
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
