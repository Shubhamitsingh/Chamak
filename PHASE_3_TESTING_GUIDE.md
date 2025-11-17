# 🧪 Phase 3: User Profiles - Testing Guide

## ✅ Pre-Testing Setup

### 1. Ensure Firebase is Configured:
```bash
# Check firebase_options.dart exists
lib/firebase_options.dart ✅
```

### 2. Install Dependencies:
```bash
cd "C:\Users\Shubham Singh\Desktop\chamak"
flutter pub get
```

### 3. Check Permissions (Android):
- ✅ Camera permission (already in AndroidManifest.xml)
- ✅ Storage permissions (already in AndroidManifest.xml)

---

## 🚀 Testing Flow

### Test 1: Login & Initial Profile View
**Steps:**
1. Run the app: `flutter run`
2. Enter your phone number
3. Receive and enter OTP
4. Navigate to **Profile** tab (bottom navigation)

**Expected Results:**
- ✅ Loading indicator appears briefly
- ✅ Profile screen loads with your data
- ✅ Default profile icon shows (no photo yet)
- ✅ Name shows "Set your name" (if not set)
- ✅ User ID is displayed (first 7 characters)
- ✅ Stats show: 0 Followers, 0 Following, Level 1
- ✅ No location shown (not set yet)

**Console Output:**
```
✅ User logged in
✅ Profile data loaded from Firestore
```

---

### Test 2: Edit Profile - Basic Info
**Steps:**
1. On Profile screen, tap the **Edit** icon (pencil on profile picture)
2. Wait for data to load
3. Fill in the fields:
   - Name: "Your Name"
   - Age: "25"
   - Gender: Select "Male" or other
   - Country: Select "India" or other
   - City: "Your City"
   - Bio: "Living my best life! 🌟"
4. Click **"Save Changes"**

**Expected Results:**
- ✅ Form loads with empty/existing fields
- ✅ All fields are editable
- ✅ Dropdowns work correctly
- ✅ Bio character counter shows (max 150)
- ✅ Save button shows loading indicator
- ✅ Success message appears: "Profile updated successfully!"
- ✅ Auto-navigates back to Profile screen
- ✅ Profile updates immediately with new data

**Console Output:**
```
📝 Updating user profile: kJ3mD9xP2QaW1234567890
✅ Profile updated successfully
```

**Profile Screen After Save:**
- ✅ Name displays correctly
- ✅ City and Country show with location icon
- ✅ All changes are visible

---

### Test 3: Profile Picture Upload - Camera
**Steps:**
1. Go to **Edit Profile**
2. Tap on the **Camera icon** (on profile picture)
3. Select **"Open Camera"**
4. Grant camera permission if asked
5. Take a photo
6. Click **"Save Changes"**

**Expected Results:**
- ✅ Camera permission dialog appears (first time)
- ✅ Camera opens
- ✅ Photo is captured
- ✅ Image preview shows in profile picture
- ✅ Save button works
- ✅ Loading indicator appears during upload
- ✅ Success message: "Profile updated successfully!"
- ✅ Picture uploads to Firebase Storage
- ✅ Profile screen shows new picture

**Console Output:**
```
📤 Uploading new profile picture...
📤 Uploading profile picture for user: kJ3mD9xP2QaW1234567890
✅ Profile picture uploaded successfully
🔗 Download URL: https://firebasestorage.googleapis.com/v0/b/chamak-39472.appspot.com/o/profile_pictures%2FkJ3mD9xP...
💾 Saving profile to Firestore...
✅ Profile saved successfully!
```

---

### Test 4: Profile Picture Upload - Gallery
**Steps:**
1. Go to **Edit Profile**
2. Tap on the **Camera icon**
3. Select **"Open Gallery"**
4. Grant storage permission if asked
5. Choose an image from gallery
6. Click **"Save Changes"**

