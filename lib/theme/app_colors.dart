import 'package:flutter/material.dart';

/// Centralized color palette for the Chamak app
/// This ensures consistency across all screens
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF6C63FF); // Purple - Main brand color
  static const Color secondary = Color(0xFFFF1B7C); // Pink - Secondary actions
  static const Color secondaryAlt = Color(0xFFFF1744); // Red-Pink - Alternative secondary
  static const Color secondaryPink = Color(0xFFE91E63); // Deep Pink - Used in some places

  // Success & Status Colors
  static const Color success = Color(0xFF04B104); // Green - Success actions
  static const Color successAlt = Color(0xFF4CAF50); // Material Green - Alternative
  static const Color error = Color(0xFFEF4444); // Red - Error states
  static const Color warning = Color(0xFFFF9800); // Orange - Warnings

  // Background Colors
  static const Color background = Colors.white; // White background
  static const Color backgroundCream = Color(0xFFFFFEE0); // Cream background (if used)
  static const Color surface = Colors.white; // Surface color
  static const Color surfaceGrey = Color(0xFFF5F5F5); // Grey surface

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Black87 - Primary text
  static const Color textSecondary = Color(0xFF757575); // Grey600 - Secondary text
  static const Color textTertiary = Color(0xFF9E9E9E); // Grey400 - Tertiary text
  static const Color textOnPrimary = Colors.white; // White text on colored backgrounds
  static const Color textOnSecondary = Colors.white; // White text on secondary backgrounds

  // Border & Divider Colors
  static const Color border = Color(0xFFE0E0E0); // Grey300 - Borders
  static const Color divider = Color(0xFFE0E0E0); // Grey300 - Dividers

  // Live Streaming Colors
  static const Color liveRed = Color(0xFFFF1744); // Red for live indicator
  static const Color liveRedDot = Color(0xFFFF1744); // Red dot for live status

  // Chat & Message Colors
  static const Color chatBubble = Color(0xFF6366F1); // Indigo for chat bubbles
  static const Color chatBubbleDark = Color(0xFF424242); // Dark grey for chat

  // Overlay Colors
  static const Color overlayDark = Color(0x80000000); // 50% black overlay
  static const Color overlayLight = Color(0x80FFFFFF); // 50% white overlay

  // Gradient Colors (for gradients)
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF9C27B0),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFFF1B7C),
    Color(0xFFFF1744),
  ];

  // Helper method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
