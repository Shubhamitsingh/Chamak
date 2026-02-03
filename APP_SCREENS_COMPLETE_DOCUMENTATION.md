# 📱 Chamak App - Complete Screen Documentation

## 📋 Overview

**Total Screens:** 59 screens  
**Documentation Date:** $(date)  
**App Purpose:** Live streaming and social video calling platform with coin-based economy

---

## 🎯 Screen Categories

1. **Authentication & Onboarding** (5 screens)
2. **Main App Navigation** (5 screens)
3. **Live Streaming** (4 screens)
4. **Messaging & Chat** (5 screens)
5. **User Profile & Social** (7 screens)
6. **Wallet & Payments** (6 screens)
7. **Settings & Preferences** (8 screens)
8. **Support & Help** (4 screens)
9. **Legal & Policies** (3 screens)
10. **Admin & Management** (3 screens)
11. **Utilities & Tools** (5 screens)
12. **Creator Features** (4 screens)

---

## 📱 Complete Screen List

### 🔐 **1. AUTHENTICATION & ONBOARDING** (5 screens)

#### **1.1. `splash_screen.dart`**
- **Purpose:** Initial app loading screen with branding
- **Why Made:** First impression, shows app logo while initializing
- **Features:**
  - App logo display
  - Loading animation
  - Routes to login or home based on auth status
- **Navigation:** → LoginScreen or HomeScreen

#### **1.2. `intro_logo_screen.dart`**
- **Purpose:** App introduction with logo animation
- **Why Made:** Brand introduction, smooth entry point
- **Features:**
  - Animated logo
  - 2-second delay before navigation
  - Checks authentication status
- **Navigation:** → SplashScreen (if not authenticated) or HomeScreen (if authenticated)

#### **1.3. `login_screen.dart`**
- **Purpose:** User phone number login
- **Why Made:** Secure authentication via phone number
- **Features:**
  - Phone number input with country picker
  - OTP sending functionality
  - Phone number validation
- **Navigation:** → OtpScreen

#### **1.4. `otp_screen.dart`**
- **Purpose:** OTP verification for phone login
- **Why Made:** Two-factor authentication security
- **Features:**
  - 6-digit OTP input
  - Auto-verification
  - Resend OTP option
  - Timer countdown
- **Navigation:** → SetProfileScreen (first time) or HomeScreen (returning user)

#### **1.5. `set_profile_screen.dart`**
- **Purpose:** Initial profile setup for new users
- **Why Made:** Collect essential user information on first login
- **Features:**
  - Display name input
  - Profile photo upload
  - Gender selection
  - Date of birth
- **Navigation:** → HomeScreen

---

### 🏠 **2. MAIN APP NAVIGATION** (5 screens)

#### **2.1. `home_screen.dart`**
- **Purpose:** Main app hub with bottom navigation
- **Why Made:** Central navigation point, primary user interface
- **Features:**
  - Bottom navigation bar (5 tabs)
  - Tab navigation: Home, Wallet, Go Live, Messages, Profile
  - Live stream discovery
  - Announcement banners
  - Nearby users
  - Event notifications
- **Navigation:** All main app screens accessible from here

#### **2.2. `search_screen.dart`**
- **Purpose:** General search functionality
- **Why Made:** Find users, content, and features quickly
- **Features:**
  - Search bar
  - Search history
  - Recent searches
- **Navigation:** → UserSearchScreen, UserProfileViewScreen

#### **2.3. `user_search_screen.dart`**
- **Purpose:** Search and discover users
- **Why Made:** Find and connect with other users
- **Features:**
  - User search by name/ID
  - Filter options
  - User list with avatars
- **Navigation:** → UserProfileViewScreen, ChatScreen

#### **2.4. `nearby_users_screen.dart`**
- **Purpose:** Discover users based on location
- **Why Made:** Location-based social discovery feature
- **Features:**
  - Location-based user list
  - Distance display
  - Follow/Chat buttons
- **Navigation:** → UserProfileViewScreen, ChatScreen

#### **2.5. `live_reels_screen.dart`**
- **Purpose:** Browse live streams feed
- **Why Made:** Discover and watch live content
- **Features:**
  - Live streams list
  - Stream preview
  - Host information
- **Navigation:** → AgoraLiveStreamScreen

---

### 📺 **3. LIVE STREAMING** (4 screens)

