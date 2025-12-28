# PRIVATE ONE-TO-ONE CALL FEATURE - IMPLEMENTATION OVERVIEW

## ✅ FEASIBILITY ASSESSMENT

**YES, this feature is 100% possible** with your current tech stack:
- ✅ Agora RTC Engine (already integrated for live streaming)
- ✅ Firestore (for real-time call requests and status updates)
- ✅ LiveStreamModel (already has `hostStatus`, `currentCallUserId`, `callStartedAt` fields)
- ✅ User authentication and profiles (Firebase Auth)

---

## 🏗️ ARCHITECTURE OVERVIEW

### **1. DATA STRUCTURE (Firestore)**

#### **Call Requests Collection** (`callRequests`)
```
callRequests/{requestId}
{
  'requestId': 'unique_id',
  'streamId': 'stream_id',
  'callerId': 'viewer_user_id',
  'callerName': 'Viewer Name',
  'callerImage': 'profile_image_url',
  'hostId': 'host_user_id',
  'status': 'pending' | 'accepted' | 'rejected' | 'cancelled',
  'createdAt': Timestamp,
  'respondedAt': Timestamp,
  'callChannelName': 'private_call_channel_name', // For Agora
  'callToken': 'agora_token_for_call'
}
```

#### **Live Stream Updates** (existing `liveStreams` collection)
- Update `hostStatus`: `'live'` → `'in_call'` when call starts
- Update `currentCallUserId`: Set to caller's ID
- Update `callStartedAt`: Timestamp when call begins
- Revert to `'live'` when call ends

---

### **2. COMPONENTS TO CREATE**

#### **A. Call Request Service** (`lib/services/call_request_service.dart`)
- `sendCallRequest()` - Viewer sends call request
- `listenToCallRequests()` - Host listens for incoming requests
- `acceptCallRequest()` - Host accepts call
- `rejectCallRequest()` - Host rejects call
- `cancelCallRequest()` - Viewer cancels request
- `endCall()` - Either party ends the call
- `getActiveCall()` - Check if host is in a call

#### **B. Private Call Screen** (`lib/screens/private_call_screen.dart`)
- New screen for one-to-one video/audio call
- Uses Agora RTC with separate channel from live stream
- Shows local and remote video
- Mute/unmute controls
- End call button
- Updates Firestore when call ends

#### **C. Call Request Dialog** (`lib/widgets/call_request_dialog.dart`)
- Shows when host receives call request
- Displays caller's name and profile picture
- Accept/Reject buttons
- Auto-dismisses after timeout (30 seconds)

#### **D. Call Status Overlay** (`lib/widgets/call_status_overlay.dart`)
- Shows "Host is busy in a private call" message
- Appears for all viewers when host is in call
- Disables call button for other viewers

---

### **3. USER FLOW DIAGRAM**

```
VIEWER CLICKS CALL BUTTON
    ↓
Create call request in Firestore
    ↓
Show "Calling..." / "Waiting for host..." to viewer
    ↓
HOST RECEIVES NOTIFICATION (StreamBuilder listens)
    ↓
Show Call Request Dialog with Accept/Reject
    ↓
    ├─→ HOST ACCEPTS
    │       ↓
    │   Update stream: hostStatus = 'in_call'
    │   Set currentCallUserId = callerId
    │   Create private Agora channel
    │       ↓
    │   Navigate both users to PrivateCallScreen
    │       ↓
    │   One-to-one call starts
    │       ↓
    │   Other viewers see "Host is busy" overlay
    │       ↓
    │   Call ends → Update hostStatus = 'live'
    │   Remove currentCallUserId
    │   Return to live stream
    │
    └─→ HOST REJECTS
            ↓
        Update request status = 'rejected'
        Show "Host declined" to viewer
        Viewer stays in live stream
```

---

### **4. IMPLEMENTATION STEPS**

#### **STEP 1: Call Request Service**
- Create `CallRequestService` class
- Implement Firestore operations for call requests
- Handle real-time listeners

#### **STEP 2: Update Live Stream Service**
- Add method: `setHostInCall(streamId, callerId)`
- Add method: `setHostAvailable(streamId)`
- Update `hostStatus` and `currentCallUserId` fields

#### **STEP 3: Call Request Dialog Widget**
- Create dialog showing caller info
- Accept/Reject buttons
- Auto-timeout after 30 seconds

#### **STEP 4: Private Call Screen**
- New screen using Agora RTC
- Separate channel from live stream
- Video/audio controls
- End call functionality

#### **STEP 5: Update Viewer Screen**
- Add call request functionality to call button
- Show "Calling..." state
- Listen for call acceptance/rejection
- Show "Host is busy" overlay when host is in call
- Disable call button when host is busy

#### **STEP 6: Update Host Screen**
- Listen for incoming call requests
- Show call request dialog
- Handle accept/reject
- Navigate to private call screen

#### **STEP 7: Call Status Overlay**
- Widget showing "Host is busy" message
- Appears for all viewers when `hostStatus == 'in_call'`
- Disables call button