**Expected Results:**
- ✅ Gallery permission dialog appears (first time)
- ✅ Gallery opens
- ✅ Image can be selected
- ✅ Image preview shows
- ✅ Upload works correctly
- ✅ Old photo is deleted from Storage
- ✅ New photo is uploaded
- ✅ Profile updates with new picture

**Console Output:**
```
🗑️ Deleting profile picture: https://firebasestorage.googleapis.com/...
✅ Profile picture deleted successfully
📤 Uploading new profile picture...
✅ Profile picture uploaded successfully
💾 Saving profile to Firestore...
✅ Profile saved successfully!
```

---

### Test 5: Real-Time Updates
**Steps:**
1. Keep app open on Profile screen
2. On another device or Firebase Console:
   - Go to Firestore → users → [your userId]
   - Change displayName to "Updated Name"
3. Watch the Profile screen

**Expected Results:**
- ✅ Profile automatically updates
- ✅ No need to refresh
- ✅ New name appears instantly
- ✅ StreamBuilder working correctly

---

### Test 6: Form Validation
**Steps:**
1. Go to **Edit Profile**
2. Try invalid inputs:
   - Empty name (try to save)
   - Age: "5" (too young)
   - Age: "150" (too old)
   - Age: "abc" (not a number)
   - Bio: Type 200 characters

**Expected Results:**
- ✅ Empty name shows error: "Please enter your name"
- ✅ Age < 13 shows error: "Please enter valid age (13-100)"
- ✅ Age > 100 shows error
- ✅ Non-numeric age shows error
- ✅ Bio limited to 150 characters
- ✅ Character counter updates
- ✅ Save button doesn't work if validation fails

---

### Test 7: Copy User ID
**Steps:**
1. On Profile screen
2. Tap the **User ID box** (with copy icon)

**Expected Results:**
- ✅ Snackbar appears: "ID xxxxxxx copied to clipboard!"
- ✅ ID is actually copied (paste somewhere to verify)

---

### Test 8: Navigation & UI
**Steps:**
1. Test all navigation:
   - Profile → Edit → Back
   - Profile → Wallet
   - Profile → Messages
   - Profile → Level
   - Profile → Account & Security
   - Profile → Contact Support
   - Profile → Settings

**Expected Results:**
- ✅ All navigation works
- ✅ Back button returns to profile
- ✅ No crashes
- ✅ Smooth transitions

---

## 🔥 Firebase Console Verification

### Check Firestore:
1. Go to Firebase Console
2. Navigate to **Firestore Database**
3. Click **users** collection
4. Find your document (userId)

**Should See:**
```javascript
{
  userId: "kJ3mD9xP2QaW1234567890",
  phoneNumber: "+919876543210",
  countryCode: "+91",
  displayName: "Your Name",        // ✅ Updated
  photoURL: "https://...",         // ✅ Firebase Storage URL
  bio: "Living my best life! 🌟", // ✅ Your bio
  age: 25,                         // ✅ Your age
  gender: "Male",                  // ✅ Your gender
  country: "India",                // ✅ Your country
  city: "Your City",               // ✅ Your city
  followersCount: 0,
  followingCount: 0,
  level: 1,
  createdAt: Timestamp(...),
  lastLogin: Timestamp(...),
  isActive: true
}
```

### Check Firebase Storage:
1. Go to Firebase Console
2. Navigate to **Storage**
3. Open **profile_pictures** folder
4. Open your **userId** folder

**Should See:**
```
profile_pictures/
  └── kJ3mD9xP2QaW1234567890/
      └── profile_kJ3mD9xP2QaW1234567890.jpg  ✅
```

**File Details:**
- Type: image/jpeg
- Size: < 1 MB (compressed)
- Metadata shows uploadedBy and uploadedAt

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Permission denied" when opening camera
**Solution:**
- Check AndroidManifest.xml has camera permission
- Manually grant permission in: Settings → Apps → Chamak → Permissions

