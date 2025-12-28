import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class ViewerListSheet extends StatelessWidget {
  final String streamId;

  const ViewerListSheet({
    super.key,
    required this.streamId,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Audience',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Total count badge
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('live_streams')
                      .doc(streamId)
                      .collection('viewers')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Viewers list
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('live_streams')
                  .doc(streamId)
                  .collection('viewers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: const CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'Error loading viewers: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final viewers = snapshot.data?.docs ?? [];
                
                debugPrint('📊 Viewer list snapshot:');
                debugPrint('   Connection state: ${snapshot.connectionState}');
                debugPrint('   Has data: ${snapshot.hasData}');
                debugPrint('   Has error: ${snapshot.hasError}');
                debugPrint('   Error: ${snapshot.error}');
                debugPrint('   Viewers count: ${viewers.length}');
                for (var doc in viewers) {
                  debugPrint('     - Viewer ID: ${doc.id}, Data: ${doc.data()}');
                }

                if (viewers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: Colors.black,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No viewers yet',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewerDoc = viewers[index];
                    final viewerId = viewerDoc.id;
                    final joinedAt = viewerDoc.data() as Map<String, dynamic>?;
                    Timestamp? timestamp;
                    if (joinedAt != null) {
                      timestamp = joinedAt['joinedAt'] as Timestamp?;
                      // If joinedAt is null, try timestamp field
                      if (timestamp == null && joinedAt['timestamp'] != null) {
                        final ts = joinedAt['timestamp'] as int?;
                        if (ts != null) {
                          timestamp = Timestamp.fromMillisecondsSinceEpoch(ts);
                        }
                      }
                    }
                    debugPrint('📋 Viewer item: $viewerId, timestamp: $timestamp');

                    return FutureBuilder<UserModel?>(
                      future: _getUserDataWithFallback(databaseService, viewerId),
                      builder: (context, userSnapshot) {
                        final userModel = userSnapshot.data;
                        // Use displayName, name getter, or phoneNumber as fallback - never show raw ID
                        String displayName = 'User';
                        if (userModel != null) {
                          if (userModel.displayName != null && userModel.displayName!.isNotEmpty) {
                            displayName = userModel.displayName!;
                          } else {
                            displayName = userModel.name;
                          }
                        }
                        final profilePicture = userModel?.profileImage;
                        final gender = userModel?.gender;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Profile picture
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: (profilePicture != null && profilePicture.isNotEmpty)
                                    ? Image.network(
                                        profilePicture.toString(),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              
                              // User name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (gender != null && gender.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm'
                                                ? Icons.male
                                                : gender.toLowerCase() == 'female' || gender.toLowerCase() == 'f'
                                                    ? Icons.female
                                                    : Icons.transgender,
                                            color: gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm'
                                                ? Colors.blue
                                                : gender.toLowerCase() == 'female' || gender.toLowerCase() == 'f'
                                                    ? Colors.pink
                                                    : Colors.purple,
                                            size: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (timestamp != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatJoinTime(timestamp.toDate()),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Online indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinTime(DateTime joinTime) {
    final now = DateTime.now();
    final difference = now.difference(joinTime);

    if (difference.inMinutes < 1) {
      return 'Just joined';
    } else if (difference.inMinutes < 60) {
      return 'Joined ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Joined ${difference.inHours}h ago';
    } else {
      return 'Joined ${difference.inDays}d ago';
    }
  }

  // Helper method to get user data with fallback strategies
  Future<UserModel?> _getUserDataWithFallback(DatabaseService databaseService, String viewerId) async {
    try {
      debugPrint('🔍 Looking up user data for viewerId: $viewerId');
      
      // Try 1: Use viewerId as-is (could be phone number or UID)
      UserModel? user = await databaseService.getUserData(viewerId);
      if (user != null) {
        debugPrint('✅ Found user by direct ID: ${user.displayName ?? user.name}');
        return user;
      }

      // Try 2: If viewerId is a phone number with +, try without +
      if (viewerId.startsWith('+')) {
        final withoutPlus = viewerId.substring(1);
        user = await databaseService.getUserData(withoutPlus);
        if (user != null) {
          debugPrint('✅ Found user by ID without +: ${user.displayName ?? user.name}');
          return user;
        }
      }

      // Try 3: If viewerId is a phone number, try with +
      if (!viewerId.startsWith('+') && viewerId.length >= 10) {
        final withPlus = '+$viewerId';
        user = await databaseService.getUserData(withPlus);
        if (user != null) {
          debugPrint('✅ Found user by ID with +: ${user.displayName ?? user.name}');
          return user;
        }
      }

      // Try 4: Query users collection by phoneNumber field
      try {
        final firestore = FirebaseFirestore.instance;
        final querySnapshot = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: viewerId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final foundUser = UserModel.fromFirestore(querySnapshot.docs.first);
          debugPrint('✅ Found user by phoneNumber query: ${foundUser.displayName ?? foundUser.name}');
          return foundUser;
        }

        // Try 5: Query by phoneNumber without + if it has +
        if (viewerId.startsWith('+')) {
          final withoutPlus = viewerId.substring(1);
          final querySnapshot2 = await firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: withoutPlus)
              .limit(1)
              .get();

          if (querySnapshot2.docs.isNotEmpty) {
            final foundUser = UserModel.fromFirestore(querySnapshot2.docs.first);
            debugPrint('✅ Found user by phoneNumber (no +) query: ${foundUser.displayName ?? foundUser.name}');
            return foundUser;
          }
        }

        // Try 6: Query by userId field (in case viewerId is stored in userId field)
        final querySnapshot3 = await firestore
            .collection('users')
            .where('userId', isEqualTo: viewerId)
            .limit(1)
            .get();

        if (querySnapshot3.docs.isNotEmpty) {
          final foundUser = UserModel.fromFirestore(querySnapshot3.docs.first);
          debugPrint('✅ Found user by userId field: ${foundUser.displayName ?? foundUser.name}');
          return foundUser;
        }
      } catch (e) {
        debugPrint('❌ Error querying users collection: $e');
      }

      debugPrint('⚠️ Could not find user data for viewerId: $viewerId');
      return null;
    } catch (e) {
      debugPrint('❌ Error in _getUserDataWithFallback: $e');
      return null;
    }
  }
}

