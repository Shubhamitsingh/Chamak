import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/rating_service.dart';

class CallSummaryScreen extends StatefulWidget {
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
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  final RatingService _ratingService = RatingService();
  bool _hasShownReviewRequest = false;

  @override
  void initState() {
    super.initState();
    // Trigger review request after successful call (wait a moment)
    _triggerReviewAfterCall();
  }

  /// Trigger review request after successful call completion
  Future<void> _triggerReviewAfterCall() async {
    // Wait 2 seconds (don't interrupt user immediately)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasShownReviewRequest) return;

    try {
      // Check eligibility (rate limiting)
      final shouldShow = await _ratingService.shouldShowReviewRequest();
      if (!shouldShow) {
        debugPrint('ℹ️ Review request not eligible after call - skipping');
        return;
      }

      // Try native In-App Review API first (best UX)
      final nativeShown = await _ratingService.requestReview();

      if (nativeShown) {
        _hasShownReviewRequest = true;
        debugPrint('✅ Review request shown after successful call (native)');
        return;
      }

      // Fallback: Could show custom popup here if needed
      // For now, just mark as shown to avoid multiple attempts
      _hasShownReviewRequest = true;
      debugPrint('ℹ️ Review request eligible but native API not available');
    } catch (e) {
      debugPrint('❌ Error triggering review after call: $e');
    }
  }

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
        future: DatabaseService().getUserData(widget.otherUserId),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          final displayName = userData?.displayName ?? widget.otherUserName;
          final photoUrl = userData?.photoURL ?? widget.otherUserImage;

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
                          value: _formatDuration(widget.callDuration),
                          color: const Color(0xFFFF69B4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: widget.isHost ? Icons.monetization_on : null,
                          coinImage: widget.isHost ? null : 'assets/images/coin3.png',
                          label: widget.isHost ? 'Earned' : 'Spent',
                          value: widget.isHost ? '${widget.coinsEarned}' : '${widget.coinsSpent}',
                          color: widget.isHost ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
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
                        widget.isHost ? 'Call History' : 'Call Summary',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.phone,
                        text: 'You talked for ${_formatDuration(widget.callDuration)}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        icon: widget.isHost ? Icons.trending_up : null,
                        coinImage: widget.isHost ? null : 'assets/images/coin3.png',
                        text: widget.isHost 
                            ? 'You earned ${widget.coinsEarned} coins from this call'
                            : 'You spent ${widget.coinsSpent} coins for this call',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        icon: Icons.person,
                        text: widget.isHost 
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
