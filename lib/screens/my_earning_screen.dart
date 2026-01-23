import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'contact_support_screen.dart';
import 'transaction_history_screen.dart';
import '../services/gift_service.dart';
import '../services/withdrawal_service.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../models/gift_model.dart' show GiftModel;

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Real-time earnings data (C Coins)
  int totalCCoins = 0; // Host's C Coins balance
  double availableBalance = 0.00; // Withdrawable amount in INR
  final double withdrawnAmount = 0.00; // Amount already withdrawn
  static const double _coinToInrRate = 0.04; // 1 C Coin = ₹0.04
  static const double _minWithdrawalINR = 20.00; // Minimum ₹20 to withdraw (500 C Coins * 0.04)
  
  // Stats for quick cards (now calculated in real-time via StreamBuilder)
  int todayEarnings = 0;
  int weekEarnings = 0;
  int monthEarnings = 0;
  
  // Previous period earnings for trend calculation
  int previousWeekEarnings = 0;
  int previousMonthEarnings = 0;
  
  bool _isProcessing = false;
  bool _isLoading = true;
  String _selectedMethod = 'UPI'; // Default withdrawal method
  
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
  
  /// Calculate earnings for Today, Week, Month from gifts list
  /// This is now called from StreamBuilder for real-time updates
  Map<String, int> _calculatePeriodEarningsFromGifts(List<GiftModel> gifts) {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      
      int today = 0;
      int week = 0;
      int month = 0;
      
      for (var gift in gifts) {
        if (gift.timestamp == null) continue;
        final giftDate = gift.timestamp!;
        final cCoins = gift.cCoinsEarned ?? 0;
        
        if (giftDate.isAfter(todayStart)) {
          today += cCoins;
        }
        if (giftDate.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
          week += cCoins;
        }
        if (giftDate.isAfter(monthStart)) {
          month += cCoins;
        }
      }
      
      return {
        'today': today,
        'week': week,
        'month': month,
      };
    } catch (e) {
      debugPrint('Error calculating period earnings: $e');
      return {'today': 0, 'week': 0, 'month': 0};
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

  // Helper method to build AppBar
  PreferredSizeWidget _buildAppBar({bool showActions = true}) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.myEarning,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: showActions
          ? [
              // History/Details Icon - Navigate to Transaction History
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _navigateToTransactionHistory,
                tooltip: 'Transaction History',
              ),
              // Contact Support Icon
              IconButton(
                icon: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactSupportScreen(),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error navigating to contact support: $e');
                  }
                },
                tooltip: 'Contact Support',
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
      border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
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
            color: Color(0xFFFF1B7C),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadEarningsData,
        color: const Color(0xFFFF1B7C),
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earning Overview Card (Enhanced)
              _buildEarningOverview(),
              
              const SizedBox(height: 20),
              
              // Quick Stats Cards
              _buildQuickStatsCards(),
              
              const SizedBox(height: 20),
              
              // Withdrawal Section
              _buildWithdrawalSection(),
              
              const SizedBox(height: 20),
              
              // Recent Transactions Preview
              _buildRecentTransactions(),
              
              const SizedBox(height: 20),
              
              // Trust Badges Section
              _buildTrustBadges(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ========== EARNING OVERVIEW ==========
  Widget _buildEarningOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1B7C).withOpacity(0.3),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          if (weekEarnings > 0 && previousWeekEarnings > 0) ...[
                            const SizedBox(width: 8),
                            _buildTrendIndicator(weekEarnings, previousWeekEarnings),
                          ],
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
                          
                          // Balance number (Animated)
                          Flexible(
                            child: Text(
                              _displayedBalance.toString(),
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

  // ========== QUICK STATS CARDS ==========
  Widget _buildQuickStatsCards() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Use StreamBuilder for real-time period earnings updates
    return StreamBuilder<List<GiftModel>>(
      stream: _giftService.getHostReceivedGifts(currentUser.uid),
      builder: (context, snapshot) {
        // Calculate period earnings from current gifts snapshot
        final periodEarnings = snapshot.hasData
            ? _calculatePeriodEarningsFromGifts(snapshot.data!)
            : {'today': todayEarnings, 'week': weekEarnings, 'month': monthEarnings};

        // Update state variables for backward compatibility
        if (snapshot.hasData && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                todayEarnings = periodEarnings['today'] ?? 0;
                weekEarnings = periodEarnings['week'] ?? 0;
                monthEarnings = periodEarnings['month'] ?? 0;
              });
            }
          });
        }

        // Update previous values for trend calculation
        if (snapshot.hasData && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                previousWeekEarnings = weekEarnings;
                previousMonthEarnings = monthEarnings;
              });
            }
          });
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Today',
                value: periodEarnings['today'] ?? 0,
                icon: Icons.today,
                color: const Color(0xFFFF69B4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'This Week',
                value: periodEarnings['week'] ?? 0,
                icon: Icons.date_range,
                color: const Color(0xFFFF1B7C),
                previousValue: previousWeekEarnings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'This Month',
                value: periodEarnings['month'] ?? 0,
                icon: Icons.calendar_month,
                color: const Color(0xFFE91E63),
                previousValue: previousMonthEarnings,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    int? previousValue,
  }) {
    // Calculate percentage change if previous value exists
    double? percentageChange;
    if (previousValue != null && previousValue > 0) {
      percentageChange = ((value - previousValue) / previousValue) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (percentageChange != null)
                _buildTrendBadge(percentageChange),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.monetization_on, size: 16, color: color);
                },
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build trend indicator
  Widget _buildTrendIndicator(int current, int previous) {
    if (previous == 0) return const SizedBox.shrink();
    final change = ((current - previous) / previous) * 100;
    final isPositive = change >= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build trend badge for stat cards
  Widget _buildTrendBadge(double percentageChange) {
    final isPositive = percentageChange >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== RECENT TRANSACTIONS PREVIEW ==========
  Widget _buildRecentTransactions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getWhiteContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 16,
                      color: Color(0xFFFF1B7C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Recent Earnings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToTransactionHistory,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF1B7C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<GiftModel>>(
            stream: _giftService.getHostReceivedGifts(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1B7C).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: const Color(0xFFFF1B7C).withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent earnings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your earnings will appear here',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final recentGifts = snapshot.data!.take(5).toList();

              return Column(
                children: recentGifts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final gift = entry.value;
                  final isLast = index == recentGifts.length - 1;

                  return _buildTransactionPreviewItem(gift, isLast);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionPreviewItem(GiftModel gift, bool isLast) {
    final cCoins = gift.cCoinsEarned ?? 0;
    final timestamp = gift.timestamp;
    final senderName = gift.senderName ?? 'Anonymous';

    String timeAgo = 'Just now';
    if (timestamp != null) {
      final now = DateTime.now();
      final diff = now.difference(timestamp);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      }
    }

    return Column(
      children: [
        InkWell(
          onTap: () => _navigateToTransactionHistory(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF1B7C).withOpacity(0.15),
                        const Color(0xFFFF69B4).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    size: 18,
                    color: Color(0xFFFF1B7C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1B7C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/coin3.png',
                        width: 14,
                        height: 14,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.monetization_on, size: 14, color: const Color(0xFFFF1B7C));
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$cCoins',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF1B7C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ========== WITHDRAWAL SECTION ==========
  Widget _buildWithdrawalSection() {
    return Container(
      key: _withdrawalSectionKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _getWhiteContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF1B7C).withOpacity(0.15),
                      const Color(0xFFFF69B4).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/images/coin2.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.monetization_on, size: 20, color: Color(0xFFFF1B7C));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.withdrawMoney,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Withdrawal Method Selection
                Text(
                  AppLocalizations.of(context)!.withdrawalMethod,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMethod,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF1B7C)),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _withdrawalMethods.map((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                method == 'UPI'
                                    ? Icons.account_balance
                                    : method == AppLocalizations.of(context)!.crypto
                                        ? Icons.currency_bitcoin
                                        : Icons.account_balance_outlined,
                                size: 18,
                                color: const Color(0xFFFF1B7C),
                              ),
                              const SizedBox(width: 8),
                              Text(method),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMethod = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Amount Field
                Text(
                  AppLocalizations.of(context)!.amount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterAmount,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/money.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                    suffixText: '₹',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterAmount;
                    }
                    final amountInINR = double.tryParse(value);
                    if (amountInINR == null || amountInINR <= 0) {
                      return AppLocalizations.of(context)!.enterValidAmount;
                    }
                    // Validate minimum withdrawal amount (₹20)
                    if (amountInINR < _minWithdrawalINR) {
                      return 'Minimum withdrawal amount is ₹${_minWithdrawalINR.toStringAsFixed(2)}';
                    }
                    // Validate against available balance (in INR)
                    if (amountInINR > availableBalance) {
                      return 'Amount exceeds available balance. Maximum: ₹${availableBalance.toStringAsFixed(2)}';
                    }
                    // Convert INR to C Coins and validate against total C Coins
                    final amountInCCoins = (amountInINR / _coinToInrRate).round();
                    if (amountInCCoins > totalCCoins) {
                      return 'Insufficient balance. Maximum: ₹${availableBalance.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Dynamic fields based on withdrawal method
                if (_selectedMethod == 'UPI') ..._buildUPIFields(),
                if (_selectedMethod == AppLocalizations.of(context)!.bankTransfer) ..._buildBankFields(),
                if (_selectedMethod == AppLocalizations.of(context)!.crypto) ..._buildCryptoFields(),
                
                const SizedBox(height: 20),
                
                // Withdraw Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isProcessing
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                            ),
                      borderRadius: BorderRadius.circular(10),
                      color: _isProcessing ? Colors.grey[400] : null,
                      boxShadow: _isProcessing
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFFFF1B7C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
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
                        : Text(
                            AppLocalizations.of(context)!.withdraw,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== TRUST BADGES SECTION ==========
  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                  child: Icon(Icons.info_outline, size: 16, color: const Color(0xFFFF1B7C).withOpacity(0.8)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Minimum ₹20 required for withdraw (500 C Coins)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF1B7C).withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
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
          padding: const EdgeInsets.all(12),
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
            size: 24,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
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
      const SizedBox(height: 6),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
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
      const SizedBox(height: 6),
      TextFormField(
        controller: _accountHolderController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterAccountHolderName,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.person_outline, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.pleaseEnterAccountHolderName;
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      
      // Account Number
      Text(
        AppLocalizations.of(context)!.accountNumber,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 6),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
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
      const SizedBox(height: 12),
      
      // IFSC Code
      Text(
        AppLocalizations.of(context)!.ifscCode,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 6),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
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
      const SizedBox(height: 6),
      TextFormField(
        controller: _cryptoAddressController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.enterWalletAddress,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.currency_bitcoin, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
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
        ScaffoldMessenger.of(context).showSnackBar(
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
      
      try {
        // Prepare payment details based on selected method
        Map<String, dynamic> paymentDetails = {};
        
        if (_selectedMethod == 'UPI') {
          paymentDetails = {'upiId': _upiController.text.trim()};
        } else if (_selectedMethod == AppLocalizations.of(context)!.bankTransfer) {
          paymentDetails = {
            'accountHolderName': _accountHolderController.text.trim(),
            'accountNumber': _accountNumberController.text.trim(),
            'ifscCode': _ifscController.text.trim(),
          };
        } else if (_selectedMethod == AppLocalizations.of(context)!.crypto) {
          paymentDetails = {'walletAddress': _cryptoAddressController.text.trim()};
        }

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
          withdrawalMethod: _selectedMethod,
          paymentDetails: paymentDetails,
          userName: userName,
          displayId: displayId,
        );
        
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          if (requestId != null) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
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
                backgroundColor: const Color(0xFFFF1B7C),
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
            _upiController.clear();
            _accountNumberController.clear();
            _ifscController.clear();
            _accountHolderController.clear();
            _cryptoAddressController.clear();
            _loadEarningsData(); // Refresh earnings data
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
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

