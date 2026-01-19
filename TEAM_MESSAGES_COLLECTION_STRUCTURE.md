# Team Messages Collection Structure

## Collection Name: `team_messages`

## Document Structure

Each document in the `team_messages` collection represents a broadcast message sent by the admin to all users.

### Fields:

```javascript
{
  "message": "string",           // Required: The message text
  "senderId": "string",          // Required: Admin user ID (e.g., "admin_user_id")
  "senderName": "string",        // Required: Display name (e.g., "Chamakz Team")
  "timestamp": "timestamp",      // Required: Server timestamp when message was sent
  "readBy": {                    // Required: Map of userId -> true/false
    "user1_uid": true,
    "user2_uid": false,
    // ... tracks which users have read this message
  },
  "imageUrl": "string"           // Optional: URL of image if message includes image
}
```

### Example Document:

```javascript
{
  "message": "Welcome to Chamakz! New update available.",
  "senderId": "admin_user_id_123",
  "senderName": "Chamakz Team",
  "timestamp": "2025-01-15T10:30:00Z",
  "readBy": {
    "user1_uid": true,
    "user2_uid": false
  },
  "imageUrl": null  // or "https://example.com/image.jpg" if has image
}
```

## Firestore Rules

✅ Rules are already added in `firestore.rules`:

```javascript
match /team_messages/{messageId} {
  allow read: if request.auth != null;  // All authenticated users can read
  allow create: if isAdmin();            // Only admins can create
  allow update: if request.auth != null  // Users can update readBy, admins can update all
    && (isAdmin() || ...);
  allow delete: if isAdmin();            // Only admins can delete
}
```

## How It Works

1. **Auto-Creation**: Collection is created automatically when admin sends first message
2. **Admin sends message**: From Admin Panel → Team Messages tab
3. **Document created**: Firestore creates document with all fields
4. **Users see message**: App reads from `team_messages` collection
5. **Read tracking**: When user opens message, `readBy[userId]` is set to `true`

## Firestore Index Required

If you get a "FAILED_PRECONDITION" error, you need to create an index:

**Collection**: `team_messages`  
**Fields**: 
- `timestamp` (Descending)

Create index in Firebase Console:
1. Firebase Console → Firestore → Indexes
2. Click "Create Index"
3. Collection: `team_messages`
4. Field: `timestamp` → Order: Descending
5. Click "Create"

Or use the link provided in the error message.

## Testing

1. Open Admin Panel in app
2. Go to "Team Messages" tab
3. Type a message and click "Send to All Users"
4. Collection will be auto-created
5. Check Messages Screen - "Chamakz Team" box should appear
