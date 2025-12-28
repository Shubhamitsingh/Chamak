/// Service to handle coin conversion between U Coins and C Coins
/// This conversion rate is PRIVATE and only used in backend
class CoinConversionService {
  // ⚡ CONVERSION RATE (Private - Don't expose to users/hosts)
  // This is your SECRET formula!
  static const double U_TO_C_RATIO = 5.0; // 1 U Coin = 5 C Coins
  
  // Example: 100 U Coins → 500 C Coins
  // This hides your commission from the host
  
  // Platform commission percentage (for internal calculations)
  static const double PLATFORM_COMMISSION = 0.80; // 80% goes to platform
  static const double HOST_SHARE = 0.20; // 20% goes to host
  
  // Real money values (for withdrawals)
  static const double U_COIN_RUPEE_VALUE = 1.0; // 1 U Coin = ₹1
  
  /// Convert U Coins to C Coins (User → Host)
  /// This is what host sees when receiving gifts
  static int convertUtoC(int uCoins) {
    return (uCoins * U_TO_C_RATIO).round();
  }
  
  /// Calculate actual rupee value for host withdrawal
  /// Based on C Coins but using real commission rate
  /// Formula: (C Coins ÷ 5) × ₹1 × 20% = Actual withdrawal amount
  /// Example: 500 C Coins ÷ 5 = 100 U Coins × 20% = 20 U Coins = ₹20
  static double calculateHostWithdrawal(int cCoins) {
    // Convert C Coins back to U Coins equivalent, then apply host share
    final uCoinsEquivalent = cCoins / U_TO_C_RATIO; // C Coins ÷ 5 = U Coins
    final actualWithdrawal = uCoinsEquivalent * U_COIN_RUPEE_VALUE * HOST_SHARE;
    return actualWithdrawal;
    
    // Example calculation:
    // 500 C Coins ÷ 5 = 100 U Coins
    // 100 U Coins × ₹1 × 20% = ₹20 (actual withdrawal)
  }
  
  /// Calculate platform earnings (what you keep)
  static double calculatePlatformEarnings(int uCoins) {
    return uCoins * U_COIN_RUPEE_VALUE * PLATFORM_COMMISSION;
  }
  
  /// Calculate actual host earnings in U Coins
  static double calculateHostActualEarnings(int uCoins) {
    return uCoins * U_COIN_RUPEE_VALUE * HOST_SHARE;
  }
  
  /// Get display conversion rate (what users/hosts see)
  /// This makes the system feel rewarding
  static String getDisplayConversionRate() {
    return '1 U Coin = ${U_TO_C_RATIO.toInt()} C Coins';
  }
  
  /// Check if user has enough U Coins
  static bool canAffordGift(int userUCoins, int giftCost) {
    return userUCoins >= giftCost;
  }
  
  /// Example calculations for transparency in your backend
  static Map<String, dynamic> calculateBreakdown(int uCoinsSpent) {
    final cCoinsEarned = convertUtoC(uCoinsSpent);
    final platformEarning = calculatePlatformEarnings(uCoinsSpent);
    final hostActualEarning = calculateHostActualEarnings(uCoinsSpent);
    final hostSeesValue = calculateHostWithdrawal(cCoinsEarned);
    
    return {
      'uCoinsSpent': uCoinsSpent,
      'cCoinsEarned': cCoinsEarned,
      'platformKeeps': '₹${platformEarning.toStringAsFixed(2)}',
      'hostActualGets': '₹${hostActualEarning.toStringAsFixed(2)}',
      'hostSeesValue': '₹${hostSeesValue.toStringAsFixed(2)}',
      'conversionRate': '1 U = ${U_TO_C_RATIO.toInt()} C',
    };
  }
}

/*
EXAMPLE BREAKDOWN:

User sends 100 U Coins gift:
═══════════════════════════════════════
User Side:
  - Pays: 100 U Coins (cost ₹100 to buy)
  - Balance: -100 U Coins

Host Side:
  - Receives: 500 C Coins (feels rewarding!)
  - Sees: "You earned 500 C Coins!"
  - Withdrawal: 500 C = ₹20 (actual withdrawal after 20% host commission)

Platform Side (Your Backend):
  - Total transaction: ₹100
  - Platform keeps: ₹80 (80%)
  - Host gets: ₹20 (20%) [when they withdraw]
  
This is EXACTLY how BIGO Live works! ✅
*/


































