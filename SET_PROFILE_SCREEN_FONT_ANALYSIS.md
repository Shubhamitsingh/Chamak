# 📝 Set Profile Screen - Font Size & Format Analysis

**Date:** February 4, 2026  
**Screen:** `lib/screens/set_profile_screen.dart`  
**Status:** 🔍 **ANALYSIS COMPLETE**

---

## 📊 **CURRENT FONT SIZE DISTRIBUTION**

| Font Size | Count | Usage | Standard? | Status |
|-----------|-------|-------|-----------|--------|
| **22px** | 1 | Screen title | ⚠️ Non-standard | ❌ Should be 24px |
| **18px** | 2 | Bottom sheet title, language list initial | ✅ Standard | ✅ OK |
| **17px** | 2 | Input fields, language field | ⚠️ Non-standard | ❌ Should be 16px |
| **15px** | 2 | Gender buttons (Male/Female) | ⚠️ Non-standard | ❌ Should be 14px or 16px |
| **14px** | 4 | Subtitle, hint text, label, gender label | ✅ Standard | ✅ OK |
| **13px** | 4 | Terms text, links | ⚠️ Non-standard | ❌ Should be 12px or 14px |
| **12px** | 2 | Error messages, character counter | ✅ Standard | ✅ OK |

**Total:** 17 text style instances

---

## 📊 **CURRENT FONT WEIGHT DISTRIBUTION**

| Font Weight | Count | Usage | Standard? | Status |
|-------------|-------|-------|-----------|--------|
| **FontWeight.bold** | 2 | Screen title, bottom sheet title | ⚠️ Should be w700 | ❌ Fix |
| **FontWeight.w600** | 4 | Gender buttons, terms links | ✅ Standard | ✅ OK |
| **FontWeight.w500** | 5 | Input fields, labels, character counter | ✅ Standard | ✅ OK |
| **FontWeight.w400** | 1 | Subtitle | ✅ Standard | ✅ OK |
| **FontWeight.normal** | 1 | Language list (unselected) | ⚠️ Should be w400 | ❌ Fix |
| **Not specified** | 4 | Language list title, error text | ⚠️ Missing | ❌ Fix |

**Total:** 17 text style instances

---

## ⚠️ **ISSUES FOUND**

### **1. Non-Standard Font Sizes** 🔴

#### **Issue 1: Screen Title (22px)**
- **Line 294:** `fontSize: 22`
- **Problem:** Should be 24px (fontSizeXXLarge) for screen titles
- **Impact:** Inconsistent with app design system
- **Fix:** Change to `fontSize: 24`

#### **Issue 2: Input Fields (17px)**
- **Line 346:** Nickname input field
- **Line 589:** Language selection field
- **Problem:** Should be 16px (fontSizeLarge) for input fields
- **Impact:** Slightly larger than standard
- **Fix:** Change to `fontSize: 16`

#### **Issue 3: Gender Buttons (15px)**
- **Line 481:** Male button text
- **Line 532:** Female button text
- **Problem:** Should be 14px (fontSizeMedium) or 16px (fontSizeLarge)
- **Impact:** Non-standard size
- **Fix:** Change to `fontSize: 14` or `fontSize: 16`

#### **Issue 4: Terms Text (13px)**
- **Line 670, 687, 698, 713:** Terms and Privacy Policy text
- **Problem:** Should be 12px (fontSizeSmall) or 14px (fontSizeMedium)
- **Impact:** Non-standard size
- **Fix:** Change to `fontSize: 12` (for small text) or `fontSize: 14` (for body text)

---

### **2. Font Weight Issues** 🟡

#### **Issue 1: FontWeight.bold Usage**
- **Line 295:** Screen title
- **Line 125:** Bottom sheet title
- **Problem:** Should use `FontWeight.w700` instead of `FontWeight.bold`
- **Impact:** Inconsistent with app standards
- **Fix:** Replace with `FontWeight.w700`