### Issue 2: "Firebase Storage: Object not found"
**Solution:**
- Check Firebase Storage is enabled in Console
- Check Storage security rules (should be in test mode)

### Issue 3: Profile picture not loading
**Solution:**
- Check internet connection
- Check photoURL in Firestore (should be a valid URL)
- Check Firebase Storage rules allow read access

### Issue 4: "User not found" error
**Solution:**
- Make sure you're logged in
- Check Firebase Auth has the user
- Check Firestore has user document with correct userId

### Issue 5: Changes not saving
**Solution:**
- Check console for error messages
- Verify Firestore security rules allow write access
- Check internet connection

---

## 📊 Performance Testing

### Test Load Times:
- **Profile Screen Load**: < 1 second
- **Profile Picture Upload**: 2-5 seconds (depends on image size)
- **Save Profile**: < 2 seconds
- **Real-time Update**: Instant

### Test with Poor Network:
1. Enable slow network in Android Studio
2. Try uploading large image
3. Should show loading indicator
4. Should complete eventually or show error

---

## ✅ Final Checklist

Before marking Phase 3 as complete:

**Functionality:**
- [ ] Login works
- [ ] Profile screen loads
- [ ] Edit profile opens
- [ ] All fields can be edited
- [ ] Form validation works
- [ ] Camera opens and captures
- [ ] Gallery opens and selects
- [ ] Profile picture uploads
- [ ] Data saves to Firestore
- [ ] Storage uploads work
- [ ] Real-time updates work
- [ ] Navigation works
- [ ] Copy ID works

**UI/UX:**
- [ ] Loading states show
- [ ] Success messages show
- [ ] Error messages show (test by disconnecting internet)
- [ ] Animations are smooth
- [ ] No layout issues
- [ ] Profile picture displays correctly
- [ ] Default icon shows when no photo

**Firebase:**
- [ ] User data in Firestore
- [ ] Profile picture in Storage
- [ ] photoURL in Firestore matches Storage URL
- [ ] All fields populated correctly

**Console:**
- [ ] No errors in console
- [ ] Success logs appear
- [ ] No warnings

---

## 🎉 Success Criteria

**Phase 3 is complete when:**
1. ✅ User can view their profile with real-time data
2. ✅ User can edit all profile fields
3. ✅ User can upload profile picture from camera
4. ✅ User can upload profile picture from gallery
5. ✅ Profile picture saves to Firebase Storage
6. ✅ Profile data saves to Firestore
7. ✅ Profile updates in real-time
8. ✅ All UI states work (loading, error, success)
9. ✅ Navigation works smoothly
10. ✅ No crashes or major bugs

---

## 📝 Test Results Template

```
PHASE 3 TESTING RESULTS
========================

Date: _____________
Tester: _____________
Device: _____________

TEST 1: Login & Profile View        [ ] PASS  [ ] FAIL
TEST 2: Edit Basic Info              [ ] PASS  [ ] FAIL
TEST 3: Camera Upload                [ ] PASS  [ ] FAIL
TEST 4: Gallery Upload               [ ] PASS  [ ] FAIL
TEST 5: Real-Time Updates            [ ] PASS  [ ] FAIL
TEST 6: Form Validation              [ ] PASS  [ ] FAIL
TEST 7: Copy User ID                 [ ] PASS  [ ] FAIL
TEST 8: Navigation                   [ ] PASS  [ ] FAIL

Firebase Verification:
  Firestore Data:                    [ ] PASS  [ ] FAIL
  Storage Files:                     [ ] PASS  [ ] FAIL

Issues Found:
_____________________________________________
_____________________________________________

Overall Result:                      [ ] PASS  [ ] FAIL
```

---

## 🚀 Next: Phase 4!

Once Phase 3 testing is complete and all tests pass, you're ready for:
- Phase 4: Live Streaming
- Phase 5: Social Features

**Happy Testing! 🎉**


