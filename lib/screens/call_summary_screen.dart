import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class CallSummaryScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final Duration callDuration;
  final int coinsSpent; // For user (caller)
  final int coinsEarned; // For host
  final bool isHost; // true if current user is host, false if caller

  const CallSummaryScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    required this.callDuration,
    required this.coinsSpent,
    required this.coinsEarned,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          'Call Ended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: DatabaseService().getUserData(otherUserId),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          final displayName = userData?.displayName ?? otherUserName;
          final photoUrl = userData?.photoURL ?? otherUserImage;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // Other User Profile Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF69B4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Other User Name
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Call Ended Text
                      Text(
                        'Call Ended Successfully',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Metrics Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: _formatDuration(callDuration),
                          color: const Color(0xFFFF69B4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: isHost ? Icons.monetization_on : null,
                          coinImage: isHost ? null : 'assets/images/coin3.png',
                          label: isHost ? 'Earned' : 'Spent',
                          value: isHost ? '$coinsEarned' : '$coinsSpent',
                          color: isHost ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Done Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Call History Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHost ? 'Call History' : 'Call Summary',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.phone,
                        text: 'You talked for ${_formatDuration(callDuration)}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        icon: isHost ? Icons.trending_up : null,
                        coinImage: isHost ? null : 'assets/images/coin3.png',
                        text: isHost 
                            ? 'You earned $coinsEarned coins from this call'
                            : 'You spent $coinsSpent coins for this call',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        icon: Icons.person,
                        text: isHost 
                            ? 'You received a call from $displayName'
                            : 'You called $displayName',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem({
    IconData? icon,
    String? coinImage,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 10),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFF69B4),
            shape: BoxShape.circle,
          ),
        ),
        if (coinImage != null)
          Image.asset(
            coinImage,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                icon ?? Icons.account_balance,
                size: 16,
                color: Colors.grey[300],
              );
            },
          )
        else if (icon != null)
          Icon(
            icon,
            size: 16,
            color: Colors.grey[300],
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    IconData? icon,
    String? coinImage,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (coinImage != null)
            Image.asset(
              coinImage,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  icon ?? Icons.account_balance_wallet,
                  color: color,
                  size: 24,
                );
              },
            )
          else if (icon != null)
            Icon(
              icon,
              color: color,
              size: 24,
            ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
