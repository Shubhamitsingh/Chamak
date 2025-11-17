/**
 * 🧪 CREATE TEST ANNOUNCEMENT
 * 
 * Simple script to test if announcements are working
 * 
 * HOW TO USE:
 * 1. Make sure backend server is running (node server/index.js)
 * 2. Run this script: node create-test-announcement.js
 * 3. Check Flutter app - announcement should appear!
 */

const https = require('http');

const data = JSON.stringify({
  title: "🎉 Test Announcement from Script!",
  description: "If you see this in your Flutter app, announcements are WORKING! This was created using the test script.",
  date: new Date().toLocaleDateString('en-GB', { 
    day: '2-digit', 
    month: 'short', 
    year: 'numeric' 
  }),
  time: "Live Now",
  color: 4280287222,  // Blue
  iconName: "celebration",
  isNew: true
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/announcements',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

console.log('🚀 Creating test announcement...\n');
console.log('📊 Data:', JSON.parse(data));
console.log('\n📡 Sending request to: http://localhost:5000/api/announcements\n');

const req = https.request(options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📥 Response Status:', res.statusCode);
    console.log('📦 Response Body:', responseData);
    
    try {
      const response = JSON.parse(responseData);
      
      if (response.success) {
        console.log('\n✅ SUCCESS!');
        console.log('🎉 Announcement created with ID:', response.id);
        console.log('\n📱 CHECK YOUR FLUTTER APP NOW!');
        console.log('   The announcement should appear within 1-2 seconds!');
        console.log('\n🔍 You can also check:');
        console.log('   - Firebase Console → Firestore → announcements collection');
        console.log('   - Flutter app → Profile → Event → Announcements tab');
        console.log('   - Flutter app → Home → 🔥 icon → Announcement panel');
      } else {
        console.log('\n❌ FAILED!');
        console.log('Error:', response.error || 'Unknown error');
        console.log('\n💡 Troubleshooting:');
        console.log('   1. Make sure backend server is running');
        console.log('   2. Check server terminal for errors');
        console.log('   3. Verify Firebase Admin SDK is initialized');
      }
    } catch (e) {
      console.log('\n❌ ERROR parsing response!');
      console.log('Raw response:', responseData);
    }
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  });
});

req.on('error', (error) => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('❌ CONNECTION ERROR!');
  console.log('\nError:', error.message);
  console.log('\n💡 Make sure backend server is running:');
  console.log('   node server/index.js');
  console.log('\n💡 Check if port 5000 is available');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
});

req.write(data);
req.end();



