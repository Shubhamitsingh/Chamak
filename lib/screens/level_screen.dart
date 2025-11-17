import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class LevelScreen extends StatefulWidget {
  final int userLevel;
  
  const LevelScreen({
    super.key,
    required this.userLevel,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  // Mock progress data
  int currentXP = 3500;
  int xpForNextLevel = 5000;
  
  // Achievements
  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'First Stream',
      'description': 'Watch your first live stream',
      'icon': Icons.play_circle,
      'color': Colors.blue,
      'completed': true,
    },
    {
      'title': 'Gift Giver',
      'description': 'Send 10 gifts to hosts',
      'icon': Icons.card_giftcard,
      'color': Colors.pink,
      'completed': true,
    },
    {
      'title': 'Social Butterfly',
      'description': 'Follow 50 people',
      'icon': Icons.people,
      'color': Colors.orange,
      'completed': true,
    },
    {
      'title': 'Night Owl',
      'description': 'Watch streams after midnight',
      'icon': Icons.nightlight_round,
      'color': Colors.indigo,
      'completed': false,
    },
    {
      'title': 'VIP Member',
      'description': 'Reach level 20',
      'icon': Icons.workspace_premium,
      'color': Colors.amber,
      'completed': false,
    },
    {
      'title': 'Super Fan',
      'description': 'Watch 100 hours of streams',
      'icon': Icons.star,
      'color': Colors.purple,
      'completed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / xpForNextLevel;
    final completedCount = achievements.where((a) => a['completed']).length;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Level & Achievements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Level Card
            _buildLevelCard(progress),
            
            const SizedBox(height: 20),
            
            // Stats Card
            _buildStatsCard(completedCount),
            
            const SizedBox(height: 20),
            
            // Achievements List
            _buildAchievementsList(),
          ],
        ),
      ),
    );
  }

  // ========== LEVEL CARD ==========
  Widget _buildLevelCard(double progress) {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Level Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.military_tech,
                      color: Color(0xFFFF6B35),
                      size: 40,
                    ),
                    Text(
                      '${widget.userLevel}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Your Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${widget.userLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Level ${widget.userLevel + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$currentXP / $xpForNextLevel XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== STATS CARD ==========
  Widget _buildStatsCard(int completedCount) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.emoji_events,
              label: 'Achievements',
              value: '$completedCount/${achievements.length}',
              color: Colors.amber,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              icon: Icons.trending_up,
              label: 'Total XP',
              value: '${(widget.userLevel * 5000) + currentXP}',
              color: Colors.green,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              icon: Icons.star,
              label: 'Rank',
              value: '#${widget.userLevel * 100}',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ========== ACHIEVEMENTS LIST ==========
  Widget _buildAchievementsList() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            ...achievements.map((achievement) => _buildAchievementTile(achievement)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: achievement['completed']
            ? LinearGradient(
                colors: [
                  achievement['color'].withOpacity(0.1),
                  achievement['color'].withOpacity(0.05),
                ],
              )
            : null,
        color: achievement['completed'] ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: achievement['completed']
              ? achievement['color'].withOpacity(0.3)
              : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement['completed']
                  ? achievement['color'].withOpacity(0.2)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement['icon'],
              color: achievement['completed'] ? achievement['color'] : Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: achievement['completed'] ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    if (achievement['completed']) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF04B104),
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: achievement['completed'] ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (achievement['completed'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: achievement['color'],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                '+100 XP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(
              Icons.lock,
              color: Colors.grey[400],
              size: 24,
            ),
        ],
      ),
    );
  }
}

