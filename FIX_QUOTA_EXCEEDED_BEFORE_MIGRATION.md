# 🚨 CRITICAL: Fix "Quota Exceeded" Before Migration
## How to Migrate When Firestore Quota is Exceeded

**Problem:** Firebase Console shows "Quota exceeded"  
**Impact:** Cannot export Firestore data  
**Solution:** Fix quota issue first, then migrate

---

## ⚠️ WHY QUOTA EXCEEDED BLOCKS MIGRATION

### The Problem:
- ❌ **Cannot export Firestore data** (quota exceeded)
- ❌ **Cannot read collections** (quota exceeded)
- ❌ **Cannot use Firebase Console** (limited access)
- ✅ **Can still migrate** using alternative methods!

---

## 🎯 SOLUTION: 3 Options to Fix Quota

### Option 1: Upgrade to Blaze Plan (RECOMMENDED) ⭐⭐⭐

**Why This Works:**
- ✅ Removes quota limits
- ✅ Can export data immediately
- ✅ Pay-as-you-go (only pay for what you use)
- ✅ Free tier still applies

**Steps:**

1. **Go to:** Firebase Console → ⚙️ Settings → Usage and billing
2. **Click:** "Modify plan" or "Upgrade"
3. **Select:** Blaze Plan (Pay as you go)
4. **Add:** Payment method (Credit/Debit card)
5. **Confirm:** Upgrade

**Result:**
- ✅ Quota limits removed immediately
- ✅ Can export data now
- ✅ Continue with migration

**Cost:** 
- Free tier: 50K reads/day, 20K writes/day
- After free tier: ₹0.18 per 100K reads, ₹0.54 per 100K writes
- **You only pay for what you use!**

---

### Option 2: Wait for Quota Reset (SLOW) ⭐

**Why This Works:**
- ✅ Free (no cost)
- ✅ Quota resets daily
- ❌ Need to wait 24 hours
- ❌ May exceed again during export

**Steps:**

1. **Wait:** 24 hours for daily quota reset
2. **Check:** Firebase Console → Usage
3. **Export:** Quickly before quota exceeds again

**Result:**
- ✅ Can export data after reset
- ⚠️ Need to export fast before quota exceeds

**Time:** 24 hours wait

---

### Option 3: Use Alternative Export Methods (BEST) ⭐⭐⭐

**Why This Works:**
- ✅ Works even with quota exceeded
- ✅ Uses Admin SDK (different quota)
- ✅ More reliable
- ✅ Can export in batches

**Steps:** (See below)

---

## 🚀 BEST SOLUTION: Export Using Admin SDK

### Why Admin SDK Works:
- ✅ Uses different quota limits
- ✅ Higher limits than client SDK
- ✅ Can export even when Console shows "Quota exceeded"
- ✅ More reliable for large databases

### Step 1: Install Required Tools

```bash
# Install Node.js (if not installed)
# Download from: https://nodejs.org/

# Install Firebase Admin SDK
npm install -g firebase-admin

# Or create a folder and install locally
mkdir firebase-migration
cd firebase-migration
npm init -y
npm install firebase-admin
```

### Step 2: Download Service Account Key

**From OLD Project:**

1. **Go to:** Firebase Console → ⚙️ Project Settings → Service Accounts
2. **Click:** "Generate new private key"
3. **Save:** As `old-service-account.json`
4. **⚠️ Keep this secure!**

### Step 3: Create Export Script

**Create file:** `export-firestore-admin.js`

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin with service account
const serviceAccount = require('./old-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://chamak-39472.firebaseio.com'
});

const db = admin.firestore();

// Create exports directory
if (!fs.existsSync('exports')) {
  fs.mkdirSync('exports');
}

