# 📊 Firestore Database Collections Report

**App Name:** Chamak Live Streaming App  
**Database:** Cloud Firestore  
**Date:** $(date)  
**Total Collections:** 20+ Main Collections

---

## 📋 Complete Database Structure

### 🔐 **Admin & Management Collections**

#### 1. `admins` Collection
**Purpose:** Store admin user accounts  
**Document ID:** User UID  
**Fields:**
- `isAdmin` (boolean) - Admin status flag
- `email` (string, optional) - Admin email
- `createdAt` (timestamp, optional) - Account creation date

**Permissions:**
- Read: Admins only
- Write: Admins only

**Used By:**
- Admin panel authentication
- Admin status verification

---

#### 2. `adminActions` Collection
**Purpose:** Log all admin actions for audit trail  
**Document ID:** Auto-generated  
**Fields:**
- `adminId` (string) - Admin user ID
- `adminEmail` (string) - Admin email
- `userId` (string, optional) - Target user ID
- `actionType` (string) - Type of action (e.g., "add_u_coins", "update_user")
- `coinsAdded` (number, optional) - Coins added (if applicable)
- `details` (map, optional) - Additional action details
- `timestamp` (timestamp) - Action time

**Permissions:**
- Read: Admins only
- Write: Admins only

**Used By:**
- Admin service for logging actions
- Audit trail

---

### 👤 **User & Profile Collections**

#### 3. `users` Collection
**Purpose:** Store user profiles and account information  
**Document ID:** User UID (Firebase Auth UID)  
**Fields:**
- `userId` (string) - User ID (same as document ID)
- `numericUserId` (string) - Numeric-only ID for display
- `phoneNumber` (string) - User phone number
- `countryCode` (string) - Country code
- `displayName` (string, optional) - User display name
- `photoURL` (string, optional) - Profile photo URL
- `coverURL` (string, optional) - Cover photo URL
- `bio` (string, optional) - User bio
- `age` (number, optional) - User age
- `gender` (string, optional) - User gender
- `country` (string, optional) - Country
- `city` (string, optional) - City
- `language` (string, optional) - Preferred language
- `createdAt` (timestamp) - Account creation date
- `lastLogin` (timestamp) - Last login time
- `isActive` (boolean) - Account active status
- `followersCount` (number) - Number of followers
- `followingCount` (number) - Number of following
- `level` (number) - Legacy level field
- `userLevel` (number) - User level (based on coins purchased)
- `hostLevel` (number) - Host level (based on coins received)
- `coins` (number) - Legacy coins field
- `uCoins` (number) - User Coins (what users buy and spend)
- `cCoins` (number) - Host Coins (what hosts earn)
- `totalCoinsPurchased` (number) - Lifetime total coins purchased
- `totalCoinsReceived` (number) - Lifetime total coins received
- `fcmToken` (string, optional) - FCM token for push notifications
- `isHost` (boolean, optional) - Host status

**Subcollections:**
- `transactions/{transactionId}` - User transaction history
- `coinTransactions/{transactionId}` - Coin transaction history
- `following/{targetUserId}` - Users this user follows
- `followers/{followerId}` - Users following this user
- `seenAnnouncements/{announcementId}` - Announcements user has seen
- `dismissedAnnouncements/{announcementId}` - Announcements user dismissed
- `blocked/{userId}` - Blocked users

**Permissions:**
- Read: All authenticated users (public profiles)
- Create: Users can create own profile
- Update: Users can update own profile, admins can update any
- Delete: Admins only

**Used By:**
- Profile screens
- Search functionality
- Chat system
- Follow/unfollow system
- User authentication

---

#### 4. `wallets` Collection
**Purpose:** Store user wallet balances (sync with users collection)  
**Document ID:** User UID  
**Fields:**
- `userId` (string) - User ID
- `userName` (string, optional) - User name
- `userEmail` (string, optional) - User email
- `numericUserId` (string, optional) - Numeric user ID
- `coins` (number) - Coin balance (legacy)
- `balance` (number) - Wallet balance
- `uCoins` (number, optional) - User coins
- `createdAt` (timestamp) - Wallet creation date
- `updatedAt` (timestamp) - Last update time

