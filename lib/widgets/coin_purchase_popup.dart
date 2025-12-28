import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import '../services/coin_popup_service.dart';
import '../screens/payment_screen.dart';

/// Beautiful coin purchase popup with bottom sheet design matching the exclusive offer style
class CoinPurchasePopup {
  final CoinPopupService _popupService = CoinPopupService();
  
  // Check if in test mode
  bool get isTestMode => CoinPopupService.TEST_MODE;
  
  /// Show the coin purchase dialog as bottom sheet
  Future<void> show(BuildContext context, {String? specialOffer}) async {
    // Record that popup was shown
    await _popupService.recordPopupShown();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _CoinPurchaseBottomSheet(
        specialOffer: specialOffer,
        popupService: _popupService,
      ),
    );
  }
}

class _CoinPurchaseBottomSheet extends StatefulWidget {
  final String? specialOffer;
  final CoinPopupService popupService;
  
  const _CoinPurchaseBottomSheet({
    this.specialOffer,
    required this.popupService,
  });

  @override
  State<_CoinPurchaseBottomSheet> createState() => _CoinPurchaseBottomSheetState();
}

class _CoinPurchaseBottomSheetState extends State<_CoinPurchaseBottomSheet> with TickerProviderStateMixin {
  // Featured offer - can be customized
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
    final badgeSize = 110.0; // Starburst badge size
    
    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main popup container
          Container(
            height: screenHeight * 0.50, // 50% of screen height
            margin: EdgeInsets.only(top: badgeSize * 0.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2D2D3A),
                  const Color(0xFF1A1A24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Space for the badge that overlaps
                  SizedBox(height: badgeSize * 0.55),
                  
                  // Title
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
                  
                  // Subtitle
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
                  
                  // Coin Display
                  _buildCoinDisplay(),
                  
                  const SizedBox(height: 18),
                  
                  // Price Display
                  _buildPriceDisplay(),
                  
                  const Spacer(),
                  
                  // Purchase Button
                  _buildPurchaseButton(),
                  
                  const SizedBox(height: 8),
                  
                  // Later Button
                  _buildLaterButton(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Starburst Sale Badge - 50% outside popup
          Positioned(
            top: 0,
            child: _buildStarburstBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarburstBadge() {
    // Consistent pink color for badge
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
              // Outer glow
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
              // Starburst shape only
              CustomPaint(
                size: const Size(110, 110),
                painter: StarburstPainter(
                  rotation: _starburstController.value * 2 * math.pi,
                  color: badgeColor,
                ),
              ),
              // Text directly on starburst (no inner circle)
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
              // Gold coin image (same as wallet grid)
              Image.asset(
                'assets/images/coin3.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              // Coin amount
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
        // Original price (crossed out)
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
        // "discounted to" text
        Text(
          'discounted to',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        // Discounted price
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
          onPressed: () {
            Navigator.pop(context);
            final String packageId = 'exclusive_${coins}_${discountedPrice.toInt()}';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  coins: coins,
                  amount: discountedPrice.toInt(),
                  packageId: packageId,
                ),
              ),
            );
          },
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
        minimumSize: Size.zero,
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

// Custom painter for the starburst shape with rounded corners
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
    final points = 11; // 11 corners

    final path = Path();
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Calculate all points first
    List<Offset> allPoints = [];
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      allPoints.add(Offset(x, y));
    }

    // Draw rounded starburst using quadratic bezier curves
    final roundness = 0.3; // Controls how rounded the corners are
    
    path.moveTo(
      allPoints[0].dx,
      allPoints[0].dy,
    );

    for (int i = 0; i < allPoints.length; i++) {
      final current = allPoints[i];
      final next = allPoints[(i + 1) % allPoints.length];
      final afterNext = allPoints[(i + 2) % allPoints.length];
      
      // Calculate control point for smooth curve
      final midX = current.dx + (next.dx - current.dx) * (1 - roundness);
      final midY = current.dy + (next.dy - current.dy) * (1 - roundness);
      
      final endX = next.dx + (afterNext.dx - next.dx) * roundness;
      final endY = next.dy + (afterNext.dy - next.dy) * roundness;
      
      path.lineTo(midX, midY);
      path.quadraticBezierTo(next.dx, next.dy, endX, endY);
    }
    
    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, shadowPaint);

    // Draw gradient fill
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
