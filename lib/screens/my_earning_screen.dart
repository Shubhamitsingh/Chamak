import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'transaction_history_screen.dart';
import '../services/gift_service.dart';
import '../services/withdrawal_service.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../services/payment_method_service.dart';
import '../models/payment_method_model.dart';
import '../widgets/payment_method_card.dart';
import 'add_payment_method_screen.dart';

class MyEarningScreen extends StatefulWidget {
  final String phoneNumber;
  
  const MyEarningScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<MyEarningScreen> createState() => _MyEarningScreenState();
}

class _MyEarningScreenState extends State<MyEarningScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _cryptoAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _withdrawalSectionKey = GlobalKey();
  final GiftService _giftService = GiftService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final DatabaseService _databaseService = DatabaseService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Real-time earnings data (C Coins)
  int totalCCoins = 0; // Host's C Coins balance
  double availableBalance = 0.00; // Withdrawable amount in INR
  final double withdrawnAmount = 0.00; // Amount already withdrawn
  static const double _coinToInrRate = 0.04; // 1 C Coin = ₹0.04
  static const double _minWithdrawalINR = 20.00; // Minimum ₹20 to withdraw (500 C Coins * 0.04)
  
  
  bool _isProcessing = false;
  bool _isLoading = false; // Start with false to show content immediately
  PaymentMethodModel? _selectedPaymentMethod; // Selected saved payment method
  
  // Animation controller for balance
  int _displayedBalance = 0;
  
  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  /// Load host earnings data from Firebase
  Future<void> _loadEarningsData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      final summary = await _giftService.getHostEarningsSummary(currentUser.uid);
      
      if (mounted) {
        final newTotal = summary['totalCCoins'] ?? 0;
        setState(() {
          totalCCoins = newTotal;
          _displayedBalance = newTotal;
          availableBalance = summary['withdrawableAmount'] ?? 0.0;
          _isLoading = false;
        });
        // Animate balance counter
        _animateBalance(newTotal);
      }
      // Note: Period earnings now calculated in real-time via StreamBuilder in _buildQuickStatsCards()
    } catch (e) {
      debugPrint('Error loading earnings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Animate balance counter
  void _animateBalance(int target) {
    if (_displayedBalance == target) return;
    
    final duration = Duration(milliseconds: 800);
    final steps = 30;
    final stepValue = (target - _displayedBalance) / steps;
    
    int currentStep = 0;
    Timer.periodic(Duration(milliseconds: duration.inMilliseconds ~/ steps), (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _displayedBalance = (_displayedBalance + stepValue).round().clamp(0, target);
        });
      }
      if (currentStep >= steps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _displayedBalance = target;
          });
        }
      }
    });
  }

  /// Format balance with Indian numbering system (K/L/Cr)
  /// Returns abbreviated format for display
  String _formatBalance(int number) {
    if (number >= 10000000) {
      // Crore (1 Crore = 1,00,00,000)
      final crores = number / 10000000;
      return crores >= 100 
        ? '${crores.toStringAsFixed(0)}Cr'  // 100Cr, 500Cr
        : '${crores.toStringAsFixed(2)}Cr';  // 12.50Cr, 99.99Cr
    } else if (number >= 100000) {
      // Lakh (1 Lakh = 1,00,000)
      final lakhs = number / 100000;
      return lakhs >= 100
        ? '${lakhs.toStringAsFixed(0)}L'     // 100L, 500L
        : '${lakhs.toStringAsFixed(2)}L';    // 12.50L, 99.99L
    } else if (number >= 1000) {
      // Thousand
      final thousands = number / 1000;
      return '${thousands.toStringAsFixed(1)}K';  // 1.2K, 99.9K
    }
    return number.toString();  // 0-999: Show exact
  }

  /// Format number with Indian comma system (e.g., 12,50,000)
  /// Indian numbering: First 3 digits from right, then groups of 2
  String _formatExactNumber(int number) {
    final numberStr = number.toString();
    if (numberStr.length <= 3) {
      return numberStr;
    }
    
    // Indian numbering: First 3 digits from right, then groups of 2
    String result = '';
    final digits = numberStr.split('');
    final length = digits.length;
    
    // Process from right to left
    for (int i = length - 1; i >= 0; i--) {
      final positionFromRight = length - 1 - i;
      
      // Add comma after first 3 digits, then every 2 digits
      if (positionFromRight == 3) {
        result = ',' + result;
      } else if (positionFromRight > 3 && (positionFromRight - 3) % 2 == 0) {
        result = ',' + result;
      }
      
      result = digits[i] + result;
    }
    
    return result;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _cryptoAddressController.dispose();
    super.dispose();
  }
  
  List<String> get _withdrawalMethods => [
    'UPI',
    AppLocalizations.of(context)!.bankTransfer,
    AppLocalizations.of(context)!.crypto,
  ];

  // Helper method to navigate to transaction history
  void _navigateToTransactionHistory() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionHistoryScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to transaction history: $e');
    }
  }

  // Helper method to build AppBar - Pink theme like reference image
  PreferredSizeWidget _buildAppBar({bool showActions = true}) {
    return AppBar(
      backgroundColor: const Color(0xFFFF1B7C), // Pink color like reference
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Cash Out',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: showActions
          ? [
              // Clock icon for history - like reference image
              IconButton(
                icon: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _navigateToTransactionHistory,
                tooltip: 'Transaction History',
              ),
            ]
          : null,
    );
  }

  // Helper method for white container decoration
  BoxDecoration _getWhiteContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(showActions: false),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadEarningsData,
        color: const Color(0xFFFF1B7C),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stack for card inside pink container
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Pink Header Section with Available Coins
                  _buildPinkHeaderSection(),
                  
                  // White Conversion Card (inside pink container)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: null,
                    bottom: 16, // Inside the pink container
                    child: _buildConversionCard(),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Cash Out Section (With Saved Payment Methods)
              _buildWithdrawalSection(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PINK HEADER SECTION (Like Reference Image) ==========
  Widget _buildPinkHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      decoration: const BoxDecoration(
        color: Color(0xFFFF1B7C), // Pink background
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // "Available Coins" label - centered
          Text(
            'Available Coins',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
              const SizedBox(height: 12),
          // Large coin balance - scale down font when number is long so it fits
          LayoutBuilder(
            builder: (context, constraints) {
              final text = _formatExactNumber(_displayedBalance);
              final digitCount = text.replaceAll(',', '').length;
              // Cap font size: smaller when more digits (e.g. 52 -> 40 -> 28 -> 20)
              double fontSize = 52;
              if (digitCount > 10) {
                fontSize = 20;
              } else if (digitCount > 8) {
                fontSize = 28;
              } else if (digitCount > 6) {
                fontSize = 36;
              } else if (digitCount > 5) {
                fontSize = 42;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== CONVERSION CARD (White Card Overlapping) ==========
  Widget _buildConversionCard() {
    // 1 Lakh C Coins = ₹450 (display in INR)
    const oneLakhCoins = 100000;
    const oneLakhINR = 450; // 1,00,000 coins = ₹450
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(3),
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: const Color(0xFFFF1B7C).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Star icon + Conversion rate (USD)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Coin icon (coin2.png)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/images/coin2.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Color(0xFFFF9800), size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '1,00,000 Coin = ₹$oneLakhINR',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Withdraw button
          ElevatedButton(
            onPressed: () {
              // Quick withdraw action - can open withdrawal form
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Withdraw',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== WITHDRAWAL INPUT SECTION ==========
  Widget _buildWithdrawalInputSection() {
    // Calculate USD equivalent using same rate as conversion card
    // 1000 coins = $0.05, so 1 coin = $0.00005
    final usdRatePerCoin = 0.05 / 1000;
    double usdEquivalent = 0.0;
    if (_amountController.text.isNotEmpty) {
      final coinAmount = int.tryParse(_amountController.text) ?? 0;
      usdEquivalent = coinAmount * usdRatePerCoin;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Enter Amount" label
          const Text(
            'Enter Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
              const SizedBox(height: 12),
              
          // Input field with USD equivalent
          Row(
            children: [
              // Input field
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {}); // Update USD equivalent
                  },
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter withdraw Coin',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Equals sign
              const Text(
                '=',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // USD equivalent box
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$ ${usdEquivalent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
              
          const SizedBox(height: 8),
          
          // Minimum withdraw message
          Text(
            'Minimum Withdraw ${(_minWithdrawalINR / _coinToInrRate).round()} Coin',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
          ),
        ),
        ],
      ),
    );
  }

  // ========== EARNING OVERVIEW (OLD - Keep for reference) ==========
  Widget _buildEarningOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha:0.15),
                    Colors.white.withValues(alpha:0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha:0.1),
                    Colors.white.withValues(alpha:0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha:0.08),
              ),
            ),
          ),
          
          // Wallet Icon - Top Right
          Positioned(
            top: 16,
            right: 16,
            child: Image.asset(
              'assets/images/wallet.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with trend indicator
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.totalEarning,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Coin icon + Balance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Coin image
                          Image.asset(
                            'assets/images/coin2.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.monetization_on, color: Colors.white, size: 32);
                            },
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Balance number (Animated) - full digits
                          Flexible(
                            child: Text(
                              _formatExactNumber(_displayedBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Available Balance + Progress Indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '≈ ₹${availableBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Progress bar for withdrawal threshold
                          // Calculate min withdrawal in C Coins (₹20 = 500 C Coins)
                          Builder(
                            builder: (context) {
                              final minWithdrawalCCoins = (_minWithdrawalINR / _coinToInrRate).round();
                              if (totalCCoins < minWithdrawalCCoins) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 3,
                                      constraints: const BoxConstraints(maxWidth: 180),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (totalCCoins / minWithdrawalCCoins).clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₹${(_minWithdrawalINR - (totalCCoins * _coinToInrRate)).toStringAsFixed(2)} until withdrawal',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 8,
                                fontWeight: FontWeight.w400,
                              ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '✓ Ready to withdraw',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ========== CASH OUT SECTION (With Saved Payment Methods) ==========
  Widget _buildWithdrawalSection() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<PaymentMethodModel>>(
      stream: _paymentMethodService.getUserPaymentMethods(currentUser.uid),
      builder: (context, snapshot) {
        // Only show loading indicator on initial load, not on rebuilds
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            key: _withdrawalSectionKey,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFFFF1B7C),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyPaymentMethods();
        }

        return Builder(
          key: _withdrawalSectionKey,
          builder: (context) {
            final paymentMethods = snapshot.data!;
            
            // Set default selected method if not set
            if (_selectedPaymentMethod == null && paymentMethods.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final defaultMethod = paymentMethods.firstWhere(
                  (m) => m.isDefault,
                  orElse: () => paymentMethods.first,
                );
                setState(() {
                  _selectedPaymentMethod = defaultMethod;
                });
              });
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Title: Cash Out
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1B7C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFFFF1B7C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Cash Out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Methods List
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Payment Method Cards
                  ...paymentMethods.map((method) => PaymentMethodCard(
                    method: method,
                    isSelected: _selectedPaymentMethod?.id == method.id,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                    },
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPaymentMethodScreen(
                            existingMethod: method,
                          ),
                        ),
                      );
                      if (result == true) {
                        // Refresh payment methods
                      }
                    },
                  )),
                  
                  const SizedBox(height: 8),
                  
                  // Add New Payment Method Button
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPaymentMethodScreen(),
                        ),
                      );
                      if (result == true) {
                        // Payment method added, will auto-refresh via StreamBuilder
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF1B7C),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFFF1B7C),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Add New Payment Method',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF1B7C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Amount Field
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter withdraw amount',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFFFF1B7C)),
                      suffixText: '₹',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amountInINR = double.tryParse(value);
                      if (amountInINR == null || amountInINR <= 0) {
                        return 'Please enter a valid amount';
                      }
                      if (amountInINR < _minWithdrawalINR) {
                        return 'Minimum withdrawal amount is ₹${_minWithdrawalINR.toStringAsFixed(2)}';
                      }
                      if (amountInINR > availableBalance) {
                        return 'Amount exceeds available balance. Maximum: ₹${availableBalance.toStringAsFixed(2)}';
                      }
                      final amountInCCoins = (amountInINR / _coinToInrRate).round();
                      if (amountInCCoins > totalCCoins) {
                        return 'Insufficient balance. Maximum: ₹${availableBalance.toStringAsFixed(2)}';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Minimum withdraw message
                  Text(
                    'Minimum Withdraw ${(_minWithdrawalINR / _coinToInrRate).round()} Coin',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Cash Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_selectedPaymentMethod == null || _isProcessing)
                          ? null
                          : _handleWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1B7C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Cash Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Withdrawal requests are processed within 24-48 hours',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Empty state when no payment methods
  Widget _buildEmptyPaymentMethods() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          const Text(
            'No Payment Method Added',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a payment method to start\nwithdrawing your earnings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPaymentMethodScreen(),
                ),
              );
              if (result == true) {
                // Payment method added
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add Payment Method',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1B7C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== TRUST BADGES SECTION ==========
  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: _getWhiteContainerDecoration(),
      child: Column(
        children: [
          // Minimum withdrawal text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.info_outline, size: 16, color: const Color(0xFF4CAF50).withOpacity(0.8)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Minimum ₹20 required for withdraw (500 C Coins)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32).withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Trust badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Secure Payment - Shield with person
              Expanded(
                child: _buildTrustBadge(
                  icon: Icons.security,
                  text: 'Secure Payment',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Payments - Wallet
              Expanded(
                child: _buildTrustBadge(
                  icon: Icons.account_balance_wallet,
                  text: '₹20 Lacs+ Payments',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Trusted Users - Multiple people
              Expanded(
                child: _buildTrustBadge(
                  icon: Icons.people,
                  text: '50 k+ Trusted Users',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String text,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ========== UPI FIELDS ==========
  List<Widget> _buildUPIFields() {
    return [
      Text(
        AppLocalizations.of(context)!.upiId,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: _upiController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterUpiId,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.account_balance, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterUpiId;
          }
          if (!value.contains('@')) {
            return AppLocalizations.of(context)!.enterValidUpiId;
          }
          return null;
        },
      ),
    ];
  }
  
  // ========== BANK TRANSFER FIELDS ==========
  List<Widget> _buildBankFields() {
    return [
      // Account Holder Name
      Text(
        AppLocalizations.of(context)!.accountHolderName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: _accountHolderController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterAccountHolderName,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.person_outline, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterAccountHolderName;
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      
      // Account Number
      Text(
        AppLocalizations.of(context)!.accountNumber,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: _accountNumberController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterAccountNumber,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.credit_card, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterAccountNumber;
          }
          if (value.length < 9 || value.length > 18) {
            return AppLocalizations.of(context)!.enterValidAccountNumber;
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      
      // IFSC Code
      Text(
        AppLocalizations.of(context)!.ifscCode,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: _ifscController,
        style: const TextStyle(fontSize: 13),
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterIfscCode,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.business, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterIfscCode;
          }
          if (value.length != 11) {
            return AppLocalizations.of(context)!.enterValidIfscCode;
          }
          return null;
        },
      ),
    ];
  }
  
  // ========== CRYPTO FIELDS ==========
  List<Widget> _buildCryptoFields() {
    return [
      Text(
        AppLocalizations.of(context)!.walletAddress,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: _cryptoAddressController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterWalletAddress,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.currency_bitcoin, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterWalletAddress;
          }
          if (value.length < 26) {
            return AppLocalizations.of(context)!.enterValidWalletAddress;
          }
          return null;
        },
      ),
    ];
  }

  // ========== HANDLE WITHDRAWAL ==========
  void _handleWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Please login again'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _isProcessing = true;
      });
      
      // Check if payment method is selected
      if (_selectedPaymentMethod == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Please select a payment method'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Use payment details from selected saved method
        final paymentDetails = _selectedPaymentMethod!.details;
        final withdrawalMethod = _selectedPaymentMethod!.type == 'BANK'
            ? AppLocalizations.of(context)!.bankTransfer
            : _selectedPaymentMethod!.type == 'CRYPTO'
                ? AppLocalizations.of(context)!.crypto
                : 'UPI';

        // Get amount in INR from controller
        final amountInINR = double.tryParse(_amountController.text.trim()) ?? 0.0;
        
        // Get user information to store with withdrawal request
        String? userName;
        String? displayId;
        try {
          final userData = await _databaseService.getUserData(currentUser.uid);
          if (userData != null) {
            userName = userData.displayName ?? 'Unknown Host';
            displayId = IdGeneratorService.getDisplayId(userData.numericUserId);
          }
        } catch (e) {
          debugPrint('Error fetching user data: $e');
          // Continue with null values if fetch fails
        }
        
        // Submit withdrawal request with host information
        // Store INR amount directly (payment amount) - NOT C Coins
        // Admin can see pending payment amount clearly
        final requestId = await _withdrawalService.submitWithdrawalRequest(
          userId: currentUser.uid,
          amount: amountInINR, // Store INR directly (payment amount)
          withdrawalMethod: withdrawalMethod,
          paymentDetails: paymentDetails,
          userName: userName,
          displayId: displayId,
        );
        
        // Update last used timestamp for payment method
        if (_selectedPaymentMethod != null) {
          await _paymentMethodService.updateLastUsed(
            userId: currentUser.uid,
            methodId: _selectedPaymentMethod!.id,
          );
        }
        
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          if (requestId != null) {
            // Show success message
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.withdrawalRequestSubmitted,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Clear form
            _amountController.clear();
            _loadEarningsData(); // Refresh earnings data
          } else {
            // Show error message
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Failed to submit withdrawal request. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error submitting withdrawal: $e');
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

