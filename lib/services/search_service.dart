import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/live_stream_model.dart';

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

  // Search users by display name (partial match, case-insensitive)
  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      if (name.isEmpty) return [];

      final lowerName = name.toLowerCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: name)
          .where('displayName', isLessThan: name + '\uf8ff')
          .limit(50)
          .get();

      // Filter results to include partial matches (case-insensitive)
      final results = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            final userName = (user.displayName ?? '').toLowerCase();
            return userName.contains(lowerName);
          })
          .toList();

      return results;
    } catch (e) {
      print('❌ Error searching users by name: $e');
      return [];
    }
  }

  // Search users by country
  Future<List<UserModel>> searchUsersByCountry(String country) async {
    try {
      if (country.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .where('country', isEqualTo: country)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error searching users by country: $e');
      return [];
    }
  }

  // Search users by city
  Future<List<UserModel>> searchUsersByCity(String city) async {
    try {
      if (city.isEmpty) return [];

      final lowerCity = city.toLowerCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('city', isGreaterThanOrEqualTo: city)
          .where('city', isLessThan: city + '\uf8ff')
          .limit(50)
          .get();

      // Filter results for partial matches
      final results = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            final userCity = (user.city ?? '').toLowerCase();
            return userCity.contains(lowerCity);
          })
          .toList();

      return results;
    } catch (e) {
      print('❌ Error searching users by city: $e');
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

  // Search with suggestions (for autocomplete) - supports multiple search types
  Future<List<UserModel>> searchWithSuggestions(String query, {
    bool searchById = true,
    bool searchByName = true,
    bool searchByCountry = false,
    String? countryFilter,
  }) async {
    try {
      if (query.isEmpty) return [];

      final results = <UserModel>[];
      final seenIds = <String>{};

      // Helper to add unique users
      void addUniqueUsers(List<UserModel> users) {
        for (var user in users) {
          if (!seenIds.contains(user.userId)) {
            results.add(user);
            seenIds.add(user.userId);
          }
        }
      }

      // 1. Search by numeric ID (if query is numeric)
      if (searchById && RegExp(r'^\d+$').hasMatch(query.trim())) {
        final user = await searchUserByNumericId(query.trim());
        if (user != null && !seenIds.contains(user.userId)) {
          results.add(user);
          seenIds.add(user.userId);
        }
      }

      // 2. Search by name (always enabled for text queries)
      if (searchByName && query.trim().isNotEmpty) {
        final nameResults = await searchUsersByName(query.trim());
        addUniqueUsers(nameResults);
      }

      // 3. Search by country (if country filter is provided)
      if (searchByCountry && countryFilter != null && countryFilter.isNotEmpty) {
        final countryResults = await searchUsersByCountry(countryFilter);
        addUniqueUsers(countryResults);
      }

      return results;
    } catch (e) {
      print('❌ Error in search suggestions: $e');
      return [];
    }
  }

  // Get all available countries from users (for filter dropdown)
  Future<List<String>> getAvailableCountries() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('country', isNotEqualTo: null)
          .get();

      final countries = <String>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final country = data['country'] as String?;
        if (country != null && country.isNotEmpty) {
          countries.add(country);
        }
      }

      return countries.toList()..sort();
    } catch (e) {
      print('❌ Error getting available countries: $e');
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

  // Get trending hosts (users with isHost = true, sorted by followers/hostLevel)
  Stream<List<UserModel>> getTrendingHosts({int limit = 20}) {
    try {
      return _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final hosts = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
            // Sort by followers count (descending)
            hosts.sort((a, b) => b.followersCount.compareTo(a.followersCount));
            return hosts.take(limit).toList();
          });
    } catch (e) {
      print('❌ Error getting trending hosts: $e');
      return Stream.value([]);
    }
  }

  // Get popular users (sorted by followers count)
  Stream<List<UserModel>> getPopularUsers({int limit = 20}) {
    try {
      return _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final users = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
            // Sort by followers count (descending)
            users.sort((a, b) => b.followersCount.compareTo(a.followersCount));
            return users.take(limit).toList();
          });
    } catch (e) {
      print('❌ Error getting popular users: $e');
      return Stream.value([]);
    }
  }

  // Get new users (recently registered)
  Stream<List<UserModel>> getNewUsers({int limit = 20}) {
    try {
      return _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final users = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
            // Sort by createdAt (descending - newest first)
            users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return users.take(limit).toList();
          });
    } catch (e) {
      print('❌ Error getting new users: $e');
      return Stream.value([]);
    }
  }

  // Get random users (for discovery)
  Future<List<UserModel>> getRandomUsers({int limit = 20, String? excludeUserId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .limit(limit * 2) // Get more to randomize
          .get();

      final allUsers = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.userId != excludeUserId)
          .toList();

      // Shuffle and take limit
      allUsers.shuffle();
      return allUsers.take(limit).toList();
    } catch (e) {
      print('❌ Error getting random users: $e');
      return [];
    }
  }

  // ========== LIVE STREAM SEARCH METHODS ==========

  // Search live streams by title
  Future<List<LiveStreamModel>> searchStreamsByTitle(String title) async {
    try {
      if (title.isEmpty) return [];

      final lowerTitle = title.toLowerCase();
      final querySnapshot = await _firestore
          .collection('live_streams')
          .where('isActive', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: title)
          .where('title', isLessThan: title + '\uf8ff')
          .limit(50)
          .get();

      // Filter results to include partial matches (case-insensitive)
      final results = querySnapshot.docs
          .map((doc) {
            try {
              return LiveStreamModel.fromMap({
                'streamId': doc.id,
                ...doc.data(),
              });
            } catch (e) {
              print('❌ Error parsing stream document ${doc.id}: $e');
              return null;
            }
          })
          .where((stream) {
            if (stream == null) return false;
            final streamTitle = stream.title.toLowerCase();
            return streamTitle.contains(lowerTitle);
          })
          .whereType<LiveStreamModel>()
          .toList();

      return results;
    } catch (e) {
      print('❌ Error searching streams by title: $e');
      return [];
    }
  }

  // Search live streams by host name
  Future<List<LiveStreamModel>> searchStreamsByHostName(String hostName) async {
    try {
      if (hostName.isEmpty) return [];

      final lowerHostName = hostName.toLowerCase();
      final querySnapshot = await _firestore
          .collection('live_streams')
          .where('isActive', isEqualTo: true)
          .where('hostName', isGreaterThanOrEqualTo: hostName)
          .where('hostName', isLessThan: hostName + '\uf8ff')
          .limit(50)
          .get();

      // Filter results to include partial matches (case-insensitive)
      final results = querySnapshot.docs
          .map((doc) {
            try {
              return LiveStreamModel.fromMap({
                'streamId': doc.id,
                ...doc.data(),
              });
            } catch (e) {
              print('❌ Error parsing stream document ${doc.id}: $e');
              return null;
            }
          })
          .where((stream) {
            if (stream == null) return false;
            final streamHostName = stream.hostName.toLowerCase();
            return streamHostName.contains(lowerHostName);
          })
          .whereType<LiveStreamModel>()
          .toList();

      return results;
    } catch (e) {
      print('❌ Error searching streams by host name: $e');
      return [];
    }
  }

  // Combined search for streams (title and host name)
  Future<List<LiveStreamModel>> searchStreams(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final results = <LiveStreamModel>[];
      final seenIds = <String>{};

      // Helper to add unique streams
      void addUniqueStreams(List<LiveStreamModel> streams) {
        for (var stream in streams) {
          if (!seenIds.contains(stream.streamId)) {
            results.add(stream);
            seenIds.add(stream.streamId);
          }
        }
      }

      // Search by title
      final titleResults = await searchStreamsByTitle(query.trim());
      addUniqueStreams(titleResults);

      // Search by host name
      final hostResults = await searchStreamsByHostName(query.trim());
      addUniqueStreams(hostResults);

      return results;
    } catch (e) {
      print('❌ Error in stream search: $e');
      return [];
    }
  }

  // Get all active live streams (for default view)
  Stream<List<LiveStreamModel>> getActiveStreams({int limit = 50}) {
    try {
      return _firestore
          .collection('live_streams')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final streams = snapshot.docs
                .map((doc) {
                  try {
                    return LiveStreamModel.fromMap({
                      'streamId': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    print('❌ Error parsing stream document ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<LiveStreamModel>()
                .toList();
            // Sort by viewer count (descending)
            streams.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
            return streams.take(limit).toList();
          });
    } catch (e) {
      print('❌ Error getting active streams: $e');
      return Stream.value([]);
    }
  }
}

