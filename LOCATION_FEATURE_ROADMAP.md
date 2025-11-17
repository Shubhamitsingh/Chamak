# 📍 Current Location Feature - Implementation Roadmap

## 🎯 **Goal**
Replace manual city input with automatic GPS-based location detection in the Edit Profile screen.

---

## 📋 **Step-by-Step Implementation Plan**

### **Step 1: Add Required Packages** 📦

Add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # Location Services
  geolocator: ^13.0.0          # For getting GPS location
  geocoding: ^3.0.0             # For converting coordinates to address (city, country)
```

**Why:**
- `geolocator`: Gets device GPS coordinates (latitude, longitude)
- `geocoding`: Converts GPS coordinates to human-readable address (city, country, etc.)

---

### **Step 2: Add Permissions** 🔐

#### **Android Permissions** (`android/app/src/main/AndroidManifest.xml`)

Add these permissions INSIDE `<manifest>` tag:

```xml
<!-- Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Note:** You may already have some permissions. Just add location ones.

#### **iOS Permissions** (`ios/Runner/Info.plist`)

Add these keys inside `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to auto-fill your city in your profile</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to auto-fill your city in your profile</string>
```

---

### **Step 3: Create Location Service** 🔧

**File:** `lib/services/location_service.dart` (NEW FILE)

**Purpose:** Centralized location handling logic

**What it should do:**
1. Request location permissions
2. Get current GPS coordinates
3. Convert coordinates to address (city, country)
4. Handle errors gracefully

**Key Methods:**
- `requestLocationPermission()` - Ask user for permission
- `getCurrentLocation()` - Get GPS coordinates
- `getAddressFromCoordinates(lat, lng)` - Convert to city/country
- `getCurrentCityAndCountry()` - Main method combining everything

---

### **Step 4: Update Edit Profile Screen** ✏️

**File:** `lib/screens/edit_profile_screen.dart`

**Changes needed:**

#### **4.1: Add Imports**
```dart
import '../services/location_service.dart';
```

#### **4.2: Add State Variables**
- `bool _isGettingLocation = false` - Loading state for location
- `LocationService _locationService = LocationService()` - Service instance

#### **4.3: Modify City Field UI**

Replace current city TextField with:
- **Location Icon Button** next to city field
- When clicked → Get location → Auto-fill city & country
- Show loading spinner while fetching
- Keep manual input option (still editable after auto-fill)

#### **4.4: Add "Get Current Location" Button**

**Option A: Button Next to City Field**
```
[City TextField] [📍 Get Location Button]
```

**Option B: Button Inside City Field (as suffix icon)**
```
[📍 Icon] City TextField [📍 Get Location Icon]
```

**Recommendation:** Option A - More visible and user-friendly

---

### **Step 5: Implementation Details** 💻

#### **5.1: Location Service Implementation**

**Location Service Structure:**
```dart
class LocationService {
  // Check if location permission granted
  Future<bool> requestLocationPermission()
  
  // Get current GPS coordinates
  Future<Position?> getCurrentLocation()
  
  // Convert coordinates to address
  Future<Map<String, String>> getAddressFromCoordinates(double lat, double lng)
  
  // Main method - get city and country
  Future<Map<String, String>> getCurrentCityAndCountry()
}
```

**Return Format:**
```dart
{
  'city': 'Mumbai',
  'country': 'India',
  'state': 'Maharashtra',  // Optional
  'fullAddress': 'Mumbai, Maharashtra, India'  // Optional
}
```

#### **5.2: Edit Profile Integration**

**Flow:**
1. User taps "Get Current Location" button
2. Show loading indicator
3. Check permissions → Request if needed
4. Get GPS coordinates
5. Convert to address (city, country)
6. Auto-fill `_cityController` and `_selectedCountry`
7. Hide loading indicator
8. Show success message

**Error Handling:**
- Permission denied → Show dialog explaining why
- GPS off → Show message to enable location
- Network error → Show retry option
- Timeout → Show error, allow manual input

---

### **Step 6: UI/UX Enhancements** 🎨

#### **6.1: Loading States**

**While fetching location:**
- Show CircularProgressIndicator
- Disable location button
- Optional: Show "Getting location..." text

#### **6.2: Success Feedback**

**After successful location fetch:**
- Show SnackBar: "📍 Location detected: Mumbai, India"
- Highlight city field briefly
- Update country dropdown automatically

#### **6.3: Error Messages**

**Permission Denied:**
```
"Location permission required. Please enable in Settings."
[Open Settings Button]
```

