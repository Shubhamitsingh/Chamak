import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../widgets/cached_avatar_widget.dart';

class HostRulesScreen extends StatefulWidget {
  final VoidCallback onGoLive;

  const HostRulesScreen({
    super.key,
    required this.onGoLive,
  });

  @override
  State<HostRulesScreen> createState() => _HostRulesScreenState();
}

class _HostRulesScreenState extends State<HostRulesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _databaseService.getUserData(userId);
        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chamakz Live',
          style: TextStyle(
            color: Color(0xFFFF1B7C),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[200]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // White Content Section - Scrollable
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                        stops: const [0.0, 0.3],
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          
                          // Progress Steps Indicator
                          _buildProgressSteps(),
                          
                          const SizedBox(height: 32),
                          
                          // Large Host Image
                          _buildHostImage(),
                          
                          const SizedBox(height: 24),
                          
                          // Speech Bubble with Text
                          _buildSpeechBubble(),
                          
                          const SizedBox(height: 28),
                          
                          // Host Rules List
                          _buildHostRulesList(),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Go Live Button - Fixed at Bottom
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: SafeArea(
                    top: false,
                    child: _buildGoLiveButton(),
                  ),
                ),
              ],
            ),
    );
  }

  // Progress Steps - Compact Design
  Widget _buildProgressSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1 - Active
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1B7C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rules',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          // Connector Line - Enhanced Design
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 35),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF1B7C).withValues(alpha: 0.4),
                    Colors.grey[300]!,
                    Colors.grey[200]!,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Step 2 - Next
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.live_tv,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Go Live',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Large Host Image - Compact Design
  Widget _buildHostImage() {
    final userId = _auth.currentUser?.uid ?? '';
    final photoURL = _userData?.photoURL;
    
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Circle with gradient
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF1B7C).withValues(alpha: 0.12),
                  const Color(0xFFFF69B4).withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          // Profile Image
          Padding(
            padding: const EdgeInsets.all(2.5),
            child: CachedAvatarWidget(
              photoURL: photoURL,
              userId: userId,
              radius: 67,
            ),
          ),
        ],
      ),
    );
  }

  // Speech Bubble - Enhanced Design
  Widget _buildSpeechBubble() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1B7C).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: const Color(0xFFFF1B7C).withValues(alpha: 0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Go live, make connections & get gifts',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Review the community guidelines to ensure a safe and positive experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  height: 1.4,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
        // Speech bubble tail (pointing up to host image)
        Positioned(
          top: -10,
          left: MediaQuery.of(context).size.width / 2 - 10,
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _SpeechBubblePainter(),
          ),
        ),
      ],
    );
  }

  // Host Rules List - Professional Design
  Widget _buildHostRulesList() {
    final rules = [
      {
        'icon': Icons.verified_user,
        'title': 'Age Verification',
        'description': 'You must be 18+ years old to go live',
      },
      {
        'icon': Icons.shield,
        'title': 'Content Guidelines',
        'description': 'No explicit, violent, or inappropriate content',
      },
      {
        'icon': Icons.people,
        'title': 'Respectful Behavior',
        'description': 'Be respectful to all viewers and maintain a positive environment',
      },
      {
        'icon': Icons.block,
        'title': 'No Harassment',
        'description': 'Harassment, bullying, or hate speech is strictly prohibited',
      },
      {
        'icon': Icons.privacy_tip,
        'title': 'Privacy & Safety',
        'description': 'Do not share personal information or engage in unsafe activities',
      },
      {
        'icon': Icons.monetization_on,
        'title': 'Gift Policy',
        'description': 'Gifts received are subject to platform terms and conditions',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1B7C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Community Guidelines',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) => _buildRuleItem(
                icon: rule['icon'] as IconData,
                title: rule['title'] as String,
                description: rule['description'] as String,
              )),
        ],
      ),
    );
  }

  // Individual Rule Item - Enhanced Design
  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF1B7C).withValues(alpha: 0.15),
                  const Color(0xFFFF1B7C).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF1B7C),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.4,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Go Live Button - Compact Design
  Widget _buildGoLiveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFF1B7C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1B7C).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onGoLive,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.live_tv,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Go Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Custom Painter for Speech Bubble Tail - Professional
class _SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2 - 10, size.height);
    path.lineTo(size.width / 2 + 10, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF1B7C).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
