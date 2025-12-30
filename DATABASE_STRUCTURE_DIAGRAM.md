# 🗄️ Firebase Database Structure - Visual Diagram

## Database Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIREBASE FIRESTORE DATABASE                   │
│                         (Cloud Firestore)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Main Collections Hierarchy

```
Firestore Root
│
├── 📁 users (Primary Collection)
│   ├── 📄 {userId} (Document)
│   │   ├── Fields: userId, numericUserId, phoneNumber, uCoins, cCoins, etc.
│   │   │
│   │   ├── 📁 following (Subcollection)
│   │   │   └── 📄 {followingId} → User being followed
│   │   │
│   │   ├── 📁 followers (Subcollection)
│   │   │   └── 📄 {followerId} → User following this user
│   │   │
│   │   └── 📁 transactions (Subcollection)
│   │       └── 📄 {transactionId} → Transaction history
│   │
│   └── ... (other user documents)
│
├── 📁 wallets (Secondary Collection - Synced with users.uCoins)
│   └── 📄 {userId} → Wallet balance (redundant, kept for compatibility)
│
├── 📁 earnings (Host Earnings - Single Source of Truth)
│   └── 📄 {userId} → Host C Coins earnings
│
├── 📁 live_streams (Primary Collection)
│   ├── 📄 {streamId} (Document)
│   │   ├── Fields: hostId, hostName, isActive, viewerCount, etc.
│   │   │
│   │   ├── 📁 viewers (Subcollection)
│   │   │   └── 📄 {viewerId} → Individual viewer tracking
│   │   │
│   │   └── 📁 chat (Subcollection)
│   │       └── 📄 {messageId} → Live chat messages
│   │
│   └── ... (other stream documents)
│
├── 📁 chats (Primary Collection)
│   ├── 📄 {chatId} (Document - Format: "userId1_userId2")
│   │   ├── Fields: participants, lastMessage, unreadCount, etc.
│   │   │
│   │   └── 📁 messages (Subcollection)
│   │       └── 📄 {messageId} → Chat messages
│   │
│   └── ... (other chat documents)
│
├── 📁 calls (Primary Collection)
│   └── 📄 {callId} → One-on-one video call requests
│
├── 📁 announcements (Primary Collection)
│   └── 📄 {announcementId} → App-wide announcements
│
├── 📁 events (Primary Collection)
│   └── 📄 {eventId} → App events and competitions
│
├── 📁 gifts (Primary Collection)
│   └── 📄 {giftId} → Gift transactions (U Coins → C Coins)
│
├── 📁 payments (Primary Collection)
│   └── 📄 {paymentId} → UPI payment records
│
├── 📁 withdrawal_requests (Primary Collection)
│   └── 📄 {requestId} → Host withdrawal requests
│
├── 📁 callTransactions (Primary Collection)
│   └── 📄 {transactionId} → Call transaction records
│
├── 📁 supportTickets (Primary Collection)
│   └── 📄 {ticketId} → User support tickets
│
├── 📁 feedback (Primary Collection)
│   └── 📄 {feedbackId} → User feedback and ratings
│
├── 📁 reports (Primary Collection)
│   └── 📄 {reportId} → User reports (abuse, spam, etc.)
│
├── 📁 notificationRequests (Primary Collection)
│   └── 📄 {requestId} → Push notification requests (Cloud Functions)
│
└── 📁 transactions (Standalone - Potentially Unused)
    └── 📄 {transactionId} → Legacy transaction records?
```

---

## 🔄 Data Flow Diagrams

### Coin System Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    U COINS FLOW (User Coins)                 │
└─────────────────────────────────────────────────────────────┘

User Purchases Coins
        │
        ▼
┌───────────────────┐
│  payments/{id}    │  ← Payment record created
│  - utrNumber      │
│  - coins          │
│  - amount         │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  users/{userId}    │  ← PRIMARY SOURCE OF TRUTH
│  - uCoins += coins │     (Atomic update)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  wallets/{userId}  │  ← SYNCED (Secondary)
│  - balance += coins│     (Atomic batch write)
└───────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  users/{userId}/transactions │  ← Transaction history
│  - type: 'purchase'          │
│  - coins, amount             │
└──────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                    C COINS FLOW (Host Coins)                 │
└─────────────────────────────────────────────────────────────┘

User Sends Gift to Host
        │
        ▼
┌───────────────────┐
│  users/{senderId}  │  ← U Coins deducted
│  - uCoins -= cost  │     (Atomic transaction)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  earnings/{hostId}│  ← SINGLE SOURCE OF TRUTH
│  - totalCCoins += │     (Atomic increment)
│    convertedAmt   │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  gifts/{giftId}    │  ← Gift transaction record
│  - senderId        │     (Immutable)
│  - receiverId      │
│  - uCoinsSpent     │
│  - cCoinsEarned    │
└───────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                    WITHDRAWAL FLOW                           │
└─────────────────────────────────────────────────────────────┘

Host Requests Withdrawal
        │
        ▼
┌──────────────────────────────┐
│  withdrawal_requests/{id}    │  ← Request created
│  - userId                     │     (status: 'pending')
│  - amount (C Coins)           │
│  - withdrawalMethod           │
└──────────────────────────────┘
        │
        ▼
Admin Approves
        │
        ▼
┌──────────────────────────────┐
│  withdrawal_requests/{id}    │  ← Status updated
│  - status: 'approved'         │
└──────────────────────────────┘
        │
        ▼
Admin Marks as Paid
        │
        ▼
┌──────────────────────────────┐
│  withdrawal_requests/{id}    │  ← Status updated
│  - status: 'paid'             │     (Atomic batch)
│  - paymentProofURL            │
└──────────────────────────────┘
        │
        ▼
