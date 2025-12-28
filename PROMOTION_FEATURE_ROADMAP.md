portrait-girl# 🎯 Promotion Feature - Implementation Roadmap

## 📋 Overview

This document outlines the complete roadmap for implementing a **Promotion** feature in your Chamakz application. The feature allows users to share promotional images with app branding and QR codes, and earn rewards for successful sharing.

---

## 🎨 UI Reference Analysis

Based on the provided UI reference, the Promotion screen should include:

### **Screen Layout:**
1. **Fixed Top Bar:**
   - Back arrow (left)
   - "Promotion" title (center)
   - App name/branding

2. **Main Content Area (Scrollable):**
   - **Image Carousel:** Swipeable promotional images with:
     - App logo/branding frame (top-left)
     - QR code (bottom-right)
     - Page indicators (dots at bottom)
   
   - **Custom Share Template Button:** White button with border
   
   - **Earning Rate Information:**
     - "Current Downline Rate: Game 70% Gift 70%"
     - Warning text about 0% rate
   
   - **Action Buttons:**
     - "Share URL" button (white)
     - "Save QR Code" button (green)

---

## 🗺️ Implementation Roadmap

### **Phase 1: Project Setup & Dependencies** ✅

**Status:** Already Available
- ✅ `share_plus: ^10.1.2` - For sharing functionality
- ✅ `qr_flutter: ^4.1.0` - For QR code generation
- ✅ `image_picker: ^1.2.0` - For image upload
- ✅ `image_cropper: ^8.0.2` - For image cropping

**Action Required:** None - All dependencies are already installed.

---

### **Phase 2: Create Promotion Screen** 📱

**File:** `lib/screens/promotion_screen.dart`

**Components Needed:**

1. **Screen Structure:**
   ```dart
   - AppBar (fixed, dark theme matching level screen)
   - Body (scrollable):
     - Image Carousel Section
     - Custom Share Template Button
     - Earning Rate Section
     - Action Buttons (Share URL, Save QR Code)
   ```

2. **Key Features:**
   - Fixed top bar with "Promotion" title
   - Image carousel with swipeable promotional images
   - Page indicators (dots)
   - Upload image functionality
   - QR code generation and display
   - Share functionality
   - Reward system integration

---

### **Phase 3: Create Promotion Service** 🔧

**File:** `lib/services/promotion_service.dart`

**Responsibilities:**
- Generate app share link (with user referral code)
- Generate QR code data
- Track sharing activities
- Calculate rewards
- Store promotional images in Firestore
- Manage promotional frame templates

**Key Methods:**
```dart
- generateAppLink(userId) → String
- generateQRCodeData(link) → String
- trackShare(userId, shareType) → Future<void>
- calculateReward(userId, shareType) → Future<int>
- uploadPromotionalImage(imageFile) → Future<String>
- applyPromotionalFrame(image, template) → Future<File>
```

---

### **Phase 4: Create Promotion Model** 📦

**File:** `lib/models/promotion_model.dart`

**Data Structure:**
```dart
class PromotionModel {
  final String id;
  final String imageUrl;
  final String qrCodeUrl;
  final String appLink;
  final DateTime createdAt;
  final String userId;
  final int shareCount;
  final int rewardEarned;
}
```

---

### **Phase 5: Create Promotional Frame Templates** 🖼️

**File:** `lib/services/promotional_frame_service.dart`

**Responsibilities:**
- Apply predefined frames to uploaded images
- Add app logo to top-left
- Add QR code to bottom-right
- Support multiple frame templates (different for each level range)
- Generate final framed image

**Frame Templates:**
- Use level-based frames (similar to level screen)
- Each level range has unique frame design
- Frame includes:
  - App logo (top-left)
  - QR code (bottom-right)
  - Decorative border matching level

---

### **Phase 6: QR Code Generation** 📱

**Implementation:**
- Use `qr_flutter` package
- Generate QR code with app download link
- Include user referral code in link
- Display QR code on promotional images
- Allow saving QR code separately

**QR Code Data Format:**
```
https://chamakz.app/download?ref={userId}&code={referralCode}
```

---

### **Phase 7: Image Upload & Processing** 📸

**Flow:**
1. User taps "Custom share template"
2. Image picker opens (camera/gallery)
3. Image cropper for customization
4. Apply promotional frame
5. Generate QR code overlay
6. Save processed image
7. Display in carousel

**File Processing:**
- Upload original to Firebase Storage
- Process frame application
- Upload framed image
- Store metadata in Firestore

---

### **Phase 8: Share Functionality** 🔗

**Two Sharing Methods:**

1. **Share URL:**
   - Copy app link to clipboard
   - Show share dialog (WhatsApp, Messages, etc.)
   - Track share event

2. **Save QR Code:**
   - Save QR code image to device gallery
   - Show success message
   - Track save event

**Implementation:**
- Use `share_plus` for native sharing
- Use `path_provider` + `image_gallery_saver` for saving
- Track sharing events in Firestore

---

### **Phase 9: Reward System Integration** 💰

