# ✅ Next Steps After Creating Collection

**Status:** Collection `banners` created ✅  
**Next:** Complete setup and test!

---

## Step 1: Create Firestore Index (REQUIRED) ⚠️

**Why:** The code queries banners with multiple `orderBy` clauses, which requires an index.

### How to Create:

1. **Go to Firebase Console**
   - Firestore Database → **Indexes** tab (top menu)

2. **Click "Create Index"**

3. **Fill in:**
   - **Collection ID:** `banners`
   - **Fields to index:**
     - Field: `isActive` | Order: **Ascending** ⬆️
     - Field: `priority` | Order: **Descending** ⬇️
     - Field: `createdAt` | Order: **Descending** ⬇️

4. **Click "Create"**

5. **Wait:** Index building takes 1-2 minutes (you'll see "Building..." status)

**⚠️ Important:** Without this index, banners won't load! The app will show an error.

---

## Step 2: Set Up Security Rules (REQUIRED) 🔒

**Why:** Allows app to read banners and track analytics.

### How to Set Up:

1. **Go to Firebase Console**
   - Firestore Database → **Rules** tab (top menu)

2. **Add this rule** (add it inside your existing `match /databases/{database}/documents` block):

```javascript
// Banner collection rules
match /banners/{bannerId} {
  // Anyone can read active banners
  allow read: if resource.data.isActive == true;
  
  // Allow increment operations for analytics (impressions/clicks)
  allow update: if request.auth != null
               && request.resource.data.diff(resource.data).affectedKeys()
                  .hasOnly(['impressions', 'clicks', 'updatedAt']);
  
  // Only admins can create/update/delete (adjust based on your admin check)
  allow create, delete: if request.auth != null;
}
```

3. **Click "Publish"**

**Note:** If you don't have admin checking set up yet, you can use simpler rules:
```javascript
match /banners/{bannerId} {
  allow read: if resource.data.isActive == true;
  allow write: if request.auth != null;
}
```

---

## Step 3: Test in Your App 🧪

### Quick Test:

1. **Open your Flutter app**
2. **Navigate to Profile Screen**
3. **Check:**
   - ✅ Banner should appear (within 1-2 seconds)
   - ✅ Banner should auto-scroll every 3 seconds
   - ✅ Page indicators (dots) should show at bottom
   - ✅ Clicking banner should navigate to Wallet screen

### If Banner Doesn't Appear:

**Check Flutter Console for errors:**
- Look for Firestore errors
- Check if index is still building
- Verify `isActive` is `true` in Firestore

**Common Issues:**
- ❌ Index not created → Create index (Step 1)
- ❌ Security rules blocking → Update rules (Step 2)
- ❌ `isActive` is false → Set to `true` in Firestore
- ❌ Image URL not loading → Check URL is accessible

---

## Step 4: Verify Analytics Tracking 📊

### Test Impression Tracking:

1. **View banner in app** (go to Profile screen)
2. **Wait 3 seconds** (banner auto-scrolls)
3. **Go back to Firestore Console**
4. **Check document:**
   - `impressions` should be `1` or higher ✅

### Test Click Tracking:

1. **Click on banner** in app
2. **Go back to Firestore Console**
3. **Check document:**
   - `clicks` should be `1` or higher ✅

---

## Step 5: Add More Banners (Optional) 🎨

### Create Additional Banners:

1. **Go to Firestore** → `banners` collection
2. **Click "+ Add document"**
3. **Add fields** (same as first banner)
4. **Change:**
   - `imageUrl` → Your new banner image URL
   - `priority` → Different number (higher = shown first)
   - `actionTarget` → Different screen (e.g., `event_screen`)

### Banner Priority:

- **Higher priority = shown first**
- Example: Priority `10` shows before Priority `5`
- Use priorities to control banner order

---

## ✅ Checklist

- [ ] **Step 1:** Firestore index created
- [ ] **Step 2:** Security rules updated
- [ ] **Step 3:** Banner appears in app
- [ ] **Step 4:** Analytics tracking works
- [ ] **Step 5:** (Optional) More banners added

---

## 🎯 Quick Reference

### Required Fields for Banner:
```
imageUrl: string (required)
actionType: string (required) - "navigate", "external_link", "deep_link", or "none"
actionTarget: string (required if actionType != "none")
priority: number (required) - 1-10
isActive: boolean (required) - true to show
createdAt: timestamp (required)
updatedAt: timestamp (required)
createdBy: string (required)
impressions: number (required) - starts at 0
clicks: number (required) - starts at 0
```

### Optional Fields:
```
title: string (optional)
description: string (optional)
startDate: timestamp (optional) - null = always active
endDate: timestamp (optional) - null = no end date
targetAudience: map (optional) - null = all users
```

---

## 🚀 You're Almost Done!

**After completing Steps 1-3, your dynamic banner system will be fully functional!**

**Time needed:** ~5 minutes

**Need help?** Check `FIRESTORE_SETUP_GUIDE.md` for detailed instructions.