**Location Service Disabled:**
```
"Please enable location services in your device settings."
```

**Timeout/Network Error:**
```
"Unable to get location. Please try again or enter manually."
[Retry Button]
```

---

### **Step 7: Edge Cases & Best Practices** ⚠️

#### **7.1: Permission Handling**
- **First time:** Request permission with explanation
- **Denied once:** Show dialog with "Open Settings" option
- **Denied permanently:** Allow manual input only

#### **7.2: Accuracy**
- Use `geolocator` accuracy settings:
  - `LocationAccuracy.high` - More accurate but slower
  - `LocationAccuracy.medium` - Balanced (recommended)
  - `LocationAccuracy.low` - Faster but less accurate

#### **7.3: Battery Optimization**
- Only get location when user explicitly requests it
- Don't continuously track location
- Use `getCurrentPosition()` (one-time) instead of `getPositionStream()` (continuous)

#### **7.4: Privacy**
- Only get location when user taps button (not automatically)
- Explain why location is needed
- Allow user to manually override auto-filled values

---

### **Step 8: Testing Checklist** ✅

#### **Test Scenarios:**

1. **Happy Path**
   - ✅ Tap "Get Location" → Permission granted → Location fetched → City & Country auto-filled

2. **Permission Denied**
   - ✅ Tap "Get Location" → Permission denied → Show error → Allow manual input

3. **GPS Disabled**
   - ✅ Turn off GPS → Tap "Get Location" → Show "Enable GPS" message

4. **No Internet**
   - ✅ Turn off internet → Tap "Get Location" → Show network error

5. **Manual Override**
   - ✅ Auto-fill location → User edits city manually → Changes saved correctly

6. **Different Locations**
   - ✅ Test in different cities → Verify correct city/country detected

7. **App Backgrounding**
   - ✅ Get location → Switch apps → Return → Should still work

---

### **Step 9: Code Structure Example** 📝

#### **Location Service Method Structure:**

```dart
Future<Map<String, String>> getCurrentCityAndCountry() async {
  // 1. Check permission
  bool hasPermission = await requestLocationPermission();
  if (!hasPermission) {
    throw Exception('Location permission denied');
  }
  
  // 2. Get GPS coordinates
  Position? position = await getCurrentLocation();
  if (position == null) {
    throw Exception('Unable to get current location');
  }
  
  // 3. Convert to address
  List<Placemark> placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );
  
  if (placemarks.isEmpty) {
    throw Exception('Unable to get address');
  }
  
  Placemark place = placemarks[0];
  
  // 4. Return city and country
  return {
    'city': place.locality ?? place.subAdministrativeArea ?? 'Unknown',
    'country': place.country ?? 'Unknown',
  };
}
```

#### **Edit Profile Integration Example:**

```dart
Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingLocation = true;
  });

  try {
    final location = await _locationService.getCurrentCityAndCountry();
    
    setState(() {
      _cityController.text = location['city'] ?? '';
      _selectedCountry = location['country'] ?? 'India';
      _isGettingLocation = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📍 Location detected: ${location['city']}')),
    );
  } catch (e) {
    setState(() {
      _isGettingLocation = false;
    });
    
    // Show error message
    _showLocationError(e);
  }
}
```

---

## 🚀 **Implementation Order**

1. **Step 1:** Add packages → Run `flutter pub get`
2. **Step 2:** Add permissions to Android/iOS
3. **Step 3:** Create `location_service.dart`
4. **Step 4:** Update `edit_profile_screen.dart` UI
5. **Step 5:** Integrate location service calls
6. **Step 6:** Add loading states & error handling
7. **Step 7:** Test all scenarios
8. **Step 8:** Polish UI/UX

---

## 📚 **Resources**

### **Package Documentation:**
- **geolocator:** https://pub.dev/packages/geolocator
- **geocoding:** https://pub.dev/packages/geocoding

### **Key Methods:**
- `Geolocator.checkPermission()` - Check permission status
- `Geolocator.requestPermission()` - Request permission
- `Geolocator.getCurrentPosition()` - Get GPS coordinates
- `placemarkFromCoordinates()` - Convert coords to address

---

## ⚡ **Quick Start Summary**

1. Add `geolocator` & `geocoding` to `pubspec.yaml`
2. Add location permissions (Android & iOS)
3. Create `LocationService` class
4. Add "Get Location" button in Edit Profile
5. Wire up button → location service → auto-fill city/country
6. Handle errors gracefully
7. Test & deploy!

---

**This roadmap provides complete guidance for implementing GPS-based location detection in your profile edit page!** 📍✨

