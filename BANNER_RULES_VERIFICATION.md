# Banner Rules Verification - Complete Checklist

**Status:** Verifying all rules related to banner functionality

---

## ✅ Required Rules Checklist

### 1. Firestore Security Rules

#### Rule 1: Read Access (App Users)
```javascript
match /banners/{bannerId} {
  allow read: if resource.data.isActive == true
              && (resource.data.startDate == null || 
                  resource.data.startDate <= request.time)
              && (resource.data.endDate == null || 
                  resource.data.endDate >= request.time);
}
```
**Purpose:** Allows app users to read active banners within date range

#### Rule 2: Update Access (Analytics Tracking)
```javascript
allow update: if request.auth != null
             && request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['impressions', 'clicks', 'updatedAt']);
```
**Purpose:** Allows authenticated users to update only analytics fields

#### Rule 3: Create/Delete Access (Admin Panel)
```javascript
allow create, delete: if request.auth != null;
```
**Purpose:** Allows authenticated admins to create/delete banners

**OR (More Secure - Admin Only):**
```javascript
allow create, delete: if request.auth != null
                    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
```
**Purpose:** Only users with `isAdmin: true` can create/delete

---

### 2. Firebase Storage Rules

#### Rule 1: Read Access (Public Images)
```javascript
match /b/{bucket}/o {
  match /banners/{bannerId} {
    allow read: if true;
  }
}
```
**Purpose:** Anyone can view banner images (public URLs)

#### Rule 2: Write Access (Admin Upload)
```javascript
allow write: if request.auth != null;
```
**Purpose:** Authenticated users can upload images

**OR (More Secure - Admin Only):**
```javascript
allow write: if request.auth != null
           && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
```
**Purpose:** Only admins can upload images

---

### 3. Firestore Indexes Required

#### Index 1: Banner Query Index (REQUIRED)
```
Collection: banners
Fields:
  - isActive (Ascending)
  - priority (Descending)
  - createdAt (Descending)
```
**Purpose:** Required for banner list query with filtering and sorting

#### Index 2: Optional - Date Filtering
```
Collection: banners
Fields:
  - isActive (Ascending)
  - startDate (Ascending)
  - endDate (Ascending)
```
**Purpose:** Optimize date range queries (if using startDate/endDate filtering)

---

## 🔍 Verification Steps

### Step 1: Check Firestore Rules
1. Go to Firebase Console → Firestore Database → Rules
2. Look for `match /banners/{bannerId}` section
3. Verify all 3 rules exist (read, update, create/delete)

### Step 2: Check Storage Rules
1. Go to Firebase Console → Storage → Rules
2. Look for `match /banners/{bannerId}` section
3. Verify read and write rules exist

### Step 3: Check Firestore Indexes
1. Go to Firebase Console → Firestore Database → Indexes
2. Look for index with:
   - Collection: `banners`
   - Fields: `isActive`, `priority`, `createdAt`
3. Verify status is "Enabled" (not "Building")

### Step 4: Test Rules
1. **Test Read:** App should load banners ✅
2. **Test Update:** Analytics should track ✅
3. **Test Create:** Admin panel should create banners ✅
4. **Test Delete:** Admin panel should delete banners ✅
5. **Test Upload:** Admin panel should upload images ✅

---

## 📋 Complete Rules Template

