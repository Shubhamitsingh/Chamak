import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/gift_model.dart';
import '../screens/wallet_screen.dart';

class GiftSelectionSheet extends StatefulWidget {
  final String liveStreamId;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final Function(String giftName, int giftCost, String giftEmoji) onGiftSelected;

  const GiftSelectionSheet({
    super.key,
    required this.liveStreamId,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.onGiftSelected,
  });

  @override
  State<GiftSelectionSheet> createState() => _GiftSelectionSheetState();
}

class _GiftSelectionSheetState extends State<GiftSelectionSheet> with TickerProviderStateMixin {
  String _selectedCategory = 'Funny';
  String? _selectedGiftId; // Track selected gift by ID
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Category list in order
  final List<String> _categories = ['Funny', 'Hot', 'Lucky', 'Luxury'];
  
  // Animation controllers for category menu items
  late List<AnimationController> _categoryAnimationControllers;
  late List<Animation<double>> _categoryAnimations;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for each category
    _categoryAnimationControllers = List.generate(
      _categories.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );
    
    // Create animations with random delays
    _categoryAnimations = _categoryAnimationControllers.map((controller) {
      return Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();
    
    // Start random animations
    _startRandomAnimations();
  }
  
  void _startRandomAnimations() {
    // Randomly select 1-2 categories to animate
    final numToAnimate = _random.nextInt(2) + 1; // 1 or 2
    final indicesToAnimate = <int>{};
    
    while (indicesToAnimate.length < numToAnimate) {
      indicesToAnimate.add(_random.nextInt(_categories.length));
    }
    
    // Start animations with random delays
    for (final index in indicesToAnimate) {
      final delay = _random.nextInt(300); // 0-300ms delay
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          _categoryAnimationControllers[index].forward();
        }
      });
    }
  }
  
  @override
  void dispose() {
    for (final controller in _categoryAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // Change category (next or previous)
  void _changeCategory(bool next) {
    final currentIndex = _categories.indexOf(_selectedCategory);
    if (next) {
      // Next category
      if (currentIndex < _categories.length - 1) {
        setState(() {
          _selectedCategory = _categories[currentIndex + 1];
          _selectedGiftId = null; // Clear selection when changing category
        });
      }
    } else {
      // Previous category
      if (currentIndex > 0) {
        setState(() {
          _selectedCategory = _categories[currentIndex - 1];
          _selectedGiftId = null; // Clear selection when changing category
        });
      }
    }
  }

  List<GiftModel> get _currentGifts {
    switch (_selectedCategory) {
      case 'Hot':
        return GiftModel.getHotGifts();
      case 'Lucky':
        return GiftModel.getLuckyGifts();
      case 'Funny':
        return GiftModel.getFunnyGifts();
      case 'Luxury':
        return GiftModel.getLuxuryGifts();
      default:
        return GiftModel.getHotGifts();
    }
  }

  void _selectGift(GiftModel gift) {
    // Set selected gift ID to show pink border
    setState(() {
      _selectedGiftId = gift.id;
    });
  }

  // Build gift content (emoji, name, cost) - extracted for reuse
  Widget _buildGiftContent(GiftModel gift, int giftCost, String giftName, String giftEmoji, bool canAfford) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gift emoji/icon - Larger size, no clipping
          Text(
            giftEmoji,
            style: const TextStyle(
              fontSize: 40,
              height: 1.0, // Prevent line height from clipping
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
          // Gift name with better typography
          Text(
            giftName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Gift cost with pink accent for affordable items
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 3),
              Text(
                '$giftCost',
                style: TextStyle(
                  color: canAfford 
                      ? const Color(0xFFFFD700) // Gold for affordable
                      : Colors.grey[500],
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  shadows: canAfford
                      ? [
                          Shadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendSelectedGift() async {
    if (_selectedGiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gift first'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Find the selected gift from current gifts
    final selectedGift = _currentGifts.firstWhere(
      (gift) => gift.id == _selectedGiftId,
      orElse: () => _currentGifts.first,
    );

    // Catalog gifts always have these fields, so we can safely use null assertion
    final giftCost = selectedGift.cost ?? 0;
    final giftName = selectedGift.name ?? 'Unknown';
    final giftEmoji = selectedGift.emoji ?? '🎁';
    
    // Get current balance from Firestore
    try {
      final walletDoc = await _firestore.collection('wallets').doc(widget.senderId).get();
      int userBalance = 0;
      
      if (walletDoc.exists) {
        final walletData = walletDoc.data();
        final balance = (walletData?['balance'] as int?) ?? 0;
        final coins = (walletData?['coins'] as int?) ?? 0;
        userBalance = balance > 0 ? balance : coins;
      } else {
        final userDoc = await _firestore.collection('users').doc(widget.senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final uCoins = (userData?['uCoins'] as int?) ?? 0;
          final coins = (userData?['coins'] as int?) ?? 0;
          // ALWAYS use uCoins as primary (it's always updated during deductions)
          // Only use coins if uCoins is 0 and coins has value (legacy data)
          userBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
        }
      }
      
      if (userBalance >= giftCost) {
        widget.onGiftSelected(giftName, giftCost, giftEmoji);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient diamonds! You need $giftCost diamonds.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error checking balance. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.50, // 50% of screen height
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Dark background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar - Pink themed
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF1B7C), // App theme pink
                  Color(0xFF9C27B0), // Purple
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // Categories - Only text, no containers/borders with random animations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isSelected = _selectedCategory == category;
                final hasAnimation = _categoryAnimationControllers[index].isAnimating ||
                    _categoryAnimationControllers[index].value > 0;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _selectedGiftId = null; // Clear selection when changing category
                      });
                    },
                    child: hasAnimation
                        ? AnimatedBuilder(
                            animation: _categoryAnimations[index],
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _categoryAnimations[index].value),
                                child: Opacity(
                                  opacity: 1.0 - (_categoryAnimations[index].value / 20.0).clamp(0.0, 1.0),
                                  child: Text(
                                    category,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Text(
                            category,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Gift grid with real-time balance and swipe support
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // Swipe left (negative velocity) = next category
                // Swipe right (positive velocity) = previous category
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -500) {
                    // Swipe left - next category
                    _changeCategory(true);
                  } else if (details.primaryVelocity! > 500) {
                    // Swipe right - previous category
                    _changeCategory(false);
                  }
                }
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('wallets').doc(widget.senderId).snapshots(),
                builder: (context, walletSnapshot) {
                  // Fallback to users collection if wallets doesn't exist
                  return StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('users').doc(widget.senderId).snapshots(),
                    builder: (context, userSnapshot) {
                      // Get balance from wallets collection first, then fallback to users
                      int userBalance = 0;
                      if (walletSnapshot.hasData && walletSnapshot.data!.exists) {
                        final walletData = walletSnapshot.data!.data() as Map<String, dynamic>?;
                        final balance = (walletData?['balance'] as int?) ?? 0;
                        final coins = (walletData?['coins'] as int?) ?? 0;
                        userBalance = balance > 0 ? balance : coins;
                      } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        final uCoins = (userData?['uCoins'] as int?) ?? 0;
                        final coins = (userData?['coins'] as int?) ?? 0;
                        // ALWAYS use uCoins as primary (it's always updated during deductions)
                        // Only use coins if uCoins is 0 and coins has value (legacy data)
                        userBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 1, // Minimal horizontal spacing
                          mainAxisSpacing: 0, // No vertical spacing between rows
                          childAspectRatio: 0.80, // More compact layout
                        ),
                      itemCount: _currentGifts.length,
                      itemBuilder: (context, index) {
                        final gift = _currentGifts[index];
                        final giftCost = gift.cost ?? 0;
                        final giftName = gift.name ?? 'Unknown';
                        final giftEmoji = gift.emoji ?? '🎁';
                        final canAfford = userBalance >= giftCost;
                        final isSelected = _selectedGiftId == gift.id;
                        return GestureDetector(
                          onTap: () => _selectGift(gift),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : (canAfford ? 1.0 : 0.6),
                            child: _buildGiftContent(gift, giftCost, giftName, giftEmoji, canAfford),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ),
          ),
          // Bottom section: Balance, pagination, send button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Star coin balance with container (same as wallet page) - Real-time
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('wallets').doc(widget.senderId).snapshots(),
                    builder: (context, walletSnapshot) {
                      // Fallback to users collection if wallets doesn't exist
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('users').doc(widget.senderId).snapshots(),
                        builder: (context, userSnapshot) {
                          // Get balance from wallets collection first, then fallback to users
                          int userBalance = 0;
                          if (walletSnapshot.hasData && walletSnapshot.data!.exists) {
                            final walletData = walletSnapshot.data!.data() as Map<String, dynamic>?;
                            final balance = (walletData?['balance'] as int?) ?? 0;
                            final coins = (walletData?['coins'] as int?) ?? 0;
                            userBalance = balance > 0 ? balance : coins;
                          } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                            final uCoins = (userData?['uCoins'] as int?) ?? 0;
                            final coins = (userData?['coins'] as int?) ?? 0;
                            // ALWAYS use uCoins as primary (it's always updated during deductions)
                            // Only use coins if uCoins is 0 and coins has value (legacy data)
                            userBalance = uCoins > 0 ? uCoins : (coins > 0 ? coins : 0);
                          }

                          return GestureDetector(
                            onTap: () {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (currentUser != null && currentUser.phoneNumber != null) {
                                Navigator.pop(context); // Close gift sheet first
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WalletScreen(
                                      phoneNumber: currentUser.phoneNumber!,
                                      isHost: false,
                                      showBackButton: true,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/coin3.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$userBalance',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFFFF1B7C),
                                  size: 12,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Send and Close icons (right side, starting from right)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Send button - Clean pink theme
                      GestureDetector(
                        onTap: _sendSelectedGift,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C), // App theme pink
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Close icon
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
