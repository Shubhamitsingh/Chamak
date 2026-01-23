/**
 * Firebase Admin SDK Script to Create Sample Banners
 * 
 * Usage:
 * 1. Install Firebase Admin SDK: npm install firebase-admin
 * 2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable
 * 3. Run: node scripts/create_sample_banner.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (adjust path to your service account key)
const serviceAccount = require('../path/to/your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createSampleBanners() {
  const banners = [
    {
      imageUrl: 'https://via.placeholder.com/800x200/FF1B7C/FFFFFF?text=Welcome+Banner',
      title: 'Welcome to Chamak',
      description: 'Discover amazing live streams',
      actionType: 'none',
      actionTarget: null,
      priority: 5,
      isActive: true,
      startDate: null,
      endDate: null,
      targetAudience: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'admin',
      impressions: 0,
      clicks: 0,
    },
    {
      imageUrl: 'https://via.placeholder.com/800x200/FFB800/FFFFFF?text=Wallet+Promotion',
      title: 'Special Wallet Offer',
      description: 'Get coins and enjoy premium features',
      actionType: 'navigate',
      actionTarget: 'wallet_screen',
      priority: 8,
      isActive: true,
      startDate: null,
      endDate: null,
      targetAudience: {
        minLevel: 1,
        maxLevel: 100,
        userTypes: ['all'],
        countries: [],
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'admin',
      impressions: 0,
      clicks: 0,
    },
    {
      imageUrl: 'https://via.placeholder.com/800x200/8B5CF6/FFFFFF?text=Events+%26+Promotions',
      title: 'Check Out Events',
      description: 'See upcoming events and announcements',
      actionType: 'navigate',
      actionTarget: 'event_screen',
      priority: 6,
      isActive: true,
      startDate: null,
      endDate: null,
      targetAudience: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'admin',
      impressions: 0,
      clicks: 0,
    },
  ];

  try {
    console.log('🚀 Creating sample banners...');
    
    for (const banner of banners) {
      const docRef = await db.collection('banners').add(banner);
      console.log(`✅ Created banner: ${docRef.id}`);
    }
    
    console.log('🎉 All banners created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating banners:', error);
    process.exit(1);
  }
}

createSampleBanners();
