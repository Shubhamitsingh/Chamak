import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Model for nearby user with distance
class NearbyUser {
  final UserModel user;
  final double distanceKm;

  NearbyUser({
    required this.user,
    required this.distanceKm,
  });
}

class NearbyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    // Convert degrees to radians
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    // Haversine formula
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Update user's location in Firestore
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    try {
      final updates = <String, dynamic>{
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      };

      // Also update city and country if provided
      if (city != null) {
        updates['city'] = city;
      }
      if (country != null) {
        updates['country'] = country;
      }

      await _firestore.collection('users').doc(userId).update(updates);
      print('✅ Location updated for user: $userId');
    } catch (e) {
      print('❌ Error updating location: $e');
      rethrow;
    }
  }

  /// Get nearby users within specified radius
  /// Returns stream of nearby users sorted by distance
  Stream<List<NearbyUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 100,
  }) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final nearbyUsers = <NearbyUser>[];

      for (var doc in snapshot.docs) {
        // Skip current user
        if (doc.id == currentUserId) continue;

        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;

        // Skip if no location data
        if (location == null) continue;

        final userLat = location['latitude'] as double?;
        final userLon = location['longitude'] as double?;

        // Skip if coordinates are missing
        if (userLat == null || userLon == null) continue;

        // Calculate distance
        final distance = calculateDistance(
          latitude,
          longitude,
          userLat,
          userLon,
        );

        // Filter by radius
        if (distance <= radiusKm) {
          try {
            final user = UserModel.fromFirestore(doc);
            nearbyUsers.add(NearbyUser(user: user, distanceKm: distance));
          } catch (e) {
            print('❌ Error parsing user: ${doc.id}, $e');
            continue;
          }
        }
      }

      // Sort by distance (nearest first)
      nearbyUsers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Limit results
      if (nearbyUsers.length > limit) {
        return nearbyUsers.sublist(0, limit);
      }

      return nearbyUsers;
    });
  }

  /// Get user's current location from Firestore
  Future<Map<String, double>?> getUserLocation(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      final location = data?['location'] as Map<String, dynamic>?;

      if (location == null) return null;

      final lat = location['latitude'] as double?;
      final lon = location['longitude'] as double?;

      if (lat == null || lon == null) return null;

      return {
        'latitude': lat,
        'longitude': lon,
      };
    } catch (e) {
      print('❌ Error getting user location: $e');
      return null;
    }
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }
}
