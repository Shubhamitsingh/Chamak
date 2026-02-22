# 🔄 Complete Firebase Account Migration Guide
## Step-by-Step: Migrate to New Firebase Account with ALL Data, Users & Rules

**Current Project:** `chamak-39472`  
**Goal:** Create new Firebase account, migrate everything  
**What You'll Keep:** ✅ All data ✅ All users ✅ All rules ✅ Everything!

---

## 📋 TABLE OF CONTENTS

1. [Pre-Migration Checklist](#1-pre-migration-checklist)
2. [Step 1: Create New Firebase Project](#step-1-create-new-firebase-project)
3. [Step 2: Export Firestore Data](#step-2-export-firestore-data)
4. [Step 3: Migrate Firestore Rules](#step-3-migrate-firestore-rules)
5. [Step 4: Migrate Storage Rules](#step-4-migrate-storage-rules)
6. [Step 5: Migrate Storage Files](#step-5-migrate-storage-files)
7. [Step 6: Migrate Firebase Auth Users](#step-6-migrate-firebase-auth-users)
8. [Step 7: Configure New Project](#step-7-configure-new-project)
9. [Step 8: Update App Configuration](#step-8-update-app-configuration)
10. [Step 9: Import Data to New Project](#step-9-import-data-to-new-project)
11. [Step 10: Test Everything](#step-10-test-everything)
12. [Step 11: Deploy Updated App](#step-11-deploy-updated-app)
13. [Troubleshooting](#troubleshooting)

---

## 1. PRE-MIGRATION CHECKLIST

### Before You Start:

- [ ] Backup current Firebase project
- [ ] Note down current project ID: `chamak-39472`
- [ ] Note down current project number: `228866341171`
- [ ] Have access to both old and new Firebase accounts
- [ ] Have Node.js installed (for migration scripts)
- [ ] Have Firebase CLI installed
- [ ] Have FlutterFire CLI installed

### What You'll Need:

1. **Old Firebase Project Access**
   - Project ID: `chamak-39472`
   - Service account key (for admin access)

2. **New Firebase Project** (we'll create it)
   - New project name
   - New project ID

3. **Migration Scripts** (we'll create them)

---

## STEP 1: CREATE NEW FIREBASE PROJECT

### 1.1: Create New Project

1. **Go to:** https://console.firebase.google.com/
2. **Click:** "Add project" or "Create a project"
3. **Enter Project Name:** `chamak-new` (or any name you want)
4. **Click:** Continue
5. **Google Analytics:** Choose (can disable if you want)
6. **Click:** Create project
7. **Wait:** 1-2 minutes for project creation

### 1.2: Note Down New Project Details

**After creation, note down:**
- **New Project ID:** `chamak-new-xxxxx` (will be shown)
- **New Project Number:** (will be shown)

**Example:**
```
New Project ID: chamak-new-abc123
New Project Number: 987654321000
```

### 1.3: Enable Required Services

**Go to new project → Enable these:**

1. **Firestore Database**
   - Click "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode" (we'll add rules later)
   - Select location (same as old project if possible)
   - Click "Enable"

2. **Authentication**
   - Click "Authentication"
   - Click "Get started"
   - Enable "Phone" (if using phone auth)
   - Enable "Email/Password" (if using email auth)
   - Enable "Google" (if using Google Sign-In)

3. **Storage**
   - Click "Storage"
   - Click "Get started"
   - Start in test mode (we'll add rules later)
   - Select location (same as old project)
   - Click "Next" → "Done"

4. **Cloud Functions** (if using)
   - Click "Functions"
   - Click "Get started"
   - Follow setup instructions

---

## STEP 2: EXPORT FIRESTORE DATA

### 2.1: Install Firebase Admin SDK

**Create migration folder:**

```bash
mkdir firebase-migration
cd firebase-migration
npm init -y
npm install firebase-admin
```

### 2.2: Get Service Account Keys

**For OLD Project:**

1. Go to: Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save as: `old-service-account.json`
4. Place in `firebase-migration/` folder

**For NEW Project:**

1. Go to: New Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save as: `new-service-account.json`
4. Place in `firebase-migration/` folder

### 2.3: Create Export Script

**File:** `firebase-migration/export-data.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize OLD Firebase project
const oldServiceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(oldServiceAccount),
  databaseURL: `https://${oldServiceAccount.project_id}.firebaseio.com`
}, 'old');

const oldDb = admin.firestore();

// List of all collections to export
const collections = [
  'users',
  'live_streams',
  'chats',
  'orders',
  'payments',
  'gifts',
  'supportTickets',
  'supportChats',
  'announcements',
  'events',
  'earnings',
  'wallets',
  'feedback',
  'withdrawal_requests',
  'callTransactions',
  'callRequests',
  'host_applications',
  'approvedHosts',
  'banners',
  'settings',
  'share_tracking',
  'reward_transactions',
  'team_messages',
  'reports',
  'transactions',
  'notificationRequests',
  'resellerChats',
  'admins',
  'adminActions',
  // Add any other collections you have
];

async function exportCollection(collectionName) {
  console.log(`📤 Exporting ${collectionName}...`);
  
  const snapshot = await oldDb.collection(collectionName).get();
  const data = [];
  
  snapshot.forEach(doc => {
    const docData = doc.data();
    
    // Convert Firestore Timestamps to JSON-serializable format
    const processedData = processTimestamps(docData);
    
    data.push({
      id: doc.id,
      data: processedData
    });
  });
  
  // Save to file
  const fileName = `${collectionName}.json`;
  fs.writeFileSync(fileName, JSON.stringify(data, null, 2));
  
  console.log(`✅ Exported ${data.length} documents from ${collectionName}`);
  return data.length;
}

function processTimestamps(obj) {
  if (obj === null || obj === undefined) return obj;
  
  if (obj.constructor.name === 'Timestamp') {
    return {
      _timestamp: true,
      seconds: obj.seconds,
      nanoseconds: obj.nanoseconds
    };
  }
  
  if (Array.isArray(obj)) {
    return obj.map(item => processTimestamps(item));
  }
  
  if (typeof obj === 'object') {
    const processed = {};
    for (const key in obj) {
      processed[key] = processTimestamps(obj[key]);
    }
    return processed;
  }
  
  return obj;
}

async function exportSubcollections(collectionName, parentDocId) {
  const subcollections = [
    'transactions',
    'coinTransactions',
    'following',
    'followers',
    'seenAnnouncements',
    'dismissedAnnouncements',
    'seenEvents',
    'payment_methods',
    'tickets',
    'messages',
    'chat',
    'viewers',
  ];
  
  const subcollectionData = {};
  
  for (const subName of subcollections) {
    try {
      const subSnapshot = await oldDb
        .collection(collectionName)
        .doc(parentDocId)
        .collection(subName)
        .get();
      
      if (!subSnapshot.empty) {
        subcollectionData[subName] = [];
        subSnapshot.forEach(doc => {
          subcollectionData[subName].push({
            id: doc.id,
            data: processTimestamps(doc.data())
          });
        });
      }
    } catch (e) {
      // Subcollection might not exist, skip
    }
  }
  
  return subcollectionData;
}

async function exportAll() {
  console.log('🚀 Starting Firestore data export...\n');
  
  let totalDocs = 0;
  
  for (const collection of collections) {
    try {
      const count = await exportCollection(collection);
      totalDocs += count;
      
      // Export subcollections for users
      if (collection === 'users') {
        const snapshot = await oldDb.collection(collection).get();
        for (const doc of snapshot.docs) {
          const subcollections = await exportSubcollections(collection, doc.id);
          if (Object.keys(subcollections).length > 0) {
            const subFileName = `${collection}_${doc.id}_subcollections.json`;
            fs.writeFileSync(subFileName, JSON.stringify(subcollections, null, 2));
            console.log(`✅ Exported subcollections for user ${doc.id}`);
          }
        }
      }
      
      // Export subcollections for chats
      if (collection === 'chats') {
        const snapshot = await oldDb.collection(collection).get();
        for (const doc of snapshot.docs) {
          const subcollections = await exportSubcollections(collection, doc.id);
          if (Object.keys(subcollections).length > 0) {
            const subFileName = `${collection}_${doc.id}_subcollections.json`;
            fs.writeFileSync(subFileName, JSON.stringify(subcollections, null, 2));
            console.log(`✅ Exported subcollections for chat ${doc.id}`);
          }
        }
      }
      
      // Export subcollections for live_streams
      if (collection === 'live_streams') {
        const snapshot = await oldDb.collection(collection).get();
        for (const doc of snapshot.docs) {
          const subcollections = await exportSubcollections(collection, doc.id);
          if (Object.keys(subcollections).length > 0) {
            const subFileName = `${collection}_${doc.id}_subcollections.json`;
            fs.writeFileSync(subFileName, JSON.stringify(subcollections, null, 2));
            console.log(`✅ Exported subcollections for stream ${doc.id}`);
          }
        }
      }
    } catch (e) {
      console.error(`❌ Error exporting ${collection}:`, e.message);
    }
  }
  
  console.log(`\n✅ Export complete! Total documents: ${totalDocs}`);
  console.log(`📁 Files saved in: ${process.cwd()}`);
}

exportAll().catch(console.error);
```

**Run export:**

```bash
node export-data.js
```

**This will create:** JSON files for each collection in `firebase-migration/` folder

---

## STEP 3: MIGRATE FIRESTORE RULES

### 3.1: Copy Rules File

**Your current rules are in:** `firestore.rules`

**Copy to new project:**

1. **Go to:** New Firebase Console → Firestore Database → Rules
2. **Copy contents** from `firestore.rules`
3. **Paste** into new project rules editor
4. **Click:** "Publish"

**OR use Firebase CLI:**

```bash
# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy rules to new project
firebase deploy --only firestore:rules --project chamak-new-xxxxx
```

---

## STEP 4: MIGRATE STORAGE RULES

### 4.1: Copy Storage Rules

**Your current rules are in:** `storage.rules`

**Copy to new project:**

1. **Go to:** New Firebase Console → Storage → Rules
2. **Copy contents** from `storage.rules`
3. **Paste** into new project rules editor
4. **Click:** "Publish"

**OR use Firebase CLI:**

```bash
firebase deploy --only storage:rules --project chamak-new-xxxxx
```

---

## STEP 5: MIGRATE STORAGE FILES

### 5.1: Create Storage Migration Script

**File:** `firebase-migration/migrate-storage.js`

```javascript
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');

// Initialize OLD project
const oldServiceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(oldServiceAccount),
  storageBucket: `${oldServiceAccount.project_id}.appspot.com`
}, 'old');

// Initialize NEW project
const newServiceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(newServiceAccount),
  storageBucket: `${newServiceAccount.project_id}.appspot.com`
}, 'new');

const oldStorage = admin.storage('old');
const newStorage = admin.storage('new');

async function migrateStorage() {
  console.log('🚀 Starting Storage migration...\n');
  
  const [oldFiles] = await oldStorage.bucket().getFiles();
  
  console.log(`📁 Found ${oldFiles.length} files to migrate\n`);
  
  let migrated = 0;
  let failed = 0;
  
  for (const file of oldFiles) {
    try {
      console.log(`📤 Migrating: ${file.name}...`);
      
      // Download from old storage
      const [data] = await file.download();
      
      // Get metadata
      const [metadata] = await file.getMetadata();
      
      // Upload to new storage
      const newFile = newStorage.bucket().file(file.name);
      await newFile.save(data, {
        metadata: {
          contentType: metadata.contentType,
          metadata: metadata.metadata || {}
        }
      });
      
      // Make public if original was public
      if (file.isPublic()) {
        await newFile.makePublic();
      }
      
      migrated++;
      console.log(`✅ Migrated: ${file.name}\n`);
    } catch (e) {
      failed++;
      console.error(`❌ Failed to migrate ${file.name}:`, e.message);
    }
  }
  
  console.log(`\n✅ Migration complete!`);
  console.log(`✅ Migrated: ${migrated}`);
  console.log(`❌ Failed: ${failed}`);
}

migrateStorage().catch(console.error);
```

**Run:**

```bash
npm install @google-cloud/storage
node migrate-storage.js
```

---

## STEP 6: MIGRATE FIREBASE AUTH USERS

### 6.1: Export Users

**File:** `firebase-migration/export-users.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

const oldServiceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(oldServiceAccount)
}, 'old');

const oldAuth = admin.auth('old');

async function exportUsers() {
  console.log('🚀 Exporting Firebase Auth users...\n');
  
  const users = [];
  let nextPageToken;
  
  do {
    const result = await oldAuth.listUsers(1000, nextPageToken);
    
    result.users.forEach(user => {
      users.push({
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        disabled: user.disabled,
        metadata: {
          creationTime: user.metadata.creationTime,
          lastSignInTime: user.metadata.lastSignInTime
        },
        customClaims: user.customClaims || {}
      });
    });
    
    nextPageToken = result.pageToken;
    console.log(`📤 Exported ${users.length} users...`);
  } while (nextPageToken);
  
  fs.writeFileSync('users.json', JSON.stringify(users, null, 2));
  console.log(`\n✅ Exported ${users.length} users to users.json`);
}

exportUsers().catch(console.error);
```

**Run:**

```bash
node export-users.js
```

### 6.2: Import Users to New Project

**File:** `firebase-migration/import-users.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

const newServiceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(newServiceAccount)
}, 'new');

const newAuth = admin.auth('new');

async function importUsers() {
  console.log('🚀 Importing Firebase Auth users...\n');
  
  const users = JSON.parse(fs.readFileSync('users.json', 'utf8'));
  
  let imported = 0;
  let failed = 0;
  
  for (const userData of users) {
    try {
      await newAuth.createUser({
        uid: userData.uid,
        email: userData.email,
        phoneNumber: userData.phoneNumber,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        emailVerified: userData.emailVerified,
        disabled: userData.disabled
      });
      
      // Set custom claims if any
      if (Object.keys(userData.customClaims).length > 0) {
        await newAuth.setCustomUserClaims(userData.uid, userData.customClaims);
      }
      
      imported++;
      if (imported % 100 === 0) {
        console.log(`✅ Imported ${imported} users...`);
      }
    } catch (e) {
      failed++;
      console.error(`❌ Failed to import user ${userData.uid}:`, e.message);
    }
  }
  
  console.log(`\n✅ Import complete!`);
  console.log(`✅ Imported: ${imported}`);
  console.log(`❌ Failed: ${failed}`);
}

importUsers().catch(console.error);
```

**Run:**

```bash
node import-users.js
```

**Note:** This will import users, but they'll need to login again (passwords can't be migrated)

---

## STEP 7: CONFIGURE NEW PROJECT

### 7.1: Create Android App

1. **Go to:** New Firebase Console → Project Settings → Your apps
2. **Click:** Add app → Android
3. **Package name:** `com.chamak.app` (same as current)
4. **App nickname:** Chamak Android
5. **Click:** Register app
6. **Download:** `google-services.json`
7. **Save:** We'll use this later

### 7.2: Create Web App (if needed)

1. **Click:** Add app → Web
2. **App nickname:** Chamak Web
3. **Click:** Register app
4. **Copy:** Firebase config (we'll use this)

### 7.3: Add SHA Fingerprints

**Get SHA fingerprints:**

```bash
# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (if you have)
keytool -list -v -keystore android/app/release.keystore -alias release
```

**Add to Firebase:**

1. Go to: New Firebase Console → Project Settings → Your apps → Android app
2. Click "Add fingerprint"
3. Add SHA-1 and SHA-256 fingerprints

---

## STEP 8: UPDATE APP CONFIGURATION

### 8.1: Update FlutterFire Configuration

**Run FlutterFire CLI:**

```bash
# Remove old configuration
flutterfire configure --project=chamak-new-xxxxx --platforms=android,web --yes
```

**This will:**
- Update `lib/firebase_options.dart`
- Update `android/app/google-services.json`

### 8.2: Update .firebaserc

**File:** `.firebaserc`

```json
{
  "projects": {
    "default": "chamak-new-xxxxx"
  }
}
```

### 8.3: Update firebase.json (if exists)

**File:** `firebase.json`

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions"
  }
}
```

---

## STEP 9: IMPORT DATA TO NEW PROJECT

### 9.1: Create Import Script

**File:** `firebase-migration/import-data.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const newServiceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(newServiceAccount),
  databaseURL: `https://${newServiceAccount.project_id}.firebaseio.com`
}, 'new');

const newDb = admin.firestore();

function restoreTimestamps(obj) {
  if (obj === null || obj === undefined) return obj;
  
  if (obj._timestamp === true) {
    return admin.firestore.Timestamp.fromMillis(
      obj.seconds * 1000 + obj.nanoseconds / 1000000
    );
  }
  
  if (Array.isArray(obj)) {
    return obj.map(item => restoreTimestamps(item));
  }
  
  if (typeof obj === 'object') {
    const restored = {};
    for (const key in obj) {
      restored[key] = restoreTimestamps(obj[key]);
    }
    return restored;
  }
  
  return obj;
}

async function importCollection(collectionName) {
  console.log(`📥 Importing ${collectionName}...`);
  
  const fileName = `${collectionName}.json`;
  if (!fs.existsSync(fileName)) {
    console.log(`⚠️  File ${fileName} not found, skipping...`);
    return 0;
  }
  
  const data = JSON.parse(fs.readFileSync(fileName, 'utf8'));
  
  let imported = 0;
  const batch = newDb.batch();
  let batchCount = 0;
  
  for (const doc of data) {
    const docRef = newDb.collection(collectionName).doc(doc.id);
    const restoredData = restoreTimestamps(doc.data);
    batch.set(docRef, restoredData);
    batchCount++;
    
    if (batchCount === 500) {
      await batch.commit();
      imported += batchCount;
      batchCount = 0;
      console.log(`  ✅ Imported ${imported}/${data.length}...`);
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
    imported += batchCount;
  }
  
  console.log(`✅ Imported ${imported} documents to ${collectionName}`);
  return imported;
}

async function importSubcollections(collectionName, parentDocId) {
  const fileName = `${collectionName}_${parentDocId}_subcollections.json`;
  if (!fs.existsSync(fileName)) {
    return;
  }
  
  const subcollections = JSON.parse(fs.readFileSync(fileName, 'utf8'));
  
  for (const [subName, docs] of Object.entries(subcollections)) {
    for (const doc of docs) {
      const docRef = newDb
        .collection(collectionName)
        .doc(parentDocId)
        .collection(subName)
        .doc(doc.id);
      
      const restoredData = restoreTimestamps(doc.data);
      await docRef.set(restoredData);
    }
  }
  
  console.log(`✅ Imported subcollections for ${collectionName}/${parentDocId}`);
}

async function importAll() {
  console.log('🚀 Starting Firestore data import...\n');
  
  const collections = [
    'users',
    'live_streams',
    'chats',
    'orders',
    'payments',
    'gifts',
    'supportTickets',
    'supportChats',
    'announcements',
    'events',
    'earnings',
    'wallets',
    'feedback',
    'withdrawal_requests',
    'callTransactions',
    'callRequests',
    'host_applications',
    'approvedHosts',
    'banners',
    'settings',
    'share_tracking',
    'reward_transactions',
    'team_messages',
    'reports',
    'transactions',
    'notificationRequests',
    'resellerChats',
    'admins',
    'adminActions',
  ];
  
  let totalImported = 0;
  
  for (const collection of collections) {
    try {
      const count = await importCollection(collection);
      totalImported += count;
      
      // Import subcollections
      if (collection === 'users' || collection === 'chats' || collection === 'live_streams') {
        const mainData = JSON.parse(fs.readFileSync(`${collection}.json`, 'utf8'));
        for (const doc of mainData) {
          await importSubcollections(collection, doc.id);
        }
      }
    } catch (e) {
      console.error(`❌ Error importing ${collection}:`, e.message);
    }
  }
  
  console.log(`\n✅ Import complete! Total documents: ${totalImported}`);
}

importAll().catch(console.error);
```

**Run:**

```bash
node import-data.js
```

---

## STEP 10: TEST EVERYTHING

### 10.1: Test Checklist

- [ ] **Firestore Data:**
  - [ ] Users collection exists
  - [ ] All collections migrated
  - [ ] Subcollections migrated
  - [ ] Data looks correct

- [ ] **Storage Files:**
  - [ ] Profile pictures accessible
  - [ ] Cover photos accessible
  - [ ] Chat images accessible
  - [ ] All files migrated

- [ ] **Firebase Auth:**
  - [ ] Users can login
  - [ ] Phone auth works
  - [ ] Email auth works
  - [ ] Google Sign-In works

- [ ] **Rules:**
  - [ ] Firestore rules working
  - [ ] Storage rules working
  - [ ] Permissions correct

- [ ] **App:**
  - [ ] App connects to new Firebase
  - [ ] Login works
  - [ ] Data loads correctly
  - [ ] All features work

### 10.2: Test App Locally

```bash
flutter clean
flutter pub get
flutter run
```

**Test:**
1. Login with phone number
2. Check user profile loads
3. Check data displays correctly
4. Test all features

---

## STEP 11: DEPLOY UPDATED APP

### 11.1: Build App

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### 11.2: Test on Test Devices

- [ ] Install on test device
- [ ] Test login
- [ ] Test all features
- [ ] Verify data loads

### 11.3: Deploy to Play Store

1. **Update version** in `pubspec.yaml`
2. **Build release:**
   ```bash
   flutter build appbundle --release
   ```
3. **Upload to Play Store**
4. **Monitor** for errors

---

## TROUBLESHOOTING

### Issue 1: Users Can't Login

**Problem:** Users imported but can't login

**Solution:**
- Users need to login again (passwords can't be migrated)
- They'll use same phone number/email
- Firebase will create new session

### Issue 2: Data Missing

**Problem:** Some collections not migrated

**Solution:**
- Check export logs
- Re-run export for missing collections
- Re-run import

### Issue 3: Storage Files Not Loading

**Problem:** Old URLs point to old storage

**Solution:**
- Update URLs in Firestore after migration
- Or use migration script to update URLs

### Issue 4: Rules Not Working

**Problem:** Rules deployed but not working

**Solution:**
- Check rules syntax
- Verify rules published
- Check Firebase Console → Rules tab

### Issue 5: App Can't Connect

**Problem:** App still connecting to old Firebase

**Solution:**
- Verify `firebase_options.dart` updated
- Verify `google-services.json` updated
- Clean rebuild: `flutter clean && flutter pub get`

---

## ✅ FINAL CHECKLIST

### Before Going Live:

- [ ] All data migrated
- [ ] All users migrated
- [ ] All rules migrated
- [ ] Storage files migrated
- [ ] App tested locally
- [ ] App tested on devices
- [ ] All features working
- [ ] No errors in console
- [ ] Firebase Console shows correct data
- [ ] Ready to deploy

---

## 📊 MIGRATION SUMMARY

### What Was Migrated:

✅ **Firestore Data:**
- All collections
- All documents
- All subcollections
- All timestamps preserved

✅ **Firebase Auth:**
- All users
- User metadata
- Custom claims

✅ **Storage:**
- All files
- All metadata
- Public/private settings

✅ **Rules:**
- Firestore rules
- Storage rules

✅ **Configuration:**
- App configuration
- SHA fingerprints
- Service accounts

---

## 🎯 NEXT STEPS AFTER MIGRATION

1. **Monitor New Project:**
   - Check Firebase Console daily
   - Monitor costs
   - Check for errors

2. **Add Rate Limiting:**
   - Follow `ACTION_PLAN_NOW.md`
   - Add OTP rate limiting
   - Prevent high costs

3. **Update Documentation:**
   - Update project ID references
   - Update team members
   - Update deployment scripts

4. **Keep Old Project:**
   - Don't delete immediately
   - Keep for 30 days as backup
   - Then delete if everything works

---

## 📝 IMPORTANT NOTES

### User Experience:

- ✅ Users can login with same credentials
- ✅ All data preserved
- ✅ No data loss
- ✅ Seamless transition

### Costs:

- ✅ New project starts fresh
- ✅ No old billing
- ✅ Monitor new costs
- ✅ Add rate limiting to prevent high costs

### Backup:

- ✅ Keep old project for 30 days
- ✅ Export backups before deleting
- ✅ Verify everything works first

---

## 🚀 QUICK REFERENCE

### Migration Commands:

```bash
# Export data
node export-data.js

# Export users
node export-users.js

# Migrate storage
node migrate-storage.js

# Import users
node import-users.js

# Import data
node import-data.js

# Update Flutter config
flutterfire configure --project=chamak-new-xxxxx --platforms=android,web --yes

# Deploy rules
firebase deploy --only firestore:rules --project chamak-new-xxxxx
firebase deploy --only storage:rules --project chamak-new-xxxxx
```

---

## 🎉 CONGRATULATIONS!

You've successfully migrated to a new Firebase account while keeping:
- ✅ All data
- ✅ All users
- ✅ All rules
- ✅ Everything!

**Remember:** Add rate limiting to prevent high costs in new project! 💰

---

**Need help?** If you encounter any issues during migration, check the troubleshooting section or ask for help!

**Good luck with your migration! 🚀**
