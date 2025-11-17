# 🖼️ How to Add Your Custom Logo

## ✅ Setup Complete!

The app is now ready to use your custom logo. Follow these simple steps:

---

## 📁 **Step 1: Add Your Logo File**

### Where to place your logo:
```
chamak/
└── assets/
    └── images/
        └── logo.png  ← Put your logo here!
```

### Full path:
```
C:\Users\Shubham Singh\Desktop\chamak\assets\images\logo.png
```

---

## 🎨 **Step 2: Prepare Your Logo**

### Recommended specifications:

| Property | Value | Notes |
|----------|-------|-------|
| **Format** | PNG | Transparent background recommended |
| **Size** | 512x512 px | Or any square size |
| **Aspect** | 1:1 (Square) | Works best |
| **Background** | Transparent | Looks professional |
| **File size** | < 500 KB | Keeps app small |

### File name options:
- `logo.png` ← **Default (already configured)**
- `logo.jpg` (if you use this, update code)
- `logo.webp` (modern format)

---

## 🚀 **Step 3: Copy Your Logo**

### Using File Explorer:

1. **Open** File Explorer
2. **Navigate to:** `C:\Users\Shubham Singh\Desktop\chamak\assets\images\`
3. **Copy** your logo file here
4. **Rename** it to `logo.png` (or keep reading for custom names)

### Using Command Prompt:
```bash
# Copy your logo from Downloads (example)
copy "%USERPROFILE%\Downloads\my_logo.png" "C:\Users\Shubham Singh\Desktop\chamak\assets\images\logo.png"
```

---

## 🔄 **Step 4: Run the App**

```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
flutter run
```

Your logo will appear on:
- ✅ Splash Screen (140x140)
- ✅ Login Screen (100x100)
- ✅ Automatically scaled and positioned

---

## 🎯 **Using a Different File Name?**

If your logo is named something else (like `my_logo.png` or `logo.jpg`):

### Update in `lib/screens/splash_screen.dart`:
```dart
Image.asset(
  'assets/images/my_logo.png',  // Change this
  ...
)
```

### Update in `lib/screens/login_screen.dart`:
```dart
Image.asset(
  'assets/images/my_logo.png',  // Change this
  ...
)
```

---

## 🖼️ **Logo Display Settings**

### Current settings:

#### Splash Screen:
```dart
Size: 140x140
Border radius: 35 (rounded corners)
Background: White
Shadow: Yes
Fit: Cover (fills container)
```

#### Login Screen:
```dart
Size: 100x100
Border radius: 25 (rounded corners)
Background: White
Shadow: Yes
Fit: Cover (fills container)
```

---

## 🎨 **Customizing Logo Display**

### Want a circular logo?

In both files, change:
```dart
// From:
borderRadius: BorderRadius.circular(35),

// To:
shape: BoxShape.circle,
```

### Want no background?

Remove the white background:
```dart
decoration: BoxDecoration(
  // color: Colors.white,  ← Comment this out
  borderRadius: BorderRadius.circular(35),
  ...
)
```

### Want a different size?

Change the width and height:
```dart
// Splash screen - make it bigger
width: 180,
height: 180,

// Login screen - make it smaller
width: 80,
height: 80,
```

---

## 🔍 **What if Logo Doesn't Show?**

### Troubleshooting checklist:

1. **Check file exists:**
   ```bash
   dir "C:\Users\Shubham Singh\Desktop\chamak\assets\images\logo.png"
   ```

2. **Check file name is correct:**
   - Must be exactly `logo.png`
   - Case matters on some systems

3. **Run `flutter pub get`:**
   ```bash
   flutter pub get
   ```

4. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check pubspec.yaml:**
   ```yaml
   assets:
     - assets/images/
   ```

### Fallback:
Don't worry! If the logo file isn't found, the app will show a purple play icon instead (automatic fallback).

---

## 📱 **Multiple Logo Versions**

Want different logos for different screens?

### Add multiple logos:
```
assets/images/
├── logo.png          ← Main logo
├── logo_splash.png   ← Splash screen logo
└── logo_small.png    ← Login screen logo
```

### Update code:
```dart
// Splash screen
'assets/images/logo_splash.png'

// Login screen
'assets/images/logo_small.png'
```

---

## 🎨 **Logo Examples**

### For a live streaming app, consider:

1. **Icon-based logo**
   - Play button
   - Camera icon
   - Wave/signal icon

2. **Text-based logo**
   - "LiveVibe" text as image
   - Stylized typography

3. **Combination**
   - Icon + text
   - Brand mark

### Design tips:
- ✅ Simple and recognizable
- ✅ Works well at small sizes
- ✅ Looks good on white background
- ✅ High contrast
- ✅ Professional appearance

---

## 📋 **Quick Checklist**

- [ ] Logo file prepared (PNG, square, < 500 KB)
- [ ] Logo copied to `assets/images/logo.png`
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] Logo appears on Splash Screen
- [ ] Logo appears on Login Screen

---

## 🎉 **Example: Adding Your Logo**

### Step-by-step example:

```bash
# 1. Navigate to project
cd "C:\Users\Shubham Singh\Desktop\chamak"

# 2. Copy your logo (adjust path to your logo location)
copy "C:\Users\Shubham Singh\Downloads\my_awesome_logo.png" "assets\images\logo.png"

# 3. Update dependencies
flutter pub get

# 4. Run the app
flutter run

# Done! Your logo is now showing! 🎉
```

---

## 💡 **Pro Tips**

1. **Use PNG with transparency** for best results
2. **Square aspect ratio** (1:1) works best
3. **High resolution** (512x512 or larger) scales better
4. **Test on device** to see how it looks in real app
5. **Keep file small** to reduce app size

---

## 🔧 **Advanced: Different Logo for Light/Dark**

Want different logos for light/dark mode?

```dart
Image.asset(
  Theme.of(context).brightness == Brightness.dark
    ? 'assets/images/logo_dark.png'
    : 'assets/images/logo_light.png',
  ...
)
```

---

## 📞 **Need Help?**

### Common issues:

**Logo not showing:**
- Check file path is correct
- Run `flutter pub get`
- Restart app

**Logo looks stretched:**
- Use square image (1:1 ratio)
- Check `fit: BoxFit.cover`

**Logo too small/large:**
- Adjust `width` and `height` values
- Use higher resolution source image

---

## ✅ **Summary**

### What's been set up:
✅ Assets folder created  
✅ pubspec.yaml configured  
✅ Splash screen updated to use logo  
✅ Login screen updated to use logo  
✅ Automatic fallback if logo missing  
✅ Rounded corners with shadow  

### What you need to do:
1. Copy your logo to: `assets/images/logo.png`
2. Run: `flutter pub get`
3. Run: `flutter run`

**That's it!** Your custom logo will appear throughout the app! 🎉

---

**Created:** October 27, 2025  
**Location:** `assets/images/logo.png`  
**Format:** PNG recommended  
**Size:** 512x512 px recommended  

**Ready to add your logo!** 🖼️





