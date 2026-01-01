import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class LiveStreamSummaryScreen extends StatelessWidget {
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final Duration streamDuration;
  final int followersGained;
  final int incomeEarned;

  const LiveStreamSummaryScreen({
    super.key,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.streamDuration,
    required this.followersGained,
    required this.incomeEarned,
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
          'Live Ended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
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
        future: DatabaseService().getUserData(hostId),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          final displayName = userData?.displayName ?? hostName;
          final photoUrl = userData?.photoURL ?? hostPhotoUrl;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // Host Profile Section
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
                      // Host Name
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stream Ended Text
                      Text(
                        'Stream Ended Successfully',
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
                          value: _formatDuration(streamDuration),
                          color: const Color(0xFFFF69B4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people,
                          label: 'Followers',
                          value: '+$followersGained',
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.monetization_on,
                          label: 'Income',
                          value: '$incomeEarned',
                          color: const Color(0xFFFF9800),
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
                
                // Income Tips Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Increase Income Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem('Provide interesting and valuable content'),
                      const SizedBox(height: 8),
                      _buildTipItem('Actively interact with viewers'),
                      const SizedBox(height: 8),
                      _buildTipItem('Thank every viewer who joins and sends gift'),
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

  Widget _buildTipItem(String text) {
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
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
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
