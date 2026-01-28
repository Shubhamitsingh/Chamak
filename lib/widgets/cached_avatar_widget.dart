import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/avatar_service.dart';

/// Reusable avatar widget with caching and 429 error handling
/// Prevents crashes from DiceBear API rate limits
class CachedAvatarWidget extends StatelessWidget {
  final String? photoURL;
  final String userId;
  final double radius;
  final Color? backgroundColor;
  final String style; // 'big-smile' or 'avataaars'

  const CachedAvatarWidget({
    super.key,
    this.photoURL,
    required this.userId,
    this.radius = 40,
    this.backgroundColor,
    this.style = 'avataaars',
  });

  /// Get avatar URL (use photoURL if available, otherwise generate DiceBear URL)
  String get _avatarUrl {
    if (photoURL != null && photoURL!.isNotEmpty) {
      return photoURL!;
    }
    // Fallback: Generate DiceBear URL based on style
    final safeSeed = Uri.encodeComponent(userId);
    if (style == 'avataaars') {
      return 'https://api.dicebear.com/7.x/avataaars/png?seed=$safeSeed&backgroundColor=b6e3f4,c0aede,d1d4f9&size=${(radius * 2).toInt()}&randomizeIds=true';
    } else {
      return AvatarService.generateAvatarUrl(userId: userId);
    }
  }

  /// Build fallback avatar (when image fails to load or 429 error)
  Widget _buildFallbackAvatar() {
    final firstChar = userId.isNotEmpty ? userId[0].toUpperCase() : 'U';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFF9C27B0),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: _avatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (radius * 2).toInt(),
          memCacheHeight: (radius * 2).toInt(),
          maxWidthDiskCache: 400,
          maxHeightDiskCache: 400,
          httpHeaders: {
            'User-Agent': 'ChamakApp/1.0.9',
          },
          errorWidget: (context, url, error) {
            // Handle 429 and other errors gracefully - NO CRASHES
            debugPrint('⚠️ Avatar load error: $error for URL: $url');
            
            // Check if it's a 429 error (rate limit)
            final errorString = error.toString().toLowerCase();
            if (errorString.contains('429') || 
                errorString.contains('too many requests') ||
                errorString.contains('rate limit')) {
              debugPrint('⚠️ Rate limited (429) - using fallback avatar');
            }
            
            // Always return fallback - never crash
            return _buildFallbackAvatar();
          },
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: radius * 0.5,
              height: radius * 0.5,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF69B4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
