# 🎨 Login Page Color Codes - Complete Reference

**File:** `lib/screens/login_screen.dart`  
**Date:** Color Analysis Complete

---

## 📱 **Login Container Colors**

### **Main Container (Phone Input Box)**
```dart
Container(
  height: 48,
  decoration: BoxDecoration(
    color: Colors.white,                    // ← Container background
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),  // ← Shadow color
        blurRadius: 12,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  ),
)
```

**Color Codes:**
- **Container Background:** `Colors.white` = `#FFFFFF` = `Color(0xFFFFFFFF)`
- **Shadow Color:** `Colors.black.withValues(alpha: 0.08)` = Black with 8% opacity
- **Border Radius:** `10` pixels (rounded corners)

---

## 🎨 **Complete Color Palette**

### **1. Background Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Screen Background** | `Color(0xFFFFFFFF)` | `#FFFFFF` | (255, 255, 255) | Main screen background |
| **Container Background** | `Colors.white` | `#FFFFFF` | (255, 255, 255) | Phone input container |
| **Scaffold Background** | `Color(0xFFFFFFFF)` | `#FFFFFF` | (255, 255, 255) | Page background |

---

### **2. Primary Action Colors (Pink Theme)**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Primary Button** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Send OTP button |
| **Button Shadow** | `Color(0xFFFF1B7C).withValues(alpha: 0.4)` | `#FF1B7C` (40% opacity) | (255, 27, 124, 0.4) | Button shadow |
| **Success Snackbar** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Success message background |
| **Valid Check Icon** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Check icon when phone valid |
| **Valid Text** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Text when phone number valid |
| **Country Picker Border** | `Color(0xFFFF1B7C).withValues(alpha: 0.2)` | `#FF1B7C` (20% opacity) | Border when focused |
| **Country Picker Focus** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Focused border |

**Note:** This is the **main brand color** - Pink/Magenta used throughout the app.

---

### **3. Text Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Primary Text** | `Colors.black87` | `#212121` | (33, 33, 33) | Title, phone number text |
| **Secondary Text** | `Colors.grey[600]` | `#757575` | (117, 117, 117) | Subtitle, hint text |
| **Tertiary Text** | `Colors.black54` | `#000000` (54% opacity) | (0, 0, 0, 0.54) | Terms & conditions text |
| **Button Text** | `Colors.white` | `#FFFFFF` | (255, 255, 255) | Button text color |
| **Disabled Button** | `Colors.grey[300]` | `#E0E0E0` | (224, 224, 224) | Disabled button background |

---

### **4. Link Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Terms Link** | `Color(0xFF04B104)` | `#04B104` | (4, 177, 4) | Terms & Conditions link |
| **Privacy Link** | `Color(0xFF04B104)` | `#04B104` | (4, 177, 4) | Privacy Policy link |

**Note:** Green color for clickable links (Terms & Privacy Policy).

---

### **5. Border & Divider Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Divider** | `Colors.grey[300]` | `#E0E0E0` | (224, 224, 224) | Separator between country code and phone input |
| **Border (Default)** | `Color(0xFFFF1B7C).withValues(alpha: 0.2)` | `#FF1B7C` (20% opacity) | Country picker border |
| **Border (Focused)** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Country picker focused border |

---

### **6. Icon Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Info Icon (Default)** | `Colors.grey[600]` | `#757575` | (117, 117, 117) | Info icon when phone invalid |
| **Check Icon (Valid)** | `Color(0xFFFF1B7C)` | `#FF1B7C` | (255, 27, 124) | Check icon when phone valid |
| **Dropdown Icon** | `Colors.grey[600]` | `#757575` | (117, 117, 117) | Country selector dropdown |
| **Back Arrow** | `Colors.black87` | `#212121` | (33, 33, 33) | Back button icon |
| **Success Icon** | `Colors.white` | `#FFFFFF` | (255, 255, 255) | Success snackbar icon |

---

### **7. Error Colors**

| Element | Color Code | Hex | RGB | Usage |
|---------|-----------|-----|-----|-------|
| **Error Snackbar** | `Colors.red` | `#F44336` | (244, 67, 54) | Error message background |

