/**
 * One-time migration script: Move existing approved hosts to approvedHosts collection
 * 
 * Run this after deploying the Cloud Function:
 * firebase use <project-id>
 * node migrateApprovedHosts.js
 * 
 * OR set environment variable:
 * set GCLOUD_PROJECT=chamak-39472
 * node migrateApprovedHosts.js
 * 
 * This script:
 * 1. Finds all users with isActive=true (approved users = hosts)
 * 2. Adds them to approvedHosts collection
 * 3. Denormalizes essential fields for fast queries
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Get project ID from .firebaserc or environment variable
let projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;

// Try to read from .firebaserc if project ID not set
if (!projectId) {
  try {
    const firebasercPath = path.join(__dirname, '..', '.firebaserc');
    if (fs.existsSync(firebasercPath)) {
      const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, 'utf8'));
      const defaultProject = firebaserc.projects?.default;
      if (defaultProject) {
        projectId = defaultProject;
        console.log(`📋 Using project ID from .firebaserc: ${projectId}`);
      }
    }
  } catch (e) {
    console.log('⚠️ Could not read .firebaserc');
  }
}

// If still no project ID, use default from your project
if (!projectId) {
  projectId = 'chamak-39472'; // Your Firebase project ID
  console.log(`📋 Using default project ID: ${projectId}`);
}

// Initialize Firebase Admin SDK with explicit project ID
// Use application default credentials if available, otherwise use Firebase CLI credentials
let app;
try {
  // Try to initialize with project ID
  app = admin.initializeApp({
    projectId: projectId,
  });
} catch (e) {
  // If already initialized, get the app
  try {
    app = admin.app();
  } catch (e2) {
    // Last resort: initialize without project ID (will use default)
    app = admin.initializeApp();
  }
}

async function migrateApprovedHosts() {
  try {
    console.log('🚀 Starting migration of approved hosts...');
    console.log(`📋 Project ID: ${admin.app().options.projectId}`);
    
    // Get all users with isActive=true (approved users = hosts)
    let usersSnapshot;
    try {
      usersSnapshot = await admin.firestore()
        .collection('users')
        .where('isActive', '==', true)
        .get();
    } catch (indexError) {
      // If index doesn't exist, get all users and filter in code
      console.log('⚠️ Index not found, fetching all users and filtering...');
      const allUsersSnapshot = await admin.firestore()
        .collection('users')
        .get();
      
      // Filter in code
      usersSnapshot = {
        docs: allUsersSnapshot.docs.filter(doc => {
          const data = doc.data();
          return data.isActive === true;
        }),
        empty: false,
        size: 0, // Will be set below
      };
      usersSnapshot.size = usersSnapshot.docs.length;
    }
    
    if (usersSnapshot.empty) {
      console.log('⚠️ No approved hosts found to migrate');
      return;
    }
    
    console.log(`📊 Found ${usersSnapshot.docs.length} approved hosts to migrate`);
    
    const batch = admin.firestore().batch();
    let count = 0;
    let batchCount = 0;
    
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userId = userDoc.id;
      
      // Add to approvedHosts collection
      const approvedHostRef = admin.firestore()
        .collection('approvedHosts')
        .doc(userId);
      
      batch.set(approvedHostRef, {
        userId: userId,
        hostName: userData.displayName || userData.name || 'Host',
        hostPhotoUrl: userData.photoURL || '',
        displayName: userData.displayName || userData.name || 'Host',
        language: userData.language || '',
        country: userData.country || '',
        level: userData.level || 1,
        approvedAt: userData.hostApprovedAt || admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: userData.approvedBy || 'migration',
        isActive: true,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        followersCount: userData.followersCount || 0,
        followingCount: userData.followingCount || 0,
        gender: userData.gender || '',
      }, { merge: true });
      
      count++;
      batchCount++;
      
      // Commit in batches of 500 (Firestore limit)
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`✅ Migrated ${count} hosts...`);
        batchCount = 0;
      }
    }
    
    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
    }
    
    console.log(`✅ Migration complete! Migrated ${count} approved hosts to approvedHosts collection`);
    console.log('💡 The Cloud Function will now keep this collection in sync automatically');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration error:', error);
    process.exit(1);
  }
}

// Run migration
migrateApprovedHosts();