#### **Issue 2: FontWeight.normal Usage**
- **Line 163:** Language list (unselected)
- **Problem:** Should use `FontWeight.w400` instead of `FontWeight.normal`
- **Impact:** Inconsistent with app standards
- **Fix:** Replace with `FontWeight.w400`

#### **Issue 3: Missing Font Weights**
- **Line 162:** Language list title (no weight specified)
- **Line 379:** Error message text (no weight specified)
- **Problem:** Should have explicit font weight
- **Impact:** Relies on default, inconsistent
- **Fix:** Add `fontWeight: FontWeight.w400`

---

## ✅ **STANDARD FONT SIZES (App Design System)**

Based on app standards:
- **24px** (fontSizeXXLarge) - Screen titles
- **18px** (fontSizeXLarge) - AppBar titles, section headers
- **16px** (fontSizeLarge) - Input fields, section headers
- **14px** (fontSizeMedium) - Body text, buttons, labels
- **12px** (fontSizeSmall) - Small text, labels, captions

---

## ✅ **STANDARD FONT WEIGHTS**

- **FontWeight.w700** (bold) - Titles, emphasized text
- **FontWeight.w600** (semiBold) - Buttons, headings
- **FontWeight.w500** (medium) - Subtitles, secondary text
- **FontWeight.w400** (normal) - Body text

**Note:** Prefer numeric weights (w400, w500, w600, w700) over named weights (normal, bold).

---

## 🔧 **RECOMMENDED FIXES**

### **Priority 1: Critical (Consistency)**

1. **Fix Screen Title (22px → 24px)**
   ```dart
   // Line 294
   fontSize: 24,  // Instead of 22
   ```

2. **Fix Input Fields (17px → 16px)**
   ```dart
   // Lines 346, 589
   fontSize: 16,  // Instead of 17
   ```

3. **Fix Gender Buttons (15px → 14px)**
   ```dart
   // Lines 481, 532
   fontSize: 14,  // Instead of 15
   ```

4. **Fix Terms Text (13px → 12px)**
   ```dart
   // Lines 670, 687, 698, 713
   fontSize: 12,  // Instead of 13
   ```

### **Priority 2: Font Weight Standardization**

5. **Replace FontWeight.bold → FontWeight.w700**
   ```dart
   // Lines 295, 125
   fontWeight: FontWeight.w700,  // Instead of FontWeight.bold
   ```

6. **Replace FontWeight.normal → FontWeight.w400**
   ```dart
   // Line 163
   fontWeight: FontWeight.w400,  // Instead of FontWeight.normal
   ```

7. **Add Missing Font Weights**
   ```dart
   // Line 162 (language list title)
   fontWeight: FontWeight.w400,
   
   // Line 379 (error message)
   fontWeight: FontWeight.w400,
   ```

---

## 📋 **SUMMARY**

### **Issues Found:**
- ❌ **4 non-standard font sizes** (22px, 17px, 15px, 13px)
- ❌ **3 font weight issues** (bold, normal, missing weights)
- **Total:** 7 issues to fix

### **Impact:**
- ⚠️ **Medium** - Affects consistency and design system compliance
- ⚠️ **Low** - Screen is functional but not perfectly aligned with standards

### **Recommendation:**
- ✅ **Fix all issues** for production-ready consistency
- ✅ **Use standard font sizes** from app design system
- ✅ **Use numeric font weights** (w400, w500, w600, w700)

---

## ✅ **VERIFICATION CHECKLIST**

After fixes:
- [ ] All font sizes are standard (12, 14, 16, 18, 24)
- [ ] All font weights use numeric values (w400, w500, w600, w700)
- [ ] No `FontWeight.bold` or `FontWeight.normal`
- [ ] All text styles have explicit font weights
- [ ] Consistent with other screens in the app

---

**Status:** ⚠️ **NEEDS FIXES** - 7 issues found  
**Priority:** Medium  
**Effort:** ~15 minutes to fix all issues
