# 🚨 Auto Logout / Re-login Issue - Comprehensive Analysis Report

**Date:** Generated on Request  
**Issue:** Users logged out intermittently, showing login screen or previous session  
**Severity:** 🔴 **HIGH** - Critical UX Issue

---

## 📋 Issue Description

### **Observed Behavior:**

1. **User logs in successfully** ✅
2. **User navigates inside app** ✅
3. **User presses Back button** ⚠️
4. **App unexpectedly:**
   - Redirects to login screen OR
   - Restores previous user session OR
   - Forces re-login without session expiry

### **Key Characteristics:**
- ❌ Happens randomly (not consistent)
- ❌ Not related to actual session expiry
- ❌ Occurs after pressing Back button
- ❌ Sometimes shows previous user's session

---

## 🔍 Root Cause Analysis

### **Issue 1: Auth State Listener in main.dart (POTENTIAL CAUSE)**

**Location:** `lib/main.dart` (Line 102-113)

**Current Code:**
```dart
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    debugPrint('🔐 Auth state changed: User logged out');
    CrashlyticsService.clearUserId();
  } else {
    debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
    CrashlyticsService.setUserId(user.uid);
  }
});
```

**Problem:**
- ✅ Listener doesn't navigate (good)
- ⚠️ But auth state changes might trigger at unexpected times
- ⚠️ If Firebase Auth refreshes token, `authStateChanges()` fires
- ⚠️ This might cause race conditions with navigation

**Impact:** 🟡 **MEDIUM** - Could cause timing issues

---

### **Issue 2: Multiple Auth Checks on Navigation**

**Location:** `lib/screens/intro_logo_screen.dart` (Line 78-187)

**Current Flow:**
```
App Starts → IntroLogoScreen
  ↓
_decideNext() checks FirebaseAuth.instance.currentUser
  ↓
If user exists → Navigate to HomeScreen
If user null → Navigate to SplashScreen
```

**Problem:**
- ⚠️ Checks auth state **once** after 2 seconds
- ⚠️ If user presses back, might navigate back to IntroLogoScreen
- ⚠️ IntroLogoScreen checks auth again → might see stale state

**Impact:** 🟡 **MEDIUM** - Could cause navigation loops

---

### **Issue 3: SplashScreen Also Checks Auth**

**Location:** `lib/screens/splash_screen.dart` (Line 22-73)

**Current Flow:**
```
SplashScreen → _checkAuthState()
  ↓
Checks FirebaseAuth.instance.currentUser
  ↓
If user exists → Navigate to HomeScreen
If user null → Show splash (user taps Continue → Login)
```

**Problem:**
- ⚠️ Two screens checking auth state (IntroLogoScreen + SplashScreen)
- ⚠️ If navigation goes back to SplashScreen, it checks auth again
- ⚠️ Might see different auth state than expected

**Impact:** 🟡 **MEDIUM** - Could cause inconsistent navigation

---

### **Issue 4: Back Button Navigation Stack**

**Potential Issue:**
- User navigates: IntroLogoScreen → SplashScreen → LoginScreen → HomeScreen
- User presses Back button
- Navigation stack might go back to previous screens
- Previous screens check auth state again
- Might see stale or different auth state

**Impact:** 🔴 **HIGH** - Most likely cause

---

### **Issue 5: Firebase Auth Token Refresh**

**Potential Issue:**
- Firebase Auth refreshes token periodically
- `authStateChanges()` fires during refresh
- If timing is wrong, might see `user == null` temporarily
- Navigation might trigger based on this

**Impact:** 🟡 **MEDIUM** - Less likely but possible

---

## ✅ Solutions

### **Solution 1: Remove Back Navigation to Auth Screens (CRITICAL)**

**Problem:** Back button can navigate back to IntroLogoScreen/SplashScreen

**Fix:** Use `pushReplacement` instead of `push` for auth screens

**Files to Check:**
- All navigation to LoginScreen, SplashScreen, IntroLogoScreen
- Ensure they use `pushReplacement` or `pushAndRemoveUntil`

**Example:**
```dart
// ✅ CORRECT - Can't go back
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => HomeScreen(...)),
);

// ❌ WRONG - Can go back
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => HomeScreen(...)),
);
```

---

### **Solution 2: Add Auth State Stream to MaterialApp (RECOMMENDED)**

**Problem:** Multiple screens checking auth state independently

**Fix:** Use `StreamBuilder` with `authStateChanges()` at app level

**File:** `lib/main.dart`

