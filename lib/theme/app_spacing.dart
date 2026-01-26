/// Centralized spacing constants for consistent padding and margins
/// This ensures visual consistency across all screens
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Extra Small Spacing
  static const double xs = 4.0;
  
  // Small Spacing
  static const double sm = 8.0;
  
  // Medium Spacing (Most Common)
  static const double md = 12.0;
  static const double md2 = 15.0; // Alternative medium (used in some places)
  static const double md3 = 16.0; // Standard medium
  
  // Large Spacing
  static const double lg = 20.0;
  static const double lg2 = 24.0; // Alternative large
  
  // Extra Large Spacing
  static const double xl = 32.0;
  static const double xl2 = 48.0;
  
  // Screen Margins
  static const double screenHorizontal = 16.0; // Standard horizontal margin
  static const double screenHorizontalAlt = 15.0; // Alternative (used in home screen)
  static const double screenVertical = 16.0; // Standard vertical margin
  
  // Component Spacing
  static const double componentPadding = 16.0; // Standard component padding
  static const double cardPadding = 16.0; // Card padding
  static const double buttonPadding = 16.0; // Button padding
}
