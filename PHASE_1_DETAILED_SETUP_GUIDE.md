# 🚀 Phase 1: Complete Setup Guide for Beginners

## Table of Contents
1. [Agora Setup (Detailed)](#1-agora-setup)
2. [Firebase Setup (Detailed)](#2-firebase-setup)
3. [Visual Architecture](#3-visual-architecture)
4. [What You'll Have After This Phase](#4-checklist)

---

# 1. AGORA SETUP 🎥

## What is Agora?
Agora is a real-time video/audio platform that powers your live streaming and video calls. Think of it as the "engine" that handles all video transmission between users.

---

## Step 1.1: Create Agora Account

### 📋 Instructions:

1. **Open your browser** and go to: **https://console.agora.io/**

2. **Sign Up:**
   - Click **"Sign Up"** button (top right)
   - You can sign up with:
     - ✅ Email
     - ✅ GitHub account
     - ✅ Google account

3. **Verify your email** (check inbox/spam folder)

4. **Complete Profile:**
   - Enter your name
   - Select your country
   - Agree to terms and conditions

```
┌─────────────────────────────────────┐
│     AGORA CONSOLE - Sign Up         │
├─────────────────────────────────────┤
│  Email:    [________________]       │
│  Password: [________________]       │
│                                     │
│  [✓] I agree to terms               │
│                                     │
│         [ Sign Up ]                 │
└─────────────────────────────────────┘
```

---

## Step 1.2: Create a New Project

### 📋 Instructions:

1. **After login**, you'll see the Agora Dashboard

2. **Click on "Project Management"** in the left sidebar
   
3. **Click the "+ Create" button** (or "Create Project")

4. **Fill in Project Details:**
   ```
   Project Name: Chamak Live (or your app name)
   Use Case: [Select] Social
   ```

5. **Click "Submit"**

```
Visual Representation:

┌──────────────────────────────────────────┐
│  AGORA CONSOLE                           │
├──────────────────────────────────────────┤
│  Dashboard                               │
│  Project Management  ←── Click Here      │
│  Usage                                   │
│  Analytics                               │
└──────────────────────────────────────────┘

              ↓

┌──────────────────────────────────────────┐
│  Create New Project                      │
├──────────────────────────────────────────┤
│  Project Name: [Chamak Live____]         │
│  Use Case:     [Social ▼]                │
│                                          │
│           [Cancel]  [Submit]             │
└──────────────────────────────────────────┘
```

---

## Step 1.3: Get Your APP ID

### 📋 Instructions:

1. **After creating the project**, you'll see your project listed

2. **Click on your project name** "Chamak Live"

3. **You'll see the APP ID** - This is a unique identifier for your app
   ```
   Example: 1e8897d2962241148777d93f9a8fe6d2
   ```

4. **COPY THIS APP ID** and save it somewhere safe (Notepad, Google Docs, etc.)

```
Visual:

┌────────────────────────────────────────────────┐
│  Project: Chamak Live                          │
├────────────────────────────────────────────────┤
│                                                │
│  APP ID: 1e8897d2962241148777d93f9a8fe6d2     │
│          [📋 Copy]                             │
│                                                │
│  Status: ● Active                              │
│  Created: Nov 7, 2024                          │
└────────────────────────────────────────────────┘
```

---

## Step 1.4: Enable Token Authentication (CRITICAL!)

### ⚠️ Why This is Important:
Without this, anyone can join your streams/calls if they know the channel name. Token authentication keeps your app secure.

### 📋 Instructions:

1. **In your project page**, look for **"Features"** section

2. **Find "Primary Certificate"** 
   - You'll see it says "Not Enabled" or has an "Enable" button

3. **Click "Enable"**

4. **A pop-up will appear with your APP CERTIFICATE**
   ```
   Example: 6e4cb9f06be24b3bb82ff466b3756d64
   ```

5. **⚠️ IMPORTANT:** 
   - **COPY THIS CERTIFICATE** immediately
   - Save it securely (you can't view it again!)
   - Store it with your APP ID

```
Visual Flow:

┌────────────────────────────────────────────────┐
│  Project Features                              │
├────────────────────────────────────────────────┤
│                                                │
│  Primary Certificate:                          │
│  ○ Not Enabled              [Enable]  ←Click   │
│                                                │
└────────────────────────────────────────────────┘

              ↓ After Clicking Enable

┌────────────────────────────────────────────────┐
│  ⚠️  SAVE YOUR APP CERTIFICATE                 │
├────────────────────────────────────────────────┤
│  This will only be shown ONCE!                 │
│                                                │
│  Certificate:                                  │
│  6e4cb9f06be24b3bb82ff466b3756d64              │
│  [📋 Copy]                                     │
│                                                │
│  ⚠️  Save this in a secure place!              │
│                                                │
│                [I've Saved It]                 │
└────────────────────────────────────────────────┘
```

---

## Step 1.5: Save Your Credentials

### 📋 Create a Safe Document:

Create a text file named `agora_credentials.txt` and save:

```
=================================
AGORA CREDENTIALS - KEEP SECRET!
=================================

Project Name: Chamak Live
APP ID: 1e8897d2962241148777d93f9a8fe6d2
APP CERTIFICATE: 6e4cb9f06be24b3bb82ff466b3756d64
Created: November 7, 2024

⚠️ NEVER share these publicly!
⚠️ NEVER commit to GitHub!
=================================
```

---

## 🎯 What You Have Now (Agora):
- ✅ Agora account
- ✅ Project created
- ✅ APP ID (saved)
- ✅ APP Certificate (saved)
- ✅ Token authentication enabled

---

# 2. FIREBASE SETUP 🔥

## What is Firebase?
Firebase is Google's backend service. It will store your user data, live stream information, and handle user authentication.

---

## Step 2.1: Create Firebase Account

### 📋 Instructions:

1. **Go to:** https://console.firebase.google.com/

2. **Sign in with your Google Account**
   - Use existing Google account
   - Or create a new one

3. You'll see the Firebase Console dashboard

```
┌────────────────────────────────────────────┐
│  FIREBASE                   [Your Photo]   │
├────────────────────────────────────────────┤
│                                            │
│      Welcome to Firebase Console          │
│                                            │
│         [+ Add Project]  ←── Click This    │
│                                            │
└────────────────────────────────────────────┘
```

---

## Step 2.2: Create New Firebase Project

### 📋 Instructions:

**Step 1 of 3: Project Name**
```
1. Click "+ Add Project"
2. Enter project name: Chamak-Live
3. Click "Continue"
```

**Step 2 of 3: Google Analytics**
```
1. You'll see "Enable Google Analytics"
2. Toggle it ON (recommended for tracking)
3. Click "Continue"
```

**Step 3 of 3: Analytics Account**
```
1. Select "Default Account for Firebase"
2. Accept terms
3. Click "Create Project"
```

**Wait 30-60 seconds** while Firebase creates your project.

```
Visual Flow:

Step 1:
┌─────────────────────────────────────┐
│  Create a project                   │
├─────────────────────────────────────┤
│  Project name:                      │
│  [Chamak-Live____________]          │
│                                     │
│  ℹ️  Your project name will be      │
│     visible to your users           │
│                                     │
│          [Continue]                 │
└─────────────────────────────────────┘

Step 2:
┌─────────────────────────────────────┐
│  Google Analytics                   │
├─────────────────────────────────────┤
│  Enable Google Analytics            │
│  [Toggle: ON ✓]                     │
│                                     │
│  ℹ️  Recommended for tracking       │
│     user behavior and app usage     │
│                                     │
│          [Continue]                 │
└─────────────────────────────────────┘

Step 3:
┌─────────────────────────────────────┐
│  Analytics Setup                    │
├─────────────────────────────────────┤
│  Analytics Account:                 │
│  [Default Account for Firebase ▼]   │
│                                     │
│  [✓] I accept the terms             │
│                                     │
│       [Create Project]              │
└─────────────────────────────────────┘

        ↓ Creating...

┌─────────────────────────────────────┐
│  🔄 Creating your project...        │
│     Please wait...                  │
└─────────────────────────────────────┘

        ↓ Done!

┌─────────────────────────────────────┐
│  ✅ Your project is ready!          │
│        [Continue]                   │
└─────────────────────────────────────┘
```

---

## Step 2.3: Add Android App to Firebase

### 📋 Instructions:

1. **In Firebase Console**, click the **Android icon** (🤖)
   - Or click "Add App" → Select Android

2. **Fill in the form:**

```
Android package name: com.example.live_vibe
(This must match your Flutter app's package name!)

App nickname (optional): Chamak Live Android

Debug signing certificate: [Leave Empty for now]
```

3. **Click "Register App"**

```
Visual:

┌────────────────────────────────────────────┐
│  Add Firebase to your Android app          │
├────────────────────────────────────────────┤
│                                            │
│  Android package name: *                   │
│  [com.example.live_vibe______]             │
│                                            │
│  App nickname (optional):                  │
│  [Chamak Live Android________]             │
│                                            │
│  Debug signing certificate:                │
│  [_________________________]               │
│                                            │
│           [Register App]                   │
└────────────────────────────────────────────┘
```

---

## Step 2.4: Download google-services.json

### 📋 Instructions:

1. **After registering**, Firebase will show a **Download button**

2. **Click "Download google-services.json"**
   - This file contains your Firebase configuration
   - It's like a "key" that connects your app to Firebase

3. **Save this file** - you'll need it soon!

```
Visual:

┌────────────────────────────────────────────┐
│  Download config file                      │
├────────────────────────────────────────────┤
│                                            │
│  Download google-services.json             │
│                                            │
│  ⬇️  [Download google-services.json]       │
│                                            │
│  ℹ️  You'll place this file in your        │
│     Flutter project later                  │
│                                            │
│         [Next] [Skip this step]            │
└────────────────────────────────────────────┘
```

4. **Click "Next"** (Skip the SDK setup for now)

5. **Click "Continue to Console"**

---

## Step 2.5: Enable Firestore Database

### What is Firestore?
Firestore is like a big Excel spreadsheet in the cloud where you'll store:
- User profiles
- Live stream information
- Video call data

### 📋 Instructions:

1. **In Firebase Console**, look at the left sidebar

2. **Click "Build" → "Firestore Database"**

3. **Click "Create Database"**

4. **Select Mode:**
   ```
   Choose: "Start in test mode"
   (We'll secure it later)
   ```

5. **Choose Location:**
   ```
   Select: asia-south1 (India) or closest to your users
   ```

6. **Click "Enable"**

Wait 30 seconds for Firestore to initialize.

```
Visual Flow:

Left Sidebar:
┌────────────────────────┐
│  Firebase Console      │
├────────────────────────┤
│  👥 Authentication     │
│  🗄️  Firestore Database│ ← Click
│  💾 Storage            │
│  ⚙️  Functions         │
└────────────────────────┘

        ↓

┌────────────────────────────────────────────┐
│  Create Firestore Database                 │
├────────────────────────────────────────────┤
│                                            │
│  Choose starting mode:                     │
│                                            │
│  ⚪ Production mode                         │
│  🔘 Test mode  ←── Select This             │
│                                            │
│  ⚠️  Anyone can read/write for 30 days     │
│     (We'll secure it later)                │
│                                            │
│           [Next]                           │
└────────────────────────────────────────────┘

        ↓

┌────────────────────────────────────────────┐
│  Set Cloud Firestore location             │
├────────────────────────────────────────────┤
│                                            │
│  Location: [asia-south1 (Mumbai) ▼]       │
│                                            │
│  ⚠️  Cannot be changed later!              │
│                                            │
│           [Enable]                         │
└────────────────────────────────────────────┘

        ↓ Creating...

┌────────────────────────────────────────────┐
│  ✅ Firestore Database Created!            │
│                                            │
│  Status: ● Active                          │
│  Mode: Test mode                           │
│  Location: asia-south1                     │
└────────────────────────────────────────────┘
```

---

## Step 2.6: Enable Firebase Authentication

### What is Firebase Auth?
This handles user login/signup with phone numbers in your app.

### 📋 Instructions:

1. **In left sidebar**, click **"Authentication"**

2. **Click "Get Started"**

3. **Click "Sign-in method" tab** (at the top)

4. **Enable Phone Authentication:**
   ```
   - Find "Phone" in the list
   - Click on it
   - Toggle "Enable" to ON
   - Click "Save"
   ```

```
Visual Flow:

┌────────────────────────────────────────────┐
│  Authentication                            │
├────────────────────────────────────────────┤
│  Users | Sign-in method | Templates        │
│                                            │
│  Sign-in providers:                        │
│                                            │
│  📧 Email/Password        [Disabled]       │
│  📱 Phone                 [Disabled] ← Click│
│  🔐 Google                [Disabled]       │
│  📘 Facebook              [Disabled]       │
└────────────────────────────────────────────┘

        ↓ After Clicking Phone

┌────────────────────────────────────────────┐
│  Phone                                     │
├────────────────────────────────────────────┤
│                                            │
│  Enable: [Toggle: OFF] ←── Turn ON         │
│                                            │
│  ℹ️  Users will sign in with phone         │
│     number and OTP verification            │
│                                            │
│  Test phone numbers (optional):            │
│  [Add test number]                         │
│                                            │
│        [Cancel]  [Save]                    │
└────────────────────────────────────────────┘
```

---

## Step 2.7: Enable Firebase Storage

### What is Firebase Storage?
This stores user profile photos and images.

### 📋 Instructions:

1. **In left sidebar**, click **"Storage"**

2. **Click "Get Started"**

3. **Security Rules:**
   ```
   Choose: "Start in test mode"
   ```

4. **Location:**
   ```
   Use the same location as Firestore: asia-south1
   ```

5. **Click "Done"**

```
Visual:

┌────────────────────────────────────────────┐
│  Cloud Storage                             │
├────────────────────────────────────────────┤
│                                            │
│  Secure rules for Cloud Storage:           │
│                                            │
│  🔘 Test mode                              │
│  ⚪ Production mode                         │
│                                            │
│  ⚠️  Anyone can read/write for 30 days     │
│                                            │
│           [Next]                           │
└────────────────────────────────────────────┘

        ↓

┌────────────────────────────────────────────┐
│  ✅ Storage bucket created!                │
│                                            │
│  Bucket: chamak-live.appspot.com           │
└────────────────────────────────────────────┘
```

---

## Step 2.8: Enable Cloud Functions

### What are Cloud Functions?
These are server-side code that runs in the cloud. We'll use this to generate secure Agora tokens.

### 📋 Instructions:

1. **In left sidebar**, click **"Functions"**

2. **Click "Get Started"**

3. **Upgrade to Blaze Plan (Pay-as-you-go):**
   - ⚠️ Don't worry! It's FREE for small projects
   - You only pay if you exceed free limits (very unlikely)
   - Firebase gives generous free tier

4. **Click "Continue"**

5. You'll see the Functions dashboard

```
Visual:

┌────────────────────────────────────────────┐
│  Cloud Functions                           │
├────────────────────────────────────────────┤
│                                            │
│  ⚠️  Requires Blaze Plan                   │
│                                            │
│  Blaze Plan benefits:                      │
│  ✓ Free tier included                      │
│  ✓ Pay only for what you use              │
│  ✓ Functions can access external APIs      │
│                                            │
│  Monthly free tier:                        │
│  • 2M function invocations                 │
│  • 400K GB-seconds                         │
│  • 200K CPU-seconds                        │
│                                            │
│       [Upgrade to Blaze Plan]              │
└────────────────────────────────────────────┘
```

---

## Step 2.9: Save Firebase Credentials

### 📋 Create a Document:

Create `firebase_info.txt`:

```
=================================
FIREBASE PROJECT INFORMATION
=================================

Project Name: Chamak-Live
Project ID: chamak-live-xxxxx

Android Package: com.example.live_vibe

FILES DOWNLOADED:
✓ google-services.json (saved in Downloads)

SERVICES ENABLED:
✓ Firestore Database (Test mode, asia-south1)
✓ Authentication (Phone)
✓ Storage (Test mode)
✓ Cloud Functions (Blaze plan)

Created: November 7, 2024
=================================
```

---

# 3. VISUAL ARCHITECTURE 📊

## How Everything Connects:

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR FLUTTER APP                      │
│                      (Chamak Live)                       │
└────────────────┬──────────────────┬─────────────────────┘
                 │                  │
    ┌────────────▼────────┐  ┌──────▼─────────┐
    │   AGORA SDK         │  │   FIREBASE     │
    │                     │  │                │
    │  • Live Streaming   │  │  • Database    │
    │  • Video Calls      │  │  • Auth        │
    │  • Real-time Video  │  │  • Storage     │
    └─────────────────────┘  │  • Functions   │
                             └────────────────┘
```

## Data Flow Example - User Goes Live:

```
┌──────────────┐
│   Host       │  1. Clicks "Go Live"
│   (User A)   │
└──────┬───────┘
       │
       │ 2. Request Agora Token
       │
       ▼
┌─────────────────────┐
│  FIREBASE FUNCTION  │  3. Generate Token
│  (Cloud)            │     using APP ID + Certificate
└──────┬──────────────┘
       │
       │ 4. Return Token
       │
       ▼
┌──────────────┐
│   Host       │  5. Join Agora Channel
│   (User A)   │     with Token
└──────┬───────┘
       │
       │ 6. Create Stream in Firestore
       │
       ▼
┌─────────────────────┐
│  FIRESTORE          │
│  live_streams/      │  7. Stream visible to all users
│    stream123/       │
│      - hostId       │
│      - channelName  │
│      - isActive✓    │
└─────────────────────┘
       │
       │ 8. Real-time update
       │
       ▼
┌──────────────┐
│  Viewers     │  9. See stream in Explore page
│  (All Users) │     Can join and watch
└──────────────┘
```

## Database Structure Visual:

```
FIRESTORE DATABASE
│
├── 📁 users/
│   ├── user_123/
│   │   ├── name: "John Doe"
│   │   ├── phone: "+91XXXXXXXXXX"
│   │   ├── photoUrl: "https://..."
│   │   ├── isLive: false
│   │   └── numericId: "12345678"
│   │
│   └── user_456/
│       ├── name: "Jane Smith"
│       └── isLive: true  ← Currently streaming
│
├── 📁 live_streams/
│   └── stream_abc/
│       ├── streamId: "stream_abc"
│       ├── channelName: "chamak_xyz123"
│       ├── hostId: "user_456"
│       ├── hostName: "Jane Smith"
│       ├── title: "Gaming Session"
│       ├── viewerCount: 42
│       ├── isActive: true
│       └── startedAt: Timestamp
│
└── 📁 video_calls/
    └── call_xyz/
        ├── callId: "call_xyz"
        ├── channelName: "call_private_123"
        ├── callerId: "user_123"
        ├── receiverId: "user_456"
        ├── status: "accepted"
        └── createdAt: Timestamp
```

---

# 4. CHECKLIST ✅

## After completing Phase 1, you should have:

### Agora:
- [ ] Agora account created
- [ ] Project "Chamak Live" created
- [ ] APP ID copied and saved
- [ ] APP Certificate copied and saved
- [ ] Token authentication enabled
- [ ] Credentials saved in `agora_credentials.txt`

### Firebase:
- [ ] Firebase account created
- [ ] Project "Chamak-Live" created
- [ ] Android app added
- [ ] `google-services.json` downloaded
- [ ] Firestore Database enabled (test mode)
- [ ] Authentication enabled (Phone)
- [ ] Storage enabled
- [ ] Cloud Functions enabled (Blaze plan)
- [ ] Project info saved in `firebase_info.txt`

---

# 5. TROUBLESHOOTING 🔧

## Common Issues:

### Issue 1: Can't find APP Certificate
**Solution:** Once enabled, it's only shown once. If you lost it:
- Disable and re-enable Primary Certificate
- A new certificate will be generated
- Copy it immediately

### Issue 2: Firebase requires credit card for Functions
**Solution:** Yes, Blaze plan needs a payment method, but:
- It's FREE for small projects
- You get 2M function calls/month free
- You can set spending limits to $0-$5/month

### Issue 3: Can't download google-services.json
**Solution:**
- Go to Project Settings (gear icon)
- Scroll to "Your apps"
- Click on your Android app
- Click "google-services.json" download button

### Issue 4: Wrong package name
**Solution:**
- Package name must match exactly: `com.example.live_vibe`
- Check in `android/app/build.gradle`
- Look for `applicationId`

---

# 6. WHAT'S NEXT? 🚀

Once Phase 1 is complete:

✅ You have Agora credentials (APP ID + Certificate)
✅ You have Firebase project set up
✅ You have `google-services.json` file

**Next Phase:** We'll integrate these into your Flutter app and write the actual code!

---

# 7. VISUAL SUMMARY 📊

```
┌──────────────────────────────────────────────────────────┐
│                   PHASE 1 COMPLETE ✅                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  AGORA SETUP:                    FIREBASE SETUP:         │
│  ✓ Account created               ✓ Project created       │
│  ✓ Project created               ✓ Android app added     │
│  ✓ APP ID obtained               ✓ Firestore enabled     │
│  ✓ Certificate saved             ✓ Auth enabled          │
│                                  ✓ Storage enabled       │
│                                  ✓ Functions ready       │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                YOU'RE READY FOR PHASE 2!                 │
│            (Flutter Integration & Coding)                │
└──────────────────────────────────────────────────────────┘
```

---

# 8. ESTIMATED TIME ⏱️

- **Agora Setup:** 15-20 minutes
- **Firebase Setup:** 20-30 minutes
- **Total Phase 1:** 35-50 minutes

Take your time and follow each step carefully! 🎯

---

**🎉 Congratulations! Once you complete these steps, you're ready to start coding!**

**Ready to proceed to Phase 2? Let me know when Phase 1 is done!** 🚀












