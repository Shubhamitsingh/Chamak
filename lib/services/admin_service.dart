import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin Service for managing user coins and admin operations
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _adminActionsCollection =>
      _firestore.collection('adminActions');

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      final adminDoc = await _firestore
          .collection('admins')
          .doc(currentUserId)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data();
        final isAdmin = data?['isAdmin'] ?? false;
        print('👤 Admin check: $isAdmin');
        return isAdmin;
      }

      print('👤 User is not an admin');
      return false;
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// Add U Coins to a user's account (admin only)
  Future<Map<String, dynamic>> addUCoinsToUser({
    required String userId,
    required int coinsToAdd,
    String? reason,
    String? notes,
  }) async {
    print('💰 [AdminService.addUCoinsToUser] CALLED');
    print('   userId: $userId');
    print('   coinsToAdd: $coinsToAdd');
    print('   reason: $reason');
    print('   currentUserId: $currentUserId');
    
    try {
      // Check if current user is admin
      print('🔍 [AdminService] Checking admin status...');
      final isUserAdmin = await isAdmin();
      print('🔍 [AdminService] Admin check result: $isUserAdmin');
      if (!isUserAdmin) {
        throw Exception('Unauthorized: Only admins can add coins');
      }

      if (coinsToAdd <= 0) {
        throw Exception('Coins amount must be greater than 0');
      }

      print('💰 Admin $currentUserId adding $coinsToAdd U Coins to user $userId');

      // Use transaction to ensure atomic update
      final result = await _firestore.runTransaction((transaction) async {
        // Get user document
        final userRef = _usersCollection.doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentUCoins = (userData['uCoins'] as int?) ?? 0;
        final newBalance = currentUCoins + coinsToAdd;

        // Update user's U Coins balance in users collection
        transaction.update(userRef, {
          'uCoins': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Also update wallets collection if it exists (for backward compatibility)
        final walletRef = _firestore.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);
        
        if (walletDoc.exists) {
          // Update existing wallet document
          transaction.update(walletRef, {
            'coins': newBalance,
            'balance': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('📝 Transaction: Also updating wallets/$userId/coins = $newBalance');
        } else {
          // Create wallet document if it doesn't exist
          // Note: We'll update userEmail after transaction completes
          transaction.set(walletRef, {
            'userId': userId,
            'userName': userData['displayName'] ?? 'User',
            'userEmail': 'No email', // Will be updated after transaction
            'numericUserId': userData['numericUserId'] ?? '',
            'coins': newBalance,
            'balance': newBalance,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('📝 Transaction: Created wallets/$userId document with coins = $newBalance');
        }

        print('📝 Transaction: Updating users/$userId/uCoins from $currentUCoins to $newBalance');

        return {
          'currentUCoins': currentUCoins,
          'newBalance': newBalance,
          'userData': userData,
        };
      });

      // Verify the update succeeded by reading back
      final verifyDoc = await _usersCollection.doc(userId).get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data() as Map<String, dynamic>;
        final verifyBalance = (verifyData['uCoins'] as int?) ?? 0;
        print('✅ Verified: users/$userId/uCoins = $verifyBalance');
        
        if (verifyBalance != result['newBalance']) {
          print('⚠️ WARNING: Balance mismatch! Expected ${result['newBalance']}, got $verifyBalance');
        }
      }

      // Log admin action (after successful update)
      final userData = result['userData'] as Map<String, dynamic>?;
      await _adminActionsCollection.add({
        'adminId': currentUserId,
        'adminEmail': _auth.currentUser?.email ?? 'Unknown',
        'userId': userId,
        'userPhone': userData?['phoneNumber'] ?? 'Unknown',
        'actionType': 'add_u_coins',
        'coinsAdded': coinsToAdd,
        'previousBalance': result['currentUCoins'],
        'newBalance': result['newBalance'],
        'reason': reason ?? 'Admin coin addition',
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added $coinsToAdd U Coins to user $userId');
      print('   Previous balance: ${result['currentUCoins']}');
      print('   New balance: ${result['newBalance']}');
      print('   ✅ Updated in users collection: users/$userId/uCoins');
      print('   ✅ Updated in wallets collection: wallets/$userId/balance');
      print('   🔔 Real-time listeners should detect this update automatically');

      // Send notification to user about coins added
      print('🔔 [AdminService] About to send coin addition notification...');
      print('   userId: $userId');
      print('   coinsAdded: $coinsToAdd');
      print('   newBalance: ${result['newBalance']}');
      
      await _sendCoinAdditionNotification(
        userId: userId,
        coinsAdded: coinsToAdd,
        newBalance: result['newBalance'] as int,
      );
      
      print('✅ [AdminService] Notification sending completed');

      return {
        'success': true,
        'message': 'Coins added successfully to user account',
        'previousBalance': result['currentUCoins'],
        'newBalance': result['newBalance'],
        'coinsAdded': coinsToAdd,
      };
    } catch (e) {
      print('❌ Error adding U Coins: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Send notification to user when coins are added by admin
  Future<void> _sendCoinAdditionNotification({
    required String userId,
    required int coinsAdded,
    required int newBalance,
  }) async {
    print('🔔 [AdminService._sendCoinAdditionNotification] START');
    print('   userId: $userId');
    print('   coinsAdded: $coinsAdded');
    print('   newBalance: $newBalance');
    
    try {
      print('🔔 [AdminService._sendCoinAdditionNotification] Sending coin addition notification to user $userId');
      
      // Get user's FCM token and data
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User not found for notification');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final fcmToken = userData?['fcmToken'] as String?;

      // Format current date and time
      final now = DateTime.now();
      final date = '${now.day}/${now.month}/${now.year}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Format the notification message
      final title = '💰 Coins Added to Your Wallet';
      final body = '$coinsAdded coins have been added to your wallet. Your new balance is $newBalance coins.';

      // 1. Create announcement in announcements collection (for in-app display)
      try {
        final announcementData = {
          'title': title,
          'description': body,
          'date': date,
          'time': time,
          'type': 'coin_addition',
          'isNew': true,
          'color': 0xFFFFA500, // Orange/Gold color for coin notifications
          'iconName': 'account_balance_wallet', // Wallet icon
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'userId': userId, // Store userId to link to user
          'coinsAdded': coinsAdded,
          'newBalance': newBalance,
        };
        print('📝 [AdminService] Creating announcement with data:');
        print('   title: $title');
        print('   description: $body');
        print('   userId: $userId');
        print('   type: coin_addition');
        print('   coinsAdded: $coinsAdded');
        print('   newBalance: $newBalance');
        
        final announcementRef = await _firestore.collection('announcements').add(announcementData);
        print('✅ [AdminService] Coin addition announcement created with ID: ${announcementRef.id}');
        print('   Collection: announcements/${announcementRef.id}');
        print('   userId field: $userId');
        
        // Verify the announcement was created correctly
        final verifyDoc = await announcementRef.get();
        if (verifyDoc.exists) {
          final verifyData = verifyDoc.data() as Map<String, dynamic>;
          print('✅ [AdminService] Verification: Announcement exists');
          print('   verifyData[userId]: ${verifyData['userId']}');
          print('   verifyData[type]: ${verifyData['type']}');
          if (verifyData['userId'] != userId) {
            print('⚠️ [AdminService] WARNING: userId mismatch! Expected $userId, got ${verifyData['userId']}');
          }
        } else {
          print('❌ [AdminService] ERROR: Announcement document does not exist after creation!');
        }
      } catch (e) {
        print('❌ [AdminService] Error creating announcement: $e');
        print('   Stack trace: ${StackTrace.current}');
      }

      // 2. Send push notification (if FCM token exists)
      if (fcmToken != null && fcmToken.isNotEmpty) {
        try {
          // Store notification request in Firestore
          // This will be picked up by Cloud Functions to send the actual notification
          await _firestore.collection('notificationRequests').add({
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': 'coin_addition',
              'userId': userId,
              'coinsAdded': coinsAdded.toString(),
              'newBalance': newBalance.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
            'createdAt': FieldValue.serverTimestamp(),
            'processed': false,
          });
          print('✅ Coin addition notification request created for push notification');
        } catch (e) {
          print('⚠️ Error creating push notification request: $e');
        }
      } else {
        print('⚠️ User has no FCM token, skipping push notification (announcement still created)');
      }

      print('✅ Coin addition notification process completed');
    } catch (e) {
      // Don't fail the entire operation if notification fails
      print('⚠️ Error sending coin addition notification: $e');
    }
  }

  /// Add C Coins to a user's account (admin only)
  Future<Map<String, dynamic>> addCCoinsToUser({
    required String userId,
    required int coinsToAdd,
    String? reason,
    String? notes,
  }) async {
    try {
      // Check if current user is admin
      final isUserAdmin = await isAdmin();
      if (!isUserAdmin) {
        throw Exception('Unauthorized: Only admins can add coins');
      }

      if (coinsToAdd <= 0) {
        throw Exception('Coins amount must be greater than 0');
      }

        print('💰 Admin $currentUserId adding $coinsToAdd C Coins to user $userId');

      // Use transaction to ensure atomic update
      final result = await _firestore.runTransaction((transaction) async {
        // Get user document
        final userRef = _usersCollection.doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentCCoins = (userData['cCoins'] as int?) ?? 0;
        final newBalance = currentCCoins + coinsToAdd;

        // Update user's C Coins balance in users collection
        transaction.update(userRef, {
          'cCoins': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('📝 Transaction: Updating users/$userId/cCoins from $currentCCoins to $newBalance');

        return {
          'currentCCoins': currentCCoins,
          'newBalance': newBalance,
          'userData': userData,
        };
      });

      // Verify the update succeeded by reading back
      final verifyDoc = await _usersCollection.doc(userId).get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data() as Map<String, dynamic>;
        final verifyBalance = (verifyData['cCoins'] as int?) ?? 0;
        print('✅ Verified: users/$userId/cCoins = $verifyBalance');
        
        if (verifyBalance != result['newBalance']) {
          print('⚠️ WARNING: Balance mismatch! Expected ${result['newBalance']}, got $verifyBalance');
        }
      }

      // Log admin action (after successful update)
      final userData = result['userData'] as Map<String, dynamic>?;
      await _adminActionsCollection.add({
        'adminId': currentUserId,
        'adminEmail': _auth.currentUser?.email ?? 'Unknown',
        'userId': userId,
        'userPhone': userData?['phoneNumber'] ?? 'Unknown',
        'actionType': 'add_c_coins',
        'coinsAdded': coinsToAdd,
        'previousBalance': result['currentCCoins'],
        'newBalance': result['newBalance'],
        'reason': reason ?? 'Admin coin addition',
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added $coinsToAdd C Coins to user $userId');
      print('   Previous balance: ${result['currentCCoins']}');
      print('   New balance: ${result['newBalance']}');
      print('   ✅ Updated in users collection: users/$userId/cCoins');

      return {
        'success': true,
        'message': 'Coins added successfully to user account',
        'previousBalance': result['currentCCoins'],
        'newBalance': result['newBalance'],
        'coinsAdded': coinsToAdd,
      };
    } catch (e) {
      print('❌ Error adding C Coins: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Search users by phone number or user ID
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();
      final results = <Map<String, dynamic>>[];

      // Search by phone number
      final phoneQuery = await _usersCollection
          .where('phoneNumber', isGreaterThanOrEqualTo: query)
          .where('phoneNumber', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      for (var doc in phoneQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        results.add({
          'userId': doc.id,
          'phoneNumber': data['phoneNumber'] ?? '',
          'countryCode': data['countryCode'] ?? '',
          'displayName': data['displayName'] ?? 'User',
          'uCoins': data['uCoins'] ?? 0,
          'cCoins': data['cCoins'] ?? 0,
        });
      }

      // Search by user ID (if query looks like a user ID)
      if (query.length > 10) {
        try {
          final userDoc = await _usersCollection.doc(query).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;
            // Check if already in results
            if (!results.any((r) => r['userId'] == userId)) {
              results.add({
                'userId': userId,
                'phoneNumber': data['phoneNumber'] ?? '',
                'countryCode': data['countryCode'] ?? '',
                'displayName': data['displayName'] ?? 'User',
                'uCoins': data['uCoins'] ?? 0,
                'cCoins': data['cCoins'] ?? 0,
              });
            }
          }
        } catch (e) {
          print('⚠️ Error searching by user ID: $e');
        }
      }

      // Filter results by display name if needed
      final filteredResults = results.where((user) {
        final displayName = (user['displayName'] as String).toLowerCase();
        final phone = (user['phoneNumber'] as String).toLowerCase();
        return displayName.contains(queryLower) ||
            phone.contains(queryLower) ||
            user['userId'].toString().toLowerCase().contains(queryLower);
      }).toList();

      return filteredResults;
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  /// Get admin action history
  Future<List<Map<String, dynamic>>> getAdminActionHistory({
    int limit = 50,
  }) async {
    try {
      final isUserAdmin = await isAdmin();
      if (!isUserAdmin) {
        throw Exception('Unauthorized: Only admins can view action history');
      }

      final querySnapshot = await _adminActionsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'actionId': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting admin action history: $e');
      return [];
    }
  }

  /// Get user's current coin balance
  Future<Map<String, dynamic>> getUserCoinBalance(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'userId': userId,
        'uCoins': data['uCoins'] ?? 0,
        'cCoins': data['cCoins'] ?? 0,
        'displayName': data['displayName'] ?? 'User',
        'phoneNumber': data['phoneNumber'] ?? '',
        'countryCode': data['countryCode'] ?? '',
      };
    } catch (e) {
      print('❌ Error getting user coin balance: $e');
      return {};
    }
  }
}

