# 🔥 Firestore Index Setup for Live Streams

## Issue
Live streams are not appearing on other devices because Firestore requires a composite index for queries that filter by one field (`isActive`) and order by another (`startedAt`).

## Solution

### Step 1: Deploy the Index

I've created `firestore.indexes.json` with the required index. Deploy it to Firestore:

```bash
firebase deploy --only firestore:indexes
```

**OR** manually create it in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **chamak-39472**
3. Go to **Firestore Database** → **Indexes** tab
4. Click **"Create Index"**
5. Fill in:
   - **Collection ID:** `live_streams`
   - **Fields to index:**
     - Field: `isActive` → Order: **Ascending**
     - Field: `startedAt` → Order: **Descending**
6. Click **"Create"**
7. Wait for index to build (usually 1-2 minutes)

### Step 2: Verify Index Status

The index will show as "Building" initially, then "Enabled" when ready.

### Step 3: Test

1. Host goes live on Phone A
2. Check Phone B's home screen
3. Live stream should appear in the grid within seconds

## Alternative: Use Fallback Query

If you can't deploy the index immediately, the code now includes a fallback that:
- Queries without `orderBy` (no index needed)
- Sorts results manually in the app
- Works immediately but may be slightly slower

The fallback activates automatically if the index is missing.

## Files Changed

1. ✅ `firestore.indexes.json` - Index definition
2. ✅ `firebase.json` - Added Firestore config
3. ✅ `lib/services/live_stream_service.dart` - Added error handling & fallback

## Debugging

Check console logs for:
- `📡 Creating live stream` - Stream creation
- `✅ Live stream created` - Success confirmation
- `🔍 Setting up getActiveLiveStreams query` - Query setup
- `📊 Query snapshot received` - Results received
- `❌ Error in getActiveLiveStreams` - Any errors

If you see index errors, deploy the index or wait for the fallback to activate.


