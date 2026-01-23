# Firestore Setup Guide - Dynamic Banners

**Quick Setup:** Follow these steps to get your dynamic banner system running in 15 minutes!

---

## Step 1: Create Firestore Collection

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **"Create collection"**
5. Collection ID: `banners`
6. Click **"Next"**

---

## Step 2: Create Firestore Indexes

**Why:** Firestore needs indexes for queries with multiple `orderBy` clauses.

### Create Index:

1. Go to **Firestore Database** → **Indexes** tab
2. Click **"Create Index"**
3. Fill in:
   - **Collection ID:** `banners`
   - **Fields to index:**
     - Field: `isActive` | Order: **Ascending**
     - Field: `priority` | Order: **Descending**
     - Field: `createdAt` | Order: **Descending**
4. Click **"Create"**
5. Wait for index to build (usually 1-2 minutes)

**Note:** You can also let Firestore create it automatically when you run the first query (it will show a link in the console).

---

## Step 3: Set Up Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Add this rule for banners:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // Banner collection rules
    match /banners/{bannerId} {
      // Anyone can read active banners (within date range)
      allow read: if resource.data.isActive == true
                  && (resource.data.startDate == null || 
                      resource.data.startDate <= request.time)
                  && (resource.data.endDate == null || 
                      resource.data.endDate >= request.time);
      
      // Only admins can create/update/delete
      allow create, update, delete: if request.auth != null
                                    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      
      // Allow increment operations for analytics (impressions/clicks)
      allow update: if request.auth != null
                   && request.resource.data.diff(resource.data).affectedKeys()
                      .hasOnly(['impressions', 'clicks', 'updatedAt']);
    }
  }
}
```

3. Click **"Publish"**

**Note:** Adjust the admin check based on your user structure. If you don't have `isAdmin` field, you can:
- Remove the admin check temporarily for testing
- Or use a different field to identify admins

---

## Step 4: Create Your First Banner

### Option A: Manual Creation (Firebase Console)

1. Go to **Firestore Database** → **banners** collection
2. Click **"Add document"**
3. Document ID: `banner_001` (or auto-generate)
4. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `imageUrl` | string | `https://your-image-url.com/banner1.jpg` |
| `title` | string | `Welcome Banner` |
| `description` | string | `Discover amazing features` |
| `actionType` | string | `navigate` |
| `actionTarget` | string | `wallet_screen` |
| `priority` | number | `5` |
| `isActive` | boolean | `true` |
| `startDate` | timestamp | (leave empty or set future date) |
| `endDate` | timestamp | (leave empty or set future date) |
| `targetAudience` | map | (leave empty or see below) |
| `createdAt` | timestamp | (click clock icon → "Set to now") |
| `updatedAt` | timestamp | (click clock icon → "Set to now") |
| `createdBy` | string | `admin` |
| `impressions` | number | `0` |
| `clicks` | number | `0` |

5. Click **"Save"**

### Option B: Using Sample Data

Use the provided `firestore_banners_setup.json` file:
1. The JSON structure is provided for reference
2. Copy fields manually or use Firebase Admin SDK to import

---

## Step 5: Upload Banner Images

### Option A: Firebase Storage (Recommended)

1. Go to **Firebase Console** → **Storage**
2. Create folder: `banners/`
3. Upload your banner images (recommended size: 800x200px or 1200x300px)
4. Click on uploaded image → **"Get download URL"**
5. Copy the URL
6. Use this URL in the `imageUrl` field

**Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /banners/{bannerId} {
      // Anyone can read banner images
      allow read: if true;
      
      // Only admins can upload
      allow write: if request.auth != null
                   && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### Option B: External CDN/Hosting

- Upload images to your CDN or hosting service
- Use the public URL in `imageUrl` field
- Ensure URLs are HTTPS and publicly accessible

---

## Step 6: Test the System

1. **Open your app** → Go to Profile screen
2. **Check banner appears** (should show within 1-2 seconds)
3. **Test auto-scroll** (banners should change every 3 seconds)
4. **Test page indicators** (dots should show at bottom)
5. **Test click** (tap banner → should navigate)
6. **Check Firestore** → Verify `impressions` and `clicks` are incrementing

---

## Field Reference Guide

### Required Fields:
- `imageUrl` (string) - Public URL of banner image
- `actionType` (string) - `"navigate"`, `"external_link"`, `"deep_link"`, or `"none"`
- `priority` (number) - 1-10 (higher = shown first)
- `isActive` (boolean) - `true` to show, `false` to hide
- `createdAt` (timestamp) - Creation date
- `updatedAt` (timestamp) - Last update date
- `createdBy` (string) - Admin user ID
- `impressions` (number) - View count (starts at 0)
- `clicks` (number) - Click count (starts at 0)

### Optional Fields:
- `title` (string) - Banner title (for admin reference)
- `description` (string) - Banner description (for admin reference)
- `actionTarget` (string) - Screen name or URL (required if actionType != "none")
- `startDate` (timestamp) - When banner should start showing (null = immediate)
- `endDate` (timestamp) - When banner should stop showing (null = no end)
- `targetAudience` (map) - User targeting (null = all users)

### Target Audience Structure:
```json
{
  "minLevel": 1,
  "maxLevel": 100,
  "userTypes": ["all"],  // or ["host"], ["audience"], ["host", "audience"]
  "countries": []  // Empty = all countries, or ["IN", "US", "GB"]
}
```

---

## Common Banner Examples

### Example 1: Simple Welcome Banner (No Action)
```json
{
  "imageUrl": "https://storage.googleapis.com/your-app/banners/welcome.jpg",
  "actionType": "none",
  "priority": 5,
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "targetAudience": null,
  "createdAt": "2024-12-01T10:00:00Z",
  "updatedAt": "2024-12-01T10:00:00Z",
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

### Example 2: Wallet Promotion (Navigate to Wallet)
```json
{
  "imageUrl": "https://storage.googleapis.com/your-app/banners/wallet-promo.jpg",
  "title": "Wallet Promotion",
  "actionType": "navigate",
  "actionTarget": "wallet_screen",
  "priority": 8,
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "targetAudience": null,
  "createdAt": "2024-12-01T10:00:00Z",
  "updatedAt": "2024-12-01T10:00:00Z",
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

### Example 3: Time-Limited Campaign
```json
{
  "imageUrl": "https://storage.googleapis.com/your-app/banners/christmas.jpg",
  "title": "Christmas Special",
  "actionType": "navigate",
  "actionTarget": "event_screen",
  "priority": 10,
  "isActive": true,
  "startDate": "2024-12-20T00:00:00Z",
  "endDate": "2024-12-31T23:59:59Z",
  "targetAudience": null,
  "createdAt": "2024-12-01T10:00:00Z",
  "updatedAt": "2024-12-01T10:00:00Z",
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

### Example 4: VIP Users Only (Level 10+)
```json
{
  "imageUrl": "https://storage.googleapis.com/your-app/banners/vip.jpg",
  "title": "VIP Promotion",
  "actionType": "navigate",
  "actionTarget": "event_screen",
  "priority": 9,
  "isActive": true,
  "startDate": null,
  "endDate": null,
  "targetAudience": {
    "minLevel": 10,
    "maxLevel": 100,
    "userTypes": ["all"],
    "countries": []
  },
  "createdAt": "2024-12-01T10:00:00Z",
  "updatedAt": "2024-12-01T10:00:00Z",
  "createdBy": "admin",
  "impressions": 0,
  "clicks": 0
}
```

---

## Troubleshooting

### ❌ Banners Not Showing

**Check:**
1. ✅ `isActive` = `true`
2. ✅ Date range is valid (startDate ≤ now ≤ endDate)
3. ✅ Target audience matches user
4. ✅ Image URL is accessible (test in browser)
5. ✅ Firestore index is created
6. ✅ Security rules allow read

**Debug:**
- Check Flutter console for errors
- Verify banner document exists in Firestore
- Test image URL in browser

### ❌ Click Tracking Not Working

**Check:**
1. ✅ Security rules allow update
2. ✅ Banner document exists
3. ✅ Network connection is active

**Debug:**
- Check Firestore console for update errors
- Verify `clicks` field exists in document

### ❌ Banners Not Updating in Real-Time

**Check:**
1. ✅ StreamBuilder is active
2. ✅ Network connection is stable
3. ✅ Firestore rules allow read

**Debug:**
- Check Flutter console for stream errors
- Verify Firestore connection

---

## Quick Test Checklist

- [ ] Firestore collection `banners` created
- [ ] Firestore index created (isActive, priority, createdAt)
- [ ] Security rules updated
- [ ] At least one banner document created
- [ ] Banner image uploaded and URL copied
- [ ] `imageUrl` field set correctly
- [ ] `isActive` = `true`
- [ ] App tested - banner appears
- [ ] Auto-scroll works (3 seconds)
- [ ] Page indicators show
- [ ] Click navigation works
- [ ] Analytics tracking works (check Firestore)

---

## Next Steps After Setup

1. **Create More Banners:** Add promotional banners for different campaigns
2. **Monitor Analytics:** Check `impressions` and `clicks` regularly
3. **A/B Testing:** Create multiple banners with different priorities
4. **Schedule Campaigns:** Use `startDate` and `endDate` for time-limited promotions
5. **Target Users:** Use `targetAudience` for personalized banners

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all steps were completed correctly
3. Check Flutter console for error messages
4. Verify Firestore console for data structure

---

**Setup Time:** ~15 minutes  
**Status:** Ready to use! 🎉
