# AppBar Title Font Size Report

## Summary
This report analyzes all screens in the app to check if AppBar titles have consistent font sizes.

---

## Font Size Distribution

### ✅ **fontSize: 18** (Most Common - 30+ screens)
This is the standard size used across most screens:

1. **about_screen.dart** - fontSize: 18
2. **account_security_screen.dart** - fontSize: 18
3. **chat_screen.dart** (Report dialog) - fontSize: 18
4. **coin_purchase_history_screen.dart** - fontSize: 18
5. **contact_support_screen.dart** - fontSize: 18
6. **edit_profile_screen.dart** - fontSize: 18
7. **event_screen.dart** - fontSize: 18
8. **feedback_screen.dart** - fontSize: 18
9. **followers_list_screen.dart** - fontSize: 18
10. **following_list_screen.dart** - fontSize: 18
11. **help_feedback_screen.dart** - fontSize: 18
12. **language_selection_screen.dart** - fontSize: 18
13. **level_screen.dart** - fontSize: 18
14. **my_earning_screen.dart** - fontSize: 18
15. **privacy_policy_screen.dart** - fontSize: 18
16. **promotion_screen.dart** - fontSize: 18
17. **search_screen.dart** - fontSize: 18
18. **settings_screen.dart** - fontSize: 18
19. **terms_conditions_screen.dart** - fontSize: 18
20. **transaction_history_screen.dart** - fontSize: 18
21. **user_profile_view_screen.dart** - fontSize: 18
22. **user_profile_view_screen.dart** (Image viewer) - fontSize: 18
23. **user_profile_view_screen.dart** (Report dialog) - fontSize: 18
24. **user_search_screen.dart** - fontSize: 18
25. **wallet_screen.dart** - fontSize: 18
26. **warning_screen.dart** - fontSize: 18

---

### ⚠️ **fontSize: 20** (1 screen - INCONSISTENT)
1. **chat_list_screen.dart** - fontSize: 20 ❌

---

### ⚠️ **fontSize: 16** (4 screens - INCONSISTENT)
1. **call_summary_screen.dart** - fontSize: 16 ❌
2. **host_rules_screen.dart** - fontSize: 16 ❌
3. **live_stream_summary_screen.dart** - fontSize: 16 ❌
4. **notification_settings_screen.dart** - fontSize: 16 ❌

---

### ⚠️ **No fontSize specified** (Uses default - 2 screens - INCONSISTENT)
1. **messages_screen.dart** - No fontSize in TextStyle (only color and fontWeight) ❌
2. **payprime_payment_webview_screen.dart** - No TextStyle specified at all ❌

---

### ⚠️ **Special Cases** (No direct title Text widget)
1. **chat_screen.dart** - Uses `InkWell` with `Row` containing user info (no title Text widget)
   - This is intentional design, not an inconsistency

---

## Issues Found

### 🔴 **Critical Inconsistencies:**

1. **chat_list_screen.dart** (fontSize: 20)
   - **Location:** Line 250
   - **Current:** `fontSize: 20`
   - **Should be:** `fontSize: 18` to match standard

2. **call_summary_screen.dart** (fontSize: 16)
   - **Location:** Line 37
   - **Current:** `fontSize: 16`
   - **Should be:** `fontSize: 18` to match standard

3. **host_rules_screen.dart** (fontSize: 16)
   - **Location:** Line 28
   - **Current:** `fontSize: 16`
   - **Should be:** `fontSize: 18` to match standard

4. **live_stream_summary_screen.dart** (fontSize: 16)
   - **Location:** Line 35
   - **Current:** `fontSize: 16`
   - **Should be:** `fontSize: 18` to match standard

5. **notification_settings_screen.dart** (fontSize: 16)
   - **Location:** Line 35
   - **Current:** `fontSize: 16`
   - **Should be:** `fontSize: 18` to match standard

6. **messages_screen.dart** (No fontSize)
   - **Location:** Line 113-116
   - **Current:** Only `color` and `fontWeight` specified
   - **Should add:** `fontSize: 18` to match standard

7. **payprime_payment_webview_screen.dart** (No TextStyle)
   - **Location:** Line 392
   - **Current:** `title: const Text('Complete Payment')` - no style
   - **Should add:** `style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)`

---

## Recommendation

**Standard Font Size: 18**

All AppBar titles should use `fontSize: 18` with `fontWeight: FontWeight.bold` for consistency across the app.

---

## Screens Without AppBar (Not included in report)
- **splash_screen.dart** - No AppBar
- **intro_logo_screen.dart** - No AppBar
- **login_screen.dart** - No AppBar
- **otp_screen.dart** - No AppBar
- **set_profile_screen.dart** - No AppBar
- **home_screen.dart** - No AppBar (uses custom header)
- **profile_screen.dart** - No AppBar (uses custom header)
- **agora_live_stream_screen.dart** - No AppBar (fullscreen)
- **live_reels_screen.dart** - No AppBar (fullscreen)
- **private_call_screen.dart** - No AppBar (fullscreen)
- **image_crop_screen.dart** - AppBar hidden during crop
- **kyc_verification_screen.dart** - No AppBar
- **payment_success_screen.dart** - No AppBar
- **upi_payment_selection_screen.dart** - No AppBar
- **admin_panel_screen.dart** - No AppBar (uses custom header)
- **contact_support_chat_screen.dart** - No AppBar (uses custom header)
- **admin_support_chat_screen.dart** - No AppBar (uses custom header)

---

## Total Screens Analyzed: 48
- ✅ Consistent (fontSize: 18): 26 screens
- ❌ Inconsistent: 7 screens need fixes
- ℹ️ Special cases: 1 screen (chat_screen.dart - intentional design)
- 📋 No AppBar: 14 screens (not applicable)

---

**Report Generated:** $(date)
**Status:** ✅ **All font size inconsistencies have been fixed!**

---

## ✅ Fixes Applied

All 7 inconsistent screens have been updated to use `fontSize: 18`:

1. ✅ **chat_list_screen.dart** - Changed from fontSize: 20 → 18
2. ✅ **call_summary_screen.dart** - Changed from fontSize: 16 → 18
3. ✅ **host_rules_screen.dart** - Changed from fontSize: 16 → 18
4. ✅ **live_stream_summary_screen.dart** - Changed from fontSize: 16 → 18
5. ✅ **notification_settings_screen.dart** - Changed from fontSize: 16 → 18
6. ✅ **messages_screen.dart** - Added fontSize: 18
7. ✅ **payprime_payment_webview_screen.dart** - Added TextStyle with fontSize: 18

**All AppBar titles now use consistent fontSize: 18 across the entire app!**