---

## 📋 **Color Usage Summary**

### **Login Container (Phone Input Box):**
```dart
// Container
backgroundColor: Colors.white                    // #FFFFFF
borderRadius: 10                                 // Rounded corners
shadow: Colors.black.withValues(alpha: 0.08)   // Subtle shadow

// Text Input
textColor: Colors.black87                       // #212121
hintColor: Colors.grey                          // Grey hint text

// Country Selector
borderColor: Color(0xFFFF1B7C).withValues(alpha: 0.2)  // Pink border (20% opacity)
focusedBorder: Color(0xFFFF1B7C)                // Pink border (full opacity)
dividerColor: Colors.grey[300]                  // #E0E0E0
```

### **Send OTP Button:**
```dart
backgroundColor: Color(0xFFFF1B7C)              // #FF1B7C - Pink
foregroundColor: Colors.white                   // #FFFFFF - White text
shadowColor: Color(0xFFFF1B7C).withValues(alpha: 0.4)  // Pink shadow (40% opacity)
disabledColor: Colors.grey[300]                 // #E0E0E0 - Disabled state
```

---

## 🎯 **Key Theme Colors**

### **Primary Brand Color:**
- **Pink/Magenta:** `#FF1B7C` = `Color(0xFFFF1B7C)`
  - Used for: Buttons, links, accents, valid states
  - RGB: (255, 27, 124)

### **Success/Green:**
- **Green:** `#04B104` = `Color(0xFF04B104)`
  - Used for: Terms & Privacy links
  - RGB: (4, 177, 4)

### **Neutral Colors:**
- **White:** `#FFFFFF` = `Colors.white`
- **Black87:** `#212121` = `Colors.black87` (Primary text)
- **Grey600:** `#757575` = `Colors.grey[600]` (Secondary text)
- **Grey300:** `#E0E0E0` = `Colors.grey[300]` (Borders, dividers)

---

## 📝 **Code References**

### **Line Numbers in `login_screen.dart`:**

- **Line 305:** Screen background - `Color(0xFFFFFFFF)`
- **Line 376:** Container background - `Colors.white`
- **Line 380:** Shadow color - `Colors.black.withValues(alpha: 0.08)`
- **Line 426:** Divider color - `Colors.grey[300]`
- **Line 482, 491, 503:** Valid state color - `Color(0xFFFF1B7C)`
- **Line 526:** Button background - `Color(0xFFFF1B7C)`
- **Line 530:** Button shadow - `Color(0xFFFF1B7C).withValues(alpha: 0.4)`
- **Line 589, 619:** Link colors - `Color(0xFF04B104)`

---

## 🎨 **Color Palette from AppColors Class**

**File:** `lib/theme/app_colors.dart`

```dart
// Primary Colors
static const Color primary = Color(0xFF6C63FF);        // Purple
static const Color secondary = Color(0xFFFF1B7C);     // Pink (used in login)
static const Color secondaryAlt = Color(0xFFFF1744);   // Red-Pink
static const Color secondaryPink = Color(0xFFE91E63);  // Deep Pink

// Success Colors
static const Color success = Color(0xFF04B104);        // Green (used for links)

// Background Colors
static const Color background = Colors.white;          // White
static const Color backgroundCream = Color(0xFFFFFEE0); // Cream (not used in login)

// Text Colors
static const Color textPrimary = Color(0xFF212121);    // Black87
static const Color textSecondary = Color(0xFF757575);  // Grey600
```

---

## ✅ **Summary**

**Login Container Main Colors:**
1. **Background:** White (`#FFFFFF`)
2. **Primary Action:** Pink (`#FF1B7C`)
3. **Text:** Black87 (`#212121`) for primary, Grey600 (`#757575`) for secondary
4. **Links:** Green (`#04B104`)
5. **Shadow:** Black with 8% opacity
6. **Borders:** Grey300 (`#E0E0E0`) for dividers, Pink (`#FF1B7C`) for focused borders

**Theme:** Clean white background with pink accent color for actions and valid states.
