# 🔍 Banners Collection Check Guide

**Issue:** Banners collection not showing in Firestore Database

---

## ✅ What to Check

### Step 1: Check if Collection Exists
1. Go to **Firebase Console** → **Firestore Database**
2. Look for collection named: **`banners`** (not `banner`)
3. Do you see it? ✅ YES / ❌ NO

### Step 2: If Collection Doesn't Exist
**The collection will be created automatically when you add the first document!**

You can:
1. **Create it manually** (add first banner document)
2. **Or let admin panel create it** when you save first banner

---

## 📋 How to Create Banners Collection

### Option 1: Create Manually in Firestore Console

1. Go to Firebase Console → Firestore Database
2. Click **"Start collection"** (if no collections) or **"Add collection"**
3. Collection ID: **`banners`** (exactly this name)
4. Click **"Next"**
5. Add first document:
   - Document ID: **Auto-generate** (or custom)
   - Add fields:
     ```
     imageUrl: "https://example.com/banner.jpg" (String)
     title: "Test Banner" (String, optional)
     description: "Test description" (String, optional)
     actionType: "none" (String)
     actionTarget: null (String, optional)
     priority: 5 (Number)
     isActive: true (Boolean) ⚠️ MUST be true
     createdAt: [Timestamp - use "Set current time"]
     updatedAt: [Timestamp - use "Set current time"]
     createdBy: "admin" (String)
     impressions: 0 (Number)
     clicks: 0 (Number)
     ```
6. Click **"Save"**

### Option 2: Let Admin Panel Create It

1. Go to your admin panel → Banners page
2. Fill in banner form:
   - Image: Upload image
   - Title: (optional)
   - Description: (optional)
   - Action Type: Select (none, navigate, url)
   - Action Target: (if navigate/url)
   - Priority: Enter number (1-10)
   - Active: Check ✅ (must be true)
3. Click **"Save Banner"**
4. Check Firestore Console - collection should appear!

---

## ⚠️ CRITICAL: Required Fields

Each banner document MUST have these fields:

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `imageUrl` | String | ✅ Yes | `"https://..."` or Storage URL |
| `actionType` | String | ✅ Yes | `"none"`, `"navigate"`, `"url"` |
| `priority` | Number | ✅ Yes | `5` (1-10) |
| `isActive` | Boolean | ✅ Yes | `true` ⚠️ **MUST be true** |
| `createdAt` | Timestamp | ✅ Yes | Firestore Timestamp |
| `updatedAt` | Timestamp | ✅ Yes | Firestore Timestamp |
| `createdBy` | String | ✅ Yes | `"admin"` |
| `impressions` | Number | ✅ Yes | `0` |
| `clicks` | Number | ✅ Yes | `0` |

**Optional Fields:**
- `title` (String)
- `description` (String)
- `actionTarget` (String - required if actionType is not "none")
- `startDate` (Timestamp)
- `endDate` (Timestamp)
- `targetAudience` (Map/Object)

---

## 🐛 Common Issues

### Issue 1: Collection Name Wrong ❌
**Symptom:** Collection doesn't exist or has wrong name

**Fix:** Collection name must be exactly: **`banners`** (lowercase, plural)
- ❌ `banner` (singular)
- ❌ `Banners` (uppercase)
- ✅ `banners` (correct)

### Issue 2: Collection Empty ⚠️
**Symptom:** Collection exists but is empty

**Fix:** Add at least one banner document with `isActive: true`

### Issue 3: All Banners Inactive ❌
**Symptom:** Collection exists but banners don't show

**Fix:** Check if banners have `isActive: true`. The app queries: `.where('isActive', isEqualTo: true)`

### Issue 4: Missing Required Fields ❌
**Symptom:** Banners exist but app shows error

**Fix:** Ensure all required fields exist (see above)

---

## 📊 Collection Structure Example

### Collection: `banners`

**Document 1:**
```json
{
  "imageUrl": "https://storage.googleapis.com/.../banner1.jpg",
  "title": "Promo Banner 1",
  "description": "Special offer",
  "actionType": "navigate",
  "actionTarget": "wallet_screen",
  "priority": 10,
  "isActive": true,
  "createdAt": Timestamp(...),
  "updatedAt": Timestamp(...),
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

**Document 2:**
```json
{
  "imageUrl": "https://storage.googleapis.com/.../banner2.jpg",
  "actionType": "none",
  "priority": 5,
  "isActive": true,
  "createdAt": Timestamp(...),
  "updatedAt": Timestamp(...),
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

---

## 🔍 Quick Verification

### Check in Firestore Console:
1. ✅ Collection exists: `banners`
2. ✅ Collection has documents
3. ✅ At least one document has `isActive: true`
4. ✅ Documents have all required fields
5. ✅ `imageUrl` field exists and has valid URL

---

## ✅ Test Query

Try this query in Firestore Console:
1. Open Firestore Database
2. Click on `banners` collection
3. Go to "Query" tab
4. Filter:
   - Field: `isActive`
   - Operator: `==`
   - Value: `true`
5. Check if documents appear

If no documents appear → All banners are inactive or missing `isActive` field!

---

## 🎯 Next Steps

1. **Check if collection exists** in Firestore Console
2. **If not exists:** Create it manually or use admin panel
3. **If exists but empty:** Add a banner document
4. **If exists with documents:** Check if `isActive: true`

**The collection should appear automatically when you add the first banner from admin panel!**
