import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'contact_support_screen.dart';
import '../services/database_service.dart';
import '../services/gift_service.dart';

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
    {'coins': 200, 'inr': 100},
    {'coins': 550, 'inr': 250},
    {'coins': 1200, 'inr': 500},
    {'coins': 2500, 'inr': 1000},
    {'coins': 6500, 'inr': 2500},
    {'coins': 13500, 'inr': 5000},
    {'coins': 28000, 'inr': 10000},
    {'coins': 70000, 'inr': 25000},
    {'coins': 150000, 'inr': 50000},
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
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    // Setup real-time listeners FIRST (they'll listen for changes)
    _setupRealtimeListener();
    
    // Then load initial balance
    _loadCoinBalance();
  }

  /// Setup real-time listener for wallet updates
  void _setupRealtimeListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ Wallet: Cannot setup listener - no user ID');
      return;
    }

    // Prevent duplicate listeners
    if (_listenersSetup) {
      print('⚠️ Wallet: Listeners already setup, skipping...');
      return;
    }

    print('🔄 Wallet: Setting up real-time listeners for user: $userId');
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Listen to wallets collection for real-time updates (PRIMARY)
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
          final newBalance = balance > 0 ? balance : coins;
          
          print('📡 Wallet: Real-time update from wallets collection');
          print('   balance: $balance, coins: $coins → New: $newBalance, Current: $coinBalance');
          
          // Always update if there's a change (or if balance was 0 and now has value)
          if (newBalance != coinBalance) {
            print('✅ Wallet: Updating balance: $coinBalance → $newBalance');
            setState(() {
              coinBalance = newBalance;
            });
            print('✅ Wallet: Real-time update complete! Balance: $coinBalance');
          } else {
            print('ℹ️ Wallet: Balance unchanged ($coinBalance)');
          }
        } else {
          print('⚠️ Wallet: Wallet document does not exist, listening to users collection...');
        }
      },
      onError: (error) {
        print('❌ Wallet: Error in wallets listener: $error');
      },
    );

    // Also listen to users collection uCoins field (FALLBACK)
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
          
          // Use the higher value (in case coins has more from legacy data)
          final newBalance = uCoins >= coins ? uCoins : coins;
          
          print('📡 Wallet: Real-time update from users collection');
          print('   uCoins: $uCoins, coins: $coins → New: $newBalance, Current: $coinBalance');
          
          // Sync if they're different (coins should be synced to uCoins)
          if (coins > uCoins && coins > 0) {
            print('⚠️ Wallet: coins ($coins) > uCoins ($uCoins), syncing...');
            firestore.collection('users').doc(userId).update({
              'uCoins': coins,
            }).then((_) {
              print('✅ Wallet: Synced coins ($coins) → uCoins');
            }).catchError((e) {
              print('⚠️ Wallet: Could not sync: $e');
            });
          }
          
          // Update if balance changed (allow 0 values too, or if was 0 and now has value)
          if (newBalance != coinBalance) {
            print('✅ Wallet: Updating from users: $coinBalance → $newBalance');
            setState(() {
              coinBalance = newBalance;
            });
            print('✅ Wallet: Real-time update complete! Balance: $coinBalance');
          } else {
            print('ℹ️ Wallet: Balance unchanged from users collection ($coinBalance)');
          }
        }
      },
      onError: (error) {
        print('❌ Wallet: Error in users listener: $error');
      },
    );
    
    _listenersSetup = true;
    print('✅ Wallet: Real-time listeners setup complete');
    print('   Listening to: wallets/$userId');
    print('   Listening to: users/$userId');
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
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ Wallet: No authenticated user');
        setState(() {
          _isLoading = false;
          coinBalance = 0;
          hostEarnings = 0.0;
        });
        return;
      }

      print('🔄 Wallet: Loading coin balance for user: $userId');

      // Try to load from wallets collection first (primary source)
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      try {
        final walletDoc = await firestore.collection('wallets').doc(userId).get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data();
          final walletBalance = (walletData?['balance'] as int?) ?? 
                               (walletData?['coins'] as int?) ?? 0;
          
          print('✅ Wallet: Found wallet document in wallets collection');
          print('   balance: ${walletData?['balance']}');
          print('   coins: ${walletData?['coins']}');
          print('   Using balance: $walletBalance');
          
          setState(() {
            coinBalance = walletBalance;
          });
          
          // Load host earnings if user is a host
          if (widget.isHost) {
            print('👑 Wallet: Loading host earnings...');
            final earnings = await _giftService.getHostEarningsSummary(userId);
            final withdrawable = earnings['withdrawableAmount']?.toDouble() ?? 0.0;
            print('💰 Wallet: Host earnings: $withdrawable');
            setState(() {
              hostEarnings = withdrawable;
            });
          }
          
          print('✅ Wallet: Balance loaded from wallets collection - Coins: $coinBalance');
          return; // Exit early if wallet document found
        } else {
          print('⚠️ Wallet: No wallet document found, trying users collection...');
        }
      } catch (e) {
        print('⚠️ Wallet: Error loading from wallets collection: $e');
        print('⚠️ Wallet: Trying users collection as fallback...');
      }

      // Fallback: Get user data from users collection
      final userData = await _databaseService.getUserData(userId);
      
      if (userData != null) {
        print('📊 Wallet: User data loaded from users collection');
        print('   uCoins from model: ${userData.uCoins}');
        print('   cCoins from model: ${userData.cCoins}');
        print('   coins from model: ${userData.coins}');
        
        // Load U Coins - Use the higher value (coins might have more from legacy)
        int finalBalance = userData.uCoins >= userData.coins 
            ? userData.uCoins 
            : userData.coins;
        
        // If coins is higher than uCoins, sync them
        if (userData.coins > userData.uCoins) {
          print('⚠️ Wallet: coins (${userData.coins}) > uCoins (${userData.uCoins})');
          print('💰 Wallet: Using coins value and syncing to uCoins');
          
          // Sync the legacy coins to uCoins field
          try {
            final FirebaseFirestore firestore = FirebaseFirestore.instance;
            
            // Update users collection
            await firestore.collection('users').doc(userId).update({
              'uCoins': userData.coins,
            });
            print('✅ Wallet: Synced coins (${userData.coins}) → uCoins');
            
            // Also update wallets collection if it exists
            final walletRef = firestore.collection('wallets').doc(userId);
            final walletDoc = await walletRef.get();
            if (walletDoc.exists) {
              await walletRef.update({
                'balance': userData.coins,
                'coins': userData.coins,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('✅ Wallet: Synced to wallets/{userId}/balance');
            } else {
              // Create wallet document if it doesn't exist
              await walletRef.set({
                'userId': userId,
                'userName': userData.displayName ?? 'User',
                'userEmail': 'No email',
                'numericUserId': userData.numericUserId,
                'coins': userData.coins,
                'balance': userData.coins,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('✅ Wallet: Created wallet document with balance: ${userData.coins}');
            }
          } catch (e) {
            print('⚠️ Wallet: Could not sync: $e');
          }
        }
        
        print('💰 Wallet: Setting coinBalance to: $finalBalance');
        
        setState(() {
          coinBalance = finalBalance;
        });

        // Load host earnings if user is a host
        if (widget.isHost) {
          print('👑 Wallet: Loading host earnings...');
          final earnings = await _giftService.getHostEarningsSummary(userId);
          final withdrawable = earnings['withdrawableAmount']?.toDouble() ?? 0.0;
          print('💰 Wallet: Host earnings: $withdrawable');
          setState(() {
            hostEarnings = withdrawable;
          });
        }
        
        print('✅ Wallet: Balance loaded from users collection - U Coins: $coinBalance');
      } else {
        print('⚠️ Wallet: User data not found in either wallets or users collection');
        setState(() {
          coinBalance = 0;
          hostEarnings = 0.0;
        });
      }
    } catch (e) {
      print('❌ Wallet: Error loading coin balance: $e');
      print('❌ Wallet: Stack trace: ${StackTrace.current}');
      setState(() {
        coinBalance = 0;
        hostEarnings = 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                onPressed: () => Navigator.pop(context),
              )
            : null, // No back button when opened from homepage
        title: const Text(
          'Wallet',
          style: TextStyle(
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction History coming soon!'),
                  backgroundColor: Color(0xFF04B104),
                  duration: Duration(seconds: 2),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactSupportScreen(),
                ),
              );
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
            
            const SizedBox(height: 15),
            
            // Host Earnings (if user is host)
            if (widget.isHost) ...[
              _buildHostEarningsCard(),
              const SizedBox(height: 10),
            ],
            
            // Tab Bar
            _buildTabBar(),
            
            // Tab Bar View Content
            _currentTabIndex == 0
                ? _buildFlatRechargeTab()
                : _buildResellerTab(),
            
            const SizedBox(height: 30),
            
            // Trust Text Above Trust Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Recharge with confidence — your money is always secure.',
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
                    'Fast, safe, and trusted — every recharge is protected.',
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Secure Checkout
          _buildTrustBadge(
            icon: Icons.verified_user_rounded,
            topText: 'Secure',
            bottomText: 'Checkout',
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
            topText: 'Satisfaction',
            bottomText: 'Guaranteed',
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
            topText: 'Privacy',
            bottomText: 'Protected',
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
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
        height: 140,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF92400E).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.0),
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
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
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
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            // 3D Wallet Icon - Top Right (aligned with "My Balance" text)
            Positioned(
              top: 12,
              right: 18,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'My Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Coin icon + Balance
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                      // Premium coin icon with double ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          // Inner coin
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFEA00), Color(0xFFFFD700)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.diamond,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 12),
                
                // Balance number
                      Text(
                        coinBalance.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Available Coins label
                      const Text(
                        'Available Coins',
                        style: TextStyle(
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
              color: const Color(0xFF04B104).withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Total Earnings',
              style: TextStyle(
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
              child: const Text(
                'Withdraw Earnings',
                style: TextStyle(
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF92400E).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[700],
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: [
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 16),
                  SizedBox(width: 6),
                  Text('Flat Recharge'),
                ],
              ),
            ),
            Tab(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.store, size: 16),
                      SizedBox(width: 6),
                      Text('Reseller'),
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
                            color: const Color(0xFFFF512F).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'SAVE 20%',
                        style: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Deposit Amount',
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
              final cardWidth = (constraints.maxWidth - 16) / 3;
              final cardHeight = cardWidth * 1.1;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: cardWidth / cardHeight,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: rechargePackages.length,
                itemBuilder: (context, index) {
                  return _buildDepositCard(rechargePackages[index]);
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
      padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFFFF8E53).withOpacity(0.4),
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
                      color: Colors.white.withOpacity(0.25),
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
                        const Text(
                          '💰 Get Best Deals!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save up to 20% with trusted resellers',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
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
                    child: const Text(
                      'BEST',
                      style: TextStyle(
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
                ? const Color(0xFF10B981).withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                    color: const Color(0xFF92400E).withOpacity(0.3),
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
                      children: const [
                        Icon(
                          Icons.chat_bubble,
                    color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                      Text(
                          'Chat',
                        style: TextStyle(
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

  // ========== DEPOSIT CARD (3-COLUMN GRID) ==========
  Widget _buildDepositCard(Map<String, dynamic> package) {
    final int coins = package['coins'];
    final int inr = package['inr'];
    
    return GestureDetector(
        onTap: () => _showPaymentDialog(package),
        child: Container(
        padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
            border: Border.all(
            color: const Color(0xFFD97706).withOpacity(0.3),
            width: 1,
            ),
            boxShadow: [
              BoxShadow(
              color: const Color(0xFFFFB800).withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
              ),
            ],
          ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                // Star coin icon
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFB800)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(height: 5),
                // Coin value
                Text(
                  '$coins',
                    style: const TextStyle(
                    fontSize: 13,
                      fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                const Text(
                  'Coins',
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
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
                  '₹$inr',
                      style: const TextStyle(
                    fontSize: 11,
                        fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== DIALOGS ==========
  void _showPaymentDialog(Map<String, dynamic> package) {
    final int coins = package['coins'];
    final int inr = package['inr'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB800)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$coins Coins',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
              Text(
              '₹$inr',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB800),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment via Google Play',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement Google Play payment
              _showSuccessDialog('Recharge successful!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF04B104).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF04B104),
                        size: 16,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'INR',
                        style: TextStyle(
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
                labelText: 'Withdrawal Amount (INR)',
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
            const Text(
              'Minimum withdrawal: ₹50',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              amountController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount >= 50 && amount <= hostEarnings) {
                amountController.dispose();
                Navigator.pop(context);
                // TODO: Implement withdrawal API
                _showSuccessDialog('Withdrawal request submitted!');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid amount')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF04B104),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF04B104))),
          ),
        ],
      ),
    );
  }

  // ========== START CHAT WITH RESELLER ==========
  void _startChatWithReseller(Map<String, dynamic> reseller) {
    // Navigate to Messages screen to start chat
    // In production, this would navigate to a chat screen with the reseller
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Starting chat with ${reseller['name']}...',
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
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to chat/messages screen with reseller
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(reseller: reseller)));
          },
        ),
      ),
    );
  }
}

