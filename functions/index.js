/**
 * Firebase Cloud Functions for Chamak App - Notification System
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options
setGlobalOptions({maxInstances: 10});

/**
 * Send notification when a new message notification request is created
 */
exports.sendMessageNotification = onDocumentCreated(
    "notificationRequests/{requestId}",
    async (event) => {
      try {
        const data = event.data.data();

        // Check if already processed
        if (data.processed) {
          console.log("Notification already processed");
          return null;
        }

        const {token, notification, data: messageData} = data;

        if (!token) {
          console.error("No FCM token provided");
          return null;
        }

        // Determine notification channel based on type
        const notificationType = messageData?.type || "message";
        const channelId = notificationType === "coin_addition" 
          ? "chamak_wallet" 
          : "chamak_messages";

        // Prepare the notification message
        const message = {
          notification: {
            title: notification.title || "New Message",
            body: notification.body || "You have a new message",
          },
          data: messageData || {},
          token: token,
          android: {
            priority: "high",
            notification: {
              channelId: channelId,
              sound: "default",
              priority: "high",
              defaultVibrateTimings: true,
              defaultSound: true,
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                alert: {
                  title: notification.title || "New Message",
                  body: notification.body || "You have a new message",
                },
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send the notification
        const response = await admin.messaging().send(message);
        console.log("✅ Successfully sent message:", response);

        // Mark as processed
        await event.data.ref.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          response: response,
        });

        return response;
      } catch (error) {
        console.error("❌ Error sending message:", error);

        // Update document with error
        await event.data.ref.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: error.message,
        });

        return null;
      }
    },
);

/**
 * Clean up old notification requests (older than 7 days)
 * Runs every 24 hours
 */
