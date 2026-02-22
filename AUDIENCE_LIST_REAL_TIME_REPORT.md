# Audience List – Real-Time Issue Report

## Problem
The **Audience** list on the live stream screen shows **old data**: users appear with "Joined 19d ago", "Joined 9d ago", etc. The list should show only **current** viewers (who joined this session and are still in the stream), and update in real time when users join or leave.

## Current Behavior (What Was Checked)

### 1. **Data source**
- **File:** `lib/widgets/viewer_list_sheet.dart`
- The list uses a **real-time** `StreamBuilder` on:
  - `live_streams/{streamId}/viewers` (`.snapshots()`)
- So the UI **does** update in real time when documents are added or removed from that subcollection.

### 2. **When viewers are added**
- **File:** `lib/screens/agora_live_stream_screen.dart` (on Agora “join channel” success)
- Calls: `liveStreamService.joinStream(widget.streamId!, viewerId: viewerId)` with the current user’s UID.
- **File:** `lib/services/live_stream_service.dart` – `joinStream()`
- Adds a document: `live_streams/{streamId}/viewers/{viewerId}` with `joinedAt: serverTimestamp()`.
- So **join** is correct and real-time.

### 3. **When viewers are removed**
- **File:** `lib/screens/agora_live_stream_screen.dart` – `_cleanupAgoraEngine()`
- When a viewer leaves (back, end call, etc.), it calls:
  - `liveStreamService.leaveStream(widget.streamId!, viewerId: viewerId)` when `viewerId` is available.
- **File:** `lib/services/live_stream_service.dart` – `leaveStream()`
- Deletes: `live_streams/{streamId}/viewers/{viewerId}` and updates viewer count via Cloud Function.
- So **leave** is correct when the app calls it with `viewerId`.

### 4. **Root cause: viewers subcollection never cleared**
- When the **host starts a new stream**, the app often **reuses the same Firestore document** for that host (same `streamId`).
- **File:** `lib/services/live_stream_service.dart` – `createStream()`
  - When reusing an existing (inactive) stream document it:
    - Resets `viewerCount` to 0.
    - Clears **chat** via `clearLiveChat(documentId)`.
    - Does **not** clear the `viewers` subcollection.
- So the **viewers** subcollection still contains **all viewer documents from previous stream sessions** (e.g. from days ago). The list is bound to that subcollection, so it shows “Joined 19d ago” etc.
- When the **stream ends** (`endLiveStream()`), the code sets `isActive: false` and clears chat, but again **does not** clear the `viewers` subcollection. So old viewer docs remain for the next time the same document is used.

## Conclusion
- **Real-time listener:** Already correct; the Audience list listens to `live_streams/{streamId}/viewers` with `.snapshots()`.
- **Join/leave in a single session:** Correct; viewers are added on join and removed on leave with `viewerId`.
- **Why old data appears:** The **viewers subcollection is never cleared** when a stream ends or when a new stream session reuses the same stream document. So the list shows everyone who **ever** joined that stream doc, not only the current session.

## Fix (Implemented)
1. **Clear the `viewers` subcollection when starting a new stream**  
   In `createStream()`, when reusing an existing stream document (same host), clear `live_streams/{streamId}/viewers` so the new session starts with an empty audience list.

2. **Clear the `viewers` subcollection when the stream ends**  
   In `endLiveStream()`, after marking the stream as ended, clear the `viewers` subcollection so the document does not keep old viewer data for future reuse.

After this, the Audience list will show only viewers for the **current** session and will behave in a real-time way (join/leave) as intended.