---

### **5. TECHNICAL DETAILS**

#### **Agora RTC Setup for Private Calls**
- Use separate Agora channel name for private calls
- Generate separate token for call channel
- Both users join the private call channel
- Live stream channel continues (but host video paused)

#### **Firestore Real-time Listeners**
- Host listens: `callRequests` collection where `hostId == currentUserId && status == 'pending'`
- Viewers listen: `liveStreams/{streamId}` for `hostStatus` changes
- Auto-cleanup: Delete old call requests after 5 minutes

#### **State Management**
- Use `StreamBuilder` for real-time updates
- Track call request state in viewer screen
- Track active call state in host screen

---

### **6. UI/UX CONSIDERATIONS**

#### **Call Request States (Viewer)**
- **Idle**: Call button enabled
- **Requesting**: Show "Calling..." with loading indicator
- **Waiting**: Show "Waiting for host to respond..."
- **Accepted**: Navigate to private call screen
- **Rejected**: Show "Host declined" message, return to idle
- **Host Busy**: Disable button, show "Host is busy"

#### **Host States**
- **Available**: Normal live stream
- **Incoming Call**: Show call request dialog
- **In Call**: Show "In private call" indicator, pause live stream video

#### **Other Viewers**
- See "Host is busy in a private call" overlay
- Call button disabled
- Live stream video paused or shows busy screen

---

### **7. EDGE CASES TO HANDLE**

1. **Host rejects while viewer is waiting**
   - Update request status
   - Show rejection message to viewer
   - Return viewer to normal state

2. **Viewer cancels request**
   - Delete/update request status
   - Return to idle state

3. **Host ends call early**
   - Update stream status
   - Both users return to live stream
   - Other viewers see host available again

4. **Network disconnection during call**
   - Detect disconnection
   - Auto-end call
   - Update Firestore status

5. **Multiple call requests**
   - Only allow one active call at a time
   - Reject new requests if host is busy
   - Queue or reject pending requests

6. **Call timeout**
   - Auto-reject if host doesn't respond in 30 seconds
   - Show timeout message to viewer

---

### **8. FILES TO CREATE/MODIFY**

#### **New Files:**
1. `lib/services/call_request_service.dart` - Call request management
2. `lib/screens/private_call_screen.dart` - One-to-one call screen
3. `lib/widgets/call_request_dialog.dart` - Incoming call dialog
4. `lib/widgets/call_status_overlay.dart` - "Host is busy" overlay
5. `lib/models/call_request_model.dart` - Call request data model

#### **Files to Modify:**
1. `lib/screens/agora_live_stream_screen.dart` - Add call request logic
2. `lib/services/live_stream_service.dart` - Add call status methods
3. `lib/models/live_stream_model.dart` - Already has needed fields ✅

---

### **9. ESTIMATED COMPLEXITY**

- **Difficulty**: Medium
- **Time Estimate**: 4-6 hours of development
- **Dependencies**: None (all required packages already installed)
- **Breaking Changes**: None (additive feature)

---

### **10. TESTING SCENARIOS**

1. ✅ Viewer sends call request → Host receives notification
2. ✅ Host accepts → Both navigate to private call
3. ✅ Host rejects → Viewer sees rejection message
4. ✅ Other viewers see "Host is busy" overlay
5. ✅ Call ends → All return to normal state
6. ✅ Multiple viewers try to call → Only first works, others see "Host is busy"
7. ✅ Network disconnection → Call ends gracefully
8. ✅ Call timeout → Request auto-rejects

---

## 🎯 IMPLEMENTATION APPROACH

### **Phase 1: Backend/Service Layer** (Foundation)
- Create `CallRequestService`
- Update `LiveStreamService` with call status methods
- Create `CallRequestModel`

### **Phase 2: UI Components** (User Interface)
- Create call request dialog
- Create call status overlay
- Update call button with request functionality

### **Phase 3: Private Call Screen** (Core Feature)
- Create private call screen
- Integrate Agora RTC for one-to-one calls
- Handle call lifecycle

### **Phase 4: Integration** (Connect Everything)
- Wire up call button to send requests
- Add host listener for incoming calls
- Add viewer listeners for status updates
- Test end-to-end flow

---

## ✅ CONFIRMATION CHECKLIST

Before I start implementation, please confirm:

- [ ] You want to proceed with this implementation approach
- [ ] The feature should work as described above
- [ ] You're okay with using separate Agora channels for private calls
- [ ] The "Host is busy" overlay approach is acceptable
- [ ] 30-second timeout for call requests is acceptable
- [ ] You want the live stream to pause/show busy screen when host is in call

---

## 🚀 READY TO IMPLEMENT?

Once you confirm, I will:
1. Create all necessary service files
2. Build the private call screen
3. Add call request dialogs and overlays
4. Integrate everything into your existing live stream screen
5. Test the complete flow

**This feature will enhance your app significantly and provide a premium user experience!** 🎉






























