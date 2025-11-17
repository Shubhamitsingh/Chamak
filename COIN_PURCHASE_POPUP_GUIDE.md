# 💰 Smart Coin Purchase Popup Feature - Complete Guide

## ✅ **Implementation Complete!**

Your app now has a **professional, non-intrusive coin purchase popup** that appears strategically to encourage users to buy coins without annoying them!

## 🧪 **TEST MODE ENABLED** ✅

**Current Status:** Popup shows **EVERY TIME** you open the app for easy testing!

**⚠️ IMPORTANT:** Change to Production Mode before releasing app!  
See: `TEST_MODE_GUIDE.md` for details

---

## 🎯 **What Was Implemented:**

### 1. **Smart Timing Service** (`lib/services/coin_popup_service.dart`)
- ✅ Shows popup maximum **3 times per week**
- ✅ Waits **3 days** before showing to new users
- ✅ Minimum **2 days** between popups
- ✅ Tracks user preferences (Don't Show Again, Remind Later)
- ✅ Shows when coins are **low (< 100)**
- ✅ Weekly counter resets every Monday

### 2. **Beautiful Bottom Sheet Popup** (`lib/widgets/coin_purchase_popup.dart`)
- ✅ Modern, professional design
- ✅ Slides from bottom (not blocking)
- ✅ Shows 3 coin packages (100, 500, 1000)
- ✅ "Buy Now" button → Opens Wallet
- ✅ "Remind Me Later" → Shows again in 3 days
- ✅ "Don't Show Again" → Permanently hidden
- ✅ Easy to dismiss (X button or swipe down)

### 3. **Home Screen Integration** (`lib/screens/home_screen.dart`)
- ✅ Checks popup eligibility on app open
- ✅ 2-second delay before showing (non-intrusive)
- ✅ Shows special message when coins are low
- ✅ Gracefully handles errors

### 4. **User Model Update** (`lib/models/user_model.dart`)
- ✅ Added `coins` field to track balance
- ✅ Default 0 coins for new users
- ✅ Saved to Firestore
- ✅ Can be updated for purchases

---

## 📊 **How It Works:**

```
User Flow:
┌─────────────────────┐
│  User Opens App     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Wait 2 Seconds     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────────────┐
│  Check Smart Conditions:    │
│  • Not shown in 2 days?     │
│  • < 3 times this week?     │
│  • User has low coins?      │
│  • Not disabled by user?    │
└─────────┬───────────────────┘
          │
          ▼ (If YES)
┌─────────────────────┐
│  Show Beautiful     │
│  Bottom Sheet Popup │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────────────┐
│  User Chooses:              │
│  1. Buy Now → Wallet        │
│  2. Remind Later → 3 days   │
│  3. Don't Show → Never      │
│  4. Close (X)               │
└─────────────────────────────┘
```

---

## 🎨 **Popup Features:**

### **Visual Design:**
- 🪙 Golden coin icon with shadow
- 🔥 "HOT" badge on popular package (500 coins)
- 🎨 Green theme matching your app
- 📱 Responsive and professional

### **Coin Packages Shown:**
| Package | Price | Features |
|---------|-------|----------|
| 100 Coins | ₹49 | Starter |
| 500 Coins | ₹99 | 🔥 **POPULAR** |
| 1000 Coins | ₹199 | Best Value |

### **User Options:**
1. **"Buy Now"** → Opens Wallet screen
2. **"Remind Me Later"** → Won't show for 3 days
3. **"Don't Show Again"** → Permanently disabled
4. **Close (X)** → Just closes popup

---

## ⚙️ **Smart Logic Details:**

### **When Popup Shows:**
```
✅ SHOW if:
- Coins < 100 (low balance)
- OR hasn't been shown in 7+ days
- AND not shown in last 2 days
- AND shown < 3 times this week
- AND user hasn't disabled it

❌ DON'T SHOW if:
- New user (< 3 days since install)
- Shown in last 2 days
- Already shown 3 times this week
- User clicked "Don't Show Again"
- User clicked "Remind Later" (< 3 days ago)
```

### **Frequency Control:**
- **Maximum:** 3 times per week
- **Minimum Gap:** 2 days between shows
- **New Users:** Wait 3 days after install
- **Remind Later:** 3 days delay
- **Weekly Reset:** Every Monday

---

## 🧪 **Testing the Feature:**

### **Test Scenario 1: New User**
1. Install app → Register
2. Wait 3 days → Popup appears ✅
3. Close popup
4. Open app again → Popup won't show (2-day gap)

### **Test Scenario 2: Low Coins**
1. Set coins to 50 (in Firestore)
2. Open app → Popup shows "Your coins are running low!" ✅

### **Test Scenario 3: Remind Later**
1. Popup appears
2. Click "Remind Me Later"
3. For next 3 days → Won't show
4. After 3 days → Shows again ✅

### **Test Scenario 4: Don't Show Again**
1. Popup appears
2. Click "Don't Show Again"
3. Never shows again ✅

### **Test Scenario 5: Buy Now**
1. Popup appears
2. Click "Buy Now"
3. Wallet screen opens ✅

---

## 🔧 **Configuration (Customize if Needed):**

Edit `lib/services/coin_popup_service.dart`:

```dart
// Change frequency
static const int _maxShowsPerWeek = 3;  // Max shows per week
static const int _daysBetweenShows = 2; // Days between shows
static const int _daysBeforeFirstShow = 3; // Wait for new users
static const int _remindLaterDays = 3; // Remind later delay
```

Edit `lib/screens/home_screen.dart`:

```dart
// Change delay before showing
Future.delayed(const Duration(seconds: 2), () {
  _checkAndShowCoinPopup();
});
```

Edit `lib/widgets/coin_purchase_popup.dart`:

```dart
// Change coin packages displayed
final packages = [
  {'coins': '100', 'price': '₹49', 'popular': false},
  {'coins': '500', 'price': '₹99', 'popular': true},
  {'coins': '1000', 'price': '₹199', 'popular': false},
];
```

---

## 🗄️ **Firebase Setup:**

### **Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to update their own coins
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.coins is int;
    }
  }
}
```

### **Initial User Data:**
When creating a new user, make sure to include:
```javascript
{
  userId: 'xyz123',
  phoneNumber: '+911234567890',
  coins: 0,  // ← Make sure this field exists!
  // ... other fields
}
```

---

## 📱 **User Experience:**

### **Non-Intrusive Design:**
- ✅ Shows after 2 seconds (not immediately)
- ✅ Bottom sheet (doesn't block entire screen)
- ✅ Easy to dismiss
- ✅ Respects user preferences
- ✅ Smart timing logic

### **Clear Communication:**
- ✅ Shows coin packages clearly
- ✅ Highlights popular option
- ✅ Clear pricing
- ✅ Easy action buttons

### **User Control:**
- ✅ "Don't Show Again" option
- ✅ "Remind Me Later" option
- ✅ Easy to close

---

## 🚀 **Future Enhancements (Optional):**

1. **A/B Testing:**
   - Test different designs
   - Test different timings
   - Track conversion rates

2. **Personalization:**
   - Show different offers to different users
   - Special discounts for active users
   - Birthday/festival offers

3. **Analytics:**
   - Track popup views
   - Track button clicks
   - Track conversion rates

4. **Dynamic Offers:**
   - Load offers from Firebase
   - Admin can change offers
   - Limited-time promotions

---

## 🔍 **Debugging:**

### **Popup Not Showing?**

1. **Check user coins:**
   ```dart
   // In Firebase Console → Firestore
   users/{userId}/coins = 0  // Make sure this exists
   ```

2. **Reset popup preferences:**
   ```dart
   // Add this code temporarily in home screen
   await CoinPopupService().resetPopupPreferences();
   ```

3. **Check logs:**
   ```dart
   // Look for debug prints in console
   debugPrint('Error checking coin popup: ...');
   ```

4. **Verify timing:**
   - Has it been 3+ days since install?
   - Has it been 2+ days since last show?
   - Have you shown it < 3 times this week?

---

## 📝 **Summary:**

✅ **Implemented:** Smart coin purchase popup  
✅ **Design:** Beautiful bottom sheet  
✅ **Timing:** Non-intrusive, strategic  
✅ **User Control:** Don't Show / Remind Later  
✅ **Integration:** Home screen on app open  
✅ **Data:** Coins field added to user model  

**Result:** Professional monetization feature that respects user experience! 🎉

---

## 💡 **Best Practices:**

1. ✅ Never show popup on first app open
2. ✅ Always provide "Don't Show Again" option
3. ✅ Limit frequency (max 3/week)
4. ✅ Show strategically (low coins)
5. ✅ Easy to dismiss
6. ✅ Clear value proposition
7. ✅ Beautiful, professional design

---

**Need Help?**
- Check user's coin balance in Firestore
- Look at shared_preferences for popup tracking
- Test with different user accounts
- Adjust timing constants in service file

**Enjoy your new monetization feature! 💰**

