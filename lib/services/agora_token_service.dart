import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for generating Agora tokens securely from Firebase Cloud Functions
/// 
/// This service handles:
/// - Fetching tokens from Firebase Cloud Functions
/// - Caching tokens to avoid repeated calls
/// - Handling token expiration
/// - Error handling and retries
class AgoraTokenService {
  static final AgoraTokenService _instance = AgoraTokenService._internal();
  factory AgoraTokenService() => _instance;
  AgoraTokenService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for tokens: key = "channelName_uid_role", value = TokenCache
  final Map<String, _TokenCache> _tokenCache = {};

  /// Generate or retrieve cached Agora token
  /// 
  /// Parameters:
  /// - [channelName]: The Agora channel name (required)
  /// - [uid]: User ID (optional, defaults to 0 for auto-assign)
  /// - [role]: "host" or "audience" (defaults to "host")
  /// - [forceRefresh]: Force generate new token even if cached (defaults to false)
  /// 
  /// Returns:
  /// - Token string if successful
  /// - Throws exception if failed
  Future<String> getToken({
    required String channelName,
    int? uid,
    String role = 'host',
    bool forceRefresh = false,
  }) async {
    // Validate inputs
    if (channelName.isEmpty) {
      throw ArgumentError('Channel name cannot be empty');
    }

    if (role != 'host' && role != 'audience') {
      throw ArgumentError('Role must be "host" or "audience"');
    }

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cacheKey = _getCacheKey(channelName, uid, role);
      final cached = _tokenCache[cacheKey];
      
      if (cached != null && !cached.isExpired()) {
        // Return cached token if still valid
        return cached.token;
      }
    }

    // Ensure user is authenticated
    if (_auth.currentUser == null) {
      throw Exception('User must be authenticated to generate Agora token');
    }

    try {
      // Call Firebase Cloud Function
      final callable = _functions.httpsCallable('generateAgoraToken');
      
      final result = await callable.call({
        'channelName': channelName,
        'uid': uid,
        'role': role,
      });

      // Extract token from response
      final data = result.data as Map<String, dynamic>;
      
      // Debug: Log full response
      print('🔍 Firebase Function Response:');
      print('   success: ${data['success']}');
      print('   token: ${data['token']} (type: ${data['token'].runtimeType})');
      print('   token is null: ${data['token'] == null}');
      print('   token isEmpty: ${data['token'] is String ? (data['token'] as String).isEmpty : 'N/A'}');
      print('   channelName: ${data['channelName']}');
      print('   uid: ${data['uid']}');
      print('   role: ${data['role']}');
      
      if (data['success'] != true || data['token'] == null) {
        print('❌ Response validation failed');
        print('   success: ${data['success']}');
        print('   token is null: ${data['token'] == null}');
        throw Exception('Failed to generate token: ${data['error'] ?? 'Unknown error'}');
      }

      final token = data['token'] as String?;
      
      if (token == null) {
        throw Exception('Token is null in response');
      }
      
      final expiresAt = data['expiresAt'] as int?;

      // Validate token is not empty
      if (token.isEmpty) {
        print('❌ Token is empty string');
        throw Exception('Token received from Firebase Function is empty');
      }

      // Debug logging
      print('🔑 Token received successfully:');
      print('   length: ${token.length} chars');
      print('   preview: ${token.substring(0, 20)}...');

      // Cache the token
      if (expiresAt != null) {
        final cacheKey = _getCacheKey(channelName, uid, role);
        _tokenCache[cacheKey] = _TokenCache(
          token: token,
          expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
        );
      }

      return token;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Firebase Functions error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to generate Agora token: $e');
    }
  }

  /// Generate token for live streaming (host)
  Future<String> getHostToken({
    required String channelName,
    int? uid,
  }) async {
    return getToken(
      channelName: channelName,
      uid: uid,
      role: 'host',
    );
  }

  /// Generate token for live streaming (audience/viewer)
  Future<String> getAudienceToken({
    required String channelName,
    int? uid,
  }) async {
    return getToken(
      channelName: channelName,
      uid: uid,
      role: 'audience',
    );
  }

  /// Clear token cache (useful for testing or logout)
  void clearCache() {
    _tokenCache.clear();
  }

  /// Clear specific cached token
  void clearCachedToken(String channelName, int? uid, String role) {
    final cacheKey = _getCacheKey(channelName, uid, role);
    _tokenCache.remove(cacheKey);
  }

  /// Get cache key for token
  String _getCacheKey(String channelName, int? uid, String role) {
    return '${channelName}_${uid ?? 0}_$role';
  }
}

/// Internal class for caching tokens
class _TokenCache {
  final String token;
  final DateTime expiresAt;

  _TokenCache({
    required this.token,
    required this.expiresAt,
  });

  /// Check if token is expired (with 5 minute buffer)
  bool isExpired() {
    // Consider expired if less than 5 minutes remaining
    final buffer = const Duration(minutes: 5);
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }
}

