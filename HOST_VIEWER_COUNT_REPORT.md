# Host Screen: Viewer Count (0) and Audience List Not Real-Time – Report

## 1. What You Reported

- **Viewer screen:** Shows the **correct** user count (how many people are watching the host’s live stream).
- **Host screen:** Always shows **(0)** for viewer count and the count does **not** update in real time.
- **Host screen:** The icon/section where the host can see **who joined** (Audience list) also does **not** show real-time data.

You wanted a clear report on what is wrong and why, from a senior live-streaming app perspective.

---

## 2. Root Cause (Summary)

The host and viewers use **different identifiers** for the same Firestore document when the host **reuses** an existing stream document:

| Who    | Uses streamId = | Firestore document actually used | Result |
|--------|------------------|-----------------------------------|--------|
| Viewer | Document ID (from list) | Correct doc → `viewerCount` and `viewers` subcollection | Correct count and list |
| Host   | New UUID (generated at “Go Live”) | When doc is **reused**, data is written to **old** doc ID; host still listens to **new** UUID | Host listens to wrong/non-existent doc → **0** and empty list |

So:

1. **Viewer count on host:** Host listens to `getLiveStream(streamId)` with a **wrong** `streamId` when the document was reused, so the snapshot is null or stale → UI shows **0**.
2. **Audience list on host:** `ViewerListSheet` uses the same `streamId` (wrong when reused) for `live_streams/{streamId}/viewers`, so it reads the wrong (or empty) subcollection → list not real time / empty.

The **viewer count** and **“who joined”** issues on the host screen are the **same bug**: wrong `streamId` on the host when the stream document is reused.

---

## 3. Detailed Flow (What Goes Wrong)

### 3.1 When the host goes live

1. **home_screen.dart** generates a **new** ID:
   - `streamId = FirebaseFirestore.instance.collection('live_streams').doc().id` (e.g. `abc123new`).
2. It creates a `LiveStreamModel` with `streamId: streamId` and calls:
   - `liveStreamService.createStream(stream)`.
3. It then navigates to the live screen with:
   - `AgoraLiveStreamScreen(..., streamId: streamId)`.
   - So the **host’s screen** always uses this **new** `streamId` (`abc123new`).

### 3.2 Inside createStream (live_stream_service.dart)

- Code checks if this host **already has** a stream document (e.g. from a previous session):
  - Query: `where('hostId', isEqualTo: stream.hostId).limit(1)`.
- If an **existing** document is found (e.g. doc id `xyz789old`):
  - It **reuses** that document: `documentId = existingStreamQuery.docs.first.id` → `documentId = xyz789old`.
  - All writes go to **that** document: `_firestore.collection(_collection).doc(documentId).set(...)` → `live_streams/xyz789old`.
- So:
  - **Real** data (viewerCount, `viewers` subcollection, heartbeat, etc.) lives under **document ID = xyz789old**.
  - The app **never** tells the host to use `xyz789old`; it never returns this id.
- The host keeps using `streamId = abc123new`:
  - `getLiveStream(abc123new)` → listens to `live_streams/abc123new` → that document either doesn’t exist or is never updated → **viewer count stays 0**.
  - `live_streams/abc123new/viewers` → wrong path → audience list empty or not real time.

### 3.3 Why the viewer screen is correct

- Viewers don’t get `streamId` from the host’s “Go Live” flow. They get it from the **list of active streams** (e.g. `getActiveLiveStreams()`).
- In **live_stream_service.dart**, when building that list (`_processSnapshot`), the code **overrides** `streamId` with the **actual document ID**:
  - `modelData['streamId'] = doc.id;`
  - So each list item has `streamId = xyz789old` (the real doc id).
- When a viewer opens a stream from the list:
  - They use `streamId = xyz789old`.
  - `getLiveStream(xyz789old)` and `live_streams/xyz789old/viewers` are correct → **viewer count and “who joined” are correct** on the viewer side.

### 3.4 First time vs reuse

- **First time** the host goes live (no existing document):  
  - No reuse; `documentId = stream.streamId` (the new uuid).  
  - Data is written to the same id the host uses.  
  - So host can show correct count and list **until** they end and go live again.
