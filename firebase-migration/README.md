# Firebase Migration Export Script

## 🚀 Quick Start

### Step 1: Install Node.js
Download from: https://nodejs.org/ (LTS version)

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Download Service Account Key
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save as `old-service-account.json` in this folder

### Step 4: Run Export
```bash
npm run export
```

## ✅ What This Does

- Exports all Firestore collections
- Works even with "Quota exceeded" error
- Uses Admin SDK (higher limits)
- Saves to `exports/` folder

## 📁 Output

All exported collections will be in `exports/` folder as JSON files:
- `users.json`
- `chats.json`
- `orders.json`
- etc.

## ⚠️ Important

- Keep `old-service-account.json` secure!
- Don't commit it to git
- Delete after migration complete

## 🆘 Troubleshooting

**Error: Cannot find module 'firebase-admin'**
- Run: `npm install`

**Error: Cannot find 'old-service-account.json'**
- Download service account key from Firebase Console

**Error: Quota exceeded**
- Script will retry automatically
- If still fails, upgrade to Blaze Plan

## 📝 Next Steps

After export completes:
1. Follow `COMPLETE_FIREBASE_ACCOUNT_MIGRATION_STEP_BY_STEP.md`
2. Import data to new project
3. Update app configuration