**File:** `lib/services/promotion_reward_service.dart`

**Reward Logic:**
- Track successful shares
- Calculate reward based on:
  - Share type (URL vs QR Code)
  - Downline rate (Game 70%, Gift 70%)
  - User level
- Award coins to user's `uCoins` balance
- Update Firestore with reward transaction

**Reward Calculation:**
```dart
- URL Share: Base reward (e.g., 10 coins)
- QR Code Save: Base reward (e.g., 15 coins)
- Successful referral: Additional reward (e.g., 50 coins)
- Level multiplier: Higher level = higher rewards
```

---

### **Phase 10: Add Menu Item to Profile** 📍

**File:** `lib/screens/profile_screen.dart`

**Location:** Add in `_buildMainOptionsMenu()` method

**Menu Item:**
```dart
_buildMenuOption(
  icon: Icons.campaign_rounded,
  title: 'Promotion',
  subtitle: 'Share & Earn Rewards',
  color: const Color(0xFF9C27B0), // Pink/Purple theme
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionScreen(),
      ),
    );
  },
)
```

---

### **Phase 11: Firestore Structure** 🗄️

**Collections Needed:**

1. **`promotions` Collection:**
   ```json
   {
     "id": "promo_123",
     "userId": "user_abc",
     "imageUrl": "https://...",
     "qrCodeUrl": "https://...",
     "appLink": "https://chamakz.app/download?ref=...",
     "shareCount": 5,
     "rewardEarned": 150,
     "createdAt": "2025-01-15T10:00:00Z"
   }
   ```

2. **`share_tracking` Collection:**
   ```json
   {
     "id": "share_123",
     "userId": "user_abc",
     "shareType": "url" | "qr_code",
     "timestamp": "2025-01-15T10:00:00Z",
     "rewardGiven": 10,
     "referralCode": "ABC123"
   }
   ```

3. **`promotional_templates` Collection:**
   ```json
   {
     "id": "template_1",
     "levelRange": "1-9",
     "frameImageUrl": "https://...",
     "logoPosition": {"x": 0.1, "y": 0.1},
     "qrCodePosition": {"x": 0.85, "y": 0.85}
   }
   ```

---

### **Phase 12: Localization** 🌐

**File:** `lib/l10n/app_en.arb`

**Strings to Add:**
```json
{
  "promotion": "Promotion",
  "shareAndEarnRewards": "Share & Earn Rewards",
  "customShareTemplate": "Custom share template",
  "currentDownlineRate": "Current Downline Rate",
  "gameRate": "Game {rate}%",
  "giftRate": "Gift {rate}%",
  "downlineRateWarning": "When rate is 0%, the downline have no earnings.",
  "shareURL": "Share URL",
  "saveQRCode": "Save QR Code",
  "appLinkCopied": "App link copied to clipboard!",
  "qrCodeSaved": "QR code saved to gallery!",
  "imageUploaded": "Image uploaded successfully!",
  "rewardEarned": "You earned {coins} coins!",
  "selectImage": "Select Image",
  "takePhoto": "Take Photo",
  "chooseFromGallery": "Choose from Gallery"
}
```

---

## 📝 Implementation Steps (Detailed)

### **Step 1: Create Promotion Screen Structure**

1. Create `lib/screens/promotion_screen.dart`
2. Implement basic scaffold with fixed AppBar
3. Add scrollable body structure
4. Match UI design from reference

### **Step 2: Implement Image Carousel**

1. Use `PageView` for swipeable images
2. Add page indicators (dots)
3. Load promotional images from Firestore
4. Display default promotional images if none exist

### **Step 3: Implement QR Code Generation**

1. Generate app link with user referral code
2. Use `qr_flutter` to create QR code widget
3. Convert QR code to image
4. Overlay QR code on promotional images

### **Step 4: Implement Image Upload**

1. Add "Custom share template" button
2. Implement image picker (camera/gallery)
3. Add image cropper
4. Upload to Firebase Storage

### **Step 5: Implement Frame Application**

1. Create frame template service
2. Apply frame to uploaded image
3. Add app logo overlay (top-left)
4. Add QR code overlay (bottom-right)
5. Save processed image

### **Step 6: Implement Share Functionality**

1. "Share URL" button:
   - Generate app link
   - Copy to clipboard
   - Show native share dialog
   - Track share event

2. "Save QR Code" button:
   - Generate QR code image
   - Save to device gallery
   - Track save event

### **Step 7: Implement Reward System**

1. Track share events in Firestore
2. Calculate reward based on share type
3. Update user's `uCoins` balance
4. Show reward notification
5. Log reward transaction

### **Step 8: Add Earning Rate Display**

1. Fetch downline rate from Firestore
2. Display "Game 70% Gift 70%" format
3. Show warning if rate is 0%
4. Allow editing (if admin)

### **Step 9: Integration & Testing**

1. Add menu item to profile screen
2. Test image upload flow
3. Test QR code generation
4. Test sharing functionality
5. Test reward system
6. Test on different devices

---