#### **3.1. `agora_live_stream_screen.dart`**
- **Purpose:** Main live streaming interface using Agora SDK
- **Why Made:** Core feature - enables hosts to go live and users to watch
- **Features:**
  - Live video streaming
  - Chat panel
  - Gift sending
  - Viewer count
  - Host controls
  - Coin-based calling
- **Navigation:** → CallSummaryScreen, LiveStreamSummaryScreen

#### **3.2. `live_page.dart`**
- **Purpose:** Placeholder/alternative live page
- **Why Made:** Backup or alternative live streaming interface
- **Status:** ⚠️ Basic implementation - may need review
- **Features:**
  - Basic live stream display
- **Navigation:** → AgoraLiveStreamScreen

#### **3.3. `private_call_screen.dart`**
- **Purpose:** One-on-one private video calls
- **Why Made:** Private video calling feature between users
- **Features:**
  - Private video call
  - Coin deduction
  - Call controls
  - Timer display
- **Navigation:** → CallSummaryScreen

#### **3.4. `live_stream_summary_screen.dart`**
- **Purpose:** Post-stream summary and statistics
- **Why Made:** Show hosts their stream performance
- **Features:**
  - Viewers count
  - Gifts received
  - Duration
  - Earnings summary
- **Navigation:** → HomeScreen, ProfileScreen

---

### 💬 **4. MESSAGING & CHAT** (5 screens)

#### **4.1. `chat_list_screen.dart`**
- **Purpose:** List of all user chats
- **Why Made:** Central hub for all conversations
- **Features:**
  - Chat list with last message
  - Unread count badges
  - Search chats
  - Chamakz Team chat
- **Navigation:** → ChatScreen, ContactSupportChatScreen

#### **4.2. `chat_screen.dart`**
- **Purpose:** Individual chat conversation
- **Why Made:** One-on-one messaging between users
- **Features:**
  - Message bubbles
  - Text messages
  - Media sharing
  - Video call button
  - Read receipts
  - Report user option
- **Navigation:** → PrivateCallScreen, UserProfileViewScreen

#### **4.3. `messages_screen.dart`**
- **Purpose:** Messages overview/alternative messages view
- **Why Made:** Alternative messages interface
- **Features:**
  - Message list
  - Chamakz Team messages
- **Navigation:** → ChatScreen, ContactSupportChatScreen

#### **4.4. `contact_support_chat_screen.dart`**
- **Purpose:** User-to-admin support chat
- **Why Made:** Customer support communication channel
- **Features:**
  - Chat with support team
  - Number blocking (security)
  - Real-time messaging
  - Push notifications
- **Navigation:** → HomeScreen

#### **4.5. `team_messages_screen.dart`**
- **Purpose:** Broadcast messages from Chamakz Team
- **Why Made:** Announcements and updates from app team
- **Features:**
  - Team messages list
  - Broadcast notifications
  - Message history
- **Navigation:** → HomeScreen

---

### 👤 **5. USER PROFILE & SOCIAL** (7 screens)

#### **5.1. `profile_screen.dart`**
- **Purpose:** User's own profile view
- **Why Made:** Personal profile management hub
- **Features:**
  - Profile information
  - Statistics (followers, following)
  - Earnings display
  - Settings access
  - Level display
  - Quick actions
- **Navigation:** → EditProfileScreen, SettingsScreen, WalletScreen, etc.

#### **5.2. `user_profile_view_screen.dart`**
- **Purpose:** View other users' profiles
- **Why Made:** Discover and interact with other users
- **Features:**
  - User profile display
  - Follow/Unfollow button
  - Chat button
  - Photo gallery
  - User statistics
  - Report user option
- **Navigation:** → ChatScreen, FollowingListScreen, FollowersListScreen

#### **5.3. `edit_profile_screen.dart`**
- **Purpose:** Edit user profile information
- **Why Made:** Allow users to update their profile
- **Features:**
  - Edit display name
  - Change profile photo
  - Update bio
  - Edit personal information
- **Navigation:** → ProfileScreen, ImageCropScreen

#### **5.4. `followers_list_screen.dart`**
- **Purpose:** List of user's followers
- **Why Made:** Social feature - see who follows you
- **Features:**
  - Followers list
  - Follow/Unfollow actions
  - User avatars
- **Navigation:** → UserProfileViewScreen, ChatScreen

#### **5.5. `following_list_screen.dart`**
- **Purpose:** List of users you follow
- **Why Made:** Social feature - manage who you follow
- **Features:**
  - Following list
  - Unfollow option
  - User avatars
