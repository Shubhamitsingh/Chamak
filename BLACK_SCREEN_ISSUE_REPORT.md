# 🔴 Black Screen Issue Report - Viewer Joining Host Stream

**Issue:** When viewer joins host live stream, entire screen turns black, host video not showing

**Status:** 🔴 **CRITICAL ISSUE IDENTIFIED**

---

## 🚨 PROBLEM ANALYSIS

### Issue #1: FloatingChatOverlay May Be Covering Screen
**Current Implementation:**
```dart
// lib/widgets/floating_chat_overlay.dart (Line 47-65)
return Align(
  alignment: Alignment.bottomLeft,
  child: IgnorePointer(
    ignoring: true,
    child: Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        ...
      ),
    ),
  ),
);
```

**Potential Problem:**
- `Align` widget might be expanding to fill screen
- If Column has issues, it might cover entire screen
- Need to ensure it's properly constrained

### Issue #2: Remote Video Not Loading
**Current Implementation:**
```dart
// lib/screens/agora_live_stream_screen.dart (Line 3036-3041)
// No video available yet - show black screen (waiting for connection)
return Container(
  width: double.infinity,
  height: double.infinity,
  color: Colors.black,
);
```

**Problem:**
- If `_remoteUid` is null, shows black screen
- This is expected while waiting for connection
- But if connection never happens, stays black forever

### Issue #3: Widget Tree Order
**Current Order:**
```
Stack(
  children: [
    Positioned.fill(_remoteVideo()),  // Video (may be black if no connection)
    FloatingChatOverlay(),             // Chat overlay
    ...
  ],
)
```

**Potential Problem:**
- If FloatingChatOverlay expands, it might cover video
- Need to ensure proper z-ordering

---

## 🔍 ROOT CAUSE HYPOTHESIS

1. **FloatingChatOverlay Expanding:**
   - `Align` widget might be taking full screen
   - Column might be expanding
   - Need to constrain properly

2. **Video Connection Issue:**
   - `_remoteUid` might be null
   - Agora connection might not be established
   - Video view might not be rendering

3. **Widget Tree Issue:**
   - Something might be covering the video
   - Z-ordering might be wrong

---

## ✅ PROPOSED FIXES

### Fix #1: Constrain FloatingChatOverlay Properly
- Ensure Align doesn't expand
- Add explicit size constraints
- Use SizedBox.shrink when no messages

### Fix #2: Add Loading State for Video
- Show loading indicator while waiting for connection
- Don't show black screen immediately
- Add timeout handling

### Fix #3: Verify Widget Tree Order
- Ensure video is bottom layer
- Ensure chat overlay doesn't cover video
- Verify z-ordering

---

**Next Step:** Implementing fixes...