- **Second (or later) time** the host goes live:  
  - Reuse kicks in; data goes to the **old** document id.  
  - Host still uses the **new** streamId → **0** and wrong/empty audience list.

So the bug appears when the host has **reused** a stream document (typical after ending a stream and going live again).

---

## 4. Where in the Code

| Component | File | What happens |
|-----------|------|----------------------|
| Host gets streamId and navigates | `lib/screens/home_screen.dart` | Generates new `streamId`, calls `createStream(stream)`, then passes that **same** `streamId` to `AgoraLiveStreamScreen`. Never uses the **actual** document id. |
| createStream | `lib/services/live_stream_service.dart` | When reusing, sets `documentId = existingStreamQuery.docs.first.id` and writes to `doc(documentId)`. **Does not return** `documentId`. Return type is `Future<void>`. |
| Host (and viewer) viewer count | `lib/screens/agora_live_stream_screen.dart` | `_buildViewerCount()` uses `getLiveStream(widget.streamId!)`. For host, `widget.streamId` is wrong when doc was reused → 0. |
| Host audience list | `lib/widgets/viewer_list_sheet.dart` | Uses `live_streams/{streamId}/viewers` with `streamId` from host → wrong path when doc was reused. |
| List of streams (viewers) | `lib/services/live_stream_service.dart` | `_processSnapshot` sets `modelData['streamId'] = doc.id` so list items use **document ID** → viewers get correct `streamId`. |

---

## 5. Fix (What Must Change)

- **Single source of truth:** The **document ID** in `live_streams` must be the same id used by:
  - The host screen (viewer count + audience list),
  - Viewers (already correct via list),
  - Join/leave and Cloud Function (they already use `streamId` as doc id).

So the host must use the **actual document ID** that `createStream` wrote to, not the pre-generated new uuid when the document was reused.

**Concrete changes:**

1. **live_stream_service.dart – createStream**
   - Change return type from `Future<void>` to `Future<String>`.
   - Return the **actual document ID** used for the write (i.e. `documentId` after the reuse logic).
   - Callers then use this as the only `streamId` for that session.

2. **home_screen.dart – “Go Live” flow**
   - Await `createStream(stream)` and use the **returned** value as `streamId` when navigating:
     - `final actualStreamId = await liveStreamService.createStream(stream);`
     - Then: `AgoraLiveStreamScreen(..., streamId: actualStreamId)`.
   - Use `actualStreamId` (and only this) for that live session (e.g. heartbeat, end stream, etc. already use `widget.streamId` from the screen, so once the screen gets the right id, everything aligns).

3. **Optional but recommended**
   - When reusing a document in `createStream`, set the document’s `streamId` field to the **actual** document ID (e.g. `streamData['streamId'] = documentId` before `set()`). That way any code that reads `streamId` from the document (e.g. getLiveStreamOnce by streamId field) also gets the correct id.

After this:

- Host screen uses the same document id as Firestore → `getLiveStream(streamId)` and `live_streams/{streamId}/viewers` are correct → **viewer count and audience list on the host will be real time and match the viewer screen.**

---

## 6. Summary Table

| Issue | Cause | Fix |
|-------|--------|-----|
| Host always sees viewer count (0) | Host listens to wrong doc (new uuid) while data is on reused doc id | createStream returns actual doc id; host uses it for navigation and screen |
| Host “who joined” list not real time | Same wrong streamId → wrong `viewers` subcollection path | Same fix: host uses actual document id everywhere |
| Viewer count and list correct on viewer | List already uses doc.id as streamId | No change needed |

---

## 7. Checklist After Fix

- [ ] Host goes live **first time** → viewer count and audience list update when viewers join/leave.
- [ ] Host ends stream and goes live **again** (reuse path) → viewer count and audience list still update in real time.
- [ ] Viewer count on host matches viewer count on viewer screen for the same stream.
- [ ] Audience list (group icon) on host shows the same viewers as the backend/list and updates in real time.

This report and the code changes below address the issue at the source (streamId/document id consistency) so both viewer count and “who joined” work correctly on the host screen.