- **Navigation:** → UserProfileViewScreen, ChatScreen

#### **5.6. `level_screen.dart`**
- **Purpose:** User level and progress display
- **Why Made:** Gamification - show user progression
- **Features:**
  - Current level
  - XP progress
  - Level benefits
  - Next level requirements
- **Navigation:** → ProfileScreen

#### **5.7. `image_crop_screen.dart`**
- **Purpose:** Crop and edit profile images
- **Why Made:** Image editing utility for profile photos
- **Features:**
  - Image cropping
  - Rotation
  - Aspect ratio selection
- **Navigation:** → EditProfileScreen, SetProfileScreen

---

### 💰 **6. WALLET & PAYMENTS** (6 screens)

#### **6.1. `wallet_screen.dart`**
- **Purpose:** User wallet and coin management
- **Why Made:** Core feature - manage coins for calls and gifts
- **Features:**
  - Coin balance display
  - Coin purchase packages
  - Withdrawal (for hosts)
  - Transaction history access
  - Dark theme design
- **Navigation:** → CoinPurchaseHistoryScreen, UpiPaymentSelectionScreen

#### **6.2. `coin_purchase_history_screen.dart`**
- **Purpose:** History of coin purchases and spending
- **Why Made:** Track coin transactions and usage
- **Features:**
  - Purchase history
  - Spending history
  - Gift transactions
  - Date filters
  - Dark theme design
- **Navigation:** → WalletScreen

#### **6.3. `transaction_history_screen.dart`**
- **Purpose:** Withdrawal transaction history (for hosts)
- **Why Made:** Track withdrawal requests and payments
- **Features:**
  - Withdrawal history
  - Status tracking (pending, paid, rejected)
  - Filter by status
  - Dark theme design
- **Navigation:** → WalletScreen, MyEarningScreen

#### **6.4. `payprime_payment_webview_screen.dart`**
- **Purpose:** Payment gateway webview for coin purchases
- **Why Made:** Secure payment processing via PayPrime
- **Features:**
  - Payment webview
  - Payment status tracking
  - Success/failure handling
- **Navigation:** → PaymentSuccessScreen, PaymentFailureScreen

#### **6.5. `upi_payment_selection_screen.dart`**
- **Purpose:** UPI payment method selection
- **Why Made:** Multiple UPI options for Indian users
- **Features:**
  - UPI app selection
  - Payment initiation
  - Status tracking
- **Navigation:** → PayPrimePaymentWebViewScreen, PaymentSuccessScreen

#### **6.6. `payment_success_screen.dart`**
- **Purpose:** Payment success confirmation
- **Why Made:** Confirm successful coin purchase
- **Features:**
  - Success message
  - Coin amount added
  - Continue button
- **Navigation:** → WalletScreen

#### **6.7. `payment_failure_screen.dart`**
- **Purpose:** Payment failure handling
- **Why Made:** Handle failed payments gracefully
- **Features:**
  - Error message
  - Retry option
  - Support contact
- **Navigation:** → WalletScreen

---

### ⚙️ **7. SETTINGS & PREFERENCES** (8 screens)

#### **7.1. `settings_screen.dart`**
- **Purpose:** App settings hub
- **Why Made:** Central settings management
- **Features:**
  - Account settings
  - Privacy settings
  - Notification settings
  - Language settings
  - Policy links
- **Navigation:** → All settings sub-screens

#### **7.2. `account_security_screen.dart`**
- **Purpose:** Account security settings
- **Why Made:** Protect user accounts
- **Features:**
  - Password change (if applicable)
  - Two-factor authentication
  - Login history
  - Security alerts
- **Navigation:** → SettingsScreen

#### **7.3. `notification_settings_screen.dart`**
- **Purpose:** Notification preferences
- **Why Made:** Let users control notifications
- **Features:**
  - Push notification toggle
  - Notification types
  - Sound settings
  - Quiet hours
- **Navigation:** → SettingsScreen

#### **7.4. `language_selection_screen.dart`**
- **Purpose:** App language selection
- **Why Made:** Multi-language support
- **Features:**
  - Language list
  - Language switching
  - App restart prompt
- **Navigation:** → SettingsScreen

#### **7.5. `general_screen.dart`**
- **Purpose:** General app settings
- **Why Made:** General preferences and app info
- **Features:**
  - App version
  - Storage management
  - Cache clearing
- **Navigation:** → SettingsScreen

