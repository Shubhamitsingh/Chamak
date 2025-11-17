/**
 * 🔍 CHECK FIRESTORE CONNECTION
 * 
 * This script checks if your backend can connect to Firebase
 * and read/write announcements
 * 
 * HOW TO USE:
 * 1. Put your service account JSON in: server/chamak-firebase-adminsdk.json
 * 2. Run: node check-firestore-connection.js
 */

const admin = require('firebase-admin');
const path = require('path');

console.log('🔍 FIRESTORE CONNECTION TEST\n');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Try to load service account
let serviceAccount;
try {
  serviceAccount = require('./server/chamak-firebase-adminsdk.json');
  console.log('✅ Service account file found!');
  console.log('📧 Project:', serviceAccount.project_id);
  console.log('👤 Client:', serviceAccount.client_email);
  console.log('');
} catch (error) {
  console.log('❌ SERVICE ACCOUNT FILE NOT FOUND!');
  console.log('\n📍 Expected location: server/chamak-firebase-adminsdk.json');
  console.log('\n💡 How to fix:');
  console.log('   1. Go to: https://console.firebase.google.com/');
  console.log('   2. Select your project');
  console.log('   3. Settings → Service Accounts');
  console.log('   4. Generate new private key');
  console.log('   5. Save as: server/chamak-firebase-adminsdk.json');
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  process.exit(1);
}

// Initialize Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin initialized!\n');
} catch (error) {
  console.log('❌ FIREBASE INITIALIZATION FAILED!');
  console.log('\nError:', error.message);
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  process.exit(1);
}

const db = admin.firestore();

// Test Firestore connection
async function testFirestore() {
  try {
    console.log('📡 Testing Firestore connection...\n');
    
    // Test 1: Check if we can read announcements collection
    console.log('📋 Test 1: Reading announcements collection...');
    const announcementsSnapshot = await db.collection('announcements')
      .where('isActive', '==', true)
      .get();
    
    console.log(`✅ Success! Found ${announcementsSnapshot.size} announcements\n`);
    
    if (announcementsSnapshot.size > 0) {
      console.log('📄 Existing announcements:');
      announcementsSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`\n   ${index + 1}. ${data.title}`);
        console.log(`      Date: ${data.date}`);
        console.log(`      Status: ${data.isNew ? '🆕 NEW' : '📌 Old'}`);
      });
      console.log('');
    } else {
      console.log('💡 No announcements found yet - this is normal for new setup!\n');
    }
    
    // Test 2: Try to create a test announcement
    console.log('📋 Test 2: Creating test announcement...');
    const testDoc = await db.collection('announcements').add({
      title: '🧪 Test from Connection Script',
      description: 'This is an automated test. If you see this in your Flutter app, everything is working!',
      date: new Date().toLocaleDateString('en-GB', { 
        day: '2-digit', 
        month: 'short', 
        year: 'numeric' 
      }),
      time: 'Live Now',
      type: 'announcement',
      color: 0xFF10B981,  // Green
      iconName: 'celebration',
      isNew: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    });
    
    console.log(`✅ Success! Created with ID: ${testDoc.id}\n`);
    
    // Test 3: Try to read it back
    console.log('📋 Test 3: Reading back the test announcement...');
    const testDocData = await testDoc.get();
    if (testDocData.exists) {
      console.log('✅ Success! Document exists and can be read\n');
    }
    
    // Test 4: Clean up (delete test announcement)
    console.log('📋 Test 4: Cleaning up test data...');
    await testDoc.update({ isActive: false });
    console.log('✅ Success! Test data cleaned up\n');
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 ALL TESTS PASSED!');
    console.log('\n✅ Your backend CAN connect to Firebase');
    console.log('✅ Your backend CAN read announcements');
    console.log('✅ Your backend CAN write announcements');
    console.log('✅ Your Flutter app SHOULD see announcements in real-time');
    console.log('\n📱 Next steps:');
    console.log('   1. Start backend: node server/index.js');
    console.log('   2. Create announcement: node create-test-announcement.js');
    console.log('   3. Check Flutter app');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
  } catch (error) {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('❌ FIRESTORE TEST FAILED!');
    console.log('\nError:', error.message);
    console.log('\n💡 Common issues:');
    console.log('   1. Firestore not enabled in Firebase Console');
    console.log('   2. Security rules blocking access');
    console.log('   3. Network/internet connection issue');
    console.log('   4. Invalid service account credentials');
    console.log('\n💡 How to fix:');
    console.log('   1. Go to Firebase Console → Firestore Database');
    console.log('   2. Make sure Firestore is created');
    console.log('   3. Check Rules → set to test mode temporarily');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
  
  process.exit(0);
}

// Run tests
testFirestore();