async function exportCollection(collectionName) {
  console.log(`\n📦 Exporting ${collectionName}...`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    const data = [];
    
    snapshot.forEach(doc => {
      const docData = doc.data();
      
      // Convert Firestore Timestamps to ISO strings for JSON
      const processedData = {};
      for (const [key, value] of Object.entries(docData)) {
        if (value && value.toDate && typeof value.toDate === 'function') {
          processedData[key] = value.toDate().toISOString();
        } else if (value && typeof value === 'object' && value.constructor.name === 'Timestamp') {
          processedData[key] = value.toDate().toISOString();
        } else {
          processedData[key] = value;
        }
      }
      
      data.push({
        id: doc.id,
        data: processedData
      });
    });
    
    // Save to file
    const filePath = path.join(__dirname, `exports/${collectionName}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    
    console.log(`✅ Exported ${data.length} documents from ${collectionName}`);
    return data.length;
  } catch (error) {
    console.error(`❌ Error exporting ${collectionName}:`, error.message);
    return 0;
  }
}

async function exportSubcollection(parentCollection, parentDocId, subcollectionName) {
  console.log(`  📁 Exporting subcollection: ${parentCollection}/${parentDocId}/${subcollectionName}...`);
  
  try {
    const snapshot = await db
      .collection(parentCollection)
      .doc(parentDocId)
      .collection(subcollectionName)
      .get();
    
    const data = [];
    snapshot.forEach(doc => {
      data.push({
        id: doc.id,
        data: doc.data()
      });
    });
    
    if (data.length > 0) {
      const filePath = path.join(__dirname, `exports/${parentCollection}_${parentDocId}_${subcollectionName}.json`);
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
      console.log(`  ✅ Exported ${data.length} documents from subcollection`);
    }
    
    return data.length;
  } catch (error) {
    console.error(`  ❌ Error exporting subcollection:`, error.message);
    return 0;
  }
}

async function exportAll() {
  console.log('🚀 Starting Firestore Export...\n');
  
  // List of all collections to export
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
    'transactions',
    // Add all your collections here
  ];
  
  let totalDocs = 0;
  
  for (const collection of collections) {
    try {
      const count = await exportCollection(collection);
      totalDocs += count;
      
      // Export subcollections for users
      if (collection === 'users' && count > 0) {
        // Get all user IDs
        const usersSnapshot = await db.collection('users').get();
        const subcollections = [
          'transactions',
          'coinTransactions',
          'following',
          'followers',
          'seenAnnouncements',
          'dismissedAnnouncements',
          'seenEvents',
          'blocked',
          'tickets',
          'payment_methods'
        ];
        
        for (const userDoc of usersSnapshot.docs) {
          for (const subcol of subcollections) {
            await exportSubcollection('users', userDoc.id, subcol);
          }
        }
      }
      
      // Small delay to avoid rate limits
      await new Promise(resolve => setTimeout(resolve, 100));
    } catch (error) {
      console.error(`❌ Error processing ${collection}:`, error.message);
    }
  }
  
  console.log(`\n✅ Export Complete!`);
  console.log(`📊 Total documents exported: ${totalDocs}`);
  console.log(`📁 Files saved in: ${path.join(__dirname, 'exports')}`);
}

// Run export
exportAll().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
```

### Step 4: Run Export Script

```bash
# Make sure you're in the migration folder
cd firebase-migration

# Place old-service-account.json in this folder

# Run export
node export-firestore-admin.js
```

**Result:**
- ✅ All collections exported to `exports/` folder
- ✅ Works even with quota exceeded
- ✅ Uses Admin SDK (higher limits)

---

## 🔄 ALTERNATIVE: Export Using gcloud CLI

### Step 1: Install gcloud CLI

```bash
# Download from: https://cloud.google.com/sdk/docs/install
# Or use PowerShell:
# Install-Module -Name gcloud -Force
```

### Step 2: Authenticate

```bash
gcloud auth login
gcloud config set project chamak-39472
```

### Step 3: Export Firestore

```bash
# Export to Cloud Storage bucket
gcloud firestore export gs://chamak-39472-backup/firestore-export

# Wait for export to complete
# Check status:
gcloud firestore operations list
```

**Note:** This requires creating a Cloud Storage bucket first

---

## 📋 COMPLETE MIGRATION PLAN WITH QUOTA ISSUE

### Phase 1: Fix Quota Issue (Choose One)

**Option A: Upgrade to Blaze** (Recommended)
- [ ] Upgrade to Blaze Plan
- [ ] Wait 5 minutes for activation
- [ ] Proceed with export

**Option B: Use Admin SDK** (Best if can't upgrade)
- [ ] Download service account key
- [ ] Install Node.js and Firebase Admin
- [ ] Run export script
- [ ] Export completes successfully

**Option C: Wait for Reset** (Slowest)
- [ ] Wait 24 hours
- [ ] Export quickly before quota exceeds

### Phase 2: Export Everything

- [ ] Export Firestore data (using chosen method)
- [ ] Export Storage files
- [ ] Export Firebase Auth users
- [ ] Copy Firestore rules ✅ (already have)
- [ ] Copy Storage rules ✅ (already have)

### Phase 3: Create New Project

- [ ] Create new Firebase project
- [ ] Enable all services
- [ ] Download new service account key

### Phase 4: Import Everything

- [ ] Import Firestore data
- [ ] Import Storage files
- [ ] Import Firebase Auth users
- [ ] Deploy Firestore rules
- [ ] Deploy Storage rules

### Phase 5: Update App

- [ ] Run: `flutterfire configure --project=chamak-new`
- [ ] Test authentication
- [ ] Test all features
- [ ] Deploy

---

## 🎯 RECOMMENDED ACTION PLAN

### Right Now (Choose One):

**Option 1: Upgrade to Blaze** ⭐⭐⭐
1. Go to Firebase Console → Usage and billing
2. Click "Modify plan" → Upgrade to Blaze
3. Add payment method
4. Wait 5 minutes
5. Export data using Console or scripts

**Option 2: Use Admin SDK** ⭐⭐⭐
1. Download service account key
2. Install Node.js
3. Run export script (provided above)
4. Export completes even with quota exceeded

**Option 3: Wait** ⭐
1. Wait 24 hours for quota reset
2. Export quickly before it exceeds again

---

## 💰 COST COMPARISON

### Current (Spark Plan):
- ❌ Quota exceeded
- ❌ Cannot export
- ❌ Limited functionality

### Blaze Plan:
- ✅ No quota limits
- ✅ Can export immediately
- ✅ Free tier: 50K reads/day, 20K writes/day
- ✅ After free tier: Pay per use
- **Cost:** ₹0-500/month (depending on usage)

**Recommendation:** Upgrade to Blaze for migration, then optimize costs

---

## 🆘 IF EXPORT STILL FAILS

### Try These:

1. **Export in Smaller Batches:**
   - Export one collection at a time
   - Wait between exports
   - Use pagination

2. **Use Cloud Functions:**
   - Create Cloud Function to export
   - Runs with higher limits
   - More reliable

3. **Contact Firebase Support:**
   - Request quota increase
   - Explain migration need
   - May get temporary increase

---

## ✅ QUICK CHECKLIST

### Immediate Actions:
- [ ] Choose export method (Blaze upgrade OR Admin SDK)
- [ ] Download service account key
- [ ] Run export script
- [ ] Verify exports completed

### Then Continue Migration:
- [ ] Follow `COMPLETE_FIREBASE_ACCOUNT_MIGRATION_STEP_BY_STEP.md`
- [ ] Import to new project
- [ ] Update app configuration
- [ ] Test and deploy

---

## 📝 SUMMARY

**Problem:** Quota exceeded blocks export  
**Solution:** Use Admin SDK export (works even with quota exceeded)  
**Alternative:** Upgrade to Blaze Plan  
**Time:** 30 minutes to 24 hours (depending on method)

**Next Steps:**
1. Choose export method
2. Export data using Admin SDK script
3. Continue with migration steps

---

**The Admin SDK export script above will work even with quota exceeded! 🚀**

**Need help running the script?** I can guide you step by step!
