import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _GiftSelectionSheetState extends State<GiftSelectionSheet> {
  String _selectedCategory = 'Hot';
  String? _selectedGiftId; // Track selected gift by ID
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gift emoji/icon
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Text(
              giftEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        // Gift name
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              giftName,
              style: TextStyle(
                color: Colors.white, // White text for dark background
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Gift cost with star icon container (same as wallet page)
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/coin3.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$giftCost',
                  style: TextStyle(
                    color: canAfford ? Colors.amber : Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
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
        final walletData = walletDoc.data() as Map<String, dynamic>?;
        final balance = (walletData?['balance'] as int?) ?? 0;
        final coins = (walletData?['coins'] as int?) ?? 0;
        userBalance = balance > 0 ? balance : coins;
      } else {
        final userDoc = await _firestore.collection('users').doc(widget.senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final uCoins = (userData?['uCoins'] as int?) ?? 0;
          final coins = (userData?['coins'] as int?) ?? 0;
          userBalance = uCoins >= coins ? uCoins : coins;
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
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Categories
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
            child: Row(
              children: ['Hot', 'Lucky', 'Funny', 'Luxury'].map((category) {
                final isSelected = _selectedCategory == category;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _selectedGiftId = null; // Clear selection when changing category
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF9C27B0) // Purple when selected
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Gift grid with real-time balance
          Expanded(
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
                      userBalance = uCoins >= coins ? uCoins : coins;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
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
                          child: isSelected
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF9C27B0), // Purple
                                        Color(0xFFE91E63), // Pink
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(1.5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10.5),
                                    ),
                                    child: _buildGiftContent(gift, giftCost, giftName, giftEmoji, canAfford),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: canAfford
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
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
          // Bottom section: Balance, pagination, send button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), // Reduced top padding to remove gap
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                            userBalance = uCoins >= coins ? uCoins : coins;
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
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$userBalance',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 10,
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
                      // Send icon with gradient rectangular container
                      Container(
                        width: 40,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF9C27B0), // Purple
                              Color(0xFFE91E63), // Pink
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6), // Rectangular with rounded corners
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white, // White icon for gradient background
                            size: 22,
                          ),
                          onPressed: _sendSelectedGift,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close icon
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
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
