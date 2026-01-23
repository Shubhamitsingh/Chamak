# Security Rules Verification Guide

## ✅ Correct Security Rules for Banners

Copy and paste this into your Firestore Rules tab:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Your existing rules here...
    
    // ===== BANNER COLLECTION RULES =====
    match /banners/{bannerId} {
      // Anyone can read active banners
      allow read: if resource.data.isActive == true
                  && (resource.data.startDate == null || 
                      resource.data.startDate <= request.time)
                  && (resource.data.endDate == null || 
                      resource.data.endDate >= request.time);
      
      // Allow increment operations for analytics (impressions/clicks)
      allow update: if request.auth != null
                   && request.resource.data.diff(resource.data).affectedKeys()
                      .hasOnly(['impressions', 'clicks', 'updatedAt']);
      
      // Only authenticated users can create/delete (adjust based on your needs)
      allow create, delete: if request.auth != null;
    }
  }
}
```

---

## 🔍 How to Verify Your Rules

### Step 1: Check Rules Tab
1. Go to **Firebase Console** → **Firestore Database** → **Rules** tab
2. Look for `match /banners/{bannerId}` section

### Step 2: Verify Each Rule

#### ✅ Rule 1: Read Access
**Should have:**
```javascript
allow read: if resource.data.isActive == true
```

**What it does:**
- Allows anyone to read banners where `isActive = true`
- Blocks reading inactive banners

#### ✅ Rule 2: Update Access (Analytics)
**Should have:**
```javascript
allow update: if request.auth != null
             && request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['impressions', 'clicks', 'updatedAt']);
```

**What it does:**
- Allows authenticated users to update only `impressions`, `clicks`, and `updatedAt`
- Prevents changing other fields (security)

#### ✅ Rule 3: Create/Delete Access
**Should have:**
```javascript
allow create, delete: if request.auth != null;
```

**What it does:**
- Allows authenticated users to create/delete banners
- You can restrict this to admins only if needed

---

## 🧪 Test Your Rules

### Test 1: Read Active Banner
1. In your app, go to Profile screen
2. Banner should load ✅
3. If it doesn't load → Rules might be blocking

### Test 2: Analytics Tracking
1. View banner in app
2. Check Firestore → `impressions` should increment ✅
3. Click banner → `clicks` should increment ✅
4. If not incrementing → Update rule might be wrong

### Test 3: Create Banner (Admin)
1. Try creating a banner from app (if you have admin panel)
2. Should work if authenticated ✅
3. If blocked → Create rule might need admin check

---

## ⚠️ Common Rule Mistakes

### ❌ Wrong: Too Restrictive
```javascript
// BAD - Blocks everything
match /banners/{bannerId} {
  allow read, write: if false;  // ❌ Nothing works!
}
```

### ❌ Wrong: Too Permissive
```javascript
// BAD - Anyone can modify anything
match /banners/{bannerId} {
  allow read, write: if true;  // ❌ Security risk!
}
```

### ✅ Correct: Balanced
```javascript
// GOOD - Read for active banners, write for analytics only
match /banners/{bannerId} {
  allow read: if resource.data.isActive == true;
  allow update: if request.auth != null
               && request.resource.data.diff(resource.data).affectedKeys()
                  .hasOnly(['impressions', 'clicks', 'updatedAt']);
  allow create, delete: if request.auth != null;
}
```

---

## 🔧 Simplified Rules (For Testing)

If you want simpler rules for testing (less secure):

```javascript
match /banners/{bannerId} {
  // Allow read for active banners
  allow read: if resource.data.isActive == true;
  
  // Allow all writes (for testing only - not recommended for production)
  allow write: if request.auth != null;
}
```

**⚠️ Warning:** This allows authenticated users to modify any field. Use only for testing!

---

## 📋 Verification Checklist

- [ ] Rules tab opened in Firebase Console
- [ ] `match /banners/{bannerId}` section exists
- [ ] Read rule allows `isActive == true`
- [ ] Update rule allows only `impressions`, `clicks`, `updatedAt`
- [ ] Create/Delete rule requires authentication
- [ ] Rules published (clicked "Publish")
- [ ] Banner loads in app ✅
- [ ] Analytics tracking works ✅

---

## 🐛 Troubleshooting

### Banner Not Loading?
- Check: `allow read: if resource.data.isActive == true`
- Verify: Banner document has `isActive: true`
- Test: Try reading banner directly in Firestore console

### Analytics Not Tracking?
- Check: Update rule allows `impressions` and `clicks`
- Verify: User is authenticated (`request.auth != null`)
- Test: Try manually updating `impressions` field in Firestore

### Can't Create Banners?
- Check: Create rule requires authentication
- Verify: User is logged in
- Test: Try creating banner from authenticated session

---

## ✅ Quick Test

**After setting rules, test immediately:**

1. **Open app** → Profile screen
2. **Banner appears?** ✅ Rules working!
3. **Banner doesn't appear?** ❌ Check rules again

---

**Need Help?** Share your current rules and I'll verify them!
