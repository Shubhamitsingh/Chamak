import 'dart:math';

class IdGeneratorService {
  /// Generate a unique numeric user ID based on timestamp + random suffix
  /// Format: timestamp (13 digits) + random 2 digits = 15 digits total
  /// Example: 173045892345123
  static String generateNumericUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99); // Add 2 random digits (00-99)
    final randomFormatted = random.toString().padLeft(2, '0'); // Ensure 2 digits
    
    return '$timestamp$randomFormatted';
  }
  
  /// Get the display ID (first 7 digits) to show in UI
  /// Example: 1730458923451 → 1730458
  static String getDisplayId(String fullNumericId) {
    if (fullNumericId.isEmpty) {
      return '0000000'; // Default if ID is missing
    }
    
    if (fullNumericId.length >= 7) {
      return fullNumericId.substring(0, 7);
    }
    
    // If ID is shorter than 7, pad with zeros
    return fullNumericId.padLeft(7, '0');
  }
  
  /// Format display ID with spacing for better readability (optional)
  /// Example: 1730458 → 173-0458
  static String formatDisplayId(String displayId) {
    if (displayId.length >= 7) {
      return '${displayId.substring(0, 3)}-${displayId.substring(3, 7)}';
    }
    return displayId;
  }
  
  /// Validate if a string is a valid numeric ID
  static bool isValidNumericId(String id) {
    if (id.isEmpty) return false;
    return RegExp(r'^\d+$').hasMatch(id); // Only digits allowed
  }
}




























