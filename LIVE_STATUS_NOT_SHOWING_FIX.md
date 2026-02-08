# 🔧 Live Status Not Showing - Issue & Fix

## ❌ **PROBLEM IDENTIFIED**

**Issue:** When you go live, your profile shows in the grid but displays as "OFFLINE" instead of "LIVE", even though you're actively streaming.

**Root Cause:** The query is filtering out your stream because:
1. **Heartbeat timeout:** If `lastHeartbeat` is older than 3 minutes, stream is filtered out
2. **StartedAt timeout:** If no heartbeat and `startedAt` is older than 2 minutes, stream is filtered out

**Why This Happens:**
- Heartbeat should be sent every 20 seconds
- But if heartbeat fails or is delayed, stream gets filtered out
- The 2-minute threshold is too aggressive for streams without heartbeat

---

## ✅ **FIXES NEEDED**

### **Fix 1: Increase Time Threshold for Streams Without Heartbeat**

**File:** `lib/services/live_stream_service.dart` (line ~401)

**Current Code:**
```dart
// REAL-TIME: Only show streams that started within last 2 minutes (more aggressive)
if (difference.inMinutes <= 2 && now.isAfter(startedAt)) {
  isRealTimeActive = true;
} else if (difference.inMinutes > 2) {
  // Stream started more than 2 minutes ago - not real-time active
  print('   ❌ Filtering out: ${doc.id} - started ${difference.inMinutes} min ago - NOT real-time active');
  return null; // Filter out - not real-time active
}
```

**Problem:** 2 minutes is too short. If heartbeat fails or is delayed, stream disappears.

**Fixed Code:**
```dart
// REAL-TIME: Show streams that started within last 10 minutes (if no heartbeat)
// This gives more time for heartbeat to catch up
if (difference.inMinutes <= 10 && now.isAfter(startedAt)) {
  isRealTimeActive = true;
  print('   ✅ Stream ${doc.id} started ${difference.inMinutes} min ago - REAL-TIME ACTIVE (no heartbeat, within 10 min)');
} else if (difference.inMinutes > 10) {
  // Stream started more than 10 minutes ago - not real-time active
  print('   ❌ Filtering out: ${doc.id} - started ${difference.inMinutes} min ago - NOT real-time active');
  _markStreamAsInactive(doc.id).catchError((e) {
    print('   ⚠️ Could not mark stream inactive (permission error expected): $e');
  });
  return null; // Filter out - not real-time active
}
```

**Why:** 10 minutes gives enough buffer for heartbeat to catch up while still filtering out old streams.

---

### **Fix 2: Add Fallback for Active Streams**

**File:** `lib/services/live_stream_service.dart` (line ~420)

**Add before line 423:**
```dart
// FALLBACK: If stream is marked as active and has no endedAt, keep it
// This prevents filtering out active streams due to timing issues
if (!isRealTimeActive && isActive == true && endedAt == null && hostStatus != 'ended') {
  print('   ⚠️ Stream ${doc.id} is active but no recent heartbeat/startedAt - keeping as fallback');
  isRealTimeActive = true; // Keep stream if it's marked as active
}
```

**Why:** If stream is clearly active (`isActive: true`, no `endedAt`, `hostStatus != 'ended'`), keep it even if timing checks fail.

---

### **Fix 3: Verify Heartbeat is Being Sent**

**File:** `lib/screens/agora_live_stream_screen.dart` (line ~279)

**Check:** Heartbeat timer should be running. Add more logging:

```dart
_heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
  if (!mounted || widget.streamId == null) {
    timer.cancel();
    return;
  }
  
  // Send heartbeat to keep stream alive
  _liveStreamService.keepStreamAlive(widget.streamId!).then((_) {
    debugPrint('💓 ✅ Heartbeat sent successfully for stream: ${widget.streamId}');
  }).catchError((error) {
    debugPrint('❌ Error sending heartbeat: $error');
    debugPrint('   Stream ID: ${widget.streamId}');
    debugPrint('   This will cause stream to disappear after 3 minutes!');
    // Don't cancel timer on error - keep trying
  });
  
  debugPrint('💓 Heartbeat sent for stream: ${widget.streamId}');
});
```

---

## 🔍 **DEBUGGING STEPS**

### **Step 1: Check Debug Logs**

When you go live, check console for:
```
💓 Heartbeat sent for stream: [streamId]
💓 ✅ Heartbeat sent successfully for stream: [streamId]
```

**If you see errors:**
```
❌ Error sending heartbeat: [error]
```
→ Heartbeat is failing, which causes stream to disappear

### **Step 2: Check Firestore**

1. Go to Firestore Console
2. Open `live_streams` collection
3. Find your stream document
4. Check:
   - `isActive: true` ✅
   - `hostStatus: 'live'` ✅
   - `lastHeartbeat: [recent timestamp]` ✅ (should update every 20 seconds)
   - `endedAt: null` ✅

**If `lastHeartbeat` is old or missing:**
→ Heartbeat is not being sent/updated

### **Step 3: Check Matching**

Check debug logs for:
```
🔍 [EXPLORE] Live hostIds from streams: [yourUserId, ...]
🔍 [EXPLORE] Approved hostIds from approvedHosts: [yourUserId, ...]
   ✅ MATCHED LIVE: yourUserId - YourName (streamId: ...)
```

**If you see:**
```
⚠️ [EXPLORE] No live hosts matched!
   - Live stream hostIds: [yourUserId]
   - Approved hostIds: [yourUserId]
```
→ IDs match but stream was filtered out by query

---

## 🎯 **QUICK FIX (Temporary)**

If you need an immediate fix, increase the time threshold:

**File:** `lib/services/live_stream_service.dart` line 401

**Change:**
```dart
if (difference.inMinutes <= 2 && now.isAfter(startedAt)) {
```

**To:**
```dart
if (difference.inMinutes <= 30 && now.isAfter(startedAt)) {
```

This will show streams for up to 30 minutes even without heartbeat (temporary fix).

---

## ✅ **PERMANENT FIX**

Apply all three fixes above:
1. Increase time threshold to 10 minutes
2. Add fallback for active streams
3. Verify heartbeat is working

This ensures:
- Streams stay visible as long as they're active
- Heartbeat issues don't cause streams to disappear
- Only truly inactive streams are filtered out
