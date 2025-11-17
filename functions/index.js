/**
 * Firebase Cloud Functions for Chamak App - Notification System
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");

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