**Add:**
```dart
class LiveVibeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading while checking auth
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                home: const IntroLogoScreen(),
                // ... other config
              );
            }
            
            final user = snapshot.data;
            
            // Determine initial route based on auth state
            Widget home;
            if (user != null && user.phoneNumber != null) {
              // User logged in - check profile
              home = const ProfileCheckScreen(); // New screen to check profile
            } else {
              // User not logged in
              home = const SplashScreen();
            }
            
            return MaterialApp(
              navigatorKey: navigatorKey,
              home: home,
              // ... other config
            );
          },
        );
      },
    );
  }
}
```

**Benefits:**
- ✅ Single source of truth for auth state
- ✅ Automatic navigation on auth changes
- ✅ No race conditions
- ✅ Consistent behavior

---

### **Solution 3: Prevent Back Navigation to Auth Screens**

**Problem:** Back button can navigate to auth screens

**Fix:** Add `WillPopScope` or `PopScope` to prevent back navigation

**File:** `lib/screens/home_screen.dart`

**Add:**
```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false, // Prevent back button
    onPopInvoked: (didPop) {
      if (didPop) return;
      
      // Check if user is still logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User logged out - navigate to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      } else {
        // User still logged in - prevent app closure
        // Or show exit confirmation
        _showExitConfirmation();
      }
    },
    child: Scaffold(
      // ... existing code
    ),
  );
}
```

---

### **Solution 4: Fix Auth State Listener (OPTIONAL)**

**Problem:** Auth state listener might fire at wrong times

**Fix:** Add debouncing or check if navigation is needed

**File:** `lib/main.dart`

**Current:**
```dart
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    debugPrint('🔐 Auth state changed: User logged out');
    CrashlyticsService.clearUserId();
  } else {
    debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
    CrashlyticsService.setUserId(user.uid);
  }
});
```

**Keep as is** - It doesn't navigate, so it's fine.

---

### **Solution 5: Clear Navigation Stack on Login**

**Problem:** Old navigation stack might cause issues

**Fix:** Use `pushAndRemoveUntil` when navigating to HomeScreen

**Files:** `lib/screens/intro_logo_screen.dart`, `lib/screens/splash_screen.dart`

**Change:**
```dart
// ❌ BEFORE
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => HomeScreen(...)),
);

// ✅ AFTER
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => HomeScreen(...)),
  (route) => false, // Clear all previous routes
);
```

---

## 🎯 Recommended Implementation

### **Priority 1: Fix Navigation Stack (CRITICAL)**

1. ✅ Ensure all auth → home navigation uses `pushAndRemoveUntil`
2. ✅ Prevent back navigation to auth screens
3. ✅ Clear navigation stack on login

### **Priority 2: Add StreamBuilder Auth Check (RECOMMENDED)**

1. ✅ Add `StreamBuilder` with `authStateChanges()` at app level
2. ✅ Single source of truth for auth state
3. ✅ Automatic navigation on auth changes

### **Priority 3: Add Back Button Handling (OPTIONAL)**

1. ✅ Add `PopScope` to HomeScreen
2. ✅ Check auth state on back button
3. ✅ Navigate to login if logged out

---

## 📊 Expected Results

### **Before:**
- ❌ Random logout on back button
- ❌ Shows previous user session
- ❌ Inconsistent behavior

### **After:**
- ✅ No random logouts
- ✅ Consistent navigation
- ✅ Proper auth state management
- ✅ Can't navigate back to auth screens

---

## 🧪 Testing Checklist

### **Test Scenarios:**

1. **Login → Navigate → Press Back:**
   - ✅ Should stay in app (not go to login)
   - ✅ Should show exit confirmation if at root

2. **Login → Close App → Reopen:**
   - ✅ Should stay logged in
   - ✅ Should go directly to HomeScreen

3. **Login → Logout → Press Back:**
   - ✅ Should go to login screen
   - ✅ Should not show previous session

4. **Multiple Users:**
   - ✅ Should not show previous user's session
   - ✅ Should show current user's session

---

## 📝 Summary

### **Root Causes:**
1. 🔴 **Back navigation to auth screens** (Most Likely)
2. 🟡 **Multiple auth checks** (Medium)
3. 🟡 **Navigation stack issues** (Medium)
4. 🟢 **Auth state listener** (Low - doesn't navigate)

### **Solutions:**
1. ✅ Use `pushAndRemoveUntil` for auth → home navigation
2. ✅ Add `StreamBuilder` auth check at app level
3. ✅ Prevent back navigation to auth screens
4. ✅ Clear navigation stack on login

### **Priority:**
- 🔴 **CRITICAL:** Fix navigation stack
- 🟡 **HIGH:** Add StreamBuilder auth check
- 🟢 **MEDIUM:** Add back button handling

---

**Report Generated By:** Senior Application Developer  
**Date:** Generated on Request  
**Status:** 🔴 **ACTION REQUIRED** - Fix Navigation Stack
