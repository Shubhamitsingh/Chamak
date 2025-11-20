# 🧪 TEST MODE vs 🚀 PRODUCTION MODE

## Quick Toggle Guide

---

## 🧪 **TEST MODE (Current)** ✅

### What It Does:
- ✅ Popup shows **EVERY TIME** you open the app
- ✅ Orange banner shows "🧪 TEST MODE - Shows Every Time"
- ✅ Bypasses all timing checks
- ✅ Perfect for testing

### When to Use:
- ✅ During development
- ✅ Testing popup design
- ✅ Showing to team/stakeholders
- ✅ Debugging

---

## 🚀 **PRODUCTION MODE** (Before Release)

### What It Does:
- ✅ Smart timing logic enabled
- ✅ Shows maximum 3 times per week
- ✅ Waits 3 days for new users
- ✅ Minimum 2 days between shows
- ✅ Respects user preferences

### When to Use:
- ✅ Before uploading to Play Store
- ✅ Production release
- ✅ Real users

---

## 🔄 **How to Switch Modes:**

### **File:** `lib/services/coin_popup_service.dart`

### **Line 8:**

**TEST MODE (Shows every time):**
```dart
static const bool TEST_MODE = true; // ← Shows every time!
```

**PRODUCTION MODE (Smart timing):**
```dart
static const bool TEST_MODE = false; // ← Smart timing enabled!
```

---

## ⚠️ **IMPORTANT - Before Release:**

### ✅ Checklist:

```
Before uploading to Play Store:

[ ] Open: lib/services/coin_popup_service.dart
[ ] Find: Line 8 - static const bool TEST_MODE = true;
[ ] Change to: static const bool TEST_MODE = false;
[ ] Save file
[ ] Run: flutter clean
[ ] Run: flutter build apk --release
[ ] Test: Open app 3-4 times (should NOT show every time)
[ ] Upload to Play Store
```

---

## 🧪 **Testing in Test Mode:**

### What to Test:

1. **Open App:** Popup appears after 2 seconds ✅
2. **Close Popup:** Click X button ✅
3. **Reopen App:** Popup appears again immediately ✅
4. **Buy Now Button:** Opens Wallet screen ✅
5. **Remind Later:** Still shows next time (in test mode) ✅
6. **Don't Show Again:** Still shows next time (in test mode) ✅

### Expected Behavior:
```
Test Mode ON:
- Open app → Popup shows
- Close popup
- Open app again → Popup shows AGAIN (ignores all rules)

Test Mode OFF (Production):
- Open app → Popup shows (if eligible)
- Close popup
- Open app again → NO popup (2-day minimum gap)
- Wait 2 days → Popup shows again
```

---

## 📊 **Visual Differences:**

### Test Mode:
```
┌─────────────────────────────────┐
│ 🧪 TEST MODE - Shows Every Time │ ← Orange banner
├─────────────────────────────────┤
│     🪙 Golden Coin              │
│                                 │
│  🎉 Special Coin Offer!         │
│  ...                            │
└─────────────────────────────────┘
```

### Production Mode:
```
┌─────────────────────────────────┐
│     🪙 Golden Coin              │ ← No banner
│                                 │
│  🎉 Special Coin Offer!         │
│  ...                            │
└─────────────────────────────────┘
```

---

## 🎯 **Quick Commands:**

### Enable Test Mode:
```bash
# 1. Open file
code lib/services/coin_popup_service.dart

# 2. Change line 8 to:
static const bool TEST_MODE = true;

# 3. Hot restart
r  # in terminal
```

### Enable Production Mode:
```bash
# 1. Open file
code lib/services/coin_popup_service.dart

# 2. Change line 8 to:
static const bool TEST_MODE = false;

# 3. Clean build
flutter clean
flutter run
```

---

## 🐛 **Troubleshooting:**

### Popup not showing in Test Mode?

1. **Check line 8:**
   ```dart
   static const bool TEST_MODE = true; // ← Should be true
   ```

2. **Hot restart app:** Press `R` in terminal

3. **Check console for errors**

4. **Verify popup is called:** Check `home_screen.dart` line 47

### Popup showing too much in Production?

1. **Check line 8:**
   ```dart
   static const bool TEST_MODE = false; // ← Should be false
   ```

2. **Do full rebuild:**
   ```bash
   flutter clean
   flutter run
   ```

---

## 📝 **Summary:**

| Feature | Test Mode | Production Mode |
|---------|-----------|-----------------|
| **Shows Every Time** | ✅ YES | ❌ NO |
| **Orange Banner** | ✅ YES | ❌ NO |
| **Smart Timing** | ❌ NO | ✅ YES |
| **Frequency Limit** | ❌ NO | ✅ 3/week |
| **User Preferences** | ❌ Ignored | ✅ Respected |
| **Use For** | Testing | Production |

---

## ⚡ **Pro Tips:**

1. ✅ **Always test in Test Mode first** before switching to production
2. ✅ **Show to team in Test Mode** so they see it immediately
3. ✅ **Switch to Production Mode** at least 1 day before release
4. ✅ **Test Production Mode** on a real device before uploading
5. ✅ **Set reminder** to switch mode before release!

---

## 🚨 **Warning:**

**DON'T FORGET TO SWITCH TO PRODUCTION MODE BEFORE RELEASE!**

If you release with Test Mode ON:
- ❌ Users will see popup EVERY TIME they open app
- ❌ Users will get VERY ANNOYED
- ❌ Bad reviews on Play Store
- ❌ Users will uninstall app

**Set a reminder NOW:**
```
📅 Before Play Store Upload:
- [ ] Change TEST_MODE to false
- [ ] Remove orange test banner
- [ ] Test production behavior
- [ ] Upload to Play Store
```

---

**Current Status:** 🧪 **TEST MODE ENABLED** ✅

**Remember:** Switch to Production Mode before release! 🚀


































