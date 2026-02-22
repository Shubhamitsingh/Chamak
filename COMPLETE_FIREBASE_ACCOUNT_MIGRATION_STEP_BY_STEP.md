# 🔄 Complete Firebase Account Migration Guide
## Step-by-Step: Migrate Everything to New Firebase Account

**Current Project:** `chamak-39472`  
**Goal:** Create new Firebase account and migrate ALL data, users, and rules  
**Status:** Complete Step-by-Step Guide

---

## 📋 TABLE OF CONTENTS

1. [Pre-Migration Checklist](#1-pre-migration-checklist)
2. [Step 1: Create New Firebase Project](#step-1-create-new-firebase-project)
3. [Step 2: Export Firestore Rules](#step-2-export-firestore-rules)
4. [Step 3: Export Storage Rules](#step-3-export-storage-rules)
5. [Step 4: Export Firestore Data](#step-4-export-firestore-data)
6. [Step 5: Export Storage Files](#step-5-export-storage-files)
7. [Step 6: Export Firebase Auth Users](#step-6-export-firebase-auth-users)
8. [Step 7: Import to New Project](#step-7-import-to-new-project)
9. [Step 8: Update App Configuration](#step-8-update-app-configuration)
10. [Step 9: Test Everything](#step-9-test-everything)
11. [Step 10: Deploy & Monitor](#step-10-deploy--monitor)

---

## 1. PRE-MIGRATION CHECKLIST

### Before You Start:

- [ ] Backup current Firebase project
- [ ] Note down current Project ID: `chamak-39472`
- [ ] Note down current Project Number: `228866341171`
- [ ] Have Firebase CLI installed
- [ ] Have Node.js installed (for scripts)
- [ ] Have admin access to both projects
- [ ] Plan downtime window (if needed)

### What Will Be Migrated:

✅ **Firestore Database** (all collections & documents)  
✅ **Firestore Rules** (security rules)  
✅ **Firebase Storage** (all files)  
✅ **Storage Rules** (security rules)  
✅ **Firebase Auth Users** (all user accounts)  
✅ **Cloud Functions** (if any)  
✅ **Indexes** (Firestore indexes)

### What Needs Manual Update:

⚠️ **App Configuration** (firebase_options.dart, google-services.json)  
⚠️ **Service Account Keys** (if using admin SDK)  
⚠️ **Webhooks/API Keys** (third-party integrations)

---

## STEP 1: CREATE NEW FIREBASE PROJECT

### 1.1 Go to Firebase Console

1. **Open:** https://console.firebase.google.com/
2. **Click:** "Add project" or "Create a project"
3. **Enter Project Name:** `chamak-new` (or your preferred name)
4. **Click:** Continue

### 1.2 Configure Project

1. **Google Analytics:** 
   - Choose: Enable (recommended) or Disable
   - Click: Continue

2. **Wait for Creation:**
   - Project creation takes 1-2 minutes
   - Click: Continue when ready

### 1.3 Enable Required Services

**Enable these services in new project:**

#### A. Firestore Database

1. **Go to:** Firestore Database
2. **Click:** "Create database"
3. **Choose:** "Start in production mode" (we'll import rules later)
4. **Select Location:** Same as old project (e.g., `asia-south1`)
5. **Click:** Enable

#### B. Firebase Storage

1. **Go to:** Storage
2. **Click:** "Get started"
3. **Choose:** "Start in production mode" (we'll import rules later)
4. **Select Location:** Same as old project
5. **Click:** Done

#### C. Firebase Authentication

1. **Go to:** Authentication → Sign-in method
2. **Enable:**
   - ✅ Phone (for OTP)
   - ✅ Email/Password (if using)
   - ✅ Google (if using)
3. **Click:** Save

#### D. Cloud Functions (if using)

1. **Go to:** Functions
2. **Click:** "Get started"
3. **Follow:** Setup instructions

---

## STEP 2: EXPORT FIRESTORE RULES

### 2.1 Get Current Rules

**File:** `firestore.rules` (already in your project)

**Copy this file - you'll need it later!**

**Location:** `firestore.rules` in your project root

**Content:** Already has all your rules ✅

### 2.2 Verify Rules File

**Check:** `firestore.rules` exists and has content

**If missing:** Download from Firebase Console:
1. Go to: Firestore Database → Rules
2. Copy all rules
3. Save to `firestore.rules`

---

## STEP 3: EXPORT STORAGE RULES

### 3.1 Get Current Rules

**File:** `storage.rules` (already in your project)

**Copy this file - you'll need it later!**

**Location:** `storage.rules` in your project root

**Content:** Already has all your rules ✅

### 3.2 Verify Rules File

**Check:** `storage.rules` exists and has content

**If missing:** Download from Firebase Console:
1. Go to: Storage → Rules
2. Copy all rules
3. Save to `storage.rules`

---

## STEP 4: EXPORT FIRESTORE DATA

### 4.1 Install Firebase CLI (if not installed)

```bash
npm install -g firebase-tools
```

### 4.2 Login to Firebase

```bash
firebase login
```

### 4.3 Export Firestore Data

**Method 1: Using Firebase Console (Easiest)**

1. **Go to:** Firebase Console → Firestore Database
2. **Click:** "..." menu → Export
3. **Wait:** Export completes (may take time for large databases)
4. **Download:** Export file (GCS bucket)

**Method 2: Using Firebase CLI**

```bash
# Set project to old project
firebase use chamak-39472

# Export Firestore
gcloud firestore export gs://chamak-39472-backup/firestore-export --project=chamak-39472
```

**Method 3: Using Script (Recommended)**

Create file: `export-firestore.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize old Firebase project
const serviceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://chamak-39472.firebaseio.com'
});

const db = admin.firestore();

async function exportCollection(collectionName) {
  console.log(`Exporting ${collectionName}...`);
  
  const snapshot = await db.collection(collectionName).get();
  const data = [];
  
  snapshot.forEach(doc => {
    data.push({
      id: doc.id,
      data: doc.data()
    });
  });
  
  // Save to file
  fs.writeFileSync(
    path.join(__dirname, `exports/${collectionName}.json`),
    JSON.stringify(data, null, 2)
  );
  
  console.log(`✅ Exported ${data.length} documents from ${collectionName}`);
  return data.length;
}

async function exportAll() {
  // Create exports directory
  if (!fs.existsSync('exports')) {
    fs.mkdirSync('exports');
  }
  
  // List of collections to export
  const collections = [
    'users',
    'live_streams',
    'chats',
    'orders',
    'payments',
    'gifts',
    'supportTickets',
    'promotions',
    'events',
    'announcements',
    'admins',
    'wallets',
    'earnings',
    'feedback',
    'host_applications',
    'banners',
    'settings',
    'share_tracking',
    'reward_transactions',
    'approvedHosts',
    'team_messages',
    'supportChats',
    'withdrawal_requests',
    'callTransactions',
    'callRequests',
    'reports',
    // Add all your collections here
  ];
  
  let totalDocs = 0;
  for (const collection of collections) {
    try {
      const count = await exportCollection(collection);
      totalDocs += count;
    } catch (error) {
      console.error(`❌ Error exporting ${collection}:`, error.message);
    }
  }
  
  console.log(`\n✅ Total documents exported: ${totalDocs}`);
}

exportAll().catch(console.error);
```

**Run script:**
```bash
node export-firestore.js
```

**Result:** All collections exported to `exports/` folder

---

## STEP 5: EXPORT STORAGE FILES

### 5.1 Using Firebase Console

1. **Go to:** Storage → Files
2. **Select:** All folders/files
3. **Download:** (if small, use browser download)
4. **For large files:** Use gsutil (see below)

### 5.2 Using gsutil (Recommended for Large Files)

```bash
# Install gsutil (if not installed)
# Download from: https://cloud.google.com/storage/docs/gsutil_install

# Export all files
gsutil -m cp -r gs://chamak-39472.appspot.com/* ./storage-backup/
```

### 5.3 Using Script

Create file: `export-storage.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize old Firebase project
const serviceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'chamak-39472.appspot.com'
});

const bucket = admin.storage().bucket();

async function exportStorage() {
  console.log('Exporting Storage files...');
  
  const [files] = await bucket.getFiles();
  const fileList = [];
  
  for (const file of files) {
    const fileName = file.name;
    const localPath = path.join(__dirname, 'storage-backup', fileName);
    const dir = path.dirname(localPath);
    
    // Create directory if doesn't exist
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    // Download file
    await file.download({ destination: localPath });
    fileList.push(fileName);
    console.log(`✅ Downloaded: ${fileName}`);
  }
  
  // Save file list
  fs.writeFileSync(
    path.join(__dirname, 'storage-backup', 'file-list.json'),
    JSON.stringify(fileList, null, 2)
  );
  
  console.log(`\n✅ Exported ${fileList.length} files`);
}

exportStorage().catch(console.error);
```

**Run script:**
```bash
node export-storage.js
```

---

## STEP 6: EXPORT FIREBASE AUTH USERS

### 6.1 Download Service Account Key

**From OLD Project:**

1. **Go to:** Firebase Console → Project Settings → Service Accounts
2. **Click:** "Generate new private key"
3. **Save:** As `old-service-account.json`
4. **⚠️ Keep this secure!**

### 6.2 Export Users Script

Create file: `export-users.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize old Firebase project
const serviceAccount = require('./old-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function exportUsers() {
  console.log('Exporting Firebase Auth users...');
  
  const users = [];
  let nextPageToken;
  
  do {
    const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
    
    listUsersResult.users.forEach(user => {
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
          lastSignInTime: user.metadata.lastSignInTime,
        },
        customClaims: user.customClaims,
      });
    });
    
    nextPageToken = listUsersResult.pageToken;
    console.log(`Exported ${users.length} users so far...`);
  } while (nextPageToken);
  
  // Save to file
  fs.writeFileSync(
    'exports/users-auth.json',
    JSON.stringify(users, null, 2)
  );
  
  console.log(`\n✅ Exported ${users.length} users`);
}

exportUsers().catch(console.error);
```

**Run script:**
```bash
node export-users.js
```

**Result:** All users exported to `exports/users-auth.json`

---

## STEP 7: IMPORT TO NEW PROJECT

### 7.1 Download New Service Account Key

**From NEW Project:**

1. **Go to:** Firebase Console → Project Settings → Service Accounts
2. **Click:** "Generate new private key"
3. **Save:** As `new-service-account.json`

### 7.2 Import Firestore Rules

**Method 1: Using Firebase CLI**

```bash
# Set project to new project
firebase use chamak-new

# Deploy rules
firebase deploy --only firestore:rules
```

**Method 2: Using Firebase Console**

1. **Go to:** Firestore Database → Rules
2. **Copy:** Content from `firestore.rules`
3. **Paste:** Into rules editor
4. **Click:** Publish

### 7.3 Import Storage Rules

**Method 1: Using Firebase CLI**

```bash
firebase deploy --only storage
```

**Method 2: Using Firebase Console**

1. **Go to:** Storage → Rules
2. **Copy:** Content from `storage.rules`
3. **Paste:** Into rules editor
4. **Click:** Publish

### 7.4 Import Firestore Data

**Method 1: Using Import Script**

Create file: `import-firestore.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize NEW Firebase project
const serviceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://chamak-new.firebaseio.com'
});

const db = admin.firestore();

async function importCollection(collectionName) {
  console.log(`Importing ${collectionName}...`);
  
  const filePath = path.join(__dirname, `exports/${collectionName}.json`);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️ File not found: ${filePath}`);
    return 0;
  }
  
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  
  const batch = db.batch();
  let count = 0;
  
  for (const doc of data) {
    const docRef = db.collection(collectionName).doc(doc.id);
    batch.set(docRef, doc.data);
    count++;
    
    // Firestore batches are limited to 500 operations
    if (count === 500) {
      await batch.commit();
      console.log(`  Committed batch of 500...`);
      count = 0;
    }
  }
  
  if (count > 0) {
    await batch.commit();
  }
  
  console.log(`✅ Imported ${data.length} documents to ${collectionName}`);
  return data.length;
}

async function importAll() {
  const collections = fs.readdirSync('exports')
    .filter(file => file.endsWith('.json') && file !== 'users-auth.json');
  
  let totalDocs = 0;
  for (const file of collections) {
    const collectionName = file.replace('.json', '');
    try {
      const count = await importCollection(collectionName);
      totalDocs += count;
    } catch (error) {
      console.error(`❌ Error importing ${collectionName}:`, error.message);
    }
  }
  
  console.log(`\n✅ Total documents imported: ${totalDocs}`);
}

importAll().catch(console.error);
```

**Run script:**
```bash
node import-firestore.js
```

### 7.5 Import Storage Files

**Method 1: Using gsutil**

```bash
# Copy to new bucket
gsutil -m cp -r ./storage-backup/* gs://chamak-new.appspot.com/
```

**Method 2: Using Script**

Create file: `import-storage.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize NEW Firebase project
const serviceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'chamak-new.appspot.com'
});

const bucket = admin.storage().bucket();

async function importStorage() {
  console.log('Importing Storage files...');
  
  const fileList = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'storage-backup', 'file-list.json'), 'utf8')
  );
  
  for (const fileName of fileList) {
    const localPath = path.join(__dirname, 'storage-backup', fileName);
    
    if (!fs.existsSync(localPath)) {
      console.log(`⚠️ File not found: ${localPath}`);
      continue;
    }
    
    await bucket.upload(localPath, {
      destination: fileName,
    });
    
    console.log(`✅ Uploaded: ${fileName}`);
  }
  
  console.log(`\n✅ Imported ${fileList.length} files`);
}

importStorage().catch(console.error);
```

**Run script:**
```bash
node import-storage.js
```

### 7.6 Import Firebase Auth Users

**⚠️ IMPORTANT:** Firebase Auth users CANNOT be directly imported!

**Options:**

**Option 1: Users Re-authenticate (Easiest)**
- Users login again with phone/email
- New accounts created automatically
- Link old Firestore data manually

**Option 2: Import Users (Complex)**

Create file: `import-users.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize NEW Firebase project
const serviceAccount = require('./new-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function importUsers() {
  console.log('Importing Firebase Auth users...');
  
  const users = JSON.parse(fs.readFileSync('exports/users-auth.json', 'utf8'));
  
  for (const userData of users) {
    try {
      const userRecord = await admin.auth().createUser({
        uid: userData.uid, // Keep same UID to match Firestore data
        email: userData.email,
        phoneNumber: userData.phoneNumber,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        emailVerified: userData.emailVerified,
        disabled: userData.disabled,
      });
      
      // Set custom claims if any
      if (userData.customClaims) {
        await admin.auth().setCustomUserClaims(userData.uid, userData.customClaims);
      }
      
      console.log(`✅ Imported user: ${userData.uid}`);
    } catch (error) {
      if (error.code === 'auth/uid-already-exists') {
        console.log(`⚠️ User already exists: ${userData.uid}`);
      } else {
        console.error(`❌ Error importing ${userData.uid}:`, error.message);
      }
    }
  }
  
  console.log(`\n✅ Imported ${users.length} users`);
}

importUsers().catch(console.error);
```

**⚠️ Note:** This keeps same UIDs, so Firestore data matches!

**Run script:**
```bash
node import-users.js
```

---

## STEP 8: UPDATE APP CONFIGURATION

### 8.1 Configure FlutterFire CLI

```bash
# Navigate to your project
cd chamak

# Configure Firebase for new project
flutterfire configure --project=chamak-new --platforms=android,web --yes
```

**This will:**
- ✅ Update `lib/firebase_options.dart`
- ✅ Update `android/app/google-services.json`
- ✅ Configure all platforms

### 8.2 Verify Configuration

**Check:** `lib/firebase_options.dart`

Should have new project ID: `chamak-new`

**Check:** `android/app/google-services.json`

Should have new project ID: `chamak-new`

### 8.3 Update Firebase.json (if exists)

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
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
```

### 8.4 Update Service Account Keys (if using Admin SDK)

**If you have backend/server using Firebase Admin:**

1. **Replace:** Old service account key with new one
2. **Update:** Environment variables
3. **Restart:** Server

---

## STEP 9: TEST EVERYTHING

### 9.1 Test Authentication

1. **Test Phone Login:**
   - Enter phone number
   - Receive OTP
   - Login successfully

2. **Test Email Login:**
   - Enter email/password
   - Login successfully

3. **Test Google Sign-In:**
   - Click Google Sign-In
   - Login successfully

### 9.2 Test Firestore Data

1. **Check Users:**
   - Login
   - View profile
   - Verify data exists

2. **Check Collections:**
   - Verify all collections exist
   - Verify data is correct
   - Test queries

### 9.3 Test Storage

1. **Check Files:**
   - View profile pictures
   - View cover photos
   - Verify files load

2. **Test Upload:**
   - Upload new file
   - Verify it saves
   - Verify it displays

### 9.4 Test Features

- [ ] User profile
- [ ] Live streams
- [ ] Chats
- [ ] Payments
- [ ] All features

---

## STEP 10: DEPLOY & MONITOR

### 10.1 Build App

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 10.2 Test on Device

1. **Install:** APK on test device
2. **Test:** All features
3. **Verify:** Everything works

### 10.3 Deploy to Play Store

1. **Build:** App bundle
2. **Upload:** To Play Console
3. **Release:** To users

### 10.4 Monitor

**First Week:**
- [ ] Monitor Firebase Console daily
- [ ] Check for errors
- [ ] Monitor costs
- [ ] Check user feedback

**Ongoing:**
- [ ] Monitor usage
- [ ] Check costs
- [ ] Fix any issues

---

## 📊 MIGRATION CHECKLIST

### Pre-Migration:
- [ ] Backup old project
- [ ] Create new Firebase project
- [ ] Enable all required services
- [ ] Download service account keys

### Export:
- [ ] Export Firestore rules ✅ (already have)
- [ ] Export Storage rules ✅ (already have)
- [ ] Export Firestore data
- [ ] Export Storage files
- [ ] Export Firebase Auth users

### Import:
- [ ] Import Firestore rules
- [ ] Import Storage rules
- [ ] Import Firestore data
- [ ] Import Storage files
- [ ] Import Firebase Auth users (or let users re-auth)

### Configuration:
- [ ] Update firebase_options.dart
- [ ] Update google-services.json
- [ ] Update Firebase.json
- [ ] Update service account keys (if needed)

### Testing:
- [ ] Test authentication
- [ ] Test Firestore data
- [ ] Test Storage files
- [ ] Test all features
- [ ] Test on devices

### Deployment:
- [ ] Build app
- [ ] Test thoroughly
- [ ] Deploy to Play Store
- [ ] Monitor for issues

---

## 🆘 TROUBLESHOOTING

### Issue 1: Users Can't Login

**Problem:** Users don't exist in new project

**Solution:**
- Import users using script (Step 7.6)
- Or let users re-register

### Issue 2: Data Missing

**Problem:** Some collections not imported

**Solution:**
- Check export files
- Re-run import script
- Verify collection names match

### Issue 3: Storage Files Not Loading

**Problem:** Old URLs point to old bucket

**Solution:**
- Update URLs in Firestore
- Or use migration script to update

### Issue 4: Rules Not Working

**Problem:** Rules not deployed

**Solution:**
- Deploy rules using Firebase CLI
- Or manually paste in Console

---

## 📝 SUMMARY

### What Gets Migrated:

✅ **Firestore Database** - All collections & documents  
✅ **Firestore Rules** - Security rules  
✅ **Storage Files** - All files  
✅ **Storage Rules** - Security rules  
✅ **Firebase Auth Users** - User accounts (with script)  
✅ **Indexes** - Firestore indexes

### What Needs Update:

⚠️ **App Configuration** - firebase_options.dart, google-services.json  
⚠️ **Service Account Keys** - If using Admin SDK  
⚠️ **Third-party Integrations** - Webhooks, API keys

### Time Estimate:

- **Export:** 1-2 hours (depending on data size)
- **Import:** 1-2 hours
- **Configuration:** 30 minutes
- **Testing:** 2-3 hours
- **Total:** 5-8 hours

---

## 🎯 NEXT STEPS

1. **Follow steps above** in order
2. **Test thoroughly** before deploying
3. **Monitor closely** after deployment
4. **Keep old project** for 1 month (backup)

---

## 📞 NEED HELP?

If you get stuck:
1. Check error messages
2. Review Firebase Console
3. Check export/import logs
4. Ask for help!

**Good luck with your migration! 🚀**

---

**Report Generated:** February 19, 2026  
**Status:** Ready for Migration  
**Estimated Time:** 5-8 hours  
**Difficulty:** Medium
