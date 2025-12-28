# 📍 How to Get SHA Fingerprints from Play Console

## Current Location:
You're on: **App integrity** page ✅

## Steps to Get SHA Fingerprints:

### **Option 1: From App Integrity Page**

1. **On the current page (App integrity):**
   - Look for **"App signing"** section or link
   - It might be in the left sidebar under **"Test and release"**
   - Or scroll down on the current page

2. **Click on "App signing"** or **"App signing key certificate"**

### **Option 2: Navigate from Sidebar**

1. **In the left sidebar**, under **"Test and release"** section:
   - Look for **"App signing"** or **"Setup"** → **"App signing"**
   - Click on it

2. **Alternative path:**
   - Go to **"Release"** → **"Setup"** → **"App signing"**

### **Option 3: Direct Navigation**

1. **Click on "Setup"** in the sidebar (under Test and release)
2. Then click **"App signing"**

## What You'll See:

Once you're on the **App signing** page, you'll see:

```
┌─────────────────────────────────────┐
│ App signing key certificate         │
│                                     │
│ SHA-1 certificate fingerprint:      │
│ XX:XX:XX:XX:XX:XX:XX:XX:XX:XX...   │
│                                     │
│ SHA-256 certificate fingerprint:    │
│ YY:YY:YY:YY:YY:YY:YY:YY:YY:YY...   │
└─────────────────────────────────────┘
```

## Quick Navigation Path:

```
Play Console
  └─ Test and release (sidebar)
      └─ Setup
          └─ App signing ← CLICK HERE
              └─ App signing key certificate
                  └─ Copy SHA-1 and SHA-256
```

## Alternative Paths:

1. **Release** → **Setup** → **App signing**
2. **App integrity** → Look for "App signing" link
3. **Advanced settings** → **App signing**

## What to Copy:

Copy BOTH fingerprints:
- ✅ **SHA-1 certificate fingerprint** (long string with colons)
- ✅ **SHA-256 certificate fingerprint** (long string with colons)

## After Getting SHA Fingerprints:

1. Go to **Firebase Console**
2. **Project Settings** → **Your apps**
3. Find your Android app (`com.chamakz.app`)
4. Click **"Add fingerprint"**
5. Paste SHA-1 and SHA-256
6. **Save**
7. Download updated `google-services.json`
8. Replace in your project

---

**Look for "App signing" in the sidebar under "Test and release" → "Setup"** 📍









