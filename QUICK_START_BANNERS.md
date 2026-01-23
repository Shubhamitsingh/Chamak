# 🚀 Quick Start - Dynamic Banners (5 Minutes)

**Get your dynamic banner system running in 5 minutes!**

---

## ⚡ Super Quick Setup

### 1. Create Collection (1 minute)
- Firebase Console → Firestore Database
- Click **"Create collection"**
- Name: `banners` (must be exactly "banners" - code expects this name)
- Click **"Next"** → **"Save"**

### 2. Create Index (1 minute)
- Firestore → **Indexes** tab
- Click **"Create Index"**
- Collection: `banners`
- Fields:
  - `isActive` (Ascending)
  - `priority` (Descending)  
  - `createdAt` (Descending)
- Click **"Create"**

### 3. Add Security Rule (1 minute)
- Firestore → **Rules** tab
- Add this rule:
```javascript
match /banners/{bannerId} {
  allow read: if resource.data.isActive == true;
  allow write: if request.auth != null;
}
```
- Click **"Publish"**

### 4. Create First Banner (2 minutes)
- Firestore → `banners` collection
- Click **"Add document"**
- Add fields:

| Field | Value |
|-------|-------|
| `imageUrl` | `https://via.placeholder.com/800x200/FF1B7C/FFFFFF?text=Test+Banner` |
| `actionType` | `navigate` |
| `actionTarget` | `wallet_screen` |
| `priority` | `5` |
| `isActive` | `true` |
| `createdAt` | (Click clock → "Set to now") |
| `updatedAt` | (Click clock → "Set to now") |
| `createdBy` | `admin` |
| `impressions` | `0` |
| `clicks` | `0` |

- Click **"Save"**

### 5. Test! ✅
- Open your app
- Go to Profile screen
- Banner should appear!

---

## 🎯 That's It!

Your dynamic banner system is now live! 

**Next:** Upload real banner images and create more banners.

**Need Help?** See `FIRESTORE_SETUP_GUIDE.md` for detailed instructions.
