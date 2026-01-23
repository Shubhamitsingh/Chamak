# 🔧 Banner Not Showing - Fix Applied

## ✅ Issue Fixed

**Problem:** Banners created in database but not showing in app

**Root Cause:** Missing Firestore composite index for banners query

---

## 🔍 What Was Fixed

### 1. Added Composite Index ✅
Created composite index for banners collection:
- **Collection:** `banners`
- **Fields:**
  - `isActive` (ASCENDING)
  - `priority` (DESCENDING)
  - `createdAt` (DESCENDING)

**File:** `firestore.indexes.json`
**Status:** ✅ Deployed successfully

### 2. Enhanced Error Logging ✅
Added detailed debug logging to `BannerService`:
- Logs when banners are fetched
- Logs parsing errors
- Logs filtering reasons (date range, targeting)
- Logs final banner count

**File:** `lib/services/banner_service.dart`

---

## 📋 Banner Document Requirements

Your banner document MUST have these fields:

### Required Fields:
```json
{
  "imageUrl": "https://storage.googleapis.com/.../banner.jpg",  // ✅ REQUIRED
  "isActive": true,                                              // ✅ REQUIRED (must be true)
  "priority": 5,                                                 // ✅ REQUIRED (number, 1-10)
  "createdAt": Timestamp,                                        // ✅ REQUIRED
  "updatedAt": Timestamp,                                        // ✅ REQUIRED
  "actionType": "none",                                          // ✅ REQUIRED ("none", "navigate", "url")
  "createdBy": "admin",                                          // ✅ REQUIRED
  "impressions": 0,                                             // ✅ REQUIRED (number)
  "clicks": 0                                                   // ✅ REQUIRED (number)
}
```

### Optional Fields:
```json
{
  "title": "Banner Title",                    // Optional
  "description": "Banner description",         // Optional
  "actionTarget": "wallet_screen",            // Optional (required if actionType != "none")
  "startDate": Timestamp,                     // Optional
  "endDate": Timestamp,                        // Optional
  "targetAudience": {                          // Optional
    "minLevel": 1,
    "maxLevel": 100,
    "userTypes": ["all"],
    "countries": []
  }
}
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Banner Not Showing ❌
**Check:**
1. ✅ Collection name is exactly: `banners` (lowercase, plural)
2. ✅ Banner has `isActive: true`
3. ✅ Banner has `priority` field (number)
4. ✅ Banner has `createdAt` field (Timestamp)
5. ✅ Banner has `imageUrl` field (valid URL)

**Solution:** Ensure all required fields exist

### Issue 2: Index Error ⚠️
**Error:** "requires an index"

**Solution:** ✅ Already fixed! Index deployed

### Issue 3: Banner Filtered Out 🔍
**Reasons:**
- `startDate` is in the future
- `endDate` is in the past
- `targetAudience` doesn't match user (level, type, country)

**Solution:** Check debug logs in console for filtering reasons

### Issue 4: Missing Fields ❌
**Error:** "Error parsing banner"

**Solution:** Ensure all required fields exist (see above)

---

## 🔍 Debugging Steps

### Step 1: Check Console Logs
Run the app and check console for:
```
🔍 Fetching banners - userLevel: X, userType: Y, country: Z
📊 Banner query result: N documents found
✅ Parsed banner: [bannerId] - isActive: true, priority: X
🎯 Final banners after filtering: N
```

### Step 2: Verify Banner Document
In Firestore Console:
1. Go to `banners` collection
2. Open your banner document
3. Verify all required fields exist
4. Check `isActive` is `true`
5. Check `priority` is a number
6. Check `createdAt` is a Timestamp

### Step 3: Test Query
In Firestore Console:
1. Go to `banners` collection
2. Click "Query" tab
3. Add filter:
   - Field: `isActive`
   - Operator: `==`
   - Value: `true`
4. Add sort:
   - Field: `priority`
   - Order: `Descending`
5. Add sort:
   - Field: `createdAt`
   - Order: `Descending`
6. Check if your banner appears

---

## ✅ Verification Checklist

- [ ] Banner collection exists: `banners`
- [ ] Banner document has all required fields
- [ ] `isActive: true`
- [ ] `priority` field exists (number)
- [ ] `createdAt` field exists (Timestamp)
- [ ] `imageUrl` field exists (valid URL)
- [ ] Composite index deployed (✅ Done)
- [ ] App restarted after index deployment
- [ ] Check console logs for errors

---

## 🎯 Next Steps

1. **Restart your app** (hot restart or full restart)
2. **Check console logs** for banner fetching
3. **Verify banner document** in Firestore Console
4. **Check debug output** to see why banners might be filtered

---

## 📊 Expected Behavior

After fix:
- ✅ Banners should appear in profile screen
- ✅ Console should show: "📊 Banner query result: X documents found"
- ✅ Console should show: "🎯 Final banners after filtering: X"
- ✅ Banners should auto-scroll every 3 seconds
- ✅ Banners should be clickable

---

## 🔗 Related Files

- `lib/services/banner_service.dart` - Banner fetching logic
- `lib/models/banner_model.dart` - Banner data model
- `lib/screens/profile_screen.dart` - Banner display
- `firestore.indexes.json` - Composite indexes
- `firestore.rules` - Security rules

---

**Status:** ✅ Index deployed, enhanced logging added
**Next:** Restart app and check console logs
