/**
 * 🔍 TEST SCRIPT FOR ADMIN PANEL
 * 
 * This script tests if your admin panel backend can connect to Firebase
 * and fetch support tickets.
 * 
 * HOW TO USE:
 * 1. Make sure you have the Firebase Admin SDK service account JSON file
 * 2. Update the path below to match your file location
 * 3. Run: node test-admin-backend.js
 */

const admin = require('firebase-admin');

// ⚠️ UPDATE THIS PATH TO YOUR SERVICE ACCOUNT FILE!
// Example: './server/chamak-firebase-adminsdk.json'
const serviceAccount = require('./YOUR_SERVICE_ACCOUNT_FILE.json');

console.log('🔍 Starting Admin Panel Backend Test...\n');

// Initialize Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin SDK initialized successfully!\n');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:');
  console.error(error.message);
  console.error('\n💡 Make sure you have the service account JSON file!');
  console.error('Download from: Firebase Console → Settings → Service Accounts → Generate New Private Key\n');
  process.exit(1);
}

const db = admin.firestore();

// Test Firestore connection and fetch tickets
async function testTickets() {
  try {
    console.log('📡 Connecting to Firestore...');
    
    // Fetch all tickets from supportTickets collection
    const ticketsSnapshot = await db.collection('supportTickets').get();
    
    console.log('✅ Connected to Firestore successfully!\n');
    console.log('📊 RESULTS:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log(`   Total Tickets Found: ${ticketsSnapshot.size}`);
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    if (ticketsSnapshot.size === 0) {
      console.log('⚠️  No tickets found in Firestore!');
      console.log('   Make sure tickets exist in Firebase Console.');
    } else {
      console.log('📄 TICKET DETAILS:\n');
      
      ticketsSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`   Ticket #${index + 1}:`);
        console.log(`   ├─ ID: ${doc.id}`);
        console.log(`   ├─ User: ${data.userName || 'Unknown'}`);
        console.log(`   ├─ Phone: ${data.userPhone || 'N/A'}`);
        console.log(`   ├─ Category: ${data.category || 'N/A'}`);
        console.log(`   ├─ Status: ${data.status || 'N/A'}`);
        console.log(`   ├─ Description: ${(data.description || '').substring(0, 50)}...`);
        
        // Check if timestamps are valid
        if (data.createdAt) {
          const timestamp = data.createdAt._seconds 
            ? new Date(data.createdAt._seconds * 1000) 
            : data.createdAt.toDate();
          console.log(`   └─ Created: ${timestamp.toLocaleString()}`);
        }
        console.log('');
      });
      
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      console.log('✅ TEST PASSED!');
      console.log('   Your backend CAN connect to Firebase and fetch tickets.');
      console.log('\n💡 Next Steps:');
      console.log('   1. Make sure your backend server (server/index.js) is running');
      console.log('   2. Test the API endpoint: http://localhost:5000/api/tickets');
      console.log('   3. Check React component is calling the API correctly');
    }
    
  } catch (error) {
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.error('❌ TEST FAILED!');
    console.error('\n💥 Error:', error.message);
    console.error('\n📋 Common Issues:');
    console.error('   1. Wrong collection name (should be "supportTickets")');
    console.error('   2. Firestore security rules blocking access');
    console.error('   3. Invalid service account credentials');
    console.error('   4. Network/connection issues');
    console.error('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
  
  process.exit(0);
}

// Run the test
testTickets();