**Permissions:**
- Read: Users (own), Admins (all)
- Create/Update: Users (own)
- Delete: Admins only

**Used By:**
- Wallet screen
- Coin balance display
- Payment processing

---

### 💰 **Payment & Transaction Collections**

#### 5. `orders` Collection
**Purpose:** Store coin purchase orders  
**Document ID:** Auto-generated  
**Fields:**
- `userId` (string) - User who placed order
- `coins` (number) - Coins purchased
- `amount` (number) - Amount paid (INR)
- `packageId` (string, optional) - Package ID
- `status` (string) - Order status (pending, completed, failed)
- `paymentId` (string, optional) - Payment ID
- `verifiedAt` (timestamp, optional) - Verification time
- `createdAt` (timestamp) - Order creation time

**Permissions:**
- Read: Users (own), Admins (all)
- Create: Authenticated users
- Update: Users (status only), Admins (all)
- Delete: Admins only

**Used By:**
- Payment processing
- Coin purchase history
- Admin panel transactions page

---

#### 6. `payments` Collection
**Purpose:** Store payment records  
**Document ID:** Auto-generated  
**Fields:**
- `userId` (string) - User who made payment
- `orderId` (string, optional) - Related order ID
- `amount` (number) - Payment amount
- `currency` (string) - Currency code (e.g., "INR")
- `status` (string) - Payment status
- `paymentMethod` (string, optional) - Payment method
- `paymentId` (string, optional) - Payment gateway ID
- `createdAt` (timestamp) - Payment creation time

**Permissions:**
- Read: Users (own), Admins (all)
- Create/Update/Delete: Admins only

**Used By:**
- Payment service
- Admin panel transactions page
- Payment history

---

#### 7. `withdrawal_requests` Collection
**Purpose:** Store user withdrawal requests  
**Document ID:** Auto-generated  
**Fields:**
- `userId` (string) - User requesting withdrawal
- `userName` (string, optional) - User name
- `displayId` (string, optional) - Display ID
- `amount` (number) - Withdrawal amount (INR)
- `withdrawalMethod` (string) - Payment method (e.g., "UPI")
- `paymentDetails` (map) - Payment details (e.g., UPI ID)
- `status` (string) - Request status (pending, approved, paid)
- `requestDate` (timestamp) - Request creation time
- `approvedDate` (timestamp, optional) - Approval time
- `paidDate` (timestamp, optional) - Payment time
- `paymentProofURL` (string, optional) - Payment proof URL
- `adminNotes` (string, optional) - Admin notes
- `approvedBy` (string, optional) - Admin user ID who approved

**Permissions:**
- Read: Users (own), Admins (all)
- Create: Users (own)
- Update: Admins only
- Delete: Not allowed

**Used By:**
- Withdrawal service
- Admin panel transactions page
- Wallet screen

---

### 🎁 **Gifts & Earnings Collections**

#### 8. `gifts` Collection
**Purpose:** Store gift definitions and metadata  
**Document ID:** Auto-generated  
**Fields:**
- `name` (string) - Gift name
- `cost` (number) - Gift cost in coins
- `imageURL` (string, optional) - Gift image URL
- `category` (string, optional) - Gift category
- `isActive` (boolean) - Gift active status

**Permissions:**
- Read: Public
- Write: Server/Cloud Functions only

**Used By:**
- Gift selection
- Live streaming gifts
- Gift service

---

#### 9. `earnings` Collection
**Purpose:** Store host earnings (C Coins)  
**Document ID:** User UID  
**Fields:**
- `userId` (string) - Host user ID
- `totalCCoins` (number) - Total C Coins earned
- `totalEarnings` (number, optional) - Total earnings in INR
- `withdrawableAmount` (number, optional) - Withdrawable amount
- `lastUpdated` (timestamp) - Last update time

**Permissions:**
- Read: Users (own), Admins (all)
- Create/Update: Authenticated users (for crediting hosts)
- Delete: Admins only

**Used By:**
- Earnings screen
- Withdrawal system
- Host earnings tracking
- Admin panel

