# ✅ Firebase Migration Quick Checklist
## Quick Reference for Migrating to New Firebase Account

**Current Project:** `chamak-39472`  
**New Project:** `chamak-new` (or your choice)

---

## 🚀 QUICK START (5 Steps)

### 1. Create New Firebase Project
- [ ] Go to Firebase Console
- [ ] Create new project
- [ ] Enable Firestore, Storage, Auth

### 2. Export Everything
- [ ] Export Firestore data
- [ ] Export Storage files
- [ ] Export Firebase Auth users
- [ ] Copy Firestore rules ✅ (already have)
- [ ] Copy Storage rules ✅ (already have)

### 3. Import Everything
- [ ] Import Firestore data
- [ ] Import Storage files
- [ ] Import Firebase Auth users
- [ ] Deploy Firestore rules
- [ ] Deploy Storage rules

### 4. Update App
- [ ] Run: `flutterfire configure --project=chamak-new`
- [ ] Verify firebase_options.dart updated
- [ ] Verify google-services.json updated

### 5. Test & Deploy
- [ ] Test authentication
- [ ] Test all features
- [ ] Deploy to Play Store

---

## 📋 DETAILED CHECKLIST

### PREPARATION
- [ ] Backup old project
- [ ] Note current Project ID: `chamak-39472`
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`

### CREATE NEW PROJECT
- [ ] Create project in Firebase Console
- [ ] Enable Firestore Database
- [ ] Enable Firebase Storage
- [ ] Enable Authentication (Phone, Email, Google)
- [ ] Download new service account key

### EXPORT FROM OLD PROJECT
- [ ] Download old service account key
- [ ] Export Firestore data (use script or Console)
- [ ] Export Storage files (use gsutil or script)
- [ ] Export Firebase Auth users (use script)
- [ ] Copy `firestore.rules` ✅
- [ ] Copy `storage.rules` ✅

### IMPORT TO NEW PROJECT
- [ ] Import Firestore data (use script)
- [ ] Import Storage files (use gsutil or script)
- [ ] Import Firebase Auth users (use script)
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Storage rules: `firebase deploy --only storage`

### UPDATE APP CONFIGURATION
- [ ] Run: `flutterfire configure --project=chamak-new --platforms=android,web --yes`
- [ ] Verify `lib/firebase_options.dart` has new project ID
- [ ] Verify `android/app/google-services.json` has new project ID
- [ ] Update service account keys (if using Admin SDK)

### TESTING
- [ ] Test phone authentication
- [ ] Test email authentication
- [ ] Test Google Sign-In
- [ ] Test user profile loading
- [ ] Test Firestore queries
- [ ] Test Storage file access
- [ ] Test all app features

### DEPLOYMENT
- [ ] Build app: `flutter build apk --release`
- [ ] Test on device
- [ ] Deploy to Play Store
- [ ] Monitor Firebase Console
- [ ] Monitor costs
- [ ] Check user feedback

---

## 🔧 QUICK COMMANDS

### Export Firestore
```bash
# Using Firebase Console (easiest)
# Go to Firestore → Export

# Or using script
node export-firestore.js
```

### Export Storage
```bash
# Using gsutil
gsutil -m cp -r gs://chamak-39472.appspot.com/* ./storage-backup/

# Or using script
node export-storage.js
```

### Export Users
```bash
node export-users.js
```

### Import Firestore
```bash
node import-firestore.js
```

### Import Storage
```bash
gsutil -m cp -r ./storage-backup/* gs://chamak-new.appspot.com/
```

### Import Users
```bash
node import-users.js
```

### Configure Flutter App
```bash
flutterfire configure --project=chamak-new --platforms=android,web --yes
```

### Deploy Rules
```bash
firebase use chamak-new
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## 📁 FILES YOU NEED

### Already Have ✅
- `firestore.rules` ✅
- `storage.rules` ✅

### Need to Create
- `export-firestore.js`
- `export-storage.js`
- `export-users.js`
- `import-firestore.js`
- `import-storage.js`
- `import-users.js`
- `old-service-account.json` (download from old project)
- `new-service-account.json` (download from new project)

---

## ⚠️ IMPORTANT NOTES

1. **Keep Same UIDs:** When importing users, keep same UIDs so Firestore data matches
2. **Test Thoroughly:** Test everything before deploying
3. **Keep Old Project:** Don't delete old project for 1 month (backup)
4. **Monitor Costs:** Check new project costs daily
5. **User Communication:** Inform users if they need to re-login

---

## 🎯 ESTIMATED TIME

- **Export:** 1-2 hours
- **Import:** 1-2 hours
- **Configuration:** 30 minutes
- **Testing:** 2-3 hours
- **Total:** 5-8 hours

---

## 📞 QUICK HELP

**Full Guide:** See `COMPLETE_FIREBASE_ACCOUNT_MIGRATION_STEP_BY_STEP.md`

**If Stuck:**
1. Check error messages
2. Review Firebase Console
3. Check export/import logs
4. Ask for help!

---

**Good luck! 🚀**