#### **7.6. `update_details_screen.dart`**
- **Purpose:** App update information
- **Why Made:** Show app update details and changelog
- **Features:**
  - Version information
  - Update notes
  - Update button
- **Navigation:** → SettingsScreen

#### **7.7. `about_screen.dart`**
- **Purpose:** About the app
- **Why Made:** App information and credits
- **Features:**
  - App description
  - Version number
  - Developer info
  - Credits
- **Navigation:** → SettingsScreen

#### **7.8. `warning_screen.dart`**
- **Purpose:** User warnings and violations
- **Why Made:** Show account warnings to users
- **Features:**
  - Warning list
  - Violation details
  - Appeal option
- **Navigation:** → ProfileScreen

---

### 🆘 **8. SUPPORT & HELP** (4 screens)

#### **8.1. `contact_support_screen.dart`**
- **Purpose:** Contact support options
- **Why Made:** Help users reach support
- **Features:**
  - Support options
  - FAQ links
  - Chat with support button
- **Navigation:** → ContactSupportChatScreen, HelpFeedbackScreen

#### **8.2. `help_feedback_screen.dart`**
- **Purpose:** Help center and feedback
- **Why Made:** Self-service help and user feedback
- **Features:**
  - FAQ section
  - Help articles
  - Feedback form
- **Navigation:** → FeedbackScreen, ContactSupportChatScreen

#### **8.3. `feedback_screen.dart`**
- **Purpose:** Submit feedback to app team
- **Why Made:** Collect user feedback for improvements
- **Features:**
  - Feedback form
  - Rating system
  - Category selection
- **Navigation:** → HelpFeedbackScreen

#### **8.4. `call_summary_screen.dart`**
- **Purpose:** Post-call summary and feedback
- **Why Made:** Show call details and collect feedback
- **Features:**
  - Call duration
  - Coins spent
  - Rating option
  - Feedback form
- **Navigation:** → HomeScreen, ProfileScreen

---

### 📜 **9. LEGAL & POLICIES** (3 screens)

#### **9.1. `policy_screen.dart`**
- **Purpose:** Combined policy viewer (Privacy, Terms, Child Safety)
- **Why Made:** Legal compliance and user transparency
- **Features:**
  - Tabbed interface
  - Privacy Policy tab
  - Terms & Conditions tab
  - Child Safety Policy tab
- **Navigation:** → SettingsScreen

#### **9.2. `privacy_policy_screen.dart`**
- **Purpose:** Privacy policy display
- **Why Made:** Legal requirement - data privacy information
- **Features:**
  - Privacy policy content
  - Scrollable text
- **Navigation:** → SettingsScreen, PolicyScreen

#### **9.3. `terms_and_conditions_screen.dart` / `terms_conditions_screen.dart`**
- **Purpose:** Terms and conditions display
- **Why Made:** Legal requirement - user agreement
- **Features:**
  - Terms content
  - Scrollable text
- **Note:** Two similar files exist - may need consolidation
- **Navigation:** → SettingsScreen, PolicyScreen

---

### 👨‍💼 **10. ADMIN & MANAGEMENT** (3 screens)

#### **10.1. `admin_panel_screen.dart`**
- **Purpose:** Admin dashboard for app management
- **Why Made:** Admin tools for managing app, users, and content
- **Features:**
  - User management
  - Content moderation
  - Analytics dashboard
  - Support chat access
  - Broadcast messages
- **Navigation:** → AdminSupportChatScreen, PerformanceDashboardScreen

#### **10.2. `admin_support_chat_screen.dart`**
- **Purpose:** Admin-to-user support chat interface
- **Why Made:** Allow admins to respond to user support requests
- **Features:**
  - Chat with users
  - User information display
  - Number blocking (security)
  - Push notifications to users
- **Navigation:** → AdminPanelScreen

#### **10.3. `performance_dashboard_screen.dart`**
- **Purpose:** Performance analytics dashboard
- **Why Made:** Monitor app performance and metrics
- **Features:**
  - User statistics
  - Revenue metrics
  - Activity charts
- **Navigation:** → AdminPanelScreen

---

### 🎨 **11. CREATOR FEATURES** (4 screens)

#### **11.1. `become_creator_screen.dart`**
- **Purpose:** Apply to become a host/creator
- **Why Made:** Onboarding for users who want to go live
- **Features:**
  - Application form
  - Requirements display
  - Submission process
- **Navigation:** → CreatorApplicationStatusScreen, HostRulesScreen