---

### 📞 **Call & Communication Collections**

#### 10. `callRequests` Collection
**Purpose:** Store call requests (live stream calls and chat calls)  
**Document ID:** Auto-generated  
**Fields:**
- `callerId` (string) - User making the call
- `receiverId` (string, optional) - User receiving call (chat calls)
- `hostId` (string, optional) - Host ID (live stream calls)
- `streamId` (string, optional) - Live stream ID
- `status` (string) - Request status (pending, accepted, rejected, cancelled)
- `callType` (string, optional) - Call type (live_stream, chat)
- `createdAt` (timestamp) - Request creation time
- `answeredAt` (timestamp, optional) - Answer time

**Permissions:**
- Read: Caller, Receiver, Host
- Create: Authenticated users (as caller)
- Update: Caller, Receiver, Host
- Delete: Not allowed

**Used By:**
- Call request service
- Live streaming calls
- Chat calls

---

#### 11. `callTransactions` Collection
**Purpose:** Track call transactions and coin deductions  
**Document ID:** Auto-generated  
**Fields:**
- `callerId` (string) - User making the call
- `receiverId` (string, optional) - User receiving call
- `hostId` (string, optional) - Host ID
- `coinsDeducted` (number) - Coins deducted
- `callDuration` (number, optional) - Call duration in seconds
- `callType` (string, optional) - Call type
- `createdAt` (timestamp) - Transaction time

**Permissions:**
- Read: Authenticated users, Admins (all)
- Create: Authenticated users (as caller)
- Update/Delete: Admins only

**Used By:**
- Call coin deduction service
- Transaction history
- Admin panel

---

### 💬 **Chat Collections**

#### 12. `chats` Collection
**Purpose:** Store user-to-user chat conversations  
**Document ID:** Auto-generated  
**Fields:**
- `participants` (array) - Array of 2 user IDs
- `lastMessage` (string, optional) - Last message text
- `lastMessageTime` (timestamp, optional) - Last message time
- `unreadCount` (map, optional) - Unread count per participant
- `createdAt` (timestamp) - Chat creation time
- `participantNames` (map, optional) - Participant names
- `participantImages` (map, optional) - Participant images

**Subcollections:**
- `messages/{messageId}` - Chat messages

**Permissions:**
- Read: Participants, Admins (all)
- Create: Authenticated users (must be participant)
- Update: Participants, Admins (all)
- Delete: Admins only

**Used By:**
- Chat service
- Chat list screen
- Chat screen
- Admin panel

---

#### 13. `supportChats` Collection
**Purpose:** Store support chat conversations  
**Document ID:** Auto-generated  
**Fields:**
- `userId` (string) - User requesting support
- `subject` (string, optional) - Support subject
- `status` (string, optional) - Chat status
- `createdAt` (timestamp) - Chat creation time

**Subcollections:**
- `messages/{messageId}` - Support chat messages

**Permissions:**
- Read: User (own), Admins (all)
- Create: Authenticated users (own)
- Update: User (own), Admins (all)
- Delete: Not allowed

**Used By:**
- Support chat service
- Contact support screen
- Admin panel

---

### 🎥 **Live Streaming Collections**

#### 14. `live_streams` Collection
**Purpose:** Store active and past live streams  
**Document ID:** Auto-generated  
**Fields:**
- `hostId` (string) - Host user ID
- `title` (string, optional) - Stream title
- `description` (string, optional) - Stream description
- `thumbnailURL` (string, optional) - Thumbnail image URL
- `isLive` (boolean) - Live status
- `viewerCount` (number) - Current viewer count
- `startedAt` (timestamp) - Stream start time
- `endedAt` (timestamp, optional) - Stream end time
- `totalGiftsReceived` (number, optional) - Total gifts received
- `totalCoinsEarned` (number, optional) - Total coins earned

**Subcollections:**
- `chat/{messageId}` - Live stream chat messages
- `viewers/{viewerId}` - Current viewers list

**Permissions:**
- Read: Public
- Create: Authenticated users
- Update: Host (own stream)
- Delete: Host (own stream)

