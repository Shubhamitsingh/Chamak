# Firestore Collection Setup - Step by Step

## ⚠️ Important: Collection Name Must Match Code

The code expects the collection name to be: **`banners`**

If you use a different name, you'll need to update the code in:
- `lib/services/banner_service.dart` (line 17)

---

## Step-by-Step: Create Collection in Firebase Console

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project
3. Click **"Firestore Database"** in the left menu

### Step 2: Create Collection
1. Click the **"Start collection"** button (or **"Create collection"**)
2. **Collection ID:** Enter `banners` (exactly as shown - lowercase)
3. Click **"Next"**

### Step 3: Add First Document (Optional - for testing)
You can skip this and add documents later, but if you want to test:

1. **Document ID:** Click **"Auto-ID"** (or enter custom ID like `banner_001`)
2. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| `imageUrl` | string | `https://via.placeholder.com/800x200/FF1B7C/FFFFFF?text=Test+Banner` |
| `actionType` | string | `navigate` |
| `actionTarget` | string | `wallet_screen` |
| `priority` | number | `5` |
| `isActive` | boolean | `true` |
| `createdAt` | timestamp | Click clock icon → "Set to now" |
| `updatedAt` | timestamp | Click clock icon → "Set to now" |
| `createdBy` | string | `admin` |
| `impressions` | number | `0` |
| `clicks` | number | `0` |

3. Click **"Save"**

### Step 4: Verify Collection Created
- You should see `banners` collection in the left sidebar
- Click on it to see your documents

---

## ✅ Collection Created Successfully!

Now proceed to:
1. Create Firestore indexes (see `QUICK_START_BANNERS.md` step 2)
2. Set up security rules (see `QUICK_START_BANNERS.md` step 3)
3. Add banner documents (see `QUICK_START_BANNERS.md` step 4)

---

## 🔧 If You Want Different Collection Name

If you want to use a different collection name (e.g., `promotional_banners`):

1. **Update Code:**
   - Open `lib/services/banner_service.dart`
   - Find line 17: `.collection('banners')`
   - Change to: `.collection('your_collection_name')`
   - Do the same for line 50 (getActiveBanners method)

2. **Update Firestore:**
   - Create collection with your chosen name
   - Update all references in documentation

**Recommendation:** Stick with `banners` - it's simple and matches the code!

---

## 📸 Visual Guide

```
Firebase Console
├── Firestore Database
    ├── Collections
        └── banners  ← Create this collection
            ├── banner_001  ← Documents go here
            ├── banner_002
            └── banner_003
```

---

## ❓ Troubleshooting

### Collection Not Appearing?
- Refresh the page
- Check you're in the correct Firebase project
- Verify you have permission to create collections

### Can't Create Collection?
- Check Firebase project billing status
- Verify you have Editor/Owner permissions
- Try incognito/private browsing mode

### Collection Name Error?
- Collection names must be lowercase
- No spaces allowed
- Use underscores instead: `banner_images` ✅ (not `Banner Images` ❌)

---

**Next:** After creating the collection, follow `QUICK_START_BANNERS.md` for complete setup!
