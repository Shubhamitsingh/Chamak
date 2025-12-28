import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'contact_support_screen.dart';
import '../services/database_service.dart';
import '../services/gift_service.dart';
import '../services/coin_service.dart';
import 'payment_screen.dart';

class WalletScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isHost;
  final bool showBackButton; // Control back button visibility
  
  const WalletScreen({
    super.key,
    required this.phoneNumber,
    this.isHost = false,
    this.showBackButton = true, // Default: show back button
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final GiftService _giftService = GiftService();
  final CoinService _coinService = CoinService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Real coin data - fetched from Firestore
  int coinBalance = 0; // U Coins (User Coins)
  double hostEarnings = 0.0; // C Coins converted to real money
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _walletSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _listenersSetup = false; // Track if listeners are set up
  
  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // Recharge packages - 9 options
  final List<Map<String, dynamic>> rechargePackages = [
    {'coins': 1100, 'inr': 99, 'bonus': 10, 'badge': 'Popular Choice'},
    {'coins': 3500, 'inr': 299, 'bonus': 17, 'badge': 'Great Value'},
    {'coins': 7500, 'inr': 599, 'bonus': 25, 'badge': 'Best Value'},
    {'coins': 13000, 'inr': 999, 'bonus': 30, 'badge': 'VIP Choice'},
    {'coins': 28000, 'inr': 1999, 'bonus': 40, 'badge': 'Most Popular'},
    {'coins': 45000, 'inr': 2999, 'bonus': 50, 'badge': 'Exclusive'},
    {'coins': 80000, 'inr': 4999, 'bonus': 60, 'badge': 'Elite Member'},
    {'coins': 135000, 'inr': 7999, 'bonus': 69, 'badge': 'Ultimate Deal'},
    {'coins': 175000, 'inr': 9999, 'bonus': 75, 'badge': 'Legendary'},
  ];
  
  // Reseller list
  final List<Map<String, dynamic>> resellers = [
    {
      'name': 'John Reseller',
      'rating': 4.8,
      'coins': 50000,
      'price': '₹32,000',
      'discount': '15% OFF',
      'verified': true,
    },
    {
      'name': 'Sarah Coins',
      'rating': 4.9,
      'coins': 100000,
      'price': '₹62,400',
      'discount': '20% OFF',
      'verified': true,
    },
    {
      'name': 'Mike Trader',
      'rating': 4.7,
      'coins': 25000,
      'price': '₹16,000',
      'discount': '10% OFF',
      'verified': true,
    },
    {
      'name': 'Emma Store',
      'rating': 4.6,
      'coins': 75000,
      'price': '₹47,200',
      'discount': '18% OFF',
      'verified': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    // Setup real-time listeners FIRST (they'll listen for changes)
    _setupRealtimeListener();
    
    // Then load initial balance (this will set the initial value, listeners will update it)
    _loadCoinBalance();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure listeners are set up
    if (!_listenersSetup) {
      _setupRealtimeListener();
    }
  }
  
  @override
  void didUpdateWidget(WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh balance when widget is updated
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      _loadCoinBalance();
    }
  }

  /// Setup real-time listener for wallet updates
  void _setupRealtimeListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ Wallet: Cannot setup listener - no user ID');
      return;
    }

    // Prevent duplicate listeners
    if (_listenersSetup) {
      debugPrint('⚠️ Wallet: Listeners already setup, skipping...');
      return;
    }

    print('🔄 Wallet: Setting up real-time listeners for user: $userId');
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Listen to users collection uCoins field (PRIMARY SOURCE OF TRUTH)
    // This is updated immediately when coins are deducted during calls
    _userSubscription = firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        
        if (snapshot.exists) {
          final userData = snapshot.data();
          final uCoins = (userData?['uCoins'] as int?) ?? 0;
          final coins = (userData?['coins'] as int?) ?? 0;
          
          // Use uCoins as primary (it's always updated during deductions)
          // Only use coins if uCoins is 0 and coins has value (legacy data)
          final newBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
          
          debugPrint('📡 Wallet: Real-time update from users collection (PRIMARY)');
          debugPrint('   uCoins: $uCoins, coins: $coins → New: $newBalance, Current: $coinBalance');
          
          // Sync if they're different (coins should be synced to uCoins)
          if (coins > uCoins && coins > 0 && uCoins == 0) {
            debugPrint('⚠️ Wallet: coins ($coins) > uCoins ($uCoins), syncing...');
            firestore.collection('users').doc(userId).update({
              'uCoins': coins,
            }).then((_) {
              debugPrint('✅ Wallet: Synced coins ($coins) → uCoins');
            }).catchError((e) {
              debugPrint('⚠️ Wallet: Could not sync: $e');
            });
          }
          
          // ALWAYS update if balance changed (this is the source of truth)
          if (newBalance != coinBalance) {
            debugPrint('✅ Wallet: Updating from users (PRIMARY): $coinBalance → $newBalance');
            if (!mounted) return;
            setState(() {
              coinBalance = newBalance;
            });
            debugPrint('✅ Wallet: Real-time update complete! Balance: $coinBalance');
          } else {
            debugPrint('ℹ️ Wallet: Balance unchanged from users collection ($coinBalance)');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Wallet: Error in users listener: $error');
        if (!mounted) return;
        // Show error to user if critical
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating balance: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );

    // Also listen to wallets collection for sync (SECONDARY - for display consistency)
    _walletSubscription = firestore
        .collection('wallets')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        
        if (snapshot.exists) {
          final walletData = snapshot.data();
          final balance = (walletData?['balance'] as int?) ?? 0;
          final coins = (walletData?['coins'] as int?) ?? 0;
          final walletBalance = balance > 0 ? balance : coins;
          
          debugPrint('📡 Wallet: Real-time update from wallets collection (SECONDARY)');
          debugPrint('   balance: $balance, coins: $coins → Wallet: $walletBalance, Current: $coinBalance');
          
          // Only update if wallets balance is lower (coins can only decrease, not increase without purchase)
          // This ensures we don't show stale higher values from wallets
          if (walletBalance < coinBalance && walletBalance >= 0) {
            debugPrint('✅ Wallet: Updating from wallets (lower value): $coinBalance → $walletBalance');
            if (!mounted) return;
            setState(() {
              coinBalance = walletBalance;
            });
            debugPrint('✅ Wallet: Real-time update from wallets complete! Balance: $coinBalance');
          } else if (walletBalance != coinBalance) {
            debugPrint('ℹ️ Wallet: Wallets balance ($walletBalance) differs but using users value ($coinBalance) as source of truth');
          }
        } else {
          debugPrint('⚠️ Wallet: Wallet document does not exist, using users collection only...');
        }
      },
      onError: (error) {
        debugPrint('❌ Wallet: Error in wallets listener: $error');
        // Don't show error to user for secondary listener
        // Primary listener (users) will handle errors
      },
    );
    
    _listenersSetup = true;
    debugPrint('✅ Wallet: Real-time listeners setup complete');
    debugPrint('   Listening to: wallets/$userId');
    debugPrint('   Listening to: users/$userId');
  }

  @override
  void dispose() {
    print('🔄 Wallet: Disposing listeners...');
    _walletSubscription?.cancel();
    _userSubscription?.cancel();
    _listenersSetup = false; // Reset flag for next time
    _tabController.dispose();
    super.dispose();
  }

  /// Load real coin balance from Firestore
  Future<void> _loadCoinBalance() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ Wallet: No authenticated user');
        setState(() {
          _isLoading = false;
          coinBalance = 0;
          hostEarnings = 0.0;
        });
        return;
      }

      debugPrint('🔄 Wallet: Loading coin balance for user: $userId');

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // PRIMARY: Load directly from Firestore users collection (bypass cache for accuracy)
      // This ensures we get the latest value, not cached data
      int finalBalance = 0;
      
      try {
        // Read directly from Firestore to get the latest value
        // Use serverAndCache to get fresh data but fallback to cache if offline
        final userDoc = await firestore.collection('users').doc(userId).get(
          const GetOptions(source: Source.serverAndCache),
        );
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final uCoins = (userData?['uCoins'] as int?) ?? 0;
          final coins = (userData?['coins'] as int?) ?? 0;
          
          debugPrint('📊 Wallet: User data loaded directly from Firestore (PRIMARY SOURCE OF TRUTH)');
          debugPrint('   uCoins: $uCoins');
          debugPrint('   coins: $coins');
          
          // ALWAYS use uCoins as primary (it's always updated during deductions)
          // Only use coins if uCoins is 0 and coins has value (legacy data)
          finalBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
          
          debugPrint('✅ Wallet: Using users collection balance: $finalBalance');
          
          // Sync if coins is higher (legacy data migration)
          if (coins > uCoins && coins > 0 && uCoins == 0) {
            debugPrint('⚠️ Wallet: coins ($coins) > uCoins ($uCoins), syncing...');
            try {
              await firestore.collection('users').doc(userId).update({
                'uCoins': coins,
              });
              finalBalance = coins;
              debugPrint('✅ Wallet: Synced coins ($coins) → uCoins');
            } catch (e) {
              debugPrint('⚠️ Wallet: Could not sync: $e');
            }
          }
        } else {
          debugPrint('⚠️ Wallet: User document not found in users collection');
          // Fallback to wallets collection only if users collection doesn't exist
          try {
            final walletDoc = await firestore.collection('wallets').doc(userId).get();
            if (walletDoc.exists) {
              final walletData = walletDoc.data();
              finalBalance = (walletData?['balance'] as int?) ?? (walletData?['coins'] as int?) ?? 0;
              debugPrint('⚠️ Wallet: Using wallets collection as fallback: $finalBalance');
            }
          } catch (e) {
            debugPrint('⚠️ Wallet: Error loading from wallets collection: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Wallet: Error loading from Firestore: $e');
        // Fallback to database service if direct Firestore read fails
        try {
          final userData = await _databaseService.getUserData(userId);
          if (userData != null) {
            finalBalance = userData.uCoins > 0 ? userData.uCoins : (userData.coins > 0 ? userData.coins : 0);
            debugPrint('✅ Wallet: Using database service fallback: $finalBalance');
          }
        } catch (e2) {
          debugPrint('❌ Wallet: Database service also failed: $e2');
        }
      }
      
      debugPrint('💰 Wallet: Setting coinBalance to: $finalBalance');
      
      if (!mounted) return;
      setState(() {
        coinBalance = finalBalance;
      });

      // Load host earnings if user is a host
      if (widget.isHost) {
        debugPrint('👑 Wallet: Loading host earnings...');
        try {
          final earnings = await _giftService.getHostEarningsSummary(userId);
          final withdrawable = earnings['withdrawableAmount']?.toDouble() ?? 0.0;
          debugPrint('💰 Wallet: Host earnings: $withdrawable');
          if (!mounted) return;
          setState(() {
            hostEarnings = withdrawable;
          });
        } catch (e) {
          debugPrint('⚠️ Wallet: Error loading host earnings: $e');
          if (!mounted) return;
          setState(() {
            hostEarnings = 0.0;
          });
        }
      }
      
      debugPrint('✅ Wallet: Balance loaded - Final: $coinBalance');
    } catch (e, stackTrace) {
      debugPrint('❌ Wallet: Error loading coin balance: $e');
      debugPrint('❌ Wallet: Stack trace: $stackTrace');
      
      // Try to sync wallet as fallback
      try {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _coinService.syncWalletWithUsers(userId);
        }
      } catch (syncError) {
        debugPrint('❌ Wallet: Error syncing wallet: $syncError');
      }
      
      if (!mounted) return;
      setState(() {
        coinBalance = 0;
        hostEarnings = 0.0;
        _isLoading = false;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error loading balance. Please refresh.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadCoinBalance,
          ),
        ),
      );
      return;
    }
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false, // Disable default back button
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 22,
                ),
                onPressed: () {
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error navigating back: $e');
                  }
                },
              )
            : null, // No back button when opened from homepage
        title: Text(
          AppLocalizations.of(context)!.wallet,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Refresh Icon
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.black87,
              size: 22,
            ),
            onPressed: _loadCoinBalance,
          ),
          // Transaction History Icon
          IconButton(
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.black87,
              size: 22,
            ),
            onPressed: () {
              // TODO: Navigate to transaction history
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.transactionHistoryComingSoon),
                  backgroundColor: const Color(0xFF04B104),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          // Contact Support Icon
          IconButton(
            icon: const Icon(
              Icons.support_agent,
              color: Colors.black87,
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Coin Balance Card
                  _buildBalanceCard(),
            
            const SizedBox(height: 8),
            
            // Host Earnings (if user is host)
            if (widget.isHost) ...[
              _buildHostEarningsCard(),
              const SizedBox(height: 8),
            ],
            
            // Tab Bar
            _buildTabBar(),
            
            // Tab Bar View Content
            _currentTabIndex == 0
                ? _buildFlatRechargeTab()
                : _buildResellerTab(),
            
            const SizedBox(height: 25),
            
            // Trust Text Above Trust Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    '1: ${AppLocalizations.of(context)!.rechargeWithConfidence}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '2: ${AppLocalizations.of(context)!.fastSafeTrusted}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trust Badges at Bottom
            _buildTrustBadges(),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ========== TRUST BADGES ==========
  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Secure Checkout
          _buildTrustBadge(
            icon: Icons.verified_user_rounded,
            topText: AppLocalizations.of(context)!.secure,
            bottomText: AppLocalizations.of(context)!.checkout,
          ),
          
          // Divider
          Container(
            height: 35,
            width: 1,
            color: Colors.grey[300],
          ),
          
          // Satisfaction Guaranteed
          _buildTrustBadge(
            icon: Icons.emoji_events_rounded,
            topText: AppLocalizations.of(context)!.satisfaction,
            bottomText: AppLocalizations.of(context)!.guaranteed,
          ),
          
          // Divider
          Container(
            height: 35,
            width: 1,
            color: Colors.grey[300],
          ),
          
          // Privacy Protected
          _buildTrustBadge(
            icon: Icons.lock_rounded,
            topText: AppLocalizations.of(context)!.privacy,
            bottomText: AppLocalizations.of(context)!.protected,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String topText,
    required String bottomText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 6),
        Text(
          topText,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          bottomText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ========== BALANCE CARD - Ultra Dynamic Gold & Brown ==========
  Widget _buildBalanceCard() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 5),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFB800),
              Color(0xFFF59E0B),
              Color(0xFFD97706),
              Color(0xFF92400E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Decorative elements - Multiple circles for depth
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
            // Shimmer effect circle
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
            
            // Savings Icon - Top Right (vertically centered)
            Positioned(
              top: 20,
              right: 16,
              child: Image.asset(
                'assets/images/savings.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    AppLocalizations.of(context)!.myBalance,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Coin icon + Balance
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                      // Coin image
                      Image.asset(
                        'assets/images/coin3.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      
                      const SizedBox(width: 10),
                
                // Balance number
                      Expanded(
                        child: Text(
                          NumberFormat.decimalPattern().format(coinBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Available Coins label
                      Text(
                        AppLocalizations.of(context)!.availableCoins,
                        style: const TextStyle(
                          color: Colors.white70,
                      fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HOST EARNINGS CARD ==========
  Widget _buildHostEarningsCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF04B104), Color(0xFF038103)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF04B104).withValues(alpha:0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/coin3.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.host,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.totalEarnings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '₹',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hostEarnings.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showWithdrawalDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF04B104),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                AppLocalizations.of(context)!.withdrawEarnings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== TAB BAR - Modern & Professional ==========
  Widget _buildTabBar() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
        constraints: const BoxConstraints(
          maxHeight: 45,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF92400E).withValues(alpha:0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[700],
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on, size: 14),
                  const SizedBox(width: 5),
                  Text(AppLocalizations.of(context)!.flatRecharge),
                ],
              ),
            ),
            Tab(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store, size: 14),
                      const SizedBox(width: 5),
                      Text(AppLocalizations.of(context)!.reseller),
                    ],
                  ),
                  // Special discount badge
                  Positioned(
                    top: -8,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF512F).withValues(alpha:0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.save20Percent,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
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
  }

  // ========== FLAT RECHARGE TAB ==========
  Widget _buildFlatRechargeTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppLocalizations.of(context)!.depositAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          // 3-column grid - Flexible
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              if (availableWidth <= 0) {
                return const SizedBox.shrink();
              }
              
              final cardWidth = (availableWidth - 16) / 3;
              final cardHeight = cardWidth * 1.1;
              
              // Ensure minimum card size and valid aspect ratio
              final minCardSize = 60.0;
              final safeCardWidth = cardWidth < minCardSize ? minCardSize : cardWidth;
              final safeCardHeight = cardHeight < minCardSize ? minCardSize : cardHeight;
              final aspectRatio = safeCardWidth / safeCardHeight;
              
              // Clamp aspect ratio to prevent invalid values
              final safeAspectRatio = aspectRatio.clamp(0.5, 2.0);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: safeAspectRatio,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: rechargePackages.length,
                itemBuilder: (context, index) {
                  return _buildDepositCard(rechargePackages[index], index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== RESELLER TAB ==========
  Widget _buildResellerTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      child: Column(
        children: [
          // Attractive header banner
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF8E53),
                    Color(0xFFFFB347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8E53).withValues(alpha:0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.getBestDeals,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.saveUpTo20Percent,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.best,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF512F),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Reseller cards
          ...resellers.map((reseller) => _buildResellerCard(reseller)).toList(),
        ],
      ),
    );
  }

  // ========== RESELLER CARD - Clean & Modern ==========
  Widget _buildResellerCard(Map<String, dynamic> reseller) {
    final int index = resellers.indexOf(reseller);
    
    return FadeInUp(
      delay: Duration(milliseconds: 150 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: reseller['verified'] 
                ? const Color(0xFF10B981).withValues(alpha:0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
              child: Row(
                children: [
            // Avatar
                  Container(
              width: 52,
              height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                Icons.store_rounded,
                      color: Colors.white,
                size: 26,
                    ),
                  ),
                  
                  const SizedBox(width: 14),
                  
            // Name, Verified, Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Name with verified badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reseller['name'],
                                style: const TextStyle(
                            fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (reseller['verified']) ...[
                        const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                            size: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                  // Rating
                  Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFB800),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                        '${reseller['rating']}',
                        style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                  if (reseller['discount'] != null && reseller['discount'].isNotEmpty)
                    Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reseller['discount'],
                        style: const TextStyle(
                              fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
                        ),
                      ],
                    ),
                  ),
            
            // Contact Button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFD97706)],
                    ),
                borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                    color: const Color(0xFF92400E).withValues(alpha:0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                      ),
                    ],
                  ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _startChatWithReseller(reseller),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/chat.png',
                          width: 16,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                      Text(
                          AppLocalizations.of(context)!.chat,
                        style: const TextStyle(
                      color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== START CHAT WITH RESELLER ==========
  void _startChatWithReseller(Map<String, dynamic> reseller) {
    if (!mounted) return;
    // Navigate to Messages screen to start chat
    // In production, this would navigate to a chat screen with the reseller
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.asset('assets/images/chat.png', width: 20, height: 20, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.startingChatWith(reseller['name']),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB800),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.open,
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to chat/messages screen with reseller
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(reseller: reseller)));
          },
        ),
      ),
    );
  }

  // ========== DEPOSIT CARD (3-COLUMN GRID) ==========
  Widget _buildDepositCard(Map<String, dynamic> package, int index) {
    final int coins = package['coins'];
    final int inr = package['inr'];
    final dynamic bonusValue = package['bonus'];
    final int bonus = (bonusValue is int) ? bonusValue : (bonusValue is String) ? int.tryParse(bonusValue) ?? 0 : 0;
    final bool showBadge = bonus > 0 && index > 1 && index != 3 && index != 5 && index != 7; // Hide badge for 1st (index 0), 2nd (index 1), 4th (index 3), 6th (index 5), and 8th (index 7) grid
    final bool showBadgeText = (index == 3 || index == 5 || index == 7) && package['badge'] != null; // Show badge text for 4th (index 3), 6th (index 5), and 8th (index 7) grid items
    
    return GestureDetector(
        onTap: () => _showPaymentDialog(package),
        child: Container(
        padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
            border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha:0.3),
            width: 1,
            ),
            boxShadow: [
              BoxShadow(
              color: const Color(0xFFFFB800).withValues(alpha:0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Coin image
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5),
                        // Coin value
                        Text(
                          NumberFormat.decimalPattern().format(coins),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Divider
                        Container(
                          width: 20,
                          height: 1,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        // INR value
                        Text(
                          '₹${NumberFormat.decimalPattern().format(inr)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Badge Text Container - Top Center (for 4th grid item)
              if (showBadgeText)
                Positioned(
                  top: -2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha:0.4),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        (package['badge'] as String? ?? ''),
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              // Bonus Badge - Top Right (Inside Container)
              if (showBadge)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha:0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 7,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '$bonus%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }

  // ========== DIALOGS ==========
  void _showPaymentDialog(Map<String, dynamic> package) {
    if (!mounted) return;
    final int coins = package['coins'];
    final int inr = package['inr'];
    final String packageId = 'package_${coins}_${inr}'; // Generate unique package ID
    
    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          coins: coins,
          amount: inr,
          packageId: packageId,
        ),
      ),
    ).then((success) {
      // Refresh wallet data if payment was successful
      // The real-time listeners will automatically update the balance
      // But we can also manually refresh to ensure immediate update
      if (success == true) {
        _loadCoinBalance();
        // Also sync wallet to ensure consistency
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          _coinService.syncWalletWithUsers(userId);
        }
      }
    });
  }

  void _showWithdrawalDialog() {
    if (!mounted) return;
    final TextEditingController amountController = TextEditingController();
    
    try {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.withdrawEarningsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF04B104).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF04B104),
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        AppLocalizations.of(context)!.inr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF04B104),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Available: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${hostEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF04B104),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.withdrawalAmountINR,
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF04B104)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF04B104), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.minimumWithdrawal50,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              amountController.dispose();
              try {
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error closing withdrawal dialog: $e');
              }
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount >= 50 && amount <= hostEarnings) {
                amountController.dispose();
                try {
                  Navigator.pop(context);
                  // TODO: Implement withdrawal API
                  _showSuccessDialog(AppLocalizations.of(context)!.withdrawalRequestSubmitted);
                } catch (e) {
                  debugPrint('Error in withdrawal dialog: $e');
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidAmount)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF04B104),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.withdraw),
          ),
        ],
      ),
      );
    } catch (e) {
      debugPrint('Error showing withdrawal dialog: $e');
    }
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF04B104),
              size: 60,
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              try {
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error closing success dialog: $e');
              }
            },
            child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Color(0xFF04B104))),
          ),
        ],
      ),
      );
    } catch (e) {
      debugPrint('Error showing success dialog: $e');
    }
  }

}