**Used By:**
- Live stream service
- Home screen
- Live streaming screen
- Agora integration

---

### 📢 **Content & Events Collections**

#### 15. `announcements` Collection
**Purpose:** Store app announcements  
**Document ID:** Auto-generated  
**Fields:**
- `title` (string) - Announcement title
- `description` (string) - Announcement description
- `date` (string) - Announcement date
- `time` (string) - Announcement time
- `type` (string) - Announcement type
- `isNew` (boolean) - New announcement flag
- `color` (number) - Display color (hex)
- `iconName` (string) - Icon name
- `createdAt` (timestamp) - Creation time
- `isActive` (boolean) - Active status

**Permissions:**
- Read: Public
- Write: Admins only

**Used By:**
- Event service
- Home screen announcements
- Admin panel

---

#### 16. `events` Collection
**Purpose:** Store app events  
**Document ID:** Auto-generated  
**Fields:**
- `title` (string) - Event title
- `description` (string) - Event description
- `date` (string) - Event date
- `time` (string) - Event time
- `imageURL` (string, optional) - Event image URL
- `location` (string, optional) - Event location
- `createdAt` (timestamp) - Creation time
- `isActive` (boolean) - Active status

**Permissions:**
- Read: Public
- Write: Admins only

**Used By:**
- Event service
- Events screen
- Admin panel

---

### 🚨 **Support & Reports Collections**

#### 17. `reports` Collection
**Purpose:** Store user reports (abuse, spam, etc.)  
**Document ID:** Auto-generated  
**Fields:**
- `reporterId` (string) - User who reported
- `reportedUserId` (string, optional) - Reported user ID
- `reportType` (string) - Type of report
- `description` (string, optional) - Report description
- `status` (string) - Report status
- `createdAt` (timestamp) - Report creation time

**Permissions:**
- Read: Admins only
- Create: Authenticated users
- Update/Delete: Admins only

**Used By:**
- Report functionality
- Admin panel

---

#### 18. `notificationRequests` Collection
**Purpose:** Queue notification requests for Cloud Functions  
**Document ID:** Auto-generated  
**Fields:**
- `userId` (string) - Target user ID
- `title` (string) - Notification title
- `body` (string) - Notification body
- `type` (string, optional) - Notification type
- `data` (map, optional) - Additional data
- `status` (string) - Request status
- `createdAt` (timestamp) - Request time

**Permissions:**
- Read/Update/Delete: Cloud Functions only
- Create: Authenticated users

**Used By:**
- Notification service
- Cloud Functions

---

## 📊 Collection Summary Table

| # | Collection | Purpose | Document ID | Read Access | Write Access |
|---|------------|---------|-------------|-------------|--------------|
| 1 | `admins` | Admin accounts | User UID | Admins | Admins |
| 2 | `adminActions` | Admin audit log | Auto | Admins | Admins |
| 3 | `users` | User profiles | User UID | All auth | Own/Admin |
| 4 | `wallets` | Wallet balances | User UID | Own/Admin | Own |
| 5 | `orders` | Coin orders | Auto | Own/Admin | Users/Admin |
| 6 | `payments` | Payment records | Auto | Own/Admin | Admin |
| 7 | `withdrawal_requests` | Withdrawal requests | Auto | Own/Admin | Users/Admin |
| 8 | `gifts` | Gift definitions | Auto | Public | Server |
| 9 | `earnings` | Host earnings | User UID | Own/Admin | Auth users |
| 10 | `callRequests` | Call requests | Auto | Caller/Receiver | Caller/Receiver |
| 11 | `callTransactions` | Call transactions | Auto | Auth/Admin | Caller/Admin |
| 12 | `chats` | User chats | Auto | Participants/Admin | Participants/Admin |
| 13 | `supportChats` | Support chats | Auto | Own/Admin | Own/Admin |
| 14 | `live_streams` | Live streams | Auto | Public | Host |
| 15 | `announcements` | Announcements | Auto | Public | Admin |
| 16 | `events` | Events | Auto | Public | Admin |
| 17 | `reports` | User reports | Auto | Admin | Users/Admin |
| 18 | `notificationRequests` | Notification queue | Auto | Server | Users |