## 🎯 Key Technical Decisions

### **1. QR Code Generation:**
- **Package:** `qr_flutter: ^4.1.0` (already installed)
- **Format:** App download link with referral code
- **Display:** Overlay on promotional images

### **2. Image Processing:**
- **Package:** `image_picker` + `image_cropper` (already installed)
- **Storage:** Firebase Storage
- **Processing:** Use `dart:ui` or `image` package for frame overlay

### **3. Share Functionality:**
- **Package:** `share_plus: ^10.1.2` (already installed)
- **Methods:** Native share dialog + clipboard copy

### **4. Reward System:**
- **Integration:** Use existing `CoinService`
- **Update:** User's `uCoins` field in Firestore
- **Tracking:** Store in `share_tracking` collection

### **5. Frame Templates:**
- **Design:** Level-based frames (reuse level screen frame designs)
- **Storage:** Firebase Storage or local assets
- **Application:** Image compositing using `dart:ui`

---

## 📊 File Structure

```
lib/
├── screens/
│   └── promotion_screen.dart          (NEW)
├── services/
│   ├── promotion_service.dart         (NEW)
│   ├── promotional_frame_service.dart (NEW)
│   └── promotion_reward_service.dart  (NEW)
├── models/
│   └── promotion_model.dart           (NEW)
├── widgets/
│   ├── promotional_image_carousel.dart (NEW)
│   ├── qr_code_overlay.dart           (NEW)
│   └── promotional_frame_builder.dart (NEW)
└── l10n/
    └── app_en.arb                      (UPDATE - add strings)
```

---

## 🔄 User Flow

```
1. User opens Profile Screen
   ↓
2. Taps "Promotion" menu item
   ↓
3. Promotion Screen opens
   - Shows promotional image carousel
   - Displays app link and QR code options
   ↓
4. User can:
   a) View existing promotional images
   b) Upload custom image → Apply frame → Share
   c) Share URL → Copy link → Get reward
   d) Save QR Code → Save to gallery → Get reward
   ↓
5. After successful share:
   - Reward calculated
   - Coins added to user balance
   - Success notification shown
```

---

## 💡 Additional Features (Optional)

1. **Referral System:**
   - Track referrals from shared links
   - Additional rewards for successful referrals
   - Referral leaderboard

2. **Analytics:**
   - Track share performance
   - View share statistics
   - Most shared images

3. **Customization:**
   - Multiple frame templates
   - Custom QR code colors
   - Logo positioning options

4. **Social Integration:**
   - Direct share to WhatsApp
   - Share to Instagram Stories
   - Share to Facebook

---

## ⚠️ Important Considerations

1. **Permissions:**
   - Camera permission (for image picker)
   - Storage permission (for saving QR code)
   - Already handled by `image_picker` package

2. **Performance:**
   - Optimize image sizes before upload
   - Cache promotional images
   - Lazy load carousel images

3. **Security:**
   - Validate image uploads
   - Sanitize referral codes
   - Rate limit sharing rewards

4. **Error Handling:**
   - Handle network errors
   - Handle storage errors
   - Handle share failures
   - Show user-friendly error messages

---

## 📅 Estimated Implementation Time

- **Phase 1:** ✅ Already complete (dependencies)
- **Phase 2-4:** 2-3 hours (Screen + Service + Model)
- **Phase 5-6:** 2-3 hours (Frame templates + QR code)
- **Phase 7-8:** 2-3 hours (Image upload + Share)
- **Phase 9:** 1-2 hours (Reward system)
- **Phase 10-11:** 1 hour (Menu + Firestore)
- **Phase 12:** 30 minutes (Localization)

**Total Estimated Time:** 8-12 hours

---

## ✅ Implementation Checklist

- [ ] Create `promotion_screen.dart` with basic structure
- [ ] Implement image carousel with PageView
- [ ] Add QR code generation functionality
- [ ] Implement image upload and cropping
- [ ] Create promotional frame service
- [ ] Implement frame application to images
- [ ] Add "Share URL" functionality
- [ ] Add "Save QR Code" functionality
- [ ] Integrate reward system
- [ ] Add earning rate display
- [ ] Create Firestore collections
- [ ] Add menu item to profile screen
- [ ] Add localization strings
- [ ] Test all functionalities
- [ ] Handle errors and edge cases
- [ ] Optimize performance

---

## 🎯 Next Steps

1. **Review this roadmap**
2. **Confirm implementation approach**
3. **Start with Phase 2** (Create Promotion Screen)
4. **Iterate through each phase**
5. **Test thoroughly before production**

---

## 📚 Reference Files

- **Profile Menu:** `lib/screens/profile_screen.dart` (lines 794-1100)
- **Share Example:** `lib/screens/user_profile_view_screen.dart` (lines 1230-1256)
- **Coin Service:** `lib/services/coin_service.dart`
- **Level Frames:** `lib/screens/level_screen.dart` (frame designs)

---

**Ready to proceed?** Let me know if you'd like me to start implementing any specific phase, or if you have questions about the roadmap!