#### **11.2. `creator_application_status_screen.dart`**
- **Purpose:** Check creator application status
- **Why Made:** Track application approval status
- **Features:**
  - Application status
  - Approval/rejection messages
  - Reapply option
- **Navigation:** → BecomeCreatorScreen, ProfileScreen

#### **11.3. `host_rules_screen.dart`**
- **Purpose:** Rules and guidelines for hosts
- **Why Made:** Ensure hosts understand community guidelines
- **Features:**
  - Host rules display
  - Community guidelines
  - Dark theme design
- **Navigation:** → BecomeCreatorScreen, AgoraLiveStreamScreen

#### **11.4. `my_earning_screen.dart`**
- **Purpose:** Host earnings dashboard
- **Why Made:** Show hosts their earnings and statistics
- **Features:**
  - Total earnings
  - Withdrawable amount
  - Earnings breakdown
  - Withdrawal history
- **Navigation:** → WalletScreen, TransactionHistoryScreen

---

### 🛠️ **12. UTILITIES & TOOLS** (5 screens)

#### **12.1. `kyc_verification_screen.dart`**
- **Purpose:** KYC (Know Your Customer) verification
- **Why Made:** Identity verification for withdrawals
- **Features:**
  - Document upload
  - Verification status
  - ID verification
- **Navigation:** → WalletScreen, MyEarningScreen

#### **12.2. `event_screen.dart`**
- **Purpose:** App events and promotions display
- **Why Made:** Show special events and promotions
- **Features:**
  - Event list
  - Event details
  - Participation options
- **Navigation:** → HomeScreen, ProfileScreen

#### **12.3. `promotion_screen.dart`**
- **Purpose:** Promotional content and offers
- **Why Made:** Display promotions and special offers
- **Features:**
  - Promotion list
  - Offer details
  - Claim options
- **Navigation:** → HomeScreen, WalletScreen

---

## 📊 Screen Statistics

### **By Category:**
- Authentication & Onboarding: **5 screens**
- Main App Navigation: **5 screens**
- Live Streaming: **4 screens**
- Messaging & Chat: **5 screens**
- User Profile & Social: **7 screens**
- Wallet & Payments: **7 screens**
- Settings & Preferences: **8 screens**
- Support & Help: **4 screens**
- Legal & Policies: **3 screens**
- Admin & Management: **3 screens**
- Creator Features: **4 screens**
- Utilities & Tools: **3 screens**

### **Total: 59 screens**

---

## 🔄 Navigation Flow Summary

### **Main User Flow:**
```
SplashScreen / IntroLogoScreen
    ↓
LoginScreen → OtpScreen → SetProfileScreen
    ↓
HomeScreen (Main Hub)
    ├─→ ProfileScreen
    ├─→ WalletScreen
    ├─→ ChatListScreen
    ├─→ AgoraLiveStreamScreen
    └─→ [Various Feature Screens]
```

### **Bottom Navigation (HomeScreen):**
1. **Home Tab** - Explore content, live streams
2. **Wallet Tab** - Coin management
3. **Go Live Tab** - Start streaming
4. **Messages Tab** - Chat list
5. **Profile Tab** - User profile

---

## 🎯 Key Features by Screen Category

### **Core Features:**
- ✅ Live streaming (Agora SDK)
- ✅ Video calling (Private calls)
- ✅ Messaging (Real-time chat)
- ✅ Social features (Follow/Unfollow)
- ✅ Coin-based economy
- ✅ Gift system
- ✅ Support chat

### **Monetization:**
- ✅ Coin purchases
- ✅ Host earnings
- ✅ Withdrawal system
- ✅ Payment gateway integration

### **User Management:**
- ✅ Profile management
- ✅ Settings & preferences
- ✅ Account security
- ✅ KYC verification

---

## 📝 Notes

### **Duplicate Files:**
- `terms_and_conditions_screen.dart` and `terms_conditions_screen.dart` - Consider consolidating

### **Basic Implementation:**
- `live_page.dart` - May need enhancement or removal

### **Admin Only:**
- `admin_panel_screen.dart`
- `admin_support_chat_screen.dart`
- `performance_dashboard_screen.dart`

---

## ✅ Summary

**Total Screens:** 59  
**Status:** ✅ All screens documented  
**Purpose:** Complete reference for app structure and navigation

This document serves as a comprehensive guide to all screens in the Chamak app, their purpose, and why they were created.

---

**Document Generated:** $(date)  
**Last Updated:** $(date)  
**Version:** 1.0