---

## 🔗 Subcollections Structure

### Users Subcollections
```
users/{userId}/
  ├── transactions/{transactionId}
  ├── coinTransactions/{transactionId}
  ├── following/{targetUserId}
  ├── followers/{followerId}
  ├── seenAnnouncements/{announcementId}
  ├── dismissedAnnouncements/{announcementId}
  └── blocked/{userId}
```

### Chats Subcollections
```
chats/{chatId}/
  └── messages/{messageId}

supportChats/{chatId}/
  └── messages/{messageId}
```

### Live Streams Subcollections
```
live_streams/{streamId}/
  ├── chat/{messageId}
  └── viewers/{viewerId}
```

---

## 📈 Data Flow

### User Registration Flow
1. User signs up → `users` collection created
2. Wallet created → `wallets` collection
3. Earnings initialized → `earnings` collection

### Payment Flow
1. User creates order → `orders` collection
2. Payment processed → `payments` collection
3. Coins added → `users.uCoins` updated
4. Transaction logged → `users/{userId}/coinTransactions`

### Live Streaming Flow
1. Host starts stream → `live_streams` collection
2. Viewers join → `live_streams/{streamId}/viewers`
3. Gifts sent → `earnings` updated
4. Chat messages → `live_streams/{streamId}/chat`

### Call Flow
1. Caller creates request → `callRequests` collection
2. Receiver accepts → `callRequests` updated
3. Call starts → `callTransactions` created
4. Coins deducted → `users.uCoins` updated
5. Host credited → `earnings` updated

---

## 🔐 Security Summary

### Public Read Access
- `live_streams` - Public
- `gifts` - Public
- `announcements` - Public
- `events` - Public

### Authenticated Read Access
- `users` - All authenticated users
- `chats` - Participants
- `callTransactions` - All authenticated users

### User-Specific Read Access
- `wallets` - Own wallet only
- `earnings` - Own earnings only
- `orders` - Own orders only
- `payments` - Own payments only
- `withdrawal_requests` - Own requests only
- `users/{userId}/transactions` - Own transactions only
- `users/{userId}/coinTransactions` - Own transactions only

### Admin-Only Access
- `admins` - Admins only
- `adminActions` - Admins only
- `reports` - Admins only (read)
- All collections - Admin can read/write all

---

## 📊 Collection Statistics (Estimated)

| Collection | Estimated Documents | Growth Rate | Storage |
|------------|---------------------|-------------|---------|
| `users` | 1,000+ | High | Medium |
| `chats` | 5,000+ | Very High | High |
| `live_streams` | 500+ | Medium | Medium |
| `orders` | 2,000+ | High | Low |
| `payments` | 2,000+ | High | Low |
| `withdrawal_requests` | 100+ | Low | Low |
| `callTransactions` | 10,000+ | Very High | Medium |
| `announcements` | 10-50 | Very Low | Very Low |
| `events` | 10-50 | Very Low | Very Low |

---

## 🎯 Key Collections for Admin Panel

### Transactions Page Needs:
1. ✅ `withdrawal_requests` - All requests
2. ✅ `orders` - All orders
3. ✅ `payments` - All payments
4. ✅ `users/{userId}/transactions` - All user transactions
5. ✅ `users/{userId}/coinTransactions` - All coin transactions
6. ✅ `callTransactions` - All call transactions
7. ✅ `wallets` - All wallets
8. ✅ `earnings` - All earnings

### Announcements/Events Page Needs:
1. ✅ `announcements` - Create/Read/Update/Delete
2. ✅ `events` - Create/Read/Update/Delete

---

## 📝 Notes

1. **Indexes Required:** Some collections may need composite indexes for queries
2. **Storage:** Chat messages and live stream data can grow large
3. **Backup:** Regular backups recommended for critical collections
4. **Archiving:** Consider archiving old transactions and completed chats

---

**Report Generated:** $(date)  
**Total Collections:** 18 Main Collections + Multiple Subcollections  
**Database:** Cloud Firestore  
**Status:** ✅ Complete Structure Documented
