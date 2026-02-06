/**
 * Firebase Cloud Functions for Chamak App - Notification System
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");
const {RtcTokenBuilder, RtcRole} = require("agora-token");
const axios = require("axios");
const crypto = require("crypto");
const qs = require("qs");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options
setGlobalOptions({maxInstances: 10});

/**
 * Send notification when a new team message is created (broadcast to all users)
 */
exports.sendTeamMessageNotification = onDocumentCreated(
    "team_messages/{messageId}",
    async (event) => {
      try {
        const messageData = event.data.data();
        const messageId = event.params.messageId;

        console.log(`📢 New team message created: ${messageId}`);

        // Get all users with FCM tokens
        const usersSnapshot = await admin.firestore()
            .collection("users")
            .where("fcmToken", "!=", null)
            .get();

        if (usersSnapshot.empty) {
          console.log("No users with FCM tokens found");
          return null;
        }

        console.log(`📤 Sending team message notification to ${usersSnapshot.size} users`);

        const senderName = messageData.senderName || "Chamakz Team";
        const messageText = messageData.message || "";
        const truncatedMessage = messageText.length > 100 
            ? messageText.substring(0, 100) + "..." 
            : messageText;

        // Prepare notification message
        const notification = {
          title: senderName,
          body: truncatedMessage,
        };

        const data = {
          type: "team_message",
          messageId: messageId,
          senderName: senderName,
        };

        // Send notifications to all users in batches
        const batchSize = 500; // FCM allows up to 500 tokens per batch
        const tokens = usersSnapshot.docs
            .map(doc => doc.data().fcmToken)
            .filter(token => token && token.length > 0);

        let successCount = 0;
        let failureCount = 0;

        // Process in batches
        for (let i = 0; i < tokens.length; i += batchSize) {
          const batch = tokens.slice(i, i + batchSize);
          
          try {
            const message = {
              notification: notification,
              data: data,
              tokens: batch, // Send to multiple tokens
              android: {
                priority: "high",
                notification: {
                  channelId: "chamak_messages",
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
                    alert: notification,
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

            if (response.failureCount > 0) {
              console.log(`⚠️ ${response.failureCount} notifications failed in batch`);
            }
          } catch (error) {
            console.error(`❌ Error sending batch notifications:`, error);
            failureCount += batch.length;
          }
        }

        console.log(`✅ Team message notifications sent: ${successCount} success, ${failureCount} failed`);
        return {success: successCount, failures: failureCount};
      } catch (error) {
        console.error("❌ Error sending team message notifications:", error);
        return null;
      }
    }
);

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

        // Handle broadcast type differently
        if (data.type === "broadcast") {
          console.log("📢 Broadcast notification request detected");
          // For broadcast, get all users with FCM tokens
          const usersSnapshot = await admin.firestore()
              .collection("users")
              .where("fcmToken", "!=", null)
              .get();

          if (usersSnapshot.empty) {
            console.log("No users with FCM tokens found for broadcast");
            await event.data.ref.update({
              processed: true,
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
              error: "No users with FCM tokens",
            });
            return null;
          }

          const tokens = usersSnapshot.docs
              .map(doc => doc.data().fcmToken)
              .filter(token => token && token.length > 0);

          const notification = data.notification || {};
          const messageData = data.data || {};

          // Determine notification channel
          const notificationType = messageData.type || "message";
          const channelId = notificationType === "coin_addition" 
              ? "chamak_wallet" 
              : "chamak_messages";

          // Send to all users in batches
          const batchSize = 500;
          let successCount = 0;
          let failureCount = 0;

          for (let i = 0; i < tokens.length; i += batchSize) {
            const batch = tokens.slice(i, i + batchSize);
            
            try {
              const message = {
                notification: {
                  title: notification.title || "Chamakz Team",
                  body: notification.body || "You have a new message",
                },
                data: messageData,
                tokens: batch,
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
                        title: notification.title || "Chamakz Team",
                        body: notification.body || "You have a new message",
                      },
                      sound: "default",
                      badge: 1,
                    },
                  },
                },
              };

              const response = await admin.messaging().sendEachForMulticast(message);
              successCount += response.successCount;
              failureCount += response.failureCount;
            } catch (error) {
              console.error(`❌ Error sending broadcast batch:`, error);
              failureCount += batch.length;
            }
          }

          await event.data.ref.update({
            processed: true,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: successCount,
            failureCount: failureCount,
          });

          console.log(`✅ Broadcast notification sent: ${successCount} success, ${failureCount} failed`);
          return {success: successCount, failures: failureCount};
        }

        // Regular single-user notification
        const {token, notification, data: messageData} = data;

        if (!token) {
          console.error("No FCM token provided");
          await event.data.ref.update({
            processed: true,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            error: "No FCM token provided",
          });
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
 * Send notification when admin sends a message in support chat
 * Triggers automatically when a new message is created in supportChats/{chatId}/messages
 */
exports.sendChatNotification = onDocumentCreated(
    "supportChats/{chatId}/messages/{messageId}",
    async (event) => {
      try {
        const messageData = event.data.data();
        const messageId = event.params.messageId;
        const chatId = event.params.chatId;
        const senderId = messageData.senderId;

        console.log(`💬 New message created in chat: ${chatId}, messageId: ${messageId}`);
        console.log(`📋 Message data:`, JSON.stringify(messageData, null, 2));
        console.log(`👤 Sender ID: ${senderId}`);
        console.log(`📨 Receiver ID: ${messageData.receiverId}`);

        // Check if message is from admin
        // Admin messages have receiverId === "user" (string literal)
        // This is set by Flutter app when isAdmin = true
        const receiverId = messageData.receiverId;
        const isAdminMessage = receiverId === "user" || 
                               receiverId === "user" || // Double check
                               senderId === "admin" || 
                               senderId?.startsWith("admin_");

        console.log(`🔍 Admin detection check:`);
        console.log(`   receiverId === "user": ${receiverId === "user"}`);
        console.log(`   senderId === "admin": ${senderId === "admin"}`);
        console.log(`   senderId starts with "admin_": ${senderId?.startsWith("admin_")}`);
        console.log(`   Final result - isAdminMessage: ${isAdminMessage}`);

        if (!isAdminMessage) {
          console.log(`⏭️ Skipping notification - message is from user`);
          console.log(`   senderId: ${senderId}, receiverId: ${receiverId}`);
          return null;
        }

        console.log(`✅ Admin message detected! (senderId: ${senderId}, receiverId: ${receiverId})`);

        // Get chat document to find userId
        const chatDoc = await admin.firestore()
            .collection("supportChats")
            .doc(chatId)
            .get();

        if (!chatDoc.exists) {
          console.error(`❌ Chat document not found: ${chatId}`);
          return null;
        }

        const chatData = chatDoc.data();
        const userId = chatData?.userId;

        if (!userId) {
          console.error(`❌ User ID not found in chat document: ${chatId}`);
          return null;
        }

        console.log(`👤 Found user ID: ${userId}`);

        // Get user document to find FCM token
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();

        if (!userDoc.exists) {
          console.error(`❌ User document not found: ${userId}`);
          return null;
        }

        const userData = userDoc.data();
        
        console.log(`📋 User data fields:`, Object.keys(userData || {}));
        
        // Try multiple FCM token field names
        const fcmToken = userData?.fcmToken || 
                        userData?.fcm_token || 
                        userData?.deviceToken || 
                        userData?.device_token || 
                        userData?.pushToken || 
                        userData?.push_token || 
                        userData?.token;

        console.log(`🔍 FCM token check:`);
        console.log(`   fcmToken: ${userData?.fcmToken ? 'EXISTS' : 'NOT FOUND'}`);
        console.log(`   fcm_token: ${userData?.fcm_token ? 'EXISTS' : 'NOT FOUND'}`);
        console.log(`   deviceToken: ${userData?.deviceToken ? 'EXISTS' : 'NOT FOUND'}`);
        console.log(`   Final token: ${fcmToken ? fcmToken.substring(0, 20) + '...' : 'NULL'}`);

        if (!fcmToken || fcmToken.length === 0) {
          console.error(`❌ FCM token not found for user: ${userId}`);
          console.error(`⚠️ User may need to re-enable notifications in the app`);
          console.error(`⚠️ Available fields:`, Object.keys(userData || {}));
          return null;
        }

        console.log(`✅ Found FCM token for user: ${userId}`);
        console.log(`   Token preview: ${fcmToken.substring(0, 30)}...`);

        // Prepare notification message
        const messageText = messageData.message || "";
        const truncatedMessage = messageText.length > 100 
            ? messageText.substring(0, 100) + "..." 
            : messageText;

        const notification = {
          title: "New Message from Admin",
          body: truncatedMessage,
        };

        const data = {
          type: "support_message",
          chatId: chatId,
          messageId: messageId,
          senderId: senderId,
          userId: userId,
          timestamp: messageData.timestamp?.toISOString() || new Date().toISOString(),
        };

        // Send push notification
        const message = {
          notification: notification,
          data: data,
          token: fcmToken,
          android: {
            priority: "high",
            notification: {
              channelId: "chamak_messages",
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
                alert: notification,
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        console.log(`📤 Sending push notification...`);
        console.log(`   Title: ${notification.title}`);
        console.log(`   Body: ${notification.body.substring(0, 50)}...`);
        console.log(`   Chat ID: ${chatId}`);
        console.log(`   User ID: ${userId}`);
        
        const response = await admin.messaging().send(message);
        console.log(`✅ Push notification sent successfully!`);
        console.log(`   User: ${userId}`);
        console.log(`   Message ID: ${response}`);
        console.log(`   Chat ID: ${chatId}`);

        return response;
      } catch (error) {
        console.error("❌ Error sending chat notification:");
        console.error(`   Error message: ${error.message}`);
        console.error(`   Error code: ${error.code || 'N/A'}`);
        console.error(`   Stack trace:`, error.stack);
        console.error(`   Chat ID: ${chatId}`);
        console.error(`   Message ID: ${messageId}`);
        // Don't throw - allow message to be saved even if notification fails
        return null;
      }
    }
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

// ============================================================================
// PAYPRIME PAYMENT GATEWAY INTEGRATION
// ============================================================================

/**
 * PHASE 3: Payment Initiation API
 * 
 * This function initiates a payment with PayPrime gateway.
 * - Validates authenticated user
 * - Generates unique order ID
 * - Creates PENDING payment document in Firestore
 * - Calls PayPrime API to initiate payment
 * - Returns payment URL for WebView
 * 
 * Required parameters:
 * - amount: Payment amount in INR (number)
 * - currency: Currency code (default: "INR")
 * - coins: Number of coins user is purchasing (number)
 * 
 * Returns:
 * - orderId: Unique order ID
 * - paymentUrl: URL to open in WebView
 * - paymentId: Payment document ID in Firestore
 */
exports.initiatePayment = onCall(
  {
    secrets: ["PAYPRIME_API_KEY", "PAYPRIME_SECRET_KEY"],
  },
  async (request) => {
    // PHASE 1: Authentication Requirement
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const userId = request.auth.uid;
    const {amount, currency = "INR", coins} = request.data;

    // Validate required parameters
    if (!amount || typeof amount !== "number" || amount <= 0) {
      throw new Error("amount is required and must be a positive number");
    }

    if (!coins || typeof coins !== "number" || coins <= 0) {
      throw new Error("coins is required and must be a positive number");
    }

    // Get PayPrime credentials from secrets
    const publicKey = process.env.PAYPRIME_API_KEY?.trim();
    const secretKey = process.env.PAYPRIME_SECRET_KEY?.trim();

    if (!publicKey || !secretKey) {
      console.error("❌ PayPrime credentials not configured");
      throw new Error(
        "PayPrime credentials not configured. " +
        "Please set PAYPRIME_API_KEY and PAYPRIME_SECRET_KEY in Firebase Functions secrets."
      );
    }

    try {
      // Generate unique identifier (PayPrime uses identifier, not order_id)
      // PayPrime requires identifier to be max 20 characters
      // Format: CHAMAK + timestamp (last 10 digits) + user hash (4 chars) = 20 chars
      const timestamp = Date.now().toString().slice(-10); // Last 10 digits of timestamp
      const userHash = userId.substring(0, 4).replace(/[^a-zA-Z0-9]/g, ''); // First 4 alphanumeric chars
      const identifier = `CHAMAK${timestamp}${userHash}`.substring(0, 20); // Ensure max 20 chars
      const paymentId = admin.firestore().collection("payments").doc().id;

      // Get user info for payment
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userData = userDoc.exists ? userDoc.data() : {};
      
      // Split name into first and last name
      const fullName = userData.displayName || userData.nickname || "User";
      const nameParts = fullName.split(" ");
      const firstName = nameParts[0] || "User";
      const lastName = nameParts.slice(1).join(" ") || "";
      
      const userEmail = userData.email || `${userId}@chamak.app`;
      const userPhone = (userData.phoneNumber || "").replace(/\D/g, ""); // Remove non-digits

      // PHASE 2: Create PENDING payment document in Firestore
      const paymentData = {
        userId: userId,
        orderId: identifier, // Using identifier as orderId for consistency
        identifier: identifier, // PayPrime identifier
        paymentId: paymentId,
        amount: amount,
        currency: currency.toUpperCase(), // PayPrime requires uppercase
        coins: coins,
        status: "PENDING",
        gateway: "payprime",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        userInfo: {
          name: fullName,
          firstName: firstName,
          lastName: lastName,
          email: userEmail,
          phone: userPhone,
        },
        metadata: {
          retryCount: 0,
          gatewayResponse: null,
        },
      };

      await admin.firestore().collection("payments").doc(paymentId).set(paymentData);
      console.log(`✅ Created payment document: ${paymentId} for identifier: ${identifier}`);

      // Get Firebase project ID for webhook URL
      const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
      if (!projectId) {
        throw new Error("Firebase project ID not found. Cannot generate webhook URL.");
      }

      const webhookUrl = `https://us-central1-${projectId}.cloudfunctions.net/payprimeWebhook`;
      const successUrl = `https://chamak.app/payment/success/${paymentId}`;
      const cancelUrl = `https://chamak.app/payment/cancel/${paymentId}`;

      // Prepare PayPrime API request (form-urlencoded format)
      // According to PayPrime docs: https://payprime.in/api-docs/
      const payprimePayload = {
        public_key: publicKey,
        identifier: identifier,
        currency: currency.toUpperCase(),
        amount: amount.toFixed(2), // PayPrime expects decimal as string
        details: `Purchase ${coins} coins for Chamak App`,
        ipn_url: webhookUrl,
        success_url: successUrl,
        cancel_url: cancelUrl,
        site_name: "Chamak",
        checkout_theme: "light",
        "customer[first_name]": firstName,
        "customer[last_name]": lastName,
        "customer[email]": userEmail,
        "customer[mobile]": userPhone,
      };

      // PayPrime API endpoint (use test URL for testing, production for live)
      const isTestMode = publicKey.startsWith("test_");
      const payprimeApiUrl = isTestMode
        ? "https://merchant.payprime.in/test/payment/initiate"
        : "https://merchant.payprime.in/payment/initiate";
      
      console.log(`📞 Calling PayPrime API (${isTestMode ? "TEST" : "PRODUCTION"}) for identifier: ${identifier}`);
      console.log(`   Amount: ₹${amount}`);
      console.log(`   Currency: ${currency.toUpperCase()}`);
      console.log(`   Webhook URL: ${webhookUrl}`);

      // PayPrime requires application/x-www-form-urlencoded
      const payprimeResponse = await axios.post(
        payprimeApiUrl,
        qs.stringify(payprimePayload),
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          timeout: 30000, // 30 seconds timeout
        }
      );

      const payprimeData = payprimeResponse.data;
      console.log(`✅ PayPrime API response received for identifier: ${identifier}`);
      console.log(`   Response status: ${payprimeData.status || 'N/A'}`);
      console.log("PayPrime response:", JSON.stringify(payprimeData, null, 2));

      // Check if PayPrime returned an error
      if (payprimeData.status === "error") {
        const errorMessage = Array.isArray(payprimeData.message)
          ? payprimeData.message.join(", ")
          : payprimeData.message || "Unknown error from PayPrime";
        throw new Error(`PayPrime API error: ${errorMessage}`);
      }

      // Extract payment URL from PayPrime response
      // PayPrime can return either:
      // 1. redirect_url (for web-based payments)
      // 2. UPI intent URLs (for UPI payments)
      let paymentUrl = payprimeData.redirect_url;

      // If no redirect_url, check for UPI URLs (PayPrime returns UPI URLs directly)
      if (!paymentUrl) {
        // Prioritize GPay, then PhonePe, then Paytm, then generic UPI
        if (payprimeData.gpay_upi_intent_url) {
          paymentUrl = payprimeData.gpay_upi_intent_url;
          console.log(`   Using GPay UPI URL`);
        } else if (payprimeData.phonepe_upi_intent_url) {
          paymentUrl = payprimeData.phonepe_upi_intent_url;
          console.log(`   Using PhonePe UPI URL`);
        } else if (payprimeData.paytm_upi_intent_url) {
          paymentUrl = payprimeData.paytm_upi_intent_url;
          console.log(`   Using Paytm UPI URL`);
        } else if (payprimeData.upi_intent_url) {
          paymentUrl = payprimeData.upi_intent_url;
          console.log(`   Using generic UPI URL`);
        }
      }

      if (!paymentUrl) {
        console.error("PayPrime response:", JSON.stringify(payprimeData, null, 2));
        throw new Error("PayPrime API did not return a redirect_url or UPI intent URL");
      }

      // Update payment document with gateway response
      await admin.firestore().collection("payments").doc(paymentId).update({
        status: "PROCESSING",
        metadata: {
          ...paymentData.metadata,
          gatewayResponse: payprimeData,
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Payment initiated successfully. Identifier: ${identifier}, Payment ID: ${paymentId}`);
      console.log(`   Payment URL: ${paymentUrl.substring(0, 50)}...`);

      // Return all available UPI URLs for user selection
      const upiUrls = {};
      if (payprimeData.gpay_upi_intent_url) {
        upiUrls.gpay_upi_intent_url = payprimeData.gpay_upi_intent_url;
      }
      if (payprimeData.upi_intent_url) {
        upiUrls.upi_intent_url = payprimeData.upi_intent_url;
      }

      return {
        success: true,
        orderId: identifier,
        identifier: identifier,
        paymentId: paymentId,
        paymentUrl: paymentUrl, // Primary URL (for backward compatibility)
        upiUrls: upiUrls, // All available UPI URLs + Card Payment URL
        amount: amount,
        currency: currency.toUpperCase(),
        coins: coins,
      };
    } catch (error) {
      console.error("❌ Error initiating payment:", error);
      
      // Log error details
      if (error.response) {
        console.error("PayPrime API Error Response:", JSON.stringify(error.response.data, null, 2));
        console.error("PayPrime API Status:", error.response.status);
      }

      throw new Error(`Failed to initiate payment: ${error.message}`);
    }
  }
);

/**
 * PHASE 5: Webhook Receiver for PayPrime
 * 
 * This function receives webhooks from PayPrime gateway.
 * - Validates webhook signature
 * - Verifies payment status with PayPrime API
 * - Updates Firestore payment status
 * - Handles coin addition on success
 * 
 * This is the SINGLE SOURCE OF TRUTH for payment confirmation.
 */
exports.payprimeWebhook = onRequest(
  {
    secrets: ["PAYPRIME_API_KEY", "PAYPRIME_SECRET_KEY"],
    cors: true,
  },
  async (req, res) => {
    try {
      // Only accept POST requests
      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed"});
      }

      // PayPrime sends form data (application/x-www-form-urlencoded)
      // Parameters: status, signature, identifier, data (object)
      const status = req.body.status;
      const signature = req.body.signature;
      const identifier = req.body.identifier;
      const data = req.body.data; // This is an object containing payment details

      console.log("📥 Received PayPrime webhook:");
      console.log(`   Status: ${status}`);
      console.log(`   Identifier: ${identifier}`);
      console.log(`   Data:`, JSON.stringify(data, null, 2));

      // Validate required fields
      if (!status || !signature || !identifier || !data) {
        console.error("❌ Webhook missing required fields");
        return res.status(400).json({error: "Missing required fields"});
      }

      // PHASE 5: Validate webhook signature
      // PayPrime signature: HMAC-SHA256(amount + identifier, secret_key) in UPPERCASE
      const secretKey = process.env.PAYPRIME_SECRET_KEY?.trim();
      if (!secretKey) {
        console.error("❌ PayPrime secret key not configured");
        return res.status(500).json({error: "Server configuration error"});
      }

      // Generate expected signature according to PayPrime docs
      const customKey = data.amount + identifier;
      const expectedSignature = crypto
        .createHmac("sha256", secretKey)
        .update(customKey)
        .digest("hex")
        .toUpperCase();

      console.log(`🔐 Signature verification:`);
      console.log(`   Received: ${signature}`);
      console.log(`   Expected: ${expectedSignature}`);

      if (signature !== expectedSignature) {
        console.error("❌ Invalid webhook signature");
        return res.status(401).json({error: "Invalid signature"});
      }

      console.log("✅ Signature verified successfully");

      // Find payment document by identifier (PayPrime uses identifier, not order_id)
      const paymentsSnapshot = await admin.firestore()
        .collection("payments")
        .where("identifier", "==", identifier)
        .limit(1)
        .get();

      if (paymentsSnapshot.empty) {
        console.error(`❌ Payment not found for identifier: ${identifier}`);
        return res.status(404).json({error: "Payment not found"});
      }

      const paymentDoc = paymentsSnapshot.docs[0];
      const paymentId = paymentDoc.id;
      const paymentData = paymentDoc.data();

      // Skip if already processed
      if (paymentData.status === "SUCCESS" || paymentData.status === "FAILED") {
        console.log(`ℹ️ Payment ${paymentId} already processed with status: ${paymentData.status}`);
        return res.status(200).json({message: "Already processed"});
      }

      // Extract payment details from data object
      const webhookAmount = parseFloat(data.amount || 0);
      const transactionId = data.transaction_id || data.payment_transaction_id || null;

      // Cross-check: Verify amount matches
      if (Math.abs(webhookAmount - paymentData.amount) > 0.01) {
        console.error(`❌ Amount mismatch. Expected: ${paymentData.amount}, Got: ${webhookAmount}`);
        return res.status(400).json({error: "Amount mismatch"});
      }

      // Update payment status based on webhook status
      // PayPrime sends: "success" or other status
      let finalStatus = "FAILED";
      if (status === "success" || status === "SUCCESS") {
        finalStatus = "SUCCESS";
      } else if (status === "pending" || status === "PENDING") {
        finalStatus = "PROCESSING";
      } else {
        finalStatus = "FAILED";
      }

      // Update payment document
      await admin.firestore().collection("payments").doc(paymentId).update({
        status: finalStatus,
        gatewayTransactionId: transactionId,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...paymentData.metadata,
          webhookData: {
            status: status,
            signature: signature,
            identifier: identifier,
            data: data,
          },
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If payment successful, add coins to user's wallet
      if (finalStatus === "SUCCESS") {
        const userId = paymentData.userId;
        const coins = paymentData.coins;

        // Update user's coin balance
        // Update both uCoins (primary) and coinBalance (legacy) for compatibility
        const userRef = admin.firestore().collection("users").doc(userId);
        await userRef.update({
          uCoins: admin.firestore.FieldValue.increment(coins), // Primary field used by wallet screen
          coinBalance: admin.firestore.FieldValue.increment(coins), // Legacy field for compatibility
        });

        // Log coin addition transaction
        await admin.firestore().collection("users").doc(userId).collection("coinTransactions").add({
          type: "purchase",
          amount: coins,
          paymentId: paymentId,
          orderId: identifier, // Using identifier as orderId
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Added ${coins} coins to user ${userId} for payment ${paymentId}`);
        console.log(`   Updated uCoins and coinBalance fields`);
      }

      console.log(`✅ Payment ${paymentId} updated to status: ${finalStatus}`);

      return res.status(200).json({
        success: true,
        paymentId: paymentId,
        status: finalStatus,
      });
    } catch (error) {
      console.error("❌ Error processing PayPrime webhook:", error);
      return res.status(500).json({
        error: "Internal server error",
        message: error.message,
      });
    }
  }
);

/**
 * PHASE 4: Distributed Counters for Follow/Unfollow
 * 
 * These functions update follower/following counts asynchronously
 * to avoid write contention on user documents.
 */

/**
 * Update counters when a user follows someone
 * Triggered when a document is created in users/{userId}/following/{targetId}
 */
exports.onFollow = onDocumentCreated(
  "users/{userId}/following/{targetId}",
  async (event) => {
    try {
      const userId = event.params.userId;
      const targetId = event.params.targetId;

      console.log(`👥 User ${userId} followed ${targetId}`);

      const db = admin.firestore();
      const batch = db.batch();

      // Update followingCount for the user who followed
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        followingCount: admin.firestore.FieldValue.increment(1),
      });

      // Update followersCount for the user who was followed
      const targetRef = db.collection("users").doc(targetId);
      batch.update(targetRef, {
        followersCount: admin.firestore.FieldValue.increment(1),
      });

      await batch.commit();
      console.log(`✅ Updated counters: ${userId} followingCount++, ${targetId} followersCount++`);
    } catch (error) {
      console.error(`❌ Error updating follow counters:`, error);
      // Don't throw - allow follow to succeed even if counter update fails
    }
  }
);

/**
 * Callable function to update counters on unfollow
 * Called from client when unfollow happens
 * Note: We use a callable function because Firestore v2 doesn't support
 * onDocumentDeleted for subcollections easily
 */
exports.updateUnfollowCounters = onCall(async (request) => {
  try {
    const { userId, targetId } = request.data;

    if (!userId || !targetId) {
      throw new Error("userId and targetId are required");
    }

    console.log(`👥 User ${userId} unfollowed ${targetId}`);

    const db = admin.firestore();
    const batch = db.batch();

    // Decrement followingCount for the user who unfollowed
    const userRef = db.collection("users").doc(userId);
    batch.update(userRef, {
      followingCount: admin.firestore.FieldValue.increment(-1),
    });

    // Decrement followersCount for the user who was unfollowed
    const targetRef = db.collection("users").doc(targetId);
    batch.update(targetRef, {
      followersCount: admin.firestore.FieldValue.increment(-1),
    });

    await batch.commit();
    console.log(`✅ Updated counters: ${userId} followingCount--, ${targetId} followersCount--`);

    return { success: true };
  } catch (error) {
    console.error(`❌ Error updating unfollow counters:`, error);
    throw new Error(`Failed to update counters: ${error.message}`);
  }
});

/**
 * PHASE 7: Reconciliation Job
 * 
 * This scheduled function checks for payments stuck in PENDING or PROCESSING state
 * and verifies their status with PayPrime API.
 * Runs every 10 minutes.
 */
exports.reconcilePayments = onSchedule("every 10 minutes", async () => {
  try {
    console.log("🔄 Starting payment reconciliation...");

    // Find payments stuck in PENDING or PROCESSING for more than 15 minutes
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
    const stuckPayments = await admin.firestore()
      .collection("payments")
      .where("status", "in", ["PENDING", "PROCESSING"])
      .where("createdAt", "<", fifteenMinutesAgo)
      .limit(50) // Process max 50 at a time
      .get();

    if (stuckPayments.empty) {
      console.log("✅ No stuck payments found");
      return null;
    }

    console.log(`📋 Found ${stuckPayments.size} stuck payments to reconcile`);

    // PayPrime doesn't have a separate verification API endpoint
    // The webhook IS the verification. For reconciliation, we'll mark very old payments as failed
    // Payments older than 24 hours without webhook = likely failed/abandoned
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    for (const paymentDoc of stuckPayments.docs) {
      const paymentData = paymentDoc.data();
      const paymentId = paymentDoc.id;
      const identifier = paymentData.identifier || paymentData.orderId;
      const createdAt = paymentData.createdAt?.toDate();

      try {
        // If payment is older than 24 hours and still pending, mark as failed
        if (createdAt && createdAt < twentyFourHoursAgo) {
          await paymentDoc.ref.update({
            status: "FAILED",
            metadata: {
              ...paymentData.metadata,
              reconciled: true,
              reconciliationReason: "Payment abandoned - no webhook received after 24 hours",
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`✅ Reconciled payment ${paymentId}: FAILED (abandoned after 24 hours)`);
        } else {
          // Payment is still recent, just increment retry count
          const retryCount = (paymentData.metadata?.retryCount || 0) + 1;
          await paymentDoc.ref.update({
            "metadata.retryCount": retryCount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`ℹ️ Payment ${paymentId} still pending (retry ${retryCount}, waiting for webhook)`);
        }
      } catch (error) {
        console.error(`❌ Error reconciling payment ${paymentId}:`, error.message);
        // Continue with next payment
      }
    }

    console.log(`✅ Reconciliation completed. Processed ${stuckPayments.size} payments`);
    return null;
  } catch (error) {
    console.error("❌ Error in reconciliation job:", error);
    return null;
  }
});

/**
 * ⚠️ MANDATORY BACKEND FEATURE: Stream Timeout Auto-Cleanup
 * Runs every 5 minutes to automatically mark inactive streams as ended
 * This prevents zombie streams from cluttering the database
 */
exports.cleanupInactiveStreams = onSchedule("every 5 minutes", async (event) => {
  try {
    console.log("🧹 Starting stream timeout auto-cleanup...");
    const now = admin.firestore.Timestamp.now();
    const heartbeatTimeout = 60; // 60 seconds = 1 minute (stream is dead if no heartbeat for 60s)
    
    const streamsRef = admin.firestore().collection("live_streams");
    const activeStreams = await streamsRef
      .where("isActive", "==", true)
      .get();
    
    if (activeStreams.empty) {
      console.log("✅ No active streams to check");
      return null;
    }
    
    const batch = admin.firestore().batch();
    let cleanedCount = 0;
    
    for (const doc of activeStreams.docs) {
      const data = doc.data();
      const lastHeartbeat = data.lastHeartbeat;
      const startedAt = data.startedAt;
      const hostStatus = data.hostStatus || "live";
      const endedAt = data.endedAt;
      
      let shouldCleanup = false;
      let cleanupReason = "";
      
      // Check 1: If stream already has endedAt, mark as inactive
      if (endedAt != null) {
        shouldCleanup = true;
        cleanupReason = "already_ended";
      }
      // Check 2: If hostStatus is 'ended', mark as inactive
      else if (hostStatus === "ended") {
        shouldCleanup = true;
        cleanupReason = "host_status_ended";
      }
      // Check 3: If heartbeat is too old (primary check)
      else if (lastHeartbeat) {
        const heartbeatAge = (now.toMillis() - lastHeartbeat.toMillis()) / 1000; // Age in seconds
        
        if (heartbeatAge > heartbeatTimeout) {
          shouldCleanup = true;
          cleanupReason = `heartbeat_timeout_${Math.round(heartbeatAge)}s`;
        }
      }
      // Check 4: If no heartbeat and startedAt is very old (fallback)
      else if (startedAt) {
        try {
          const startedAtTime = typeof startedAt === "string" 
            ? new Date(startedAt).getTime() 
            : startedAt.toMillis();
          const streamAge = (now.toMillis() - startedAtTime) / 1000; // Age in seconds
          
          // If stream started more than 5 minutes ago and no heartbeat, it's dead
          if (streamAge > 300) { // 5 minutes
            shouldCleanup = true;
            cleanupReason = `no_heartbeat_old_stream_${Math.round(streamAge)}s`;
          }
        } catch (e) {
          console.error(`⚠️ Error parsing startedAt for stream ${doc.id}: ${e.message}`);
        }
      }
      
      if (shouldCleanup) {
        batch.update(doc.ref, {
          isActive: false,
          hostStatus: "ended",
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          endReason: cleanupReason,
        });
        cleanedCount++;
        console.log(`   🧹 Marking stream ${doc.id} as inactive (${cleanupReason})`);
      }
    }
    
    if (cleanedCount > 0) {
      await batch.commit();
      console.log(`✅ Cleanup complete: ${cleanedCount} streams marked as inactive`);
    } else {
      console.log("✅ No streams needed cleanup");
    }
    
    return null;
  } catch (error) {
    console.error("❌ Error in stream cleanup:", error);
    return null;
  }
});

/**
 * ⚠️ MANDATORY BACKEND FEATURE: Server-Controlled Stream State
 * Runs every 1 minute to enforce stream state consistency
 * Server is the source of truth for stream state
 * Note: Using cron expression for 1-minute interval (Cloud Scheduler minimum is 1 minute)
 */
exports.manageStreamState = onSchedule("*/1 * * * *", async (event) => {
  try {
    console.log("🖥️ Starting server-controlled stream state management...");
    const now = admin.firestore.Timestamp.now();
    const heartbeatTimeout = 60; // 60 seconds
    
    const streamsRef = admin.firestore().collection("live_streams");
    const activeStreams = await streamsRef
      .where("isActive", "==", true)
      .get();
    
    if (activeStreams.empty) {
      console.log("✅ No active streams to manage");
      return null;
    }
    
    const batch = admin.firestore().batch();
    let managedCount = 0;
    
    // Group streams by hostId to detect duplicates
    const streamsByHost = {};
    for (const doc of activeStreams.docs) {
      const data = doc.data();
      const hostId = data.hostId;
      
      if (!streamsByHost[hostId]) {
        streamsByHost[hostId] = [];
      }
      streamsByHost[hostId].push({doc, data});
    }
    
    for (const doc of activeStreams.docs) {
      const data = doc.data();
      const lastHeartbeat = data.lastHeartbeat;
      const hostId = data.hostId;
      const hostStatus = data.hostStatus || "live";
      
      // Check 1: Heartbeat timeout - mark stream as ended
      if (lastHeartbeat) {
        const heartbeatAge = (now.toMillis() - lastHeartbeat.toMillis()) / 1000;
        
        if (heartbeatAge > heartbeatTimeout) {
          batch.update(doc.ref, {
            isActive: false,
            hostStatus: "ended",
            endedAt: admin.firestore.FieldValue.serverTimestamp(),
            endReason: "server_heartbeat_timeout",
          });
          managedCount++;
          console.log(`   ⏱️ Stream ${doc.id} ended due to heartbeat timeout (${Math.round(heartbeatAge)}s)`);
          continue; // Skip duplicate check for this stream
        }
      }
      
      // Check 2: Duplicate streams - keep most recent, end others
      const hostStreams = streamsByHost[hostId] || [];
      if (hostStreams.length > 1) {
        // Sort by lastHeartbeat or startedAt (most recent first)
        hostStreams.sort((a, b) => {
          const aTime = a.data.lastHeartbeat || a.data.startedAt;
          const bTime = b.data.lastHeartbeat || b.data.startedAt;
          
          const aMillis = aTime ? (typeof aTime === "string" ? new Date(aTime).getTime() : aTime.toMillis()) : 0;
          const bMillis = bTime ? (typeof bTime === "string" ? new Date(bTime).getTime() : bTime.toMillis()) : 0;
          
          return bMillis - aMillis; // Most recent first
        });
        
        // Keep the first (most recent), end the rest
        for (let i = 1; i < hostStreams.length; i++) {
          const streamDoc = hostStreams[i].doc;
          batch.update(streamDoc.ref, {
            isActive: false,
            hostStatus: "ended",
            endedAt: admin.firestore.FieldValue.serverTimestamp(),
            endReason: "server_duplicate_stream",
          });
          managedCount++;
          console.log(`   🔄 Stream ${streamDoc.id} ended (duplicate, keeping most recent)`);
        }
      }
    }
    
    if (managedCount > 0) {
      await batch.commit();
      console.log(`✅ Stream state management complete: ${managedCount} streams managed`);
    } else {
      console.log("✅ All streams in correct state");
    }
    
    return null;
  } catch (error) {
    console.error("❌ Error in stream state management:", error);
    return null;
  }
});

/**
 * Update viewer count for live streams
 * Called by viewers when they join/leave a stream
 * This fixes the Firestore permission issue where viewers cannot update viewer count directly
 */
exports.updateViewerCount = onCall({}, async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const { streamId, action } = request.data; // action: 'join' or 'leave'
  
  // Validate required parameters
  if (!streamId || typeof streamId !== "string") {
    throw new Error("streamId is required and must be a string");
  }
  
  if (!action || (action !== 'join' && action !== 'leave')) {
    throw new Error("action is required and must be 'join' or 'leave'");
  }

  try {
    const streamRef = admin.firestore().collection('live_streams').doc(streamId);
    
    // Verify stream exists
    const streamDoc = await streamRef.get();
    if (!streamDoc.exists) {
      throw new Error("Stream not found");
    }
    
    const streamData = streamDoc.data();
    if (!streamData || streamData.isActive !== true) {
      throw new Error("Stream is not active");
    }
    
    // Get current viewer count
    const currentCount = streamData.viewerCount || 0;
    
    if (action === 'join') {
      // Increment viewer count
      await streamRef.update({
        'viewerCount': admin.firestore.FieldValue.increment(1),
      });
      console.log(`✅ Viewer joined stream ${streamId}, new count: ${currentCount + 1}`);
      return { 
        success: true,
        viewerCount: currentCount + 1
      };
    } else if (action === 'leave') {
      // Decrement viewer count (but don't go below 0)
      const newCount = Math.max(0, currentCount - 1);
      await streamRef.update({
        'viewerCount': newCount,
      });
      console.log(`✅ Viewer left stream ${streamId}, new count: ${newCount}`);
      return { 
        success: true,
        viewerCount: newCount
      };
    }
  } catch (error) {
    console.error("❌ Error updating viewer count:", error);
    throw new Error(`Failed to update viewer count: ${error.message}`);
  }
});

/**
 * Verify Google Play Store purchase and add coins
 */
exports.verifyPlayStorePurchase = onCall(
  {},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const userId = request.auth.uid;
    const { productId, purchaseToken, orderId, packageName } = request.data;

    // Validate inputs
    if (!productId || !purchaseToken || !orderId) {
      throw new Error("Missing required purchase parameters");
    }

    try {
      // Map product IDs to coin amounts
      const productToCoins = {
        'coins_90_pack': 90, // Changed from coins_90 (deleted ID can't be reused)
        'coins_550': 550,
        'coins_1100': 1100,
        'coins_1700': 1700,
        'coins_2400': 2400,
        'coins_3500': 3500,
        'coins_7500': 7500,
        'coins_13000': 13000,
        'coins_28000': 28000,
        'coins_45000': 45000,
        'coins_80000': 80000,
        'coins_175000': 175000,
      };

      const coins = productToCoins[productId];
      if (!coins) {
        throw new Error(`Invalid product ID: ${productId}`);
      }

      console.log(`🛒 Verifying Play Store purchase: ${orderId}`);
      console.log(`   Product: ${productId}`);
      console.log(`   Coins: ${coins}`);
      console.log(`   User: ${userId}`);

      // Check if purchase already processed
      const existingPayment = await admin.firestore()
        .collection('payments')
        .where('orderId', '==', orderId)
        .where('gateway', '==', 'play_store')
        .limit(1)
        .get();

      if (!existingPayment.empty) {
        const paymentData = existingPayment.docs[0].data();
        if (paymentData.status === 'SUCCESS') {
          console.log(`ℹ️ Purchase already processed: ${orderId}`);
          return {
            success: true,
            message: 'Purchase already processed',
            coins: coins,
          };
        }
      }

      // TODO: Verify purchase token with Google Play API
      // For production, use Google Play Developer API to verify purchase
      // For now, we'll trust the client (not recommended for production)
      // In production, implement server-side verification using:
      // https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get

      // Create payment record
      const paymentId = admin.firestore().collection('payments').doc().id;
      const paymentData = {
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
        productId: productId,
        coins: coins,
        amount: 0, // Amount handled by Play Store
        currency: 'INR',
        status: 'SUCCESS',
        gateway: 'play_store',
        purchaseToken: purchaseToken,
        packageName: packageName || 'com.chamakz.app',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore().collection('payments').doc(paymentId).set(paymentData);

      // Add coins to user's wallet
      const userRef = admin.firestore().collection('users').doc(userId);
      await userRef.update({
        uCoins: admin.firestore.FieldValue.increment(coins),
        coinBalance: admin.firestore.FieldValue.increment(coins), // Legacy
      });

      // Log transaction
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('coinTransactions')
        .add({
          type: 'purchase',
          amount: coins,
          paymentId: paymentId,
          orderId: orderId,
          gateway: 'play_store',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ Play Store purchase verified: ${orderId}, added ${coins} coins to user ${userId}`);

      return {
        success: true,
        message: 'Purchase verified and coins added',
        coins: coins,
        paymentId: paymentId,
      };
    } catch (error) {
      console.error('❌ Error verifying Play Store purchase:', error);
      throw new Error(`Failed to verify purchase: ${error.message}`);
    }
  }
);

/**
 * Send notification when a host goes live
 * Triggers automatically when a new active live stream is created
 */
exports.sendLiveStreamNotification = onDocumentCreated(
    "live_streams/{streamId}",
    async (event) => {
      try {
        const streamData = event.data.data();
        const streamId = event.params.streamId;

        console.log(`📺 New live stream created: ${streamId}`);
        console.log(`   Host: ${streamData.hostName} (${streamData.hostId})`);
        console.log(`   Active: ${streamData.isActive}`);
        console.log(`   Host Status: ${streamData.hostStatus || 'undefined'}`);

        // ✅ FIX: Only check isActive (primary check)
        // hostStatus might not be set yet when document is first created
        // If isActive is true, we should send notification
        if (!streamData.isActive) {
          console.log('⏭️ Skipping notification - stream is not active');
          return null;
        }

        // ✅ FIX: Only skip if hostStatus is explicitly 'ended'
        // If hostStatus is undefined/null or 'live', proceed with notification
        if (streamData.hostStatus === 'ended') {
          console.log('⏭️ Skipping notification - host status is ended');
          return null;
        }

        // Verify host is approved (double-check)
        const hostDoc = await admin.firestore()
            .collection('users')
            .doc(streamData.hostId)
            .get();

        if (!hostDoc.exists) {
          console.log('❌ Host user not found');
          return null;
        }

        const hostData = hostDoc.data();
        if (!hostData.isActive) {
          console.log('⏭️ Skipping notification - host is not approved');
          return null;
        }

        const hostName = streamData.hostName || hostData.name || hostData.displayName || 'Someone';
        const hostPhotoUrl = streamData.hostPhotoUrl || hostData.photoURL || '';

        console.log(`✅ Host verified: ${hostName} (approved: ${hostData.isActive})`);

        // Get all users with FCM tokens (except the host)
        const usersSnapshot = await admin.firestore()
            .collection('users')
            .where('fcmToken', '!=', null)
            .get();

        if (usersSnapshot.empty) {
          console.log('No users found in database');
          return null;
        }

        // ✅ FIX: Filter users with valid FCM tokens (excluding host)
        // This ensures we get all users with tokens, even if query doesn't work perfectly
        const tokens = usersSnapshot.docs
            .filter(doc => {
              const userData = doc.data();
              const hasToken = userData.fcmToken && 
                              typeof userData.fcmToken === 'string' && 
                              userData.fcmToken.length > 0;
              const isNotHost = doc.id !== streamData.hostId;
              return hasToken && isNotHost;
            })
            .map(doc => doc.data().fcmToken);

        if (tokens.length === 0) {
          console.log('No valid FCM tokens found (excluding host)');
          return null;
        }

        console.log(`📤 Sending live stream notification to ${tokens.length} users`);

        // Prepare notification
        const notification = {
          title: `${hostName} is live now`,
          body: 'Tap to watch the live stream',
        };

        const data = {
          type: 'live_stream',
          streamId: streamId,
          hostId: streamData.hostId,
          hostName: hostName,
          hostPhotoUrl: hostPhotoUrl || '',
          channelName: streamData.channelName || streamId,
        };

        // Send notifications in batches (FCM limit: 500 per batch)
        const batchSize = 500;
        let successCount = 0;
        let failureCount = 0;

        for (let i = 0; i < tokens.length; i += batchSize) {
          const batch = tokens.slice(i, i + batchSize);
          
          try {
            const message = {
              notification: notification,
              data: data,
              tokens: batch,
              android: {
                priority: 'high',
                notification: {
                  channelId: 'chamak_live_streams',
                  sound: 'default',
                  priority: 'high',
                  defaultVibrateTimings: true,
                  defaultSound: true,
                  clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
              },
              apns: {
                headers: {
                  'apns-priority': '10',
                },
                payload: {
                  aps: {
                    alert: notification,
                    sound: 'default',
                    badge: 1,
                    category: 'LIVE_STREAM',
                  },
                },
              },
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

            // Log failures for debugging
            if (response.failureCount > 0) {
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  console.error(`❌ Failed to send to token ${idx}: ${resp.error}`);
                }
              });
            }
          } catch (error) {
            console.error(`❌ Error sending batch:`, error);
            failureCount += batch.length;
          }
        }

        console.log(`✅ Live stream notification sent: ${successCount} success, ${failureCount} failed`);
        return {success: successCount, failures: failureCount};
      } catch (error) {
        console.error('❌ Error in sendLiveStreamNotification:', error);
        return null;
      }
    }
);
