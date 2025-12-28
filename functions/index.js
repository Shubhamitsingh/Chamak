/**
 * Firebase Cloud Functions for Chamak App - Notification System
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
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
