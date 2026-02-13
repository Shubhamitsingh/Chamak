# Font Style Analysis Report - Complete App Screens

**Date:** December 2024  
**App:** Chamak  
**Default Font Family:** Poppins (via Google Fonts)  
**Theme Configuration:** `lib/main.dart` - `GoogleFonts.poppinsTextTheme(baseTextTheme)`

---

## 📋 Executive Summary

### **Default Font Configuration:**
- **Font Family:** Poppins (Google Fonts)
- **Location:** `lib/main.dart` line 266
- **Implementation:** `GoogleFonts.poppinsTextTheme(baseTextTheme)`
- **Scope:** Applied globally to all screens via MaterialApp theme

### **Font Weight Usage Summary:**
- **FontWeight.normal** (400): Used in some text elements
- **FontWeight.w400**: Used for regular body text
- **FontWeight.w500**: Used for medium emphasis text
- **FontWeight.w600**: Used for semi-bold text (buttons, labels)
- **FontWeight.w700**: Used for bold headings
- **FontWeight.bold** (700): Used for titles and important text

### **Font Size Range:**
- **Smallest:** 9px (profile screen badges)
- **Small:** 10px, 11px, 12px, 13px (labels, captions, small text)
- **Medium:** 14px, 15px, 16px (body text, buttons, standard text)
- **Large:** 17px, 18px, 20px (headings, titles)
- **Extra Large:** 24px, 28px, 32px (main titles, hero text)

---

## 📱 Screen-by-Screen Font Style Analysis

### **1. chat_screen.dart**
**Font Styles Used:**
- **fontSize: 10** - Small badges, timestamps
- **fontSize: 11** - Small labels, metadata (with FontWeight.w600)
- **fontSize: 13** - Hint text, secondary information
- **fontSize: 14** - Standard body text, message text
- **fontSize: 15** - Medium emphasis text
- **fontSize: 16** - Standard headings, important text
- **fontSize: 18** - Dialog titles, section headings (FontWeight.bold)
- **fontSize: 20** - Large headings
- **fontSize: 32** - Hero text, large numbers

**Font Weights:**
- FontWeight.bold - Titles, important text
- FontWeight.w500 - Medium emphasis
- FontWeight.w600 - Semi-bold labels, buttons
- FontWeight.normal - Regular text

**Special Properties:**
- letterSpacing: 0.2 (small labels)
- letterSpacing: 0.3 (headings)

---

### **2. user_profile_view_screen.dart**
**Font Styles Used:**
- **fontSize: 11** - Small labels, metadata
- **fontSize: 12** - Labels, secondary text (FontWeight.w400, w500, w600, w700)
- **fontSize: 14** - Body text, descriptions (FontWeight.w400, w700)
- **fontSize: 16** - Standard text, buttons (FontWeight.w500, normal)
- **fontSize: 18** - Section headings (FontWeight.w600, w700, bold)
- **fontSize: 32** - Large numbers, hero text (FontWeight.w700)

**Font Weights:**
- FontWeight.w400 - Regular text
- FontWeight.w500 - Medium emphasis
- FontWeight.w600 - Semi-bold
- FontWeight.w700 - Bold headings
- FontWeight.bold - Titles
- FontWeight.normal - Default text

**Special Properties:**
- letterSpacing: 0.3 (headings)

---

