/**
 * Firebase Cloud Function to verify and process gift transactions
 * This ensures secure coin conversion and prevents cheating
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Conversion rate (same as in Flutter app)
const U_TO_C_RATIO = 5.0; // 1 U Coin = 5 C Coins
const PLATFORM_COMMISSION = 0.80; // 80% platform, 20% host

exports.verifyAndProcessGift = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const { receiverId, giftType, uCoinCost } = data;
  const senderId = context.auth.uid;
  
  // Validate input
  if (!receiverId || !giftType || !uCoinCost) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }
  
  const db = admin.firestore();
  
  try {
    // Run transaction to ensure atomicity
    const result = await db.runTransaction(async (transaction) => {
      // Get sender document
      const senderRef = db.collection('users').doc(senderId);
      const senderDoc = await transaction.get(senderRef);
      
      if (!senderDoc.exists) {
        throw new Error('Sender not found');
      }
      
      const senderData = senderDoc.data();
      const currentUCoins = senderData.uCoins || 0;
      
      // Check if user has enough U Coins
      if (currentUCoins < uCoinCost) {
        throw new Error('Insufficient U Coins');
      }
      
      // Get receiver document
      const receiverRef = db.collection('users').doc(receiverId);
      const receiverDoc = await transaction.get(receiverRef);
      
      if (!receiverDoc.exists) {
        throw new Error('Receiver not found');
      }
      
      // Calculate C Coins to give host
      const cCoinsToGive = Math.round(uCoinCost * U_TO_C_RATIO);
      
      // Update sender: deduct U Coins
      transaction.update(senderRef, {
        uCoins: admin.firestore.FieldValue.increment(-uCoinCost)
      });
      
      // Update receiver: add C Coins
      transaction.update(receiverRef, {
        cCoins: admin.firestore.FieldValue.increment(cCoinsToGive)
      });
      
      // Create gift record
      const giftRef = db.collection('gifts').doc();
      transaction.set(giftRef, {
        senderId: senderId,
        receiverId: receiverId,
        giftType: giftType,
        uCoinsSpent: uCoinCost,
        cCoinsEarned: cCoinsToGive,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        senderName: senderData.displayName || 'User',
        receiverName: receiverDoc.data().displayName || 'Host'
      });
      
      // Update earnings summary
      const earningsRef = db.collection('earnings').doc(receiverId);
      transaction.set(earningsRef, {
        userId: receiverId,
        totalCCoins: admin.firestore.FieldValue.increment(cCoinsToGive),
        totalGiftsReceived: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      return {
        success: true,
        uCoinsSpent: uCoinCost,
        cCoinsEarned: cCoinsToGive,
        newSenderBalance: currentUCoins - uCoinCost
      };
    });
    
    return result;
    
  } catch (error) {
    console.error('Error processing gift:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to process gift'
    );
  }
});

/**
 * Calculate withdrawal amount for host
 * C Coins → Real Money (INR)
 */
exports.calculateWithdrawal = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { cCoins } = data;
  const C_COIN_RUPEE_VALUE = 0.20; // 1 C Coin = ₹0.20
  
  const withdrawalAmount = cCoins * C_COIN_RUPEE_VALUE;
  
  return {
    cCoins: cCoins,
    withdrawalAmount: withdrawalAmount,
    currency: 'INR'
  };
});


































