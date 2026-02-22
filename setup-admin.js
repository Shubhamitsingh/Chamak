/**
 * Quick Admin Setup Script
 * Creates admin user in Firestore
 * 
 * Usage:
 * 1. Download service account key from Firebase Console
 * 2. Save as: service-account.json
 * 3. Run: node setup-admin.js
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function setupAdmin() {
  console.log('\n🔧 Admin Setup Tool\n');
  console.log('This will create an admin user in Firestore.\n');
  
  // Get admin UID
  const uid = await question('Enter admin user UID (from Firebase Console → Authentication → Users): ');
  
  if (!uid || uid.trim() === '') {
    console.log('❌ UID is required!');
    rl.close();
    return;
  }
  
  // Get admin email
  const email = await question('Enter admin email (optional): ');
  
  // Get admin name
  const name = await question('Enter admin name (optional): ');
  
  try {
    // Create admin document
    await db.collection('admins').doc(uid).set({
      isAdmin: true,
      email: email || '',
      displayName: name || 'Admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'setup-script'
    });
    
    console.log('\n✅ Admin user created successfully!');
    console.log(`\nAdmin Details:`);
    console.log(`  UID: ${uid}`);
    console.log(`  Email: ${email || 'N/A'}`);
    console.log(`  Name: ${name || 'Admin'}`);
    console.log(`\n✅ Admin can now access admin panel features!`);
    
  } catch (error) {
    console.error('\n❌ Error creating admin:', error.message);
    
    if (error.code === 'permission-denied') {
      console.log('\n⚠️ Permission denied. Make sure:');
      console.log('  1. Service account has admin access');
      console.log('  2. Firestore rules allow admin creation');
      console.log('  3. Using correct service account key');
    }
  }
  
  rl.close();
}

setupAdmin().catch(error => {
  console.error('❌ Fatal error:', error);
  rl.close();
  process.exit(1);
});
