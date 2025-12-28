import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../screens/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Beautiful low coin popup with animations matching coin purchase popup style
class LowCoinPopup {
  /// Show the low coin popup as bottom sheet
  static Future<void> show(
    BuildContext context, {
    required int currentBalance,
    required int requiredCoins,
    String? phoneNumber,
  }) async {
    final shortfall = requiredCoins - currentBalance;
    final percentage = (currentBalance / requiredCoins * 100).clamp(0.0, 100.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _LowCoinBottomSheet(
        currentBalance: currentBalance,
        requiredCoins: requiredCoins,
        shortfall: shortfall,
        percentage: percentage,
        phoneNumber: phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
      ),
    );
  }
}

class _LowCoinBottomSheet extends StatefulWidget {
  final int currentBalance;
  final int requiredCoins;
  final int shortfall;
  final double percentage;
  final String phoneNumber;

  const _LowCoinBottomSheet({
    required this.currentBalance,
    required this.requiredCoins,
    required this.shortfall,
    required this.percentage,
    required this.phoneNumber,
  });

  @override
  State<_LowCoinBottomSheet> createState() => _LowCoinBottomSheetState();
}

class _LowCoinBottomSheetState extends State<_LowCoinBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for coin icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _navigateToWallet() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletScreen(
          phoneNumber: widget.phoneNumber,
          isHost: false,
          showBackButton: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        height: screenHeight * 0.40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D2D3A),
              Color(0xFF1A1A24),
              Colors.black,
            ],
          ),
          borderRadius: BorderRadius.only(
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

              const SizedBox(height: 14),

              // Title
              Text(
                'Low Balance Alert',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 5),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'You don\'t have enough coins to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Balance Display
              _buildBalanceDisplay(),

              const SizedBox(height: 12),

              // Progress Bar
              _buildProgressBar(),

              const Spacer(),

              // Add Coins Button
              _buildAddCoinsButton(),

              const SizedBox(height: 5),

              // Later Button
              _buildLaterButton(),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.03);
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/coin3.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.currentBalance} coins',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFC107),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.requiredCoins} coins',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final progressAnimation = Tween<double>(begin: 0.0, end: widget.percentage / 100)
        .animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                '${widget.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              return Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.5),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.5),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE91E63),
                          Color(0xFFC2185B),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddCoinsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: LinearGradient(
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
              color: Color(0xFFFFC107).withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToWallet,
            borderRadius: BorderRadius.circular(23),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                'Add Coins',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
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
          fontSize: 12,
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}


















