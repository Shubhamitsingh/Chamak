import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';
import 'database_service.dart';

/// Service to handle location permission request for new users
class LocationPermissionService {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is new (first time opening app)
  /// Returns true if user doesn't have location saved yet
  Future<bool> isNewUserWithoutLocation() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        // User document doesn't exist yet
        return true;
      }

      final data = userDoc.data();
      if (data == null) return true;

      // Check if city or country is empty/null
      final city = data['city'] as String?;
      final country = data['country'] as String?;

      // Return true if location is missing
      return city == null || city.isEmpty || country == null || country.isEmpty;
    } catch (e) {
      print('❌ Error checking if new user: $e');
      return false;
    }
  }

  /// Request location permission and save to user profile
  /// This should be called when a new user first opens the app
  Future<bool> requestAndSaveLocation() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('📍 Starting location permission request for new user...');

      // Check if location is already saved
      final hasLocation = !(await isNewUserWithoutLocation());
      if (hasLocation) {
        print('✅ Location already saved for user');
        return true;
      }

      // Request permission and get location
      Map<String, String> location = await _locationService.getCurrentCityAndCountry();

      if (location['city'] == null || location['city']!.isEmpty) {
        print('⚠️ Location data incomplete');
        return false;
      }

      print('✅ Location detected: ${location['city']}, ${location['country']}');

      // Save location to user profile
      await _databaseService.updateUserProfile(
        city: location['city'],
        country: location['country'],
      );

      print('✅ Location saved to user profile successfully!');
      return true;
    } catch (e) {
      print('❌ Error requesting/saving location: $e');
      // Don't block user flow if location fails
      return false;
    }
  }
}





















