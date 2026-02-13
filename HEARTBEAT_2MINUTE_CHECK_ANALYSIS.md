# 🔍 Heartbeat 2-Minute Check Analysis Report

**Date:** Analysis Report  
**Status:** ⚠️ **CHANGES NEEDED**

---

## 📋 Current Implementation Analysis

### **1. Heartbeat Sending (Agora Screen)**
- **Location:** `lib/screens/agora_live_stream_screen.dart`
- **Frequency:** Every 20 seconds ✅
- **Status:** Working correctly

### **2. Stream List Filtering (live_stream_service.dart)**
- **Location:** `lib/services/live_stream_service.dart` (Line 354-389)
- **Current Logic:**
  - ✅ If heartbeat ≤ 5 minutes → Stream is active
  - ⚠️ If heartbeat 5-10 minutes → Still shows (network tolerance)
  - ❌ If heartbeat > 10 minutes → Stream filtered out
- **Issue:** Uses 5-10 minute window (too long)

### **3. Live Badge Check (online_status_service.dart)**
- **Location:** `lib/services/online_status_service.dart` (Line 208-295)
- **Current Logic:**
  - ❌ **DOES NOT CHECK HEARTBEAT AT ALL**
  - Only checks: `isActive`, `hostStatus`, `endedAt`, `startedAt` (24 hours)
- **Issue:** Badge may show "Live" even if heartbeat stopped 2+ minutes ago

---

## 🎯 Required Changes

### **Change 1: Add Heartbeat Check to Live Badge**
**File:** `lib/services/online_status_service.dart`  
**Method:** `getUserLiveStatusStream()`

**Current Code:**
```dart
// Line 224-289: Checks isActive, hostStatus, endedAt, startedAt
// BUT DOES NOT CHECK lastHeartbeat
```

**Required Change:**
- Add `lastHeartbeat` check
- If heartbeat exists and is older than 2 minutes → Return `false` (not live)
- If heartbeat is within 2 minutes → Continue with other checks

### **Change 2: Update Stream List Filtering to 2 Minutes**
**File:** `lib/services/live_stream_service.dart`  
**Method:** `_processSnapshot()` (Line 354-389)

**Current Code:**
```dart
if (heartbeatAge.inMinutes <= 5) {
  isRealTimeActive = true;
} else if (heartbeatAge.inMinutes > 10) {
  // Filter out
} else {
  // 5-10 minutes: Still show
}
```

**Required Change:**
- Change to: If heartbeat ≤ 2 minutes → Active
- If heartbeat > 2 minutes → Filter out (immediately)

---

## 🔄 Expected Behavior After Changes

### **Scenario 1: Host is Live (Heartbeat Active)**
- Heartbeat sent every 20 seconds
- Heartbeat age: 0-20 seconds
- **Result:** ✅ Badge shows "LIVE" (red)

### **Scenario 2: Host Crashes/Force Closes (Heartbeat Stops)**
- Last heartbeat: 1 minute ago
- **Result:** ✅ Badge still shows "LIVE" (within 2 min window)

### **Scenario 3: Host Crashes (Heartbeat Stops for 2+ Minutes)**
- Last heartbeat: 2 minutes 1 second ago
- **Result:** ❌ Badge immediately changes to "ONLINE" or "OFFLINE"
- **Result:** ❌ Stream removed from list

### **Scenario 4: Host Ends Stream Properly**
- `hostStatus` = 'ended'
- `endedAt` timestamp set
- **Result:** ❌ Badge immediately changes (regardless of heartbeat)

---

## 📝 Files to Modify

1. ✅ `lib/services/online_status_service.dart`
   - Add heartbeat check to `getUserLiveStatusStream()`
   - Check if `lastHeartbeat` exists
   - If heartbeat > 2 minutes → Return `false`

2. ✅ `lib/services/live_stream_service.dart`
   - Change heartbeat window from 5-10 minutes to 2 minutes
   - If heartbeat > 2 minutes → Filter out immediately

---

## ⚠️ Important Notes

1. **Heartbeat is sent every 20 seconds**, so 2-minute window = 6 missed heartbeats
2. **Network delays:** 2 minutes should be enough tolerance for network issues
3. **Immediate badge update:** Badge will update within 2 minutes of heartbeat stopping
4. **Stream list sync:** Both badge and stream list will use same 2-minute logic

---

## ✅ Verification Checklist

After changes:
- [ ] Badge shows "LIVE" when heartbeat is active (within 2 min)
- [ ] Badge changes to "ONLINE"/"OFFLINE" when heartbeat stops for 2+ minutes
- [ ] Stream list filters out streams with heartbeat > 2 minutes
- [ ] Badge updates immediately when host ends stream properly
- [ ] All screens using badge update correctly (home, profile, chat, viewer list)

---

**Status:** ⚠️ **READY FOR IMPLEMENTATION**  
**Waiting for user permission to proceed**