┌───────────────────┐
│  earnings/{hostId}│  ← C Coins deducted
│  - totalCCoins -= │     (Atomic decrement)
│    amount         │
└───────────────────┘
```

### Live Streaming Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    LIVE STREAMING FLOW                      │
└─────────────────────────────────────────────────────────────┘

Host Starts Stream
        │
        ▼
┌──────────────────────────────┐
│  live_streams/{streamId}      │  ← Stream created/updated
│  - isActive: true             │     (Reuses existing if available)
│  - hostStatus: 'live'         │
│  - viewerCount: 0             │
└──────────────────────────────┘
        │
        ▼
Viewers Join
        │
        ├───► Increment viewerCount (document)
        │
        └───► Add to live_streams/{streamId}/viewers/{viewerId}
        │
        └───► Add to live_streams/{streamId}/chat/{messageId} (if chat)
        │
        ▼
Host Ends Stream
        │
        ▼
┌──────────────────────────────┐
│  live_streams/{streamId}      │  ← Stream marked inactive
│  - isActive: false            │     (Soft delete)
│  - hostStatus: 'ended'         │
│  - endedAt: timestamp         │
└──────────────────────────────┘
        │
        ▼
Chat Cleared (optional)
        │
        ▼
Auto-cleanup after 24 hours
```

### Chat Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        CHAT FLOW                            │
└─────────────────────────────────────────────────────────────┘

User Opens Chat
        │
        ▼
Generate Chat ID (deterministic: sorted user IDs)
        │
        ▼
┌───────────────────┐
│  chats/{chatId}    │  ← Chat created/retrieved
│  - participants    │     (if not exists)
│  - unreadCount     │
└───────────────────┘
        │
        ▼
User Sends Message
        │
        ├───► Add to chats/{chatId}/messages/{messageId}
        │
        ├───► Update chats/{chatId}:
        │     - lastMessage
        │     - lastMessageTime
        │     - unreadCount[receiverId]++
        │
        └───► Create notificationRequests/{id}
              (for push notification)
```

### Private Call Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PRIVATE CALL FLOW                        │
└─────────────────────────────────────────────────────────────┘

Caller Initiates Call
        │
        ├───► Create calls/{callId}
        │     (status: 'pending')
        │
        └───► Update live_streams/{streamId}:
              - hostStatus: 'in_call'
              - currentCallUserId: callerId
        │
        ▼
Host Accepts/Rejects
        │
        ├───► If Accepted:
        │     ├── Update calls/{callId}:
        │     │    - status: 'accepted'
        │     │
        │     ├── Deduct U Coins from caller
        │     │   (users/{callerId}.uCoins)
        │     │
        │     ├── Add C Coins to host
        │     │   (earnings/{hostId}.totalCCoins)
        │     │
        │     └── Create callTransactions/{id}
        │
        └───► If Rejected:
              └── Update calls/{callId}:
                   - status: 'rejected'
        │
        ▼
Call Ends
        │
        ├───► Update calls/{callId}:
        │     - status: 'ended'
        │
        └───► Update live_streams/{streamId}:
              - hostStatus: 'live'
              - currentCallUserId: null
```

---

## 🔗 Collection Relationships

```
┌─────────────┐
│    users    │ ◄───┐
└─────────────┘     │
     │              │
     ├──► wallets (synced)
     │              │
     ├──► earnings (host earnings)
     │              │
     ├──► chats (participant)
     │              │
     ├──► calls (caller/receiver)
     │              │
     ├──► live_streams (host)
     │              │
     ├──► gifts (sender/receiver)
     │              │
     ├──► payments (user)
     │              │
     ├──► withdrawal_requests (user)
     │              │
     └──► supportTickets (user)
                    │
                    │ References
                    │
┌──────────────────────────────────────────────┐
│         Related Collections                  │
├──────────────────────────────────────────────┤
│  • live_streams → users (hostId)              │
│  • chats → users (participants)               │
│  • calls → users (callerId, receiverId)      │
│  • gifts → users (senderId, receiverId)      │
│  • gifts → earnings (receiverId)            │
│  • payments → users (userId)                 │
│  • withdrawal_requests → earnings (userId)   │
│  • callTransactions → users (callerId, hostId)│
└──────────────────────────────────────────────┘
```

---

## 📈 Collection Usage Heatmap

```
High Usage (Critical):
████████████████████████████████████████████████
  • users
  • live_streams
  • chats
  • earnings
  • gifts

Medium Usage (Important):
████████████████████████████████████
  • payments
  • wallets
  • calls
  • announcements
  • events
  • notificationRequests

Low Usage (Moderate):
████████████
  • withdrawal_requests
  • supportTickets
  • callTransactions
  • feedback
  • reports
```

---

## 🎯 Key Points

### Single Source of Truth:
- ✅ **U Coins:** `users.uCoins` (primary), `wallets.balance` (synced)
- ✅ **C Coins (Earnings):** `earnings.totalCCoins` (ONLY source)
- ✅ **Host Status:** `live_streams.hostStatus`

### Atomic Operations:
- ✅ Coin additions/deductions (batch writes)
- ✅ Gift sending (Firestore transactions)
- ✅ Withdrawal processing (batch writes)

### Real-time Updates:
- ✅ Live streams (`.snapshots()`)
- ✅ Chat messages (`.snapshots()`)
- ✅ Call status (`.snapshots()`)
- ✅ User data (`.snapshots()`)

---

**Last Updated:** $(date)  
**Status:** ✅ Complete Visual Diagram
