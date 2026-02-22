# Live Stream Viewer List vs Count – Mismatch Report & Fix

## 1. Confirmed Behavior

- **Viewer count** (eye icon + number on host and viewer screens): **Working correctly.**  
  It comes from the `live_streams/{streamId}` document field `viewerCount`, updated by the Cloud Function `updateViewerCount` when viewers join/leave.

- **Viewer list** (User List icon → “who’s watching”): **Mismatch.**  
  It shows the `live_streams/{streamId}/viewers` subcollection. The list can still show users who have left (old/stale entries), so it does not always match the current session.

## 2. Root Cause

- **Count** is updated **only** by the Cloud Function when the client calls it with `action: 'join'` or `'leave'`. So the count is correct as long as leave is called.
- **List** is updated by the **client** only:
  - **Join:** client writes `viewers/{viewerId}` in `joinStream()`.
  - **Leave:** client deletes `viewers/{viewerId}` in `leaveStream()`.

If the client **does not** run or **fails** to delete the viewer doc on leave (e.g. app killed, back button with cleanup in background, network error, or leave path not passing `viewerId`), then:

- The Cloud Function may still be called (count decrements) **or** not (count stays high).
- The viewer doc in `viewers` is **not** removed, so the list still shows that user.

So the list can show **more** users than are actually watching, while the main viewer count (from the stream document) can be correct. That’s the “user list mismatch” and “old user data still shown”.

## 3. Fix: Server-Side Removal on Leave

To keep the **viewer list** in sync with the **viewer count** and current session:

1. **Cloud Function `updateViewerCount`**  
   On `action === 'leave'`:
   - Accept an optional **viewerId** in the request.
   - If **viewerId** is present, delete `live_streams/{streamId}/viewers/{viewerId}` (in addition to decrementing `viewerCount`).

   This way, every time a viewer “leaves” through the CF, their document is removed from the list even if the client-side delete never ran or failed.

2. **Client**  
   When calling the Cloud Function for leave, pass the current user’s **viewerId** (e.g. `request.auth.uid` or the same id used when adding to `viewers` on join).

3. **Client-side delete**  
   Keep the existing client delete in `leaveStream()` so the list updates immediately when possible; the CF delete acts as a reliable backup.

## 4. Result After Fix

- **Viewer count:** Unchanged; still correct via existing `updateViewerCount` join/leave.
- **Viewer list:** Matches current session because:
  - On leave, the CF removes the viewer doc when `viewerId` is provided.
  - Stale entries from missed client deletes are removed the next time that user (or any leave path that passes viewerId) triggers the CF.

Both the viewer count and the user list then reflect only **current-session** viewers.
