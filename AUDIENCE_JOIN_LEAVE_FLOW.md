# Audience list – How join/leave works (host live stream)

## 1. How the viewer list is shown
- **Screen:** When you tap the group/people icon on the **viewer’s phone** (or host’s), a bottom sheet opens: **Audience**.
- **Data:** It reads from Firestore in **real time**:
  - Path: `live_streams / {streamId} / viewers`
  - Each document id = viewer’s user id. Fields include `joinedAt` (when they joined).

So the list **is** a real-time listener: when docs are added or removed, the list updates.

---

## 2. When a viewer JOINS (other phone opens your live)
1. Viewer opens your live from home → app calls `joinStream(streamId)` **without** viewerId (only to bump count).
2. App opens **Agora live stream screen** with that `streamId`.
3. Agora SDK joins the channel. On **success** (`onJoinChannelSuccess`):
   - App gets current user id: `viewerId = currentUser.uid`
   - App calls: `liveStreamService.joinStream(streamId, viewerId: viewerId)`
4. **LiveStreamService.joinStream(streamId, viewerId: viewerId)**:
   - Adds a document: `live_streams / {streamId} / viewers / {viewerId}` with `joinedAt: serverTimestamp()`.
   - Calls Cloud Function to increment `viewerCount` on the stream.

So: **join = add one doc under `viewers`**. The Audience list sees it and shows that user.

---

## 3. When a viewer LEAVES (other phone closes your live)
1. Viewer closes the live screen (back button or end).
2. **Agora screen** runs cleanup: `_cleanupAgoraEngine()`.
3. In cleanup, for a viewer it calls:  
   `liveStreamService.leaveStream(streamId, viewerId: viewerId)` (viewerId = current user uid).
4. **LiveStreamService.leaveStream(streamId, viewerId: viewerId)**:
   - Deletes the document: `live_streams / {streamId} / viewers / {viewerId}`.
   - Calls Cloud Function to decrement `viewerCount`.

So: **leave = remove that viewer’s doc**. The Audience list updates and that user disappears.

---

## 4. Why you still see the OLD user list

Two parts:

### A. Old data was never cleared
- When you **start a new live**, the app **reuses** the same Firestore stream document (same host).
- We added code to **clear** the `viewers` subcollection when you start a new stream so the list starts empty and only shows **this** session’s join/leave.
- So in code: **join/leave and “clear on new stream” are correct.**

### B. Clear is blocked by Firestore rules
- The **viewers** subcollection rule was: only **that viewer** can delete **their own** doc (`request.auth.uid == viewerId`).
- When **you (the host)** go live, the app runs on **your** phone and tries to delete **all** viewer docs (old session). That is done with **host’s auth**, not each viewer’s.
- So Firestore **denies** those deletes: host is not allowed to delete other users’ viewer docs. The clear fails (we only log it), and the **old list stays**.

So: **the issue is not join/leave logic; it’s that the host is not allowed to clear the viewers list in Firestore.**

---

## 5. Fix applied
- **Firestore rules** were updated so that **the host of the stream** can also delete documents in `live_streams/{streamId}/viewers`.
- So when you go live and the app clears the old viewers list, the deletes are now allowed and the Audience list starts empty and stays real-time (join = add doc, leave = remove doc).

After deploying the new rules, the Audience list should show only **current** viewers: who joined and who left in **real time**.