### Firestore Rules (Complete)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Your existing rules...
    
    // ===== BANNER COLLECTION RULES =====
    match /banners/{bannerId} {
      // Rule 1: App users can read active banners
      allow read: if resource.data.isActive == true
                  && (resource.data.startDate == null || 
                      resource.data.startDate <= request.time)
                  && (resource.data.endDate == null || 
                      resource.data.endDate >= request.time);
      
      // Rule 2: Allow analytics tracking (impressions/clicks)
      allow update: if request.auth != null
                   && request.resource.data.diff(resource.data).affectedKeys()
                      .hasOnly(['impressions', 'clicks', 'updatedAt']);
      
      // Rule 3: Admin can create/delete banners
      // Option A: Any authenticated user (for testing)
      allow create, delete: if request.auth != null;
      
      // Option B: Admin only (for production - uncomment if using)
      // allow create, delete: if request.auth != null
      //                     && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### Storage Rules (Complete)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Your existing rules...
    
    // ===== BANNER IMAGES RULES =====
    match /banners/{bannerId} {
      // Anyone can read banner images (public URLs)
      allow read: if true;
      
      // Authenticated users can upload
      // Option A: Any authenticated user (for testing)
      allow write: if request.auth != null;
      
      // Option B: Admin only (for production - uncomment if using)
      // allow write: if request.auth != null
      //            && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

---

## ⚠️ Common Rule Mistakes

### ❌ Mistake 1: Too Restrictive Read Rule
```javascript
// BAD - Blocks app from reading banners
allow read: if false;
```

### ❌ Mistake 2: Missing Analytics Update Rule
```javascript
// BAD - Can't track impressions/clicks
// Missing: allow update rule
```

### ❌ Mistake 3: Wrong Update Fields
```javascript
// BAD - Allows updating any field
allow update: if request.auth != null;
// Should only allow: impressions, clicks, updatedAt
```

### ❌ Mistake 4: Missing Index
```javascript
// BAD - Query will fail without index
// Need index: isActive + priority + createdAt
```

---

## ✅ Correct Rules Summary

### For App (Mobile):
- ✅ Read active banners
- ✅ Update analytics (impressions/clicks)

### For Admin Panel:
- ✅ Read all banners
- ✅ Create banners
- ✅ Update banners (all fields)
- ✅ Delete banners
- ✅ Upload images

---

## 🧪 Testing Checklist

### Test 1: App Can Read Banners
- [ ] Open app → Profile screen
- [ ] Banner appears ✅
- [ ] If not → Check read rule

### Test 2: Analytics Tracking Works
- [ ] View banner → Check Firestore
- [ ] `impressions` increments ✅
- [ ] Click banner → Check Firestore
- [ ] `clicks` increments ✅
- [ ] If not → Check update rule

### Test 3: Admin Can Create Banner
- [ ] Admin panel → Create banner
- [ ] Banner saves successfully ✅
- [ ] If not → Check create rule

### Test 4: Admin Can Upload Image
- [ ] Admin panel → Upload image
- [ ] Image uploads successfully ✅
- [ ] If not → Check storage write rule

### Test 5: Admin Can Delete Banner
- [ ] Admin panel → Delete banner
- [ ] Banner deletes successfully ✅
- [ ] If not → Check delete rule

---

## 🔧 Quick Fixes

### If Banners Don't Load in App:
1. Check: `allow read: if resource.data.isActive == true`
2. Verify: Banner has `isActive: true` in Firestore
3. Check: Index is created and enabled

### If Analytics Don't Track:
1. Check: Update rule allows `impressions` and `clicks`
2. Verify: User is authenticated
3. Check: Fields exist in document

### If Admin Can't Create:
1. Check: Create rule requires authentication
2. Verify: Admin is logged in
3. Check: Admin has `isAdmin: true` (if using admin check)

### If Image Upload Fails:
1. Check: Storage write rule allows upload
2. Verify: User is authenticated
3. Check: File size < 5MB
4. Check: File type is image (jpg, png, webp)

---

## 📊 Rules Status Check

**Copy this checklist and verify:**

- [ ] Firestore rules file exists
- [ ] `match /banners/{bannerId}` section exists
- [ ] Read rule allows `isActive == true`
- [ ] Update rule allows only analytics fields
- [ ] Create rule requires authentication
- [ ] Delete rule requires authentication
- [ ] Storage rules file exists
- [ ] `match /banners/{bannerId}` section exists
- [ ] Storage read rule allows public access
- [ ] Storage write rule requires authentication
- [ ] Firestore index created (isActive + priority + createdAt)
- [ ] Index status is "Enabled"

---

## 🎯 Summary

**Required Rules:**
1. ✅ Firestore: Read (app users)
2. ✅ Firestore: Update (analytics)
3. ✅ Firestore: Create/Delete (admin)
4. ✅ Storage: Read (public)
5. ✅ Storage: Write (admin)
6. ✅ Index: isActive + priority + createdAt

**All rules verified?** Your banner system is ready! 🎉

---

**Next:** Test in app and admin panel to confirm everything works!
