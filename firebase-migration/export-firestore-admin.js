const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ⚠️ IMPORTANT: Place your service account key file here
// Download from: Firebase Console → Project Settings → Service Accounts → Generate new private key
const serviceAccount = require('./old-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://chamak-39472.firebaseio.com'
});

const db = admin.firestore();

// Create exports directory
if (!fs.existsSync('exports')) {
  fs.mkdirSync('exports');
}

// Helper function to convert Firestore Timestamps to ISO strings
function processFirestoreData(data) {
  const processed = {};
  for (const [key, value] of Object.entries(data)) {
    if (value && typeof value === 'object') {
      if (value.toDate && typeof value.toDate === 'function') {
        // Firestore Timestamp
        processed[key] = value.toDate().toISOString();
      } else if (value.constructor && value.constructor.name === 'Timestamp') {
        // Another Timestamp format
        processed[key] = value.toDate().toISOString();
      } else if (Array.isArray(value)) {
        // Process array items
        processed[key] = value.map(item => 
          typeof item === 'object' && item !== null && item.toDate 
            ? item.toDate().toISOString() 
            : item
        );
      } else {
        processed[key] = value;
      }
    } else {
      processed[key] = value;
    }
  }
  return processed;
}

async function exportCollection(collectionName) {
  console.log(`\n📦 Exporting ${collectionName}...`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    const data = [];
    
    snapshot.forEach(doc => {
      const docData = doc.data();
      const processedData = processFirestoreData(docData);
      
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
    if (error.code === 'resource-exhausted') {
      console.log(`⚠️ Quota exceeded for ${collectionName}. Waiting 60 seconds...`);
      await new Promise(resolve => setTimeout(resolve, 60000));
      // Retry once
      try {
        const snapshot = await db.collection(collectionName).get();
        const data = [];
        snapshot.forEach(doc => {
          data.push({
            id: doc.id,
            data: processFirestoreData(doc.data())
          });
        });
        const filePath = path.join(__dirname, `exports/${collectionName}.json`);
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
        console.log(`✅ Retry successful: Exported ${data.length} documents`);
        return data.length;
      } catch (retryError) {
        console.error(`❌ Retry failed:`, retryError.message);
        return 0;
      }
    }
    return 0;
  }
}

async function exportSubcollection(parentCollection, parentDocId, subcollectionName) {
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
        data: processFirestoreData(doc.data())
      });
    });
    
    if (data.length > 0) {
      const filePath = path.join(__dirname, `exports/${parentCollection}_${parentDocId}_${subcollectionName}.json`);
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
      console.log(`  ✅ Exported ${data.length} documents from ${parentCollection}/${parentDocId}/${subcollectionName}`);
    }
    
    return data.length;
  } catch (error) {
    // Silently skip if subcollection doesn't exist or has no data
    return 0;
  }
}

async function exportAll() {
  console.log('🚀 Starting Firestore Export (Using Admin SDK - Works even with quota exceeded!)...\n');
  
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
  ];
  
  let totalDocs = 0;
  
  for (const collection of collections) {
    try {
      const count = await exportCollection(collection);
      totalDocs += count;
      
      // Export subcollections for users (if users collection exists)
      if (collection === 'users' && count > 0) {
        console.log(`\n📁 Exporting user subcollections...`);
        try {
          const usersSnapshot = await db.collection('users').limit(100).get(); // Limit to avoid quota
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
          
          let userCount = 0;
          for (const userDoc of usersSnapshot.docs) {
            if (userCount >= 50) break; // Limit to first 50 users to avoid quota
            for (const subcol of subcollections) {
              await exportSubcollection('users', userDoc.id, subcol);
            }
            userCount++;
            // Small delay
            await new Promise(resolve => setTimeout(resolve, 100));
          }
        } catch (error) {
          console.log(`⚠️ Skipping subcollections export: ${error.message}`);
        }
      }
      
      // Small delay to avoid rate limits
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      console.error(`❌ Error processing ${collection}:`, error.message);
    }
  }
  
  console.log(`\n✅ Export Complete!`);
  console.log(`📊 Total documents exported: ${totalDocs}`);
  console.log(`📁 Files saved in: ${path.join(__dirname, 'exports')}`);
  console.log(`\n📝 Next steps:`);
  console.log(`1. Check exports/ folder for JSON files`);
  console.log(`2. Follow import steps in migration guide`);
}

// Run export
exportAll().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
