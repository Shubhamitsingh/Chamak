import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/coin_popup_service.dart';
import '../screens/wallet_screen.dart';
import 'dart:async';

/// Enum for different popup styles
enum PopupStyle {
  starburst,      // #1 - Bottom sheet with starburst (existing)
  premiumCard,    // #2 - Center modal premium card
  flashDeal,      // #3 - Full screen flash deal
  minimalist,     // #4 - Side panel minimalist
}

/// Coin purchase popup with 4 unique designs that rotate randomly
class CoinPurchasePopup {
  final CoinPopupService _popupService = CoinPopupService();
  
  // Check if in test mode
  bool get isTestMode => CoinPopupService.TEST_MODE;
  
  /// Get random popup style (weighted probabilities)
  PopupStyle _getRandomPopupStyle() {
    final random = math.Random();
    final value = random.nextDouble();
    
    // Weighted probabilities:
    // Starburst: 30%, Premium: 25%, Flash: 25%, Minimalist: 20%
    if (value < 0.30) return PopupStyle.starburst;
    if (value < 0.55) return PopupStyle.premiumCard;
    if (value < 0.80) return PopupStyle.flashDeal;
    return PopupStyle.minimalist;
  }
  
  /// Show the coin purchase dialog with random style selection (all as bottom sheets)
  Future<void> show(BuildContext context, {String? specialOffer, PopupStyle? forcedStyle}) async {
    // Record that popup was shown
    await _popupService.recordPopupShown();
    
    // Get popup style (random or forced for testing)
    final style = forcedStyle ?? _getRandomPopupStyle();
    
    Widget popupWidget;
    
    switch (style) {
      case PopupStyle.starburst:
        popupWidget = _StarburstPopup(
          specialOffer: specialOffer,
          popupService: _popupService,
        );
        break;
        
      case PopupStyle.premiumCard:
        popupWidget = _PremiumCardPopup(
          specialOffer: specialOffer,
          popupService: _popupService,
        );
        break;
        
      case PopupStyle.flashDeal:
        popupWidget = _FlashDealPopup(
          specialOffer: specialOffer,
          popupService: _popupService,
        );
        break;
        
      case PopupStyle.minimalist:
        popupWidget = _MinimalistPopup(
          specialOffer: specialOffer,
          popupService: _popupService,
        );
        break;
    }
    
    // All popups use bottom sheet format
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      isDismissible: true,
      builder: (context) => popupWidget,
    );
  }
  
  /// Navigate to wallet screen (shared function)
  static void _navigateToWallet(BuildContext context) {
    Navigator.pop(context);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final phoneNumber = currentUser?.phoneNumber ?? '';
    
    if (phoneNumber.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletScreen(
            phoneNumber: phoneNumber,
            isHost: false,
            showBackButton: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get user information. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ============================================================================
// POPUP #1: STARBURST BOTTOM SHEET (Existing Design)
// ============================================================================
class _StarburstPopup extends StatefulWidget {
  final String? specialOffer;
  final CoinPopupService popupService;
  
  const _StarburstPopup({
    this.specialOffer,
    required this.popupService,
  });

  @override
  State<_StarburstPopup> createState() => _StarburstPopupState();
}

class _StarburstPopupState extends State<_StarburstPopup> with TickerProviderStateMixin {
  final int discountPercent = 50;
  final int coins = 13000;
  final double originalPrice = 1499.00;
  final double discountedPrice = 999.00;

  late AnimationController _pulseController;
  late AnimationController _starburstController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _starburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starburstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeSize = 110.0;
    final isSmallScreen = screenHeight < 700; // Detect small screens
    
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.85 : screenHeight * 0.50,
              minHeight: 400,
            ),
            margin: EdgeInsets.only(top: badgeSize * 0.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D2D3A),
                  Color(0xFF1A1A24),
                  Colors.black,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: badgeSize * 0.55),
                    const Text(
                      'Exclusive Offer!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Make a new purchase and take advantage of this insane offer!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCoinDisplay(),
                    const SizedBox(height: 18),
                    _buildPriceDisplay(),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildPurchaseButton(),
                    const SizedBox(height: 8),
                    _buildLaterButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _buildStarburstBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarburstBadge() {
    const badgeColor = Color(0xFFE91E63);
    
    return AnimatedBuilder(
      animation: _starburstController,
      builder: (context, child) {
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(110, 110),
                painter: StarburstPainter(
                  rotation: _starburstController.value * 2 * math.pi,
                  color: badgeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '%$discountPercent',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.white.withOpacity(0.5),
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'discounted to',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFC107),
              Color(0xFFFFB300),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => CoinPurchasePopup._navigateToWallet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Purchase Coins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaterButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44), // Fixed: Changed from Size.zero to meet 44px minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Later',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================================
// POPUP #2: PREMIUM CARD (Same Layout as #1, Different Colors & Values)
// ============================================================================
class _PremiumCardPopup extends StatefulWidget {
  final String? specialOffer;
  final CoinPopupService popupService;
  
  const _PremiumCardPopup({
    this.specialOffer,
    required this.popupService,
  });

  @override
  State<_PremiumCardPopup> createState() => _PremiumCardPopupState();
}

class _PremiumCardPopupState extends State<_PremiumCardPopup> with TickerProviderStateMixin {
  // Different values for Popup #2
  final int discountPercent = 20;
  final int coins = 28000;
  final double originalPrice = 2499.00;
  final double discountedPrice = 1999.00;
  
  // Badge color - Purple/Pink gradient
  final Color badgeColor = const Color(0xFF9C27B0);

  late AnimationController _pulseController;
  late AnimationController _starburstController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _starburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starburstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeSize = 110.0;
    final isSmallScreen = screenHeight < 700; // Detect small screens
    
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.85 : screenHeight * 0.50,
              minHeight: 400,
            ),
            margin: EdgeInsets.only(top: badgeSize * 0.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D2D3A),
                  Color(0xFF1A1A24),
                  Colors.black,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: badgeSize * 0.55),
                    const Text(
                      'Exclusive Offer!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Make a new purchase and take advantage of this insane offer!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCoinDisplay(),
                    const SizedBox(height: 18),
                    _buildPriceDisplay(),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildPurchaseButton(),
                    const SizedBox(height: 8),
                    _buildLaterButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _buildStarburstBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarburstBadge() {
    return AnimatedBuilder(
      animation: _starburstController,
      builder: (context, child) {
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(110, 110),
                painter: StarburstPainter(
                  rotation: _starburstController.value * 2 * math.pi,
                  color: badgeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '%$discountPercent',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.white.withOpacity(0.5),
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'discounted to',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFC107),
              Color(0xFFFFB300),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => CoinPurchasePopup._navigateToWallet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Purchase Coins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaterButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44), // Fixed: Changed from Size.zero to meet 44px minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Later',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================================
// POPUP #3: FLASH DEAL (Same Layout as #1, Different Colors & Values)
// ============================================================================
class _FlashDealPopup extends StatefulWidget {
  final String? specialOffer;
  final CoinPopupService popupService;
  
  const _FlashDealPopup({
    this.specialOffer,
    required this.popupService,
  });

  @override
  State<_FlashDealPopup> createState() => _FlashDealPopupState();
}

class _FlashDealPopupState extends State<_FlashDealPopup> with TickerProviderStateMixin {
  // Different values for Popup #3
  final int discountPercent = 33;
  final int coins = 8000;
  final double originalPrice = 899.00;
  final double discountedPrice = 599.00;
  
  // Badge color - Cyan/Blue (keep this color)
  final Color badgeColor = const Color(0xFF00E5FF);

  late AnimationController _pulseController;
  late AnimationController _starburstController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _starburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starburstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeSize = 110.0;
    final isSmallScreen = screenHeight < 700; // Detect small screens
    
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.85 : screenHeight * 0.50,
              minHeight: 400,
            ),
            margin: EdgeInsets.only(top: badgeSize * 0.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D2D3A),
                  Color(0xFF1A1A24),
                  Colors.black,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: badgeSize * 0.55),
                    const Text(
                      'Exclusive Offer!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Make a new purchase and take advantage of this insane offer!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCoinDisplay(),
                    const SizedBox(height: 18),
                    _buildPriceDisplay(),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildPurchaseButton(),
                    const SizedBox(height: 8),
                    _buildLaterButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _buildStarburstBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarburstBadge() {
    return AnimatedBuilder(
      animation: _starburstController,
      builder: (context, child) {
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(110, 110),
                painter: StarburstPainter(
                  rotation: _starburstController.value * 2 * math.pi,
                  color: badgeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '%$discountPercent',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.white.withOpacity(0.5),
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'discounted to',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFC107),
              Color(0xFFFFB300),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => CoinPurchasePopup._navigateToWallet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Purchase Coins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaterButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44), // Fixed: Changed from Size.zero to meet 44px minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Later',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================================
// POPUP #4: MINIMALIST PREMIUM (Same Layout as #1, Different Colors & Values)
// ============================================================================
class _MinimalistPopup extends StatefulWidget {
  final String? specialOffer;
  final CoinPopupService popupService;
  
  const _MinimalistPopup({
    this.specialOffer,
    required this.popupService,
  });

  @override
  State<_MinimalistPopup> createState() => _MinimalistPopupState();
}

class _MinimalistPopupState extends State<_MinimalistPopup> with TickerProviderStateMixin {
  // Different values for Popup #4
  final int discountPercent = 20;
  final int coins = 50000;
  final double originalPrice = 3748.75; // Adjusted to maintain 20% discount with ₹2,999
  final double discountedPrice = 2999.00;
  
  // Badge color - Orange/Gold
  final Color badgeColor = const Color(0xFFFF9800);

  late AnimationController _pulseController;
  late AnimationController _starburstController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _starburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starburstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeSize = 110.0;
    final isSmallScreen = screenHeight < 700; // Detect small screens
    
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.85 : screenHeight * 0.50,
              minHeight: 400,
            ),
            margin: EdgeInsets.only(top: badgeSize * 0.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D2D3A),
                  Color(0xFF1A1A24),
                  Colors.black,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: badgeSize * 0.55),
                    const Text(
                      'Exclusive Offer!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Make a new purchase and take advantage of this insane offer!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCoinDisplay(),
                    const SizedBox(height: 18),
                    _buildPriceDisplay(),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildPurchaseButton(),
                    const SizedBox(height: 8),
                    _buildLaterButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _buildStarburstBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarburstBadge() {
    return AnimatedBuilder(
      animation: _starburstController,
      builder: (context, child) {
        return SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(110, 110),
                painter: StarburstPainter(
                  rotation: _starburstController.value * 2 * math.pi,
                  color: badgeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '%$discountPercent',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.white.withOpacity(0.5),
            decorationThickness: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'discounted to',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFC107),
              Color(0xFFFFB300),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => CoinPurchasePopup._navigateToWallet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Purchase Coins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaterButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44), // Fixed: Changed from Size.zero to meet 44px minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Later',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

// Starburst Painter (existing)
class StarburstPainter extends CustomPainter {
  final double rotation;
  final Color color;

  StarburstPainter({
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.80;
    final points = 11;

    final path = Path();
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    List<Offset> allPoints = [];
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      allPoints.add(Offset(x, y));
    }

    final roundness = 0.3;
    
    path.moveTo(allPoints[0].dx, allPoints[0].dy);

    for (int i = 0; i < allPoints.length; i++) {
      final current = allPoints[i];
      final next = allPoints[(i + 1) % allPoints.length];
      final afterNext = allPoints[(i + 2) % allPoints.length];
      
      final midX = current.dx + (next.dx - current.dx) * (1 - roundness);
      final midY = current.dy + (next.dy - current.dy) * (1 - roundness);
      
      final endX = next.dx + (afterNext.dx - next.dx) * roundness;
      final endY = next.dy + (afterNext.dy - next.dy) * roundness;
      
      path.lineTo(midX, midY);
      path.quadraticBezierTo(next.dx, next.dy, endX, endY);
    }
    
    path.close();

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, shadowPaint);

    final gradient = RadialGradient(
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: outerRadius),
      );
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(StarburstPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

