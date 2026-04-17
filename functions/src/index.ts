/**
 * NexChat — Firebase Cloud Functions
 *
 * Cloud Functions for:
 * - Push notification delivery (FCM)
 * - Scheduled message processing
 * - Status expiry cleanup (24-hour auto-delete)
 * - User presence management
 * - Call signaling helpers
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ════════════════════════════════════════════════════════
// Push Notifications — New Message
// ════════════════════════════════════════════════════════

export const onNewMessage = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = message.chatId;
    const senderId = message.senderId;

    // Get the chat document to find participants
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;

    const chat = chatDoc.data()!;
    const participants: string[] = chat.participants || [];

    // Get sender info
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data()!.name : "Someone";

    // Send FCM to all participants except sender
    const recipientIds = participants.filter((uid: string) => uid !== senderId);

    for (const recipientId of recipientIds) {
      const recipientDoc = await db.collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) continue;

      const recipientData = recipientDoc.data()!;
      const tokens: string[] = recipientData.deviceTokens || [];

      // Check if recipient has muted this chat
      const mutedBy: string[] = chat.mutedBy || [];
      if (mutedBy.includes(recipientId)) continue;

      if (tokens.length === 0) continue;

      const notification: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: chat.type === "private" ? senderName : `${senderName} @ ${chat.name || "Group"}`,
          body: _getMessagePreview(message.type),
        },
        data: {
          chatId: chatId,
          messageId: context.params.messageId,
          senderId: senderId,
          type: "new_message",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "nexchat_messages",
            priority: "high",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
              contentAvailable: true,
            },
          },
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(notification);
        // Clean up invalid tokens
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });
        if (failedTokens.length > 0) {
          await db.collection("users").doc(recipientId).update({
            deviceTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
          });
        }
      } catch (error) {
        functions.logger.error("FCM send error:", error);
      }
    }
  });

function _getMessagePreview(type: string): string {
  switch (type) {
  case "text":
    return "🔒 Encrypted message";
  case "image":
    return "📷 Photo";
  case "video":
    return "🎥 Video";
  case "audio":
    return "🎵 Audio";
  case "document":
    return "📄 Document";
  case "poll":
    return "📊 Poll";
  case "contact":
    return "👤 Contact";
  case "location":
    return "📍 Location";
  case "sticker":
    return "🎭 Sticker";
  case "gif":
    return "GIF";
  default:
    return "New message";
  }
}

// ════════════════════════════════════════════════════════
// Push Notifications — Incoming Call
// ════════════════════════════════════════════════════════

export const onIncomingCall = functions.firestore
  .document("calls/{callId}")
  .onCreate(async (snap, context) => {
    const call = snap.data();
    const callerId = call.callerId;
    const receiverIds: string[] = call.receiverIds || [];

    // Get caller info
    const callerDoc = await db.collection("users").doc(callerId).get();
    const callerName = callerDoc.exists ? callerDoc.data()!.name : "Someone";

    for (const receiverId of receiverIds) {
      const receiverDoc = await db.collection("users").doc(receiverId).get();
      if (!receiverDoc.exists) continue;

      const tokens: string[] = receiverDoc.data()!.deviceTokens || [];
      if (tokens.length === 0) continue;

      const notification: admin.messaging.MulticastMessage = {
        tokens: tokens,
        data: {
          callId: context.params.callId,
          callerId: callerId,
          callerName: callerName,
          callerPic: callerDoc.data()?.profilePicUrl || "",
          callType: call.type,
          type: "incoming_call",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "nexchat_calls",
            priority: "max",
            defaultSound: true,
            visibility: "public",
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "ringtone.caf",
              contentAvailable: true,
              category: "INCOMING_CALL",
            },
          },
        },
      };

      try {
        await messaging.sendEachForMulticast(notification);
      } catch (error) {
        functions.logger.error("Call FCM error:", error);
      }
    }
  });

// ════════════════════════════════════════════════════════
// Scheduled Messages — Process pending scheduled messages
// ════════════════════════════════════════════════════════

export const processScheduledMessages = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const pendingMessages = await db
      .collection("scheduled_messages")
      .where("status", "==", "pending")
      .where("scheduledAt", "<=", now)
      .get();

    const batch = db.batch();

    for (const doc of pendingMessages.docs) {
      const scheduled = doc.data();

      // Create the actual message
      const messageRef = db.collection("messages").doc();
      batch.set(messageRef, {
        messageId: messageRef.id,
        chatId: scheduled.chatId,
        senderId: scheduled.senderId,
        type: scheduled.type,
        encryptedText: scheduled.encryptedText,
        status: "sent",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        localId: doc.id,
      });

      // Update the chat's lastMessage
      const chatRef = db.collection("chats").doc(scheduled.chatId);
      batch.update(chatRef, {
        lastMessage: {
          text: "[encrypted]",
          senderId: scheduled.senderId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          type: scheduled.type,
        },
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark scheduled message as sent
      batch.update(doc.ref, { status: "sent" });
    }

    if (pendingMessages.size > 0) {
      await batch.commit();
      functions.logger.info(`Processed ${pendingMessages.size} scheduled messages`);
    }
  });

// ════════════════════════════════════════════════════════
// Status Cleanup — Delete expired statuses (24-hour TTL)
// ════════════════════════════════════════════════════════

export const cleanupExpiredStatuses = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredStatuses = await db
      .collection("status")
      .where("expiresAt", "<=", now)
      .get();

    const batch = db.batch();

    for (const doc of expiredStatuses.docs) {
      batch.delete(doc.ref);

      // Also delete associated media from Storage
      const statusData = doc.data();
      if (statusData.mediaUrl) {
        try {
          const bucket = admin.storage().bucket();
          const filePath = `status/${statusData.userId}/${doc.id}`;
          await bucket.file(filePath).delete();
        } catch (error) {
          functions.logger.warn("Failed to delete status media:", error);
        }
      }
    }

    if (expiredStatuses.size > 0) {
      await batch.commit();
      functions.logger.info(`Cleaned up ${expiredStatuses.size} expired statuses`);
    }
  });

// ════════════════════════════════════════════════════════
// User Presence — Update lastSeen on disconnect
// ════════════════════════════════════════════════════════

export const onUserStatusChange = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // If user went offline, update lastSeen
    if (before.status === "online" && after.status === "offline") {
      await change.after.ref.update({
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
