# 1-to-1 Private Call: Video Off Not Showing on Other Side – Cross-Check Report

**Date:** February 19, 2025  
**Scope:** When user or host turns off video during a private call, the other side does not see that video was removed (or sees black with no clear indicator).  
**Requested:** Cross-check implementation, identify if it is a code issue vs user device/network issue, and produce a report only. **No code or behavior changes were made.**

---

## 1. Issue Summary

- **Reported:** When the user (caller) turns off video, the host does not see that video is off; when the host turns off video, the user does not see it.
- **Interpretation:** Either (a) the other side does not get any visible indication that video was turned off (e.g. still shows last frame or black), or (b) the “video off” state is not reflected in the UI at all.

---

## 2. Implementation Cross-Check

### 2.1 Where Video On/Off Is Handled

**File:** `lib/screens/private_call_screen.dart`

| What | Location | Behavior |
|------|----------|----------|
| Local video toggle | `_toggleVideo()` (~line 600) | Calls `_engine.enableLocalVideo(!_isVideoEnabled)` and updates `_isVideoEnabled`. |
| Local state | `_isVideoEnabled` (default `true`) | Used in UI to show/hide **local** preview (small tile and full-screen when swapped). |
| Remote video state callback | `onRemoteVideoStateChanged` (~463) | Logs `RemoteVideoState` (Starting / Decoding / Stopped). **Does not update any state and does not call setState().** |
| Remote “video off” state | — | **Not stored.** There is no variable such as `_remoteVideoEnabled` or `_remoteVideoOff`. |
| UI for remote video | Build method (~850–880, ~1080–1090) | When `_remoteUid != null`, remote is always shown via `AgoraVideoView` (remote uid). **No branch for “remote video off”** (e.g. avatar + “Video off” placeholder). |

So:

- **User/Host turns off video:** Local side correctly stops sending video via `enableLocalVideo(false)`. Agora is expected to signal the other peer with `onRemoteVideoStateChanged(..., remoteVideoStateStopped, ...)`.
- **Other side (Host/User):** The app only logs that callback; it does **not** store “remote video off” and does **not** change the UI to show a “Video off” state (e.g. placeholder with avatar and text). The remote view remains the same `AgoraVideoView` for that UID, which can show black or a frozen last frame when the remote has stopped sending video.

Conclusion: The app does not currently **reflect** remote video-off to the user in the UI. So even when Agora works correctly, the other side will not see a clear “video is off” indication; they may only see a black or stuck remote view.

---

## 3. Agora Behavior (Expected)

- When one peer calls **`enableLocalVideo(false)`**, that peer stops publishing the camera track.
- On the **other** peer, the Agora SDK should fire **`onRemoteVideoStateChanged`** with:
  - **State:** `RemoteVideoState.remoteVideoStateStopped`
  - **Reason:** e.g. `RemoteVideoStateReason.remoteVideoStateReasonRemoteMuted` (or similar, depending on SDK version).

So the **expected** behavior is:

- User turns off video → Host’s app receives `onRemoteVideoStateChanged(remoteUid, remoteVideoStateStopped)`.
- Host turns off video → User’s app receives the same.

If this callback is not fired or is delayed, the issue can be on the **network** or **device/SDK** side (see below).

---

## 4. Root Cause Analysis

### 4.1 App-Side (Code)

| Finding | Severity |
|--------|----------|
| `onRemoteVideoStateChanged` does not update any state (e.g. `_remoteVideoEnabled`) | **High** – Without this, the UI cannot show “remote video off”. |
| No `setState()` in `onRemoteVideoStateChanged` | **High** – UI would not rebuild even if state were added later. |
| No “remote video off” UI (placeholder with avatar + “Video off”) | **High** – User/Host have no clear indication that the other side turned off video; they may only see black. |
| Local video off is correctly implemented | **OK** – Local preview is hidden when `_isVideoEnabled` is false. |

So from a **code** perspective: the app does not track or display remote video-off state. That explains why “user remove video not showing on host” and “host remove video not showing on user” in the sense of **no visible “video off” indication** (and possibly a black remote view).

### 4.2 Network / Device

Even after fixing the above, the following can still cause “video off” not to show on the other side:

| Factor | Effect |
|--------|--------|
| **Network delay / packet loss** | `onRemoteVideoStateChanged(remoteVideoStateStopped)` can arrive late or not at all. |
| **Weak or unstable connection** | Callbacks may be delayed or dropped; remote view may freeze or go black regardless of our UI. |
| **Device / OS** | Some devices or OS versions may handle Agora callbacks differently or throttle background updates. |
| **SDK version** | Different Agora SDK versions can have different timing or conditions for firing `remoteVideoStateStopped`. |

So if **after** adding state + UI for “remote video off” the issue still appears only for some users or in poor network conditions, it is reasonable to treat it as a **user device/network** issue rather than a generic app bug.

---

## 5. Summary Table

| Question | Answer |
|----------|--------|
| Is remote “video off” **tracked** in the app? | **No** – no state variable for remote video on/off. |
| Is remote “video off” **shown** in the UI? | **No** – no placeholder or label when remote stops video. |
| Does the app **receive** Agora’s remote video state? | **Only in logs** – `onRemoteVideoStateChanged` is implemented but only for logging, no state or UI. |
| Can this be a **code** issue? | **Yes** – missing state and UI for “remote video off”. |
| Can this be a **user phone/network** issue? | **Yes** – callbacks can be delayed or lost; black/frozen view can also be due to network. |

---

## 6. Recommendations (For Future Work – Not Done Here)

- **Track remote video state:** In `onRemoteVideoStateChanged`, set a variable (e.g. `_remoteVideoEnabled`) from `state != remoteVideoStateStopped` and call `setState()` so the UI can react.
- **Show “Video off” on the other side:** When remote video is stopped, show a placeholder (e.g. avatar + “Video is off” or “Camera off”) instead of only the remote `AgoraVideoView` (which may be black).
- **Optional:** If needed, re-enable remote stream when they turn video back on (e.g. `muteRemoteVideoStream(uid, mute: false)` when state becomes Starting/Decoding again); current join flow already enables remote streams in `onUserJoined`.

---

## 7. Files Referenced

- `lib/screens/private_call_screen.dart` – Private call UI, Agora event handlers, video toggle, and build (remote/local views).

**No files were modified.** This report is for analysis and planning only.