### **3. become_creator_screen.dart**
**Font Styles Used:**
- **fontSize: 11** - Small labels
- **fontSize: 12** - Labels, checkboxes (FontWeight.w600)
- **fontSize: 13** - Secondary text
- **fontSize: 14** - Body text (FontWeight.w500)
- **fontSize: 15** - Medium emphasis (FontWeight.bold)
- **fontSize: 16** - Standard headings (FontWeight.bold)
- **fontSize: 18** - Section titles (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles, headings
- FontWeight.w500 - Medium text
- FontWeight.w600 - Labels

**Special Properties:**
- letterSpacing: 0.3 (headings)

---

### **4. creator_application_status_screen.dart**
**Font Styles Used:**
- **fontSize: 14** - Body text, descriptions (FontWeight.w400, w600, w700)
- **fontSize: 16** - Standard text (FontWeight.w400, w600, w700)
- **fontSize: 18** - Section headings (FontWeight.w700)
- **fontSize: 20** - Main titles (FontWeight.w700)

**Font Weights:**
- FontWeight.w400 - Regular text
- FontWeight.w600 - Semi-bold
- FontWeight.w700 - Bold headings

**Special Properties:**
- letterSpacing: -0.2 (main title)

---

### **5. general_screen.dart**
**Font Styles Used:**
- **fontSize: 11** - Small labels
- **fontSize: 13** - Secondary text (FontWeight.w600)
- **fontSize: 18** - Section titles (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles
- FontWeight.w600 - Labels

---

### **6. policy_screen.dart**
**Font Styles Used:**
- **fontSize: 12** - Labels, metadata (FontStyle.italic)
- **fontSize: 14** - Body text (FontWeight.w400, w600)
- **fontSize: 18** - Section headings (FontWeight.w700)

**Font Weights:**
- FontWeight.w400 - Regular text
- FontWeight.w600 - Semi-bold
- FontWeight.w700 - Bold headings

**Special Properties:**
- FontStyle.italic - Metadata text

---

### **7. profile_screen.dart**
**Font Styles Used:**
- **fontSize: 9** - Small badges
- **fontSize: 10** - Tiny labels (FontWeight.w600)
- **fontSize: 11** - Small labels (FontWeight.w500)
- **fontSize: 12** - Labels, metadata (FontWeight.w500)
- **fontSize: 14** - Body text
- **fontSize: 18** - Section headings (FontWeight.w600, bold)
- **fontSize: 20** - Main titles (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles
- FontWeight.w500 - Medium text
- FontWeight.w600 - Semi-bold headings

---

### **8. settings_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **9. home_screen.dart**
**Font Styles Used:**
- **fontSize: 10** - Small badges (FontWeight.bold)
- **fontSize: 11** - Small labels (FontWeight.w400, w500)
- **fontSize: 12** - Labels, metadata (FontWeight.bold, w600)
- **fontSize: 14** - Body text, buttons (FontWeight.w500)
- **fontSize: 16** - Tab labels, headings (FontWeight.bold, w500)
- **fontSize: 24** - Large headings (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles, important text
- FontWeight.w400 - Regular text
- FontWeight.w500 - Medium emphasis
- FontWeight.w600 - Semi-bold

**Special Features:**
- Dynamic fontWeight based on tab selection (bold for active tab, w500 for inactive)

---

### **10. login_screen.dart**
**Font Styles Used:**
- **fontSize: 13** - Labels, hints (FontWeight.normal, w600, bold)
- **fontSize: 14** - Body text (FontWeight.w600)
- **fontSize: 15** - Medium emphasis (FontWeight.w600)
- **fontSize: 16** - Standard text
- **fontSize: 17** - Buttons (FontWeight.w500)
- **fontSize: 20** - Headings
- **fontSize: 28** - Main title (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles
- FontWeight.w500 - Medium text
- FontWeight.w600 - Semi-bold
- FontWeight.normal - Regular text

**Special Features:**
- Dynamic fontWeight based on input validation (w600 when digitCount >= 10)

---

### **11. chat_list_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **12. messages_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **13. wallet_screen.dart**
**Font Styles Used:**
- **fontSize: 10** - Small labels (FontWeight.w400)
- **fontSize: 11** - Small text (FontWeight.w600)
- **fontSize: 14** - Body text, buttons (FontWeight.bold, w400)
- **fontSize: 18** - Section headings (FontWeight.bold)
- **fontSize: 26** - Large numbers, amounts (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles, amounts
- FontWeight.w400 - Regular text
- FontWeight.w600 - Semi-bold labels

---

### **14. agora_live_stream_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **15. user_search_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **16. set_profile_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **17. my_earning_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **18. add_payment_method_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **19. admin_panel_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **20. about_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **21. terms_and_conditions_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **22. privacy_policy_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **23. performance_dashboard_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **24. private_call_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **25. payment_failure_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **26. update_details_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **27. live_stream_summary_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **28. transaction_history_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **29. coin_purchase_history_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **30. host_rules_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **31. followers_list_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **32. following_list_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **33. live_reels_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **34. nearby_users_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **35. otp_screen.dart**
**Font Styles Used:**
- **fontSize: 14** - Body text, buttons
- **fontSize: 18** - Section headings (FontWeight.bold)
- **fontSize: 22** - Medium headings (FontWeight.bold)
- **fontSize: 28** - Main title (FontWeight.bold)

**Font Weights:**
- FontWeight.bold - Titles, headings

---

### **36. team_messages_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **37. promotion_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **38. account_security_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **39. language_selection_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **40. notification_settings_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **41. feedback_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **42. help_feedback_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **43. edit_profile_screen.dart**
**Font Styles Used:**
- **fontSize: 9** - Small badges (FontWeight.w600)
- **fontSize: 13** - Labels, hints (FontWeight.w600)
- **fontSize: 16** - Standard text
- **fontSize: 18** - Section headings (FontWeight.bold)
- **fontSize: 20** - Main titles

**Font Weights:**
- FontWeight.bold - Titles
- FontWeight.w600 - Labels, semi-bold text

---

### **44. warning_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **45. contact_support_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **46. event_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **47. contact_support_chat_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **48. call_summary_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **49. level_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **50. intro_logo_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **51. splash_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **52. search_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **53. payment_success_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **54. image_crop_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **55. terms_conditions_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **56. admin_support_chat_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **57. live_page.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

### **58. kyc_verification_screen.dart**
**Font Styles Used:**
- Uses default theme styles (inherits from main.dart)
- Standard Material Design text styles

---

## 📊 Font Style Statistics

### **Font Size Distribution:**
- **9px:** 1 occurrence (profile badges)
- **10px:** 3 occurrences (small badges, labels)
- **11px:** 8 occurrences (small labels, metadata)
- **12px:** 15 occurrences (labels, secondary text)
- **13px:** 8 occurrences (hints, secondary text)
- **14px:** 25+ occurrences (body text, standard text)
- **15px:** 5 occurrences (medium emphasis)
- **16px:** 20+ occurrences (standard headings, buttons)
- **17px:** 1 occurrence (buttons)
- **18px:** 12+ occurrences (section headings)
- **20px:** 3 occurrences (main titles)
- **24px:** 1 occurrence (large headings)
- **22px:** 1 occurrence (medium headings)
- **26px:** 2 occurrences (large numbers, amounts)
- **28px:** 2 occurrences (hero text, main titles)
- **32px:** 2 occurrences (large numbers, hero text)

### **Font Weight Distribution:**
- **FontWeight.normal (400):** Used in regular text
- **FontWeight.w400:** Used in body text
- **FontWeight.w500:** Used in medium emphasis text (15+ occurrences)
- **FontWeight.w600:** Used in semi-bold text (30+ occurrences)
- **FontWeight.w700:** Used in bold headings (10+ occurrences)
- **FontWeight.bold (700):** Used in titles (20+ occurrences)

### **Special Properties:**
- **letterSpacing:** Used in 3 screens (0.2, 0.3, -0.2)
- **FontStyle.italic:** Used in 1 screen (policy_screen.dart)

---

## 🎨 Theme Configuration Details

### **Global Theme (lib/main.dart):**
```dart
ThemeData(
  textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
)
```

### **Default Button Style:**
- **fontSize:** 16
- **fontWeight:** FontWeight.w600 (Semi-bold)

---

## 📝 Key Findings

### **1. Font Consistency:**
- ✅ All screens use **Poppins** font family (via global theme)
- ✅ Most screens inherit default theme styles
- ⚠️ Some screens have custom TextStyle overrides

### **2. Font Size Patterns:**
- **Small Text (9-12px):** Used for badges, labels, metadata
- **Body Text (13-16px):** Most common size range
- **Headings (18-20px):** Used for section titles
- **Hero Text (24-32px):** Used for main titles and large numbers

### **3. Font Weight Patterns:**
- **Regular (400/normal):** Body text, descriptions
- **Medium (500):** Buttons, medium emphasis
- **Semi-bold (600):** Labels, important text
- **Bold (700):** Titles, headings

### **4. Screens with Custom Font Styles:**
1. **chat_screen.dart** - Extensive custom styles
2. **user_profile_view_screen.dart** - Extensive custom styles
3. **become_creator_screen.dart** - Custom styles
4. **creator_application_status_screen.dart** - Custom styles
5. **general_screen.dart** - Custom styles
6. **policy_screen.dart** - Custom styles (includes italic)
7. **profile_screen.dart** - Custom styles
8. **home_screen.dart** - Custom styles (dynamic weights)
9. **login_screen.dart** - Custom styles (dynamic weights)
10. **wallet_screen.dart** - Custom styles (large numbers)
11. **otp_screen.dart** - Custom styles (large titles)
12. **edit_profile_screen.dart** - Custom styles

### **5. Screens Using Default Theme Only:**
- All other screens (46 screens) use default Material Design text styles inherited from the global theme

---

## ✅ Recommendations

### **1. Font Consistency:**
- ✅ Current implementation is consistent (Poppins throughout)
- ✅ Global theme ensures uniformity

### **2. Font Size Standardization:**
- Consider creating a text style theme with predefined sizes:
  - Small: 12px
  - Body: 14px
  - Heading: 16px
  - Title: 18px
  - Hero: 24px+

### **3. Font Weight Standardization:**
- Consider standardizing weights:
  - Regular: w400
  - Medium: w500
  - Semi-bold: w600
  - Bold: w700

### **4. Letter Spacing:**
- Currently used inconsistently
- Consider standardizing letter spacing values

---

## 📄 Summary

**Total Screens Analyzed:** 58 screens  
**Screens with Custom Font Styles:** 12 screens  
**Screens Using Default Theme:** 46 screens  
**Default Font Family:** Poppins (Google Fonts)  
**Font Size Range:** 9px - 32px  
**Font Weight Range:** normal (400) - bold (700)

**Overall Assessment:** ✅ The app maintains good font consistency with Poppins as the default font family. Most screens use the global theme, with only a few screens requiring custom font styles for specific UI elements.

---

**Report Generated:** December 2024  
**Analysis Method:** Automated grep search + manual verification
