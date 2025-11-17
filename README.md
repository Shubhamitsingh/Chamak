# LiveVibe - Live Streaming Mobile App

A modern live streaming mobile application built with Flutter that allows users to stream video content in real-time.

## 🚀 Features (Step 1)

- ✨ **Splash Screen** - Animated logo with smooth transitions
- 📱 **Login Page** - Modern UI with gradient background and phone number authentication
- 🎨 **Material 3 Design** - Beautiful, modern design system
- 🌈 **Smooth Animations** - Engaging user experience with animate_do

## 📱 Current Progress

### ✅ Completed
- [x] Splash Screen with logo and loading animation
- [x] Login Screen with mobile number input
- [x] **OTP Verification System** ⭐ NEW!
  - [x] Dynamic OTP input field
  - [x] Countdown timer (30s)
  - [x] Resend OTP functionality
  - [x] Auto-verification
  - [x] Error handling
- [x] Home Screen with navigation ⭐ NEW!
  - [x] Live streams section
  - [x] Bottom navigation
  - [x] Profile section
  - [x] Go Live button
- [x] Gradient backgrounds (Purple + Blue theme)
- [x] Terms & Conditions and Privacy Policy links
- [x] Responsive and modern UI
- [x] Complete navigation flow

### 🔜 Coming Next
- [ ] Live Streaming Features (Camera integration)
- [ ] User Profile Management
- [ ] Chat & Comments
- [ ] Backend Integration (Firebase/API)

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Design System:** Material 3
- **UI/UX:** Google Fonts (Poppins), Animate Do, Loading Animation Widget
- **Phone Input:** Intl Phone Field

## 📦 Dependencies

```yaml
dependencies:
  - google_fonts: ^6.1.0           # Custom fonts
  - animate_do: ^3.1.2             # Animations
  - loading_animation_widget: ^1.2.0+4  # Loading indicators
  - flutter_bloc: ^8.1.3           # State management
  - go_router: ^12.1.1             # Navigation
  - intl_phone_field: ^3.2.0       # Phone input
  - pinput: ^3.0.1                 # OTP input ⭐ NEW
  - timer_count_down: ^2.2.2       # Timer ⭐ NEW
```

## 🎯 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android Emulator or Physical Device
- **Java 17+** (bundled with Android Studio)

### Installation & Running

1. **Navigate to project directory**
   ```bash
   cd "C:\Users\Shubham Singh\Desktop\chamak"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### ✅ Build Status

**Status:** ✅ **WORKING**  
**Last Build:** October 25, 2025  
**Build Time:** ~265s (first build), ~10-30s (subsequent)

The Android SDK 35 / jlink.exe build error has been **successfully resolved** by upgrading to:
- Android Gradle Plugin 8.3.0
- Gradle 8.4
- Java 17
- Kotlin 1.9.22

See [BUILD_FIX_SUMMARY.md](BUILD_FIX_SUMMARY.md) for details.

## 📂 Project Structure

```
lib/
├── main.dart                  # App entry point and theme configuration
├── screens/
│   ├── splash_screen.dart     # Splash screen with animations
│   ├── login_screen.dart      # Login + OTP verification ⭐ UPDATED
│   └── home_screen.dart       # Home screen ⭐ NEW
└── widgets/                   # (Will be added in future steps)

Documentation Files:
├── OTP_QUICK_GUIDE.md         # Quick reference for OTP feature ⭐ NEW
├── OTP_FEATURE_GUIDE.md       # Complete OTP documentation ⭐ NEW
├── README.md                  # Project overview (this file)
├── SETUP_GUIDE.md             # Setup instructions
├── BUILD_FIX_SUMMARY.md       # Build configuration fixes
└── TROUBLESHOOTING.md         # Common issues & solutions
```

## 🎨 Design Highlights

### Color Scheme
- Primary: `#6C63FF` (Purple)
- Secondary: `#5A52D5` (Medium Purple)
- Accent: `#4940B8` (Dark Purple)
- Gradient: Purple to Blue

### Typography
- Font Family: Poppins (via Google Fonts)
- Modern, clean, and readable

### UI Elements
- Rounded corners (30px border radius)
- Soft shadows for depth
- Smooth animations and transitions
- White cards on gradient backgrounds

## 🔐 Authentication Flow (Complete!)

1. **Splash Screen** (3 seconds)
   - Displays app logo with animation
   - Auto-navigates to Login Screen

2. **Login Screen - Phone Entry**
   - User enters mobile number
   - International phone field with country code
   - Click "Send OTP"

3. **Login Screen - OTP Verification** ⭐ NEW!
   - Phone field disabled
   - 6-digit OTP input appears
   - 30-second countdown timer
   - Resend OTP option
   - Auto-verification when complete
   - Error handling for wrong OTP

4. **Home Screen** ⭐ NEW!
   - Welcome message with phone number
   - Live streams feed
   - Bottom navigation (Home, Explore, Profile)
   - Go Live button
   - Profile management

## 📝 Notes

- App is locked to portrait orientation
- Uses Material 3 design principles
- Scalable architecture for future features
- Ready for state management integration

## 🚧 Development Roadmap

**Step 1:** ✅ Splash Screen + Login Page (Complete)
**Step 2:** ✅ OTP Verification (Complete) ⭐
**Step 3:** ✅ Home Screen & Bottom Navigation (Complete) ⭐
**Step 4:** 🔄 Live Streaming Features (Next)
**Step 5:** 🔄 User Profile & Settings (Pending)
**Step 6:** 🔄 Backend Integration (Pending)

## 👨‍💻 Developer

Built with ❤️ using Flutter

---

**Version:** 1.0.0+1
**Last Updated:** October 2025