exports.cleanupOldNotifications = onSchedule("every 24 hours", async () => {
  try {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7); // 7 days ago

    const snapshot = await admin.firestore()
        .collection("notificationRequests")
        .where("createdAt", "<", cutoff)
        .where("processed", "==", true)
        .get();

    if (snapshot.empty) {
      console.log("No old notifications to clean up");
      return null;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ Cleaned up ${snapshot.size} old notification requests`);

    return null;
  } catch (error) {
    console.error("❌ Error cleaning up notifications:", error);
    return null;
  }
});

/**
 * Send notification when a user receives a new follower
 */
exports.sendFollowerNotification = onDocumentCreated(
    "users/{userId}/followers/{followerId}",
    async (event) => {
      try {
        const userId = event.params.userId;
        const followerId = event.params.followerId;

        // Get the user being followed
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();

        if (!userDoc.exists || !userDoc.data().fcmToken) {
          console.log("User has no FCM token");
          return null;
        }

        // Get the follower's info
        const followerDoc = await admin.firestore()
            .collection("users")
            .doc(followerId)
            .get();

        if (!followerDoc.exists) {
          console.log("Follower not found");
          return null;
        }

        const followerName = followerDoc.data().displayName || "Someone";
        const userToken = userDoc.data().fcmToken;

        const message = {
          notification: {
            title: "New Follower! 🎉",
            body: `${followerName} started following you`,
          },
          data: {
            type: "follower",
            followerId: followerId,
          },
          token: userToken,
          android: {
            priority: "high",
            notification: {
              channelId: "chamak_messages",
              sound: "default",
            },
          },
        };

        const response = await admin.messaging().send(message);
        console.log("✅ Follower notification sent:", response);

        return response;
      } catch (error) {
        console.error("❌ Error sending follower notification:", error);
        return null;
      }
    },
);

/**
 * Test function to send a notification
 */
exports.testNotification = onCall({}, async (request) => {
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const {token, title, body} = request.data;

  if (!token) {
    throw new Error("FCM token is required");
  }

  try {
    const message = {
      notification: {
        title: title || "Test Notification",
        body: body || "This is a test notification from Chamak",
      },
      token: token,
    };

    const response = await admin.messaging().send(message);
    console.log("✅ Test notification sent:", response);

    return {success: true, messageId: response};
  } catch (error) {
    console.error("❌ Error sending test notification:", error);
    throw new Error(error.message);
  }
});

/**
 * PayPrime IPN (Instant Payment Notification) Handler
 * 
 * This function receives payment callbacks from PayPrime after a user completes payment.
 * It verifies the payment signature and adds coins to the user's account.
 * 
 * PayPrime sends POST request with form-urlencoded data:
 * - status: Payment status ("success" or "failed")
 * - identifier: Order identifier (max 20 chars)
 * - signature: HMAC SHA256 signature for verification
 * - data: Payment details (JSON string or object with amount, currency, transaction_id, etc.)
 * 
 * IPN URL will be: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/payprimeIPN
 */
exports.payprimeIPN = onRequest(
  {
    secrets: ["PAYPRIME_SECRET_KEY"],
    cors: true, // Allow CORS for PayPrime requests
  },
  async (req, res) => {
    try {
      // Only accept POST requests
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      // PayPrime sends POST with form-urlencoded data
      // Parse the request body
      const {status, identifier, signature, data} = req.body;

      // Handle data - it might be a JSON string or already an object
      let paymentData;
      if (typeof data === "string") {
        try {
          paymentData = JSON.parse(data);
        } catch (e) {
          paymentData = {};
        }
      } else {
        paymentData = data || {};
      }

      console.log("🔔 PayPrime IPN received:");
      console.log(`   Status: ${status}`);
      console.log(`   Identifier: ${identifier}`);
      console.log(`   Data: ${JSON.stringify(data)}`);

      // Validate required fields
      if (!status || !identifier || !signature || !paymentData) {
        console.error("❌ Missing required fields in IPN");
        res.status(400).send({success: false, message: "Missing required fields"});
        return;
      }

      // Get secret key from environment
      const secretKey = process.env.PAYPRIME_SECRET_KEY;
      if (!secretKey) {
        console.error("❌ PAYPRIME_SECRET_KEY not configured");
        res.status(500).send({success: false, message: "Secret key not configured"});
        return;
      }

      // Verify signature
      // PayPrime signature: HMAC SHA256 of (amount + identifier) using secret key
      const crypto = require("crypto");
      const amountFromData = paymentData.amount?.toString() || paymentData.amount;
      const customKey = `${amountFromData}${identifier}`;
      const expectedSignature = crypto
          .createHmac("sha256", secretKey)
          .update(customKey)
          .digest("hex")
          .toUpperCase();

      console.log(`🔐 Signature Verification:`);
      console.log(`   Custom Key: ${customKey}`);
      console.log(`   Expected: ${expectedSignature}`);
      console.log(`   Received: ${signature}`);

      if (signature.toUpperCase() !== expectedSignature.toUpperCase()) {
        console.error("❌ Invalid signature - payment verification failed");
        res.status(400).send({success: false, message: "Invalid signature"});
        return;
      }

      // Find order by identifier
      const ordersSnapshot = await admin.firestore()
          .collection("orders")
          .where("identifier", "==", identifier)
          .limit(1)
          .get();

      if (ordersSnapshot.empty) {
        console.error(`❌ Order not found for identifier: ${identifier}`);
        res.status(404).send({success: false, message: "Order not found"});
        return;
      }

      const orderDoc = ordersSnapshot.docs[0];
      const orderData = orderDoc.data();
      const orderId = orderDoc.id;
      const userId = orderData.userId;
      const coins = orderData.coins;
      const amount = orderData.amount;
      const packageId = orderData.packageId;

      console.log(`📦 Order found:`);
      console.log(`   Order ID: ${orderId}`);
      console.log(`   User ID: ${userId}`);
      console.log(`   Coins: ${coins}`);
      console.log(`   Amount: ${amount}`);

      // Check payment status
      if (status !== "success") {
        console.log(`⚠️ Payment status is not success: ${status}`);
        // Update order status to failed
        await orderDoc.ref.update({
          status: "failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          failureReason: `Payment status: ${status}`,
        });
        res.status(200).send({success: false, message: `Payment status: ${status}`});
        return;
      }

      // Check if payment already processed (prevent duplicates)
      const existingPayment = await admin.firestore()
          .collection("payments")
          .where("orderId", "==", orderId)
          .where("status", "==", "completed")
          .limit(1)
          .get();

      if (!existingPayment.empty) {
        console.log("✅ Payment already processed");
        res.status(200).send({
          success: true,
          message: "Payment already processed",
          coins: coins,
        });
        return;
      }

      // Get payment transaction ID
      const paymentId = paymentData.payment_transaction_id ||
                       paymentData.transaction_id ||
                       paymentData.payment_trx ||
                       orderId;

      // Add coins to user account
      // Update users collection (primary source of truth)
      const userRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        console.error(`❌ User not found: ${userId}`);
        res.status(404).send({success: false, message: "User not found"});
        return;
      }

      const currentCoins = userDoc.data().uCoins || 0;
      const newCoins = currentCoins + coins;

      // Update user's coin balance
      await userRef.update({
        uCoins: newCoins,
        coins: newCoins, // Also update coins field for compatibility
      });

      // Update wallets collection (secondary)
      const walletRef = admin.firestore().collection("wallets").doc(userId);
      await walletRef.set({
        balance: newCoins,
        coins: newCoins,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      console.log(`💰 Coins added: ${currentCoins} → ${newCoins} (+${coins})`);

      // Update order status
      await orderDoc.ref.update({
        status: "completed",
        paymentId: paymentId,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Record payment in payments collection
      await admin.firestore().collection("payments").doc(paymentId).set({
        userId: userId,
        packageId: packageId,
        coins: coins,
        amount: amount,
        paymentId: paymentId,
        orderId: orderId,
        identifier: identifier,
        status: "completed",
        paymentMethod: "payprime",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Record transaction
      await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .doc(paymentId)
          .set({
            type: "purchase",
            coins: coins,
            amount: amount,
            paymentId: paymentId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            description: "Coin purchase via PayPrime",
          });

      console.log("✅ Payment verified and coins added successfully!");

      // Return success response to PayPrime
      res.status(200).send({
        success: true,
        message: "Payment verified and coins added successfully",
        coins: coins,
        amount: amount,
      });
    } catch (error) {
      console.error("❌ Error processing PayPrime IPN:", error);
      res.status(500).send({
        success: false,
        message: `Error processing IPN: ${error.message}`,
      });
    }
  },
);

/**
 * Generate Agora Token for Live Streaming
 * 
 * This function generates a secure Agora token for users to join channels.
 * Tokens are generated server-side using App Secret (never exposed to client).
 * 
 * Required parameters:
 * - channelName: The Agora channel name (string)
 * - uid: User ID (number, 0 for auto-assign)
 * - role: "host" or "audience" (string, default: "host")
 * 
 * Returns:
 * - token: Generated Agora token (string)
 * - expiresAt: Token expiration timestamp (number)
 */
exports.generateAgoraToken = onCall(
  {
    secrets: ["AGORA_APP_ID", "AGORA_APP_CERTIFICATE"],
  },
  async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const {channelName, uid, role = "host"} = request.data;

  // Validate required parameters
  if (!channelName || typeof channelName !== "string") {
    throw new Error("channelName is required and must be a string");
  }

  // Handle uid: can be undefined, null, or a non-negative number
  // Flutter may send null instead of undefined
  if (uid !== undefined && uid !== null && (typeof uid !== "number" || uid < 0)) {
    throw new Error("uid must be a non-negative number, null, or undefined");
  }

  // Get Agora credentials from environment variables
  // These will be set using: firebase functions:secrets:set AGORA_APP_ID
  // Or set in Firebase Console: Functions → Configuration → Environment Variables
  let appId = process.env.AGORA_APP_ID;
  let appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId || !appCertificate) {
    console.error("❌ Agora credentials not configured");
    throw new Error(
      "Agora credentials not configured. " +
      "Please set AGORA_APP_ID and AGORA_APP_CERTIFICATE in Firebase Functions config."
    );
  }

  // Trim whitespace and newlines (common issue with secrets)
  appId = appId.trim();
  appCertificate = appCertificate.trim();
  
  console.log(`🔍 After trimming:`);
  console.log(`   App ID length: ${appId.length}`);
  console.log(`   Certificate length: ${appCertificate.length}`);

  // Debug logging (remove sensitive data in production)
  console.log(`🔑 Using App ID: ${appId.substring(0, 8)}...`);
  console.log(`🔑 Using Certificate: ${appCertificate.substring(0, 8)}...`);
  console.log(`📋 Channel: ${channelName}, UID: ${uid}, Role: ${role}`);

  try {
    // Determine user role
    // host = broadcaster (can publish video/audio)
    // audience = subscriber (can only receive)
    const userRole = role === "host" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    // Calculate expiration time (24 hours from now)
    const expirationTimeInSeconds = Math.floor(Date.now() / 1000) + (24 * 60 * 60);
    const currentTimestamp = Math.floor(Date.now() / 1000);

    // Use provided UID or 0 (Agora will auto-assign)
    // Handle both undefined and null from Flutter
    const userId = (uid !== undefined && uid !== null) ? uid : 0;

    // Generate token
    console.log(`🔑 Generating token with:`);
    console.log(`   App ID: ${appId.substring(0, 8)}... (full length: ${appId.length})`);
    console.log(`   Certificate: ${appCertificate.substring(0, 8)}... (full length: ${appCertificate.length})`);
    console.log(`   Channel: ${channelName} (length: ${channelName.length})`);
    console.log(`   UID: ${userId} (type: ${typeof userId})`);
    console.log(`   Role: ${userRole === RtcRole.PUBLISHER ? 'PUBLISHER' : 'SUBSCRIBER'} (value: ${userRole})`);
    console.log(`   Expiration: ${expirationTimeInSeconds} (type: ${typeof expirationTimeInSeconds})`);
    
    // Validate inputs before calling token builder
    if (!appId || appId.length === 0) {
      throw new Error('App ID is empty or invalid');
    }
    if (!appCertificate || appCertificate.length === 0) {
      throw new Error('App Certificate is empty or invalid');
    }
    if (!channelName || channelName.length === 0) {
      throw new Error('Channel name is empty or invalid');
    }
    if (typeof userId !== 'number' || userId < 0) {
      throw new Error(`Invalid UID: ${userId} (type: ${typeof userId})`);
    }
    if (typeof expirationTimeInSeconds !== 'number' || expirationTimeInSeconds <= 0) {
      throw new Error(`Invalid expiration: ${expirationTimeInSeconds} (type: ${typeof expirationTimeInSeconds})`);
    }
    
    console.log(`✅ All parameters validated, calling buildTokenWithUid...`);
    
    // Try-catch around token generation to catch any errors
    let token;
    try {
      token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        userId,
        userRole,
        expirationTimeInSeconds
      );
    } catch (tokenError) {
      console.error(`❌ Token builder threw error:`, tokenError);
      console.error(`   Error message: ${tokenError.message}`);
      console.error(`   Error stack: ${tokenError.stack}`);
      throw new Error(`Token builder error: ${tokenError.message}`);
    }
    
    console.log(`📦 Token builder returned:`);
    console.log(`   Value: ${token}`);
    console.log(`   Type: ${typeof token}`);
    console.log(`   Is null: ${token === null}`);
    console.log(`   Is undefined: ${token === undefined}`);
    console.log(`   Length: ${token ? token.length : 'N/A'}`);

    console.log(`✅ Token generated:`);
    console.log(`   Token length: ${token ? token.length : 'NULL/UNDEFINED'}`);
    console.log(`   Token preview: ${token ? token.substring(0, 20) : 'NULL/UNDEFINED'}...`);
    console.log(`   Token type: ${typeof token}`);
    console.log(`   Token is empty: ${!token || token.length === 0}`);

    if (!token || token.length === 0) {
      throw new Error('Token generation returned empty or null token');
    }

    return {
      success: true,
      token: token,
      channelName: channelName,
      uid: userId,
      role: role,
      expiresAt: expirationTimeInSeconds,
      expiresIn: expirationTimeInSeconds - currentTimestamp, // seconds until expiration
    };
  } catch (error) {
    console.error("❌ Error generating Agora token:", error);
    throw new Error(`Failed to generate token: ${error.message}`);
  }
});
