import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class LevelScreen extends StatefulWidget {
  final int? userLevel;
  
  const LevelScreen({
    super.key,
    this.userLevel,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  int _currentLevel = 1;
  int _totalCoins = 0;
  int _coinsForNextLevel = 1300;
  bool _isLoading = true;
  bool _isHostLevel = false; // false = User Level, true = Host Level
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  // Simplified level table for display with pink theme
  final List<Map<String, dynamic>> _levelTable = [
    {'label': 'Lv0', 'amount': '0', 'level': 0, 'color': const Color(0xFF9E9E9E)},
    {'label': 'Lv1', 'amount': '10,000', 'level': 1, 'color': const Color(0xFFFFB3D9)},
    {'label': 'Lv2', 'amount': '30,000', 'level': 2, 'color': const Color(0xFFFF99CC)},
    {'label': 'Lv3', 'amount': '100,000', 'level': 3, 'color': const Color(0xFFFF80BF)},
    {'label': 'Lv4', 'amount': '300,000', 'level': 4, 'color': const Color(0xFFFF66B2)},
    {'label': 'Lv5', 'amount': '1,000,000', 'level': 5, 'color': const Color(0xFFFF4DA6)},
    {'label': 'Lv6', 'amount': '3,000,000', 'level': 6, 'color': const Color(0xFFFF3399)},
    {'label': 'Lv7', 'amount': '10,000,000', 'level': 7, 'color': const Color(0xFFFF1A8C)},
    {'label': 'Lv8', 'amount': '30,000,000', 'level': 8, 'color': const Color(0xFFFF1B7C)},
    {'label': 'Lv9', 'amount': '100,000,000', 'level': 9, 'color': const Color(0xFFE91E63)},
    {'label': 'Lv10', 'amount': '300,000,000', 'level': 10, 'color': const Color(0xFFC2185B)},
    {'label': 'Lv20', 'amount': '1,000,000,000', 'level': 20, 'color': const Color(0xFFAD1457)},
    {'label': 'Lv30', 'amount': '3,000,000,000', 'level': 30, 'color': const Color(0xFF880E4F)},
    {'label': 'Lv40', 'amount': '10,000,000,000', 'level': 40, 'color': const Color(0xFF6A1B9A)},
    {'label': 'Lv50', 'amount': '30,000,000,000', 'level': 50, 'color': const Color(0xFF4A148C)},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final user = await _databaseService.getUserData(userId);
      if (user != null && mounted) {
        setState(() {
          _user = user;
          // Use appropriate field based on level type
          _totalCoins = _isHostLevel ? user.totalCoinsReceived : user.totalCoinsPurchased;
          // Calculate level from coins (always recalculate to ensure accuracy)
          _currentLevel = _calculateLevelFromCoins(_totalCoins);
          _coinsForNextLevel = _calculateCoinsForNextLevel(_currentLevel);
          _isLoading = false;
        });
        
        // Update saved level if calculated level differs from saved level
        final savedLevel = _isHostLevel ? _user!.hostLevel : _user!.userLevel;
        if (_currentLevel != savedLevel) {
          await _updateUserLevel(_currentLevel);
        }
        
        _progressController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateLevelFromCoins(int coins) {
    if (coins < 1300) return 1;
    if (coins < 2800) return 2;
    if (coins < 4600) return 3;
    if (coins < 6700) return 4;
    if (coins < 9200) return 5;
    
    int level = 5;
    int requiredCoins = 9200;
    int increment = 2500;
    
    while (coins >= requiredCoins && level < 99) {
      level++;
      increment = (increment * 1.15).round();
      requiredCoins += increment;
    }
    
    return level.clamp(1, 99);
  }

  int _calculateCoinsForNextLevel(int currentLevel) {
    if (currentLevel == 1) return 1300;
    if (currentLevel == 2) return 1500;
    if (currentLevel == 3) return 1800;
    if (currentLevel == 4) return 2100;
    if (currentLevel == 5) return 2500;
    
    int baseIncrement = 2500;
    for (int i = 6; i <= currentLevel; i++) {
      baseIncrement = (baseIncrement * 1.15).round();
    }
    return baseIncrement;
  }

  int _getTotalCoinsForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 1300;
    if (level == 3) return 2800;
    if (level == 4) return 4600;
    if (level == 5) return 6700;
    if (level == 6) return 9200;
    
    int total = 9200;
    int increment = 2500;
    for (int i = 6; i < level; i++) {
      total += increment;
      increment = (increment * 1.15).round();
    }
    return total;
  }

  Future<void> _updateUserLevel(int newLevel) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Update the appropriate level field based on type
      final updateData = _isHostLevel
          ? {'hostLevel': newLevel}
          : {'userLevel': newLevel};
      
      // Also update legacy level field for backward compatibility
      updateData['level'] = newLevel;
      
      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      debugPrint('Error updating level: $e');
    }
  }

  bool _hasReachedLevelRange(int minLevel, int maxLevel) {
    return _currentLevel >= minLevel && _currentLevel <= maxLevel;
  }

  // ignore: unused_element
  bool _hasCompletedLevelRange(int minLevel, int maxLevel) {
    return _currentLevel > maxLevel;
  }

  double _getLevelProgress() {
    if (_currentLevel == 1) {
      return (_totalCoins / 1300).clamp(0.0, 1.0);
    }
    
    int coinsForCurrentLevel = _getTotalCoinsForLevel(_currentLevel);
    int coinsForNextLevel = _getTotalCoinsForLevel(_currentLevel + 1);
    int coinsInCurrentLevel = _totalCoins - coinsForCurrentLevel;
    int coinsNeededForNext = coinsForNextLevel - coinsForCurrentLevel;
    
    if (coinsNeededForNext <= 0) return 1.0;
    return (coinsInCurrentLevel / coinsNeededForNext).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFFFF69B4),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 12),
              Text(
                'Loading your progress...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = _getLevelProgress();
    final coinsNeeded = _coinsForNextLevel - (_totalCoins - _getTotalCoinsForLevel(_currentLevel));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Fixed Top Section
          _buildTopSection(progress, coinsNeeded),
          // Scrollable Rewards Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildRewardsSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Wealth',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isHostLevel) return;
                setState(() {
                  _isHostLevel = false;
                  _updateLevelCalculation();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isHostLevel ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'User Level',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: !_isHostLevel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isHostLevel) return;
                setState(() {
                  _isHostLevel = true;
                  _updateLevelCalculation();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isHostLevel ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Host Level',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: _isHostLevel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateLevelCalculation() {
    if (_user == null) return;
    // Recalculate based on selected level type
    _totalCoins = _isHostLevel ? _user!.totalCoinsReceived : _user!.totalCoinsPurchased;
    _currentLevel = _calculateLevelFromCoins(_totalCoins);
    _coinsForNextLevel = _calculateCoinsForNextLevel(_currentLevel);
    // Update saved level in Firestore
    _updateUserLevel(_currentLevel);
    _progressController.reset();
    _progressController.forward();
  }

  Widget _buildTopSection(double progress, int coinsNeeded) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1B7C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Profile Picture
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _hasReachedLevelRange(1, 9) ? _pulseAnimation.value : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: _user?.photoURL != null && _user!.photoURL!.isNotEmpty
                              ? NetworkImage(_user!.photoURL!)
                              : null,
                          child: _user?.photoURL == null || _user!.photoURL!.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Level Display
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: _currentLevel),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                'Lv.$value',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Level Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF66BB6A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '$_currentLevel',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Total Coins Display
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/coin3.png',
                            width: 12,
                            height: 12,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.monetization_on, color: Colors.white, size: 12);
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_totalCoins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${_isHostLevel ? "received" : "purchased"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'To Lv.${_currentLevel + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    widthFactor: progress * _progressAnimation.value,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF4CAF50),
                                            Color(0xFF66BB6A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF4CAF50).withOpacity(0.5),
                                            blurRadius: 6,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Coins to Upgrade Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/coin3.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18);
                        },
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$coinsNeeded',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'upgrade',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Level Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLevelTypeToggle(),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1B7C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events, color: Color(0xFFFF1B7C), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                _isHostLevel ? 'Host Level Requirements' : 'User Level Requirements',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.15)),
              bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
            ),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF1B7C).withOpacity(0.1),
                      const Color(0xFFFF69B4).withOpacity(0.1),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFFF1B7C).withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Level',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFFFF1B7C),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _isHostLevel ? 'Coins Received' : 'Coins Purchased',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFFFF1B7C),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Data Rows
              ..._levelTable.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final rowLevel = row['level'] as int;
                // Find the highest level in table that user has reached
                int? nextTableLevel;
                if (index < _levelTable.length - 1) {
                  nextTableLevel = _levelTable[index + 1]['level'] as int;
                }
                // Highlight if user is at or past this level, but hasn't reached next table level
                final isCurrentLevel = _currentLevel >= rowLevel && 
                    (nextTableLevel == null || _currentLevel < nextTableLevel);
                final isEven = index % 2 == 0;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isCurrentLevel
                        ? const Color(0xFFFF1B7C).withOpacity(0.1)
                        : isEven
                            ? Colors.white
                            : Colors.grey.shade50,
                    border: Border(
                      left: isCurrentLevel
                          ? const BorderSide(color: Color(0xFFFF1B7C), width: 3)
                          : BorderSide.none,
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                _buildLevelBadge(row['label'] as String, row['color'] as Color),
                                if (isCurrentLevel) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row['amount'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.w600,
                                color: isCurrentLevel
                                    ? const Color(0xFFFF1B7C)
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      if (isCurrentLevel && rowLevel == _currentLevel && _coinsForNextLevel > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progress to next level',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _getLevelProgress(),
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF1B7C),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/coin3.png',
                                        width: 12,
                                        height: 12,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.monetization_on, color: Colors.grey, size: 12);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(_getTotalCoinsForLevel(_currentLevel + 1) - _totalCoins).clamp(0, _coinsForNextLevel)} coins needed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildOrnateFrame(int minLevel, bool hasCompleted, bool hasReached) {
    final isActive = hasCompleted || hasReached;
    
    // Determine frame style based on level range
    FrameStyle frameStyle;
    Color frameColor;
    IconData centerIcon;
    double iconSize;
    
    if (minLevel >= 90) {
      frameStyle = FrameStyle.ultimate;
      frameColor = const Color(0xFFFF6F00);
      centerIcon = Icons.diamond;
      iconSize = 24;
    } else if (minLevel >= 80) {
      frameStyle = FrameStyle.gem;
      frameColor = const Color(0xFFB71C1C);
      centerIcon = Icons.diamond;
      iconSize = 22;
    } else if (minLevel >= 70) {
      frameStyle = FrameStyle.crown;
      frameColor = const Color(0xFFD32F2F);
      centerIcon = Icons.star;
      iconSize = 22;
    } else if (minLevel >= 60) {
      frameStyle = FrameStyle.doubleWing;
      frameColor = const Color(0xFFC2185B);
      centerIcon = Icons.star;
      iconSize = 21;
    } else if (minLevel >= 50) {
      frameStyle = FrameStyle.wing;
      frameColor = const Color(0xFFE91E63);
      centerIcon = Icons.star;
      iconSize = 20;
    } else if (minLevel >= 40) {
      frameStyle = FrameStyle.star;
      frameColor = const Color(0xFF6A1B9A);
      centerIcon = Icons.star;
      iconSize = 19;
    } else if (minLevel >= 30) {
      frameStyle = FrameStyle.corner;
      frameColor = const Color(0xFF7B1FA2);
      centerIcon = Icons.circle;
      iconSize = 18;
    } else if (minLevel >= 20) {
      frameStyle = FrameStyle.spike;
      frameColor = const Color(0xFF9C27B0);
      centerIcon = Icons.circle;
      iconSize = 17;
    } else if (minLevel >= 10) {
      frameStyle = FrameStyle.dot;
      frameColor = const Color(0xFF03A9F4);
      centerIcon = Icons.circle;
      iconSize = 16;
    } else {
      frameStyle = FrameStyle.simple;
      frameColor = const Color(0xFF4CAF50);
      centerIcon = Icons.circle;
      iconSize = 16;
    }
    
    return AnimatedBuilder(
      animation: isActive && minLevel >= 50 ? _pulseController : _progressController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive && minLevel >= 50 ? (1.0 + (_pulseAnimation.value - 1.0) * 0.08) : 1.0,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? frameColor : Colors.grey[300]!,
                width: minLevel >= 80 ? 2.5 : minLevel >= 50 ? 2.2 : minLevel >= 20 ? 2 : 1.8,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: frameColor.withOpacity(0.5),
                        blurRadius: minLevel >= 80 ? 10 : minLevel >= 50 ? 8 : 6,
                        spreadRadius: minLevel >= 80 ? 2.5 : minLevel >= 50 ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              frameColor,
                              frameColor.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: isActive ? null : Colors.grey[100],
                  ),
                ),
                if (isActive)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _getFramePainter(frameStyle, frameColor),
                    ),
                  ),
                Center(
                  child: Icon(
                    centerIcon,
                    color: isActive ? Colors.white : Colors.grey[400],
                    size: iconSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CustomPainter _getFramePainter(FrameStyle style, Color color) {
    switch (style) {
      case FrameStyle.simple:
        return _SimpleFramePainter(color);
      case FrameStyle.dot:
        return _DotFramePainter(color);
      case FrameStyle.spike:
        return _SpikeFramePainter(color);
      case FrameStyle.corner:
        return _CornerFramePainter(color);
      case FrameStyle.star:
        return _StarFramePainter(color);
      case FrameStyle.wing:
        return _WingFramePainter(color);
      case FrameStyle.doubleWing:
        return _DoubleWingFramePainter(color);
      case FrameStyle.crown:
        return _CrownFramePainter(color);
      case FrameStyle.gem:
        return _GemFramePainter(color);
      case FrameStyle.ultimate:
        return _UltimateFramePainter(color);
    }
  }
}

enum FrameStyle {
  simple,
  dot,
  spike,
  corner,
  star,
  wing,
  doubleWing,
  crown,
  gem,
  ultimate,
}

// Frame Painters for different level ranges
class _SimpleFramePainter extends CustomPainter {
  final Color color;
  _SimpleFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Simple circle - no decorations
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotFramePainter extends CustomPainter {
  final Color color;
  _DotFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw decorative dots around the circle
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final dotX = center.dx + (radius - 2) * math.cos(angle);
      final dotY = center.dy + (radius - 2) * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpikeFramePainter extends CustomPainter {
  final Color color;
  _SpikeFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw small spikes around the circle
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2) / 12;
      final startX = center.dx + (radius - 3) * math.cos(angle);
      final startY = center.dy + (radius - 3) * math.sin(angle);
      final endX = center.dx + (radius + 5) * math.cos(angle);
      final endY = center.dy + (radius + 5) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerFramePainter extends CustomPainter {
  final Color color;
  _CornerFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw corner decorations (4 corners)
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi * 2) / 4 + math.pi / 4;
      final cornerX = center.dx + (radius - 2) * math.cos(angle);
      final cornerY = center.dy + (radius - 2) * math.sin(angle);
      
      // Draw small corner lines
      canvas.drawLine(
        Offset(cornerX - 4, cornerY - 4),
        Offset(cornerX + 4, cornerY + 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarFramePainter extends CustomPainter {
  final Color color;
  _StarFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw star points (8 points)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = center.dx + (radius - 3) * math.cos(angle);
      final startY = center.dy + (radius - 3) * math.sin(angle);
      final endX = center.dx + (radius + 6) * math.cos(angle);
      final endY = center.dy + (radius + 6) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WingFramePainter extends CustomPainter {
  final Color color;
  _WingFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw wing-like extensions (8 wings)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = center.dx + (radius - 4) * math.cos(angle);
      final startY = center.dy + (radius - 4) * math.sin(angle);
      final endX = center.dx + (radius + 7) * math.cos(angle);
      final endY = center.dy + (radius + 7) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoubleWingFramePainter extends CustomPainter {
  final Color color;
  _DoubleWingFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw double wing extensions (8 main wings + 8 smaller wings)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      // Main wing
      final startX = center.dx + (radius - 4) * math.cos(angle);
      final startY = center.dy + (radius - 4) * math.sin(angle);
      final endX = center.dx + (radius + 8) * math.cos(angle);
      final endY = center.dy + (radius + 8) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      
      // Secondary wing (between main wings)
      final angle2 = angle + (math.pi / 8);
      final startX2 = center.dx + (radius - 3) * math.cos(angle2);
      final startY2 = center.dy + (radius - 3) * math.sin(angle2);
      final endX2 = center.dx + (radius + 5) * math.cos(angle2);
      final endY2 = center.dy + (radius + 5) * math.sin(angle2);
      canvas.drawLine(Offset(startX2, startY2), Offset(endX2, endY2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownFramePainter extends CustomPainter {
  final Color color;
  _CrownFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw crown-like decorations (top spikes)
    for (int i = 0; i < 5; i++) {
      final angle = (i * math.pi * 2) / 5 - math.pi / 2;
      final startX = center.dx + (radius - 3) * math.cos(angle);
      final startY = center.dy + (radius - 3) * math.sin(angle);
      final endX = center.dx + (radius + 9) * math.cos(angle);
      final endY = center.dy + (radius + 9) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
    
    // Draw additional decorative elements
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final dotX = center.dx + (radius - 2) * math.cos(angle);
      final dotY = center.dy + (radius - 2) * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 1.5, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GemFramePainter extends CustomPainter {
  final Color color;
  _GemFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw gem-like facets (12 facets)
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2) / 12;
      final startX = center.dx + (radius - 3) * math.cos(angle);
      final startY = center.dy + (radius - 3) * math.sin(angle);
      final endX = center.dx + (radius + 8) * math.cos(angle);
      final endY = center.dy + (radius + 8) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
    
    // Draw inner decorative ring
    final innerPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UltimateFramePainter extends CustomPainter {
  final Color color;
  _UltimateFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw ultimate ornate frame with multiple layers
    // Outer layer - large wings (8)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = center.dx + (radius - 5) * math.cos(angle);
      final startY = center.dy + (radius - 5) * math.sin(angle);
      final endX = center.dx + (radius + 10) * math.cos(angle);
      final endY = center.dy + (radius + 10) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
    
    // Middle layer - medium wings (16)
    final mediumPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi * 2) / 16;
      final startX = center.dx + (radius - 3) * math.cos(angle);
      final startY = center.dy + (radius - 3) * math.sin(angle);
      final endX = center.dx + (radius + 6) * math.cos(angle);
      final endY = center.dy + (radius + 6) * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), mediumPaint);
    }
    
    // Inner decorative dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2) / 12;
      final dotX = center.dx + (radius - 4) * math.cos(angle);
      final dotY = center.dy + (radius - 4) * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 2, dotPaint);
    }
    
    // Inner ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
