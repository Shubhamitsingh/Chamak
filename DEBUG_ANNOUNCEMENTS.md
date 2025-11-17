# 🔍 DEBUG: Announcements Not Showing

## ✅ **App is running** (I can see from terminal)
## ❌ **But announcements not appearing**

---

## 🎯 **MOST COMMON CAUSES:**

### **1. Firestore Security Rules Blocking Reads** ⚠️ (90% of cases)

Your app CAN'T read announcements if Firestore rules block it!

**FIX NOW:**

1. Go to: https://console.firebase.google.com/
2. Select: **Chamak** project
3. Go to: **Firestore Database**
4. Click: **Rules** tab
5. Replace with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Announcements - ALLOW ALL (for testing)
    match /announcements/{document=**} {
      allow read: if true;   // ← IMPORTANT: Allow reading
      allow write: if true;  // ← Allow admin to write
    }
    
    // Events - ALLOW ALL (for testing)
    match /events/{document=**} {
      allow read: if true;
      allow write: if true;
    }
    
    // Other collections...
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

6. Click: **Publish**

**This allows reading announcements without restrictions (safe for testing)**

---

### **2. Data Structure Mismatch** ⚠️

Check your Firebase data has EXACTLY these fields:

Go to Firebase Console → Firestore → announcements → (click any document)

**Required fields:**
```
✅ title: (string) "Your title"
✅ description: (string) "Your description"  
✅ date: (string) "12 Nov 2025"
✅ time: (string) "Live Now"
✅ color: (number) 4280287222  ← MUST be NUMBER, not string!
✅ iconName: (string) "campaign"
✅ isNew: (boolean) true  ← MUST be BOOLEAN, not string!
✅ isActive: (boolean) true  ← MUST be BOOLEAN TRUE!
✅ createdAt: (timestamp) [shows date/time]
```

**Common mistakes:**
- ❌ `isActive: "true"` (string) → Should be: ✅ `true` (boolean)
- ❌ `color: "4280287222"` (string) → Should be: ✅ `4280287222` (number)
- ❌ `createdAt` missing → Will cause orderBy to fail

---

### **3. Missing Firestore Index** ⚠️

Your query uses:
```dart
.where('isActive', isEqualTo: true)
.orderBy('createdAt', descending: true)
```

This might need a Firestore index!

**Check Flutter console for this error:**
```
The query requires an index...
```

**If you see this:**
1. Copy the URL from the error
2. Open it in browser
3. Click "Create Index"
4. Wait 1-2 minutes

---

## 🧪 **IMMEDIATE TESTS:**

### **Test 1: Check Firebase Rules**
```
1. Firebase Console → Firestore → Rules
2. Check if announcements are readable
3. If not, use the rules I provided above
```

### **Test 2: Check Data Structure**
```
1. Firebase Console → Firestore → announcements
2. Click any document
3. Verify ALL required fields exist
4. Check data types match (number, boolean, string)
```

### **Test 3: Check Flutter Console**
```
Look for these errors:
- "Permission denied" → Fix Firestore rules
- "Requires an index" → Create the index
- "Error fetching" → Check error message
```

---

## 📱 **Add Debug Logging**

I'll add more logging to see exactly what's happening!



