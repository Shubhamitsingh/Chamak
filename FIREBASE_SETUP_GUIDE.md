# Firebase Setup Guide for Flutter App

## 📋 Prerequisites
- Flutter installed on your system
- Google account
- Your Flutter project ready

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter your project name (e.g., "Chamak App")
4. Accept terms and click **Continue**
5. Enable/disable Google Analytics (optional)
6. Click **Create project**
7. Wait for project creation, then click **Continue**

---

## Step 2: Install Firebase CLI

### Windows (PowerShell):
```bash
npm install -g firebase-tools
```

### Verify Installation:
```bash
firebase --version
```

### Login to Firebase:
```bash
firebase login
```

---

## Step 3: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Verify Installation:
```bash
flutterfire --version
```

---

## Step 4: Add Firebase Dependencies

Add these to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core (Required)
  firebase_core: ^2.24.2
  
  # Firebase Services (Add as needed)
  firebase_auth: ^4.15.3          # For Authentication
  cloud_firestore: ^4.13.6        # For Database
  firebase_storage: ^11.5.6       # For File Storage
  firebase_messaging: ^14.7.9     # For Push Notifications
  firebase_analytics: ^10.7.4     # For Analytics
```

Then run:
```bash
flutter pub get
```

---

## Step 5: Configure Firebase for Your App

### Run FlutterFire Configuration:

Navigate to your project directory and run:

```bash
flutterfire configure
```

This command will:
1. Ask you to select your Firebase project
2. Select platforms (Android, iOS, Web)
3. Automatically generate `firebase_options.dart` file
4. Configure Firebase for each platform

**Follow the prompts:**
- Select your Firebase project from the list
- Choose platforms: **Android** (press Space to select, Enter to confirm)
- It will create `lib/firebase_options.dart` automatically

---

## Step 6: Initialize Firebase in Your App

### Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamak App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Your splash screen
    );
  }
}
```

---

## Step 7: Enable Firebase Services

### A. Firestore Database

1. Go to Firebase Console → Your Project
2. Click **"Firestore Database"** in left menu
3. Click **"Create database"**
4. Choose **"Start in test mode"** (for development)
5. Select a location close to your users
6. Click **"Enable"**

**Test Mode Rules (Temporary - For Development Only):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Important:** Change to secure rules before production!

---

### B. Firebase Authentication

1. Go to Firebase Console → **Authentication**
2. Click **"Get started"**
3. Click **"Sign-in method"** tab
4. Enable methods you want:
   - **Phone** (for OTP login)
   - **Email/Password**
   - **Google**
5. Click **"Save"**

---

### C. Firebase Storage

1. Go to Firebase Console → **Storage**
2. Click **"Get started"**
3. Start in **test mode**
4. Choose location
5. Click **"Done"**

---

## Step 8: Android-Specific Setup (Important!)

### Update `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Update `android/app/build.gradle`:

At the **top** of the file (after `plugins` block):
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'  // Add this line
```

At the **bottom** of the file:
```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

### Update Minimum SDK:

In `android/app/build.gradle`, find and update:
```gradle
defaultConfig {
    minSdkVersion 21  // Change from flutter.minSdkVersion to 21
    targetSdkVersion flutter.targetSdkVersion
}
```

---

## Step 9: Test Firebase Connection

Create a test file `lib/test_firebase.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirebase extends StatelessWidget {
  const TestFirebase({super.key});

  // Test writing to Firestore
  Future<void> testWrite() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'message': 'Hello Firebase!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Write successful!');
    } catch (e) {
      print('❌ Write error: $e');
    }
  }

  // Test reading from Firestore
  Future<void> testRead() async {
    try {
      QuerySnapshot snapshot = 
          await FirebaseFirestore.instance.collection('test').get();
      print('✅ Read successful! Documents: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('Document data: ${doc.data()}');
      }
    } catch (e) {
      print('❌ Read error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testWrite,
              child: const Text('Test Write'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: testRead,
              child: const Text('Test Read'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 10: Common Firestore Operations

### Create/Add Data:
```dart
// Add a user
await FirebaseFirestore.instance.collection('users').add({
  'name': 'John Doe',
  'email': 'john@example.com',
  'createdAt': FieldValue.serverTimestamp(),
});

// Set data with specific ID
await FirebaseFirestore.instance.collection('users').doc('userId123').set({
  'name': 'Jane Doe',
  'email': 'jane@example.com',
});
```

### Read Data:
```dart
// Get all documents
QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('users')
    .get();

for (var doc in snapshot.docs) {
  print('${doc.id}: ${doc.data()}');
}

// Get specific document
DocumentSnapshot doc = await FirebaseFirestore.instance
    .collection('users')
    .doc('userId123')
    .get();

if (doc.exists) {
  print('User data: ${doc.data()}');
}

// Real-time listener
FirebaseFirestore.instance
    .collection('users')
    .snapshots()
    .listen((snapshot) {
  for (var doc in snapshot.docs) {
    print('Real-time: ${doc.data()}');
  }
});
```

### Update Data:
```dart
// Update specific fields
await FirebaseFirestore.instance
    .collection('users')
    .doc('userId123')
    .update({
  'name': 'Updated Name',
  'lastUpdated': FieldValue.serverTimestamp(),
});
```

### Delete Data:
```dart
// Delete a document
await FirebaseFirestore.instance
    .collection('users')
    .doc('userId123')
    .delete();
```

---

## Step 11: Secure Your Database (Production)

### Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read, authenticated write
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## Step 12: Run Your App

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔧 Troubleshooting

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "Firebase not initialized"
- Make sure `Firebase.initializeApp()` is called in `main()`
- Make sure `WidgetsFlutterBinding.ensureInitialized()` is called first

### Error: "google-services.json not found"
- Run `flutterfire configure` again
- Check if file exists in `android/app/google-services.json`

### Error: "Multidex error"
In `android/app/build.gradle`:
```gradle
defaultConfig {
    multiDexEnabled true
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
- [Firebase Auth Guide](https://firebase.google.com/docs/auth)

---

## ✅ Next Steps

1. **Plan your database structure** (collections, documents)
2. **Implement authentication** (Phone OTP for your app)
3. **Create data models** for users, messages, etc.
4. **Set up security rules** before going live
5. **Test thoroughly** in development mode

---

## 🎯 Quick Start Commands

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your app
flutterfire configure

# Add dependencies
flutter pub add firebase_core firebase_auth cloud_firestore

# Run app
flutter run
```

---

**Need Help?** Check the error messages carefully and refer to the troubleshooting section!















































































