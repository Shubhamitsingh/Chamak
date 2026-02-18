import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check network connectivity
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  
  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if connected to any network
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // For mobile data, WiFi, ethernet - assume internet is available
      // Note: This doesn't guarantee actual internet access, but checks network connection
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // On error, assume no connection (fail closed for security)
      return false;
    }
  }
  
  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;
  
  /// Check if connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if connected to mobile data
  Future<bool> isConnectedToMobile() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile;
    } catch (e) {
      return false;
    }
  }
}
