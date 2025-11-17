import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Request location permission from user
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return true;
  }

  /// Get current GPS coordinates
  Future<Position?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Convert GPS coordinates to address (city, country)
  Future<Map<String, String>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('No address found for the given coordinates');
      }

      Placemark place = placemarks[0];

      // Extract city and country
      String city = place.locality ?? 
                    place.subAdministrativeArea ?? 
                    place.administrativeArea ?? 
                    'Unknown';
      
      String country = place.country ?? 'Unknown';
      String state = place.administrativeArea ?? '';
      String subLocality = place.subLocality ?? '';

      return {
        'city': city.trim(),
        'country': country.trim(),
        'state': state.trim(),
        'subLocality': subLocality.trim(),
        'fullAddress': '${city}, ${country}'.trim(),
      };
    } catch (e) {
      print('Error getting address from coordinates: $e');
      throw Exception('Failed to get address: ${e.toString()}');
    }
  }

  /// Main method: Get current city and country
  Future<Map<String, String>> getCurrentCityAndCountry() async {
    try {
      // 1. Request permission
      await requestLocationPermission();

      // 2. Get current location
      Position? position = await getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get current location. Please try again.');
      }

      // 3. Convert to address
      Map<String, String> address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return address;
    } catch (e) {
      print('Error in getCurrentCityAndCountry: $e');
      rethrow;
    }
  }
}

