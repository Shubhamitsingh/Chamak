import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search user by numeric ID (supports partial 7-digit search)
  Future<UserModel?> searchUserByNumericId(String numericId) async {
    try {
      // Use range query to find IDs that start with the search term
      final querySnapshot = await _firestore
          .collection('users')
          .where('numericUserId', isGreaterThanOrEqualTo: numericId)
          .where('numericUserId', isLessThan: numericId + '\uf8ff')
          .limit(20)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Filter to find exact prefix match (in case range query returns extra results)
      for (var doc in querySnapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        if (user.numericUserId.startsWith(numericId)) {
          return user;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error searching user by numeric ID: $e');
      return null;
    }
  }

  // Search users by name (partial match)
  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      if (name.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: name + 'z')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error searching users by name: $e');
      return [];
    }
  }

  // Get user by Firebase UID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // Search with suggestions (for autocomplete)
  Future<List<UserModel>> searchWithSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];

      // Try numeric ID first
      if (RegExp(r'^\d+$').hasMatch(query)) {
        final user = await searchUserByNumericId(query);
        if (user != null) return [user];
      }

      // Fall back to name search
      return await searchUsersByName(query);
    } catch (e) {
      print('❌ Error in search suggestions: $e');
      return [];
    }
  }

  // Get recent searches (from local storage - you can implement later)
  Future<List<String>> getRecentSearches() async {
    // TODO: Implement with SharedPreferences
    return [];
  }

  // Save search to recent (local storage - you can implement later)
  Future<void> saveRecentSearch(String query) async {
    // TODO: Implement with SharedPreferences
  }
}

