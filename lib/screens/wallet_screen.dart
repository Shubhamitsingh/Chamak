import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'coin_purchase_history_screen.dart';
import 'payprime_payment_webview_screen.dart';
import 'upi_payment_selection_screen.dart';
import '../services/database_service.dart';
import '../services/gift_service.dart';
import '../services/coin_service.dart';
import '../services/payprime_payment_service.dart';
import '../services/withdrawal_service.dart';

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

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  final GiftService _giftService = GiftService();
  final CoinService _coinService = CoinService();
  final PayPrimePaymentService _paymentService = PayPrimePaymentService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Real coin data - fetched from Firestore
  int coinBalance = 0; // U Coins (User Coins)
  double hostEarnings = 0.0; // C Coins converted to real money
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _listenersSetup = false; // Track if listeners are set up
  
  // Recharge packages - 12 options (added ₹9, ₹49, ₹149, ₹199; removed ₹7,999)
  final List<Map<String, dynamic>> rechargePackages = [
    {'coins': 90, 'inr': 9, 'bonus': 0, 'badge': null}, // Entry level - no badge
    {'coins': 550, 'inr': 49, 'bonus': 10, 'badge': 'Starter'}, // Casual users
    {'coins': 1100, 'inr': 99, 'bonus': 10, 'badge': 'Popular Choice'},
    {'coins': 1700, 'inr': 149, 'bonus': 14, 'badge': null}, // Mid-tier - fills gap between ₹99-₹199
    {'coins': 2400, 'inr': 199, 'bonus': 18, 'badge': 'Smart Buy'}, // Mid-tier value
    {'coins': 3500, 'inr': 299, 'bonus': 20, 'badge': 'Great Value'}, // Increased bonus from 17% to 20%
    {'coins': 7500, 'inr': 599, 'bonus': 25, 'badge': 'Best Value'},
    {'coins': 13000, 'inr': 999, 'bonus': 30, 'badge': 'VIP Choice'},
    {'coins': 28000, 'inr': 1999, 'bonus': 40, 'badge': 'Most Popular'},
    {'coins': 45000, 'inr': 2999, 'bonus': 50, 'badge': 'Exclusive'},
    {'coins': 80000, 'inr': 4999, 'bonus': 60, 'badge': 'Elite Member'},
    {'coins': 175000, 'inr': 9999, 'bonus': 75, 'badge': 'Legendary'}, // Removed ₹7,999 - cleaner progression
  ];

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer for automatic payment checking
    WidgetsBinding.instance.addObserver(this);
    
    // Setup real-time listeners FIRST (they'll listen for changes)
    _setupRealtimeListener();
    
    // Then load initial balance (this will set the initial value, listeners will update it)
    _loadCoinBalance();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Payment gateway removed - lifecycle handler kept for future use
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
    
    // Listen to users collection uCoins field (SINGLE SOURCE OF TRUTH)
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
          
          // Use uCoins as primary (single source of truth)
          // Only use coins if uCoins is 0 and coins has value (legacy data migration)
          final newBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
          
          debugPrint('📡 Wallet: Real-time update from users.uCoins (single source of truth)');
          debugPrint('   uCoins: $uCoins, coins: $coins → New: $newBalance, Current: $coinBalance');
          
          // Migrate legacy coins to uCoins if needed (one-time migration)
          if (coins > uCoins && coins > 0 && uCoins == 0) {
            debugPrint('⚠️ Wallet: Migrating legacy coins ($coins) → uCoins');
            firestore.collection('users').doc(userId).update({
              'uCoins': coins,
            }).then((_) {
              debugPrint('✅ Wallet: Migrated legacy coins → uCoins');
            }).catchError((e) {
              debugPrint('⚠️ Wallet: Could not migrate: $e');
            });
          }
          
          // Update if balance changed
          if (newBalance != coinBalance) {
            debugPrint('✅ Wallet: Updating balance: $coinBalance → $newBalance');
            if (!mounted) return;
            setState(() {
              coinBalance = newBalance;
            });
            debugPrint('✅ Wallet: Real-time update complete! Balance: $coinBalance');
          } else {
            debugPrint('ℹ️ Wallet: Balance unchanged ($coinBalance)');
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

    _listenersSetup = true;
    debugPrint('✅ Wallet: Real-time listener setup complete');
    debugPrint('   Listening to: users/$userId (single source of truth)');
  }

  @override
  void dispose() {
    print('🔄 Wallet: Disposing listeners...');
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Cancel subscriptions
    _userSubscription?.cancel();
    
    // Reset flags
    _listenersSetup = false;
    
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
          // No fallback - users collection is single source of truth
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
          await _coinService.migrateLegacyCoins(userId);
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
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), // Dark background
        elevation: 0,
        centerTitle: false, // Left align title
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1A1A1A), // Dark status bar
          statusBarIconBrightness: Brightness.light, // Light icons
          statusBarBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false, // Disable default back button
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Coin Balance Pill Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1B7C), // App theme pink
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/coin3.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${NumberFormat.decimalPattern().format(coinBalance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 1),
          // Coin Purchase History Icon (3 dots)
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoinPurchaseHistoryScreen(),
                  ),
                );
              } catch (e) {
                debugPrint('Error navigating to coin purchase history: $e');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1B7C)))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Title
                          Text(
                            'Make a Video Call',
                            style: const TextStyle(
                              color: Color(0xFFFF1B7C), // App theme pink
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'with Coins',
                            style: const TextStyle(
                              color: Color(0xFFFF1B7C), // App theme pink
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            'Call beauties with coins',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
            
                    // Recharge Packages
                    _buildFlatRechargeTab(),
            
                    const SizedBox(height: 30),
                  ],
                ),
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
          // Secure Checkout - Gray color
          _buildTrustBadge(
            icon: Icons.verified_user_rounded,
            topText: AppLocalizations.of(context)!.secure,
            bottomText: AppLocalizations.of(context)!.checkout,
            iconColor: Colors.grey[600], // Gray color for secure icon
          ),
          
          // Divider
          Container(
            height: 35,
            width: 1,
            color: Colors.grey[300],
          ),
          
          // Satisfaction Guaranteed - Gray color
          _buildTrustBadge(
            icon: Icons.emoji_events_rounded,
            topText: AppLocalizations.of(context)!.satisfaction,
            bottomText: AppLocalizations.of(context)!.guaranteed,
            iconColor: Colors.grey[600], // Gray color to match other icons
          ),
          
          // Divider
          Container(
            height: 35,
            width: 1,
            color: Colors.grey[300],
          ),
          
          // Privacy Protected - Gray color
          _buildTrustBadge(
            icon: Icons.lock_rounded,
            topText: AppLocalizations.of(context)!.privacy,
            bottomText: AppLocalizations.of(context)!.protected,
            iconColor: Colors.grey[600], // Gray color to match other icons
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String topText,
    required String bottomText,
    Color? iconColor, // Optional icon color parameter
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: iconColor ?? Colors.grey[600], // Use provided color or default grey
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

  // ========== BALANCE CARD - Simple Pink Theme ==========
  Widget _buildBalanceCard() {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 2),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF1B7C), // Primary pink
              Color(0xFFFF69B4), // Hot pink
              Color(0xFFE91E63), // Deep pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1B7C).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements - Simple circles
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
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
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
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.0),
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
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            
            // Savings Icon - Top Right
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        padding: const EdgeInsets.all(20),
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


  // ========== FLAT RECHARGE TAB ==========
  Widget _buildFlatRechargeTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          if (availableWidth <= 0) {
            return const SizedBox.shrink();
          }
          
          // 2-column grid for better card size on dark theme
          final crossAxisCount = availableWidth > 400 ? 2 : 2;
          final cardWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
          final cardHeight = 220.0; // Increased height to prevent overflow
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: cardWidth / cardHeight,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rechargePackages.length,
            itemBuilder: (context, index) {
              return _buildDepositCard(rechargePackages[index], index);
            },
          );
        },
      ),
    );
  }

  // ========== DEPOSIT CARD (Dark Theme Design) ==========
  Widget _buildDepositCard(Map<String, dynamic> package, int index) {
    final int coins = package['coins'];
    final int inr = package['inr'];
    final dynamic bonusValue = package['bonus'];
    final int bonus = (bonusValue is int) ? bonusValue : (bonusValue is String) ? int.tryParse(bonusValue) ?? 0 : 0;
    final String? badgeText = package['badge'] as String?;
    
    // Badge display logic
    final bool showBadge = bonus > 0 && index > 0;
    final bool showBadgeText = badgeText != null && badgeText.isNotEmpty;
    final bool showOnceBadge = index == 0; // First package shows "Once"
    
    return GestureDetector(
      onTap: () => _handleRecharge(package),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // Dark grey card background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Coin Display - Single coin for first item, stacked for others
                  SizedBox(
                    height: 50, // Fixed height to prevent clipping
                    width: double.infinity,
                    child: index == 0
                        ? // First grid item - Single coin
                          Center(
                            child: Image.asset(
                              'assets/images/coin3.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          )
                        : // Other items - Stacked coins with sparkles
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none, // Allow overflow for sparkles
                            children: [
                              // Coin 1 (back)
                              Positioned(
                                bottom: 4,
                                child: Image.asset(
                                  'assets/images/coin3.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Coin 2 (middle)
                              Positioned(
                                bottom: 2,
                                child: Image.asset(
                                  'assets/images/coin3.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Coin 3 (front)
                              Image.asset(
                                'assets/images/coin3.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              // Sparkle effects
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 8,
                                  color: Colors.amber[300],
                                ),
                              ),
                              Positioned(
                                top: 2,
                                left: -2,
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 6,
                                  color: Colors.amber[200],
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Coin Amount
                  Text(
                    '${NumberFormat.decimalPattern().format(coins)} Coins',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Package Name
                  Text(
                    badgeText ?? _getPackageName(index),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Price Button at Bottom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C), // App theme pink
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹ ${NumberFormat.decimalPattern().format(inr)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // "Once" Badge - Top Left
            if (showOnceBadge)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Once',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Badge Text - Top Center
            if (showBadgeText && !showOnceBadge)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF1B7C),
                          Color(0xFFE0166C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText ?? '',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            
            // Bonus Badge - Top Right
            if (showBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF1B7C),
                        Color(0xFFE0166C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 8,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$bonus%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
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
  
  // Helper method to get package name
  String _getPackageName(int index) {
    final names = [
      'One Time',
      'Starter',
      'Popular Choice',
      'Mid-tier',
      'Smart Buy',
      'Great Value',
      'Best Value',
      'VIP Choice',
      'Most Popular',
      'Exclusive',
      'Elite Member',
      'Legendary',
    ];
    return index < names.length ? names[index] : 'Package';
  }

  // ========== PAYMENT HANDLERS ==========
  /// Handle recharge package selection and initiate PayPrime payment
  Future<void> _handleRecharge(Map<String, dynamic> package) async {
    if (!mounted) return;
    
    debugPrint('🔄 _handleRecharge called with package: $package');
    
    final int coins = package['coins'] as int;
    final int inr = package['inr'] as int;
    
    debugPrint('💰 Payment details: ₹$inr for $coins coins');
    
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ User not authenticated');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to continue'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      debugPrint('✅ User authenticated: ${currentUser.uid}');
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF1B7C),
            ),
          ),
        );
      }

      debugPrint('📞 Calling payment service...');
      
      // Initiate payment
      final result = await _paymentService.initiatePayment(
        amount: inr.toDouble(),
        coins: coins,
        currency: "INR",
      );

      debugPrint('📥 Payment service response: $result');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        debugPrint('✅ Payment initiated successfully');
        debugPrint('   Payment URL: ${result['paymentUrl']}');
        debugPrint('   Payment ID: ${result['paymentId']}');
        
        // Check if we have multiple UPI URLs - show selection screen
        final upiUrlsRaw = result['upiUrls'];
        Map<String, String> upiUrls = {};
        
        if (upiUrlsRaw != null) {
          // Convert to Map<String, String> safely
          if (upiUrlsRaw is Map) {
            upiUrls = Map<String, String>.from(
              upiUrlsRaw.map((key, value) => MapEntry(
                key.toString(),
                value.toString(),
              ))
            );
          }
        }
        
        final hasMultipleUpiOptions = upiUrls.length > 1;
        
        debugPrint('📊 UPI URLs received: ${upiUrls.length} options');
        debugPrint('   Options: ${upiUrls.keys.join(", ")}');
        
        // Navigate to payment screen
        if (mounted) {
          bool? success;
          
          if (hasMultipleUpiOptions) {
            // Show UPI selection screen
            debugPrint('🚀 Showing UPI selection screen...');
            success = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpiPaymentSelectionScreen(
                  upiUrls: upiUrls,
                  paymentId: result['paymentId'] as String,
                  orderId: result['orderId'] as String,
                  amount: (result['amount'] as num).toDouble(),
                  coins: result['coins'] as int,
                ),
              ),
            );
          } else {
            // Single URL or web URL - go directly to WebView
            debugPrint('🚀 Navigating to payment WebView...');
            success = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayPrimePaymentWebViewScreen(
                  paymentUrl: result['paymentUrl'] as String,
                  paymentId: result['paymentId'] as String,
                  orderId: result['orderId'] as String,
                  amount: (result['amount'] as num).toDouble(),
                  coins: result['coins'] as int,
                ),
              ),
            );
          }

          debugPrint('📊 Payment screen returned: $success');

          // If payment successful, refresh wallet balance
          // Note: Success dialog is already shown in payment screen
          // Real-time listener will automatically update the balance
          if (success == true && mounted) {
            _loadCoinBalance(); // Refresh to ensure latest balance
          }
        }
      } else {
        debugPrint('❌ Payment initiation failed: ${result['message']}');
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to initiate payment'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _handleRecharge: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // Dialog might already be closed
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ========== DIALOGS ==========
  void _showWithdrawalDialog() {
    if (!mounted) return;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController upiIdController = TextEditingController();
    String selectedMethod = 'UPI'; // Default to UPI
    
    try {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(AppLocalizations.of(context)!.withdrawEarningsTitle),
            content: SingleChildScrollView(
              child: Column(
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
                  // Payment Method Selection
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Method:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('UPI'),
                          value: 'UPI',
                          groupValue: selectedMethod,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMethod = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // UPI ID Input
                  TextField(
                    controller: upiIdController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'UPI ID (e.g., yourname@paytm)',
                      prefixIcon: const Icon(Icons.account_circle, color: Color(0xFF04B104)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF04B104), width: 2),
                      ),
                      hintText: 'Enter your UPI ID',
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    AppLocalizations.of(context)!.minimumWithdrawal50,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  amountController.dispose();
                  upiIdController.dispose();
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error closing withdrawal dialog: $e');
                  }
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  final upiId = upiIdController.text.trim();
                  
                  // Validation
                  if (amount == null || amount < 50 || amount > hostEarnings) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.invalidAmount)),
                    );
                    return;
                  }
                  
                  if (upiId.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your UPI ID')),
                    );
                    return;
                  }
                  
                  // Validate UPI ID format (basic validation)
                  if (!upiId.contains('@')) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid UPI ID (e.g., yourname@paytm)')),
                    );
                    return;
                  }
                  
                  // Close dialog and show loading
                  amountController.dispose();
                  upiIdController.dispose();
                  Navigator.pop(context);
                  
                  // Submit withdrawal request
                  await _submitWithdrawalRequest(amount, selectedMethod, upiId);
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
        ),
      );
    } catch (e) {
      debugPrint('Error showing withdrawal dialog: $e');
    }
  }
  
  // Submit withdrawal request to backend
  Future<void> _submitWithdrawalRequest(double amount, String method, String upiId) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Get user details for withdrawal request
      final userModel = await _databaseService.getUserData(currentUser.uid);
      final userName = userModel?.displayName;
      final displayId = userModel?.numericUserId;
      
      // Prepare payment details
      final paymentDetails = {
        'upiId': upiId,
      };
      
      // Submit withdrawal request
      final requestId = await _withdrawalService.submitWithdrawalRequest(
        userId: currentUser.uid,
        amount: amount,
        withdrawalMethod: method,
        paymentDetails: paymentDetails,
        userName: userName,
        displayId: displayId,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (requestId != null) {
        // Success
        _showSuccessDialog(AppLocalizations.of(context)!.withdrawalRequestSubmitted);
        debugPrint('✅ Withdrawal request submitted: $requestId');
      } else {
        // Failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit withdrawal request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error submitting withdrawal request: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

