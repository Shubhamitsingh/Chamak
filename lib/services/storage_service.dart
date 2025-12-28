import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      // Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        throw Exception('User not authenticated. Please login again.');
      }
      
      final userId = user.uid;
      print('✅ Authenticated user: $userId');
      print('✅ User email: ${user.email}');
      print('✅ User phone: ${user.phoneNumber}');

      // Verify file exists
      if (!await imageFile.exists()) {
        print('❌ Image file does not exist');
        throw Exception('Image file not found. Please try selecting the image again.');
      }

      final fileSize = await imageFile.length();
      print('📤 Uploading profile picture for user: $userId');
      print('📁 File path: ${imageFile.path}');
      print('📊 File size: $fileSize bytes');
      
      if (fileSize == 0) {
        print('❌ Image file is empty');
        throw Exception('Image file is empty. Please select a valid image.');
      }

      // Create a reference to the file location
      final String fileName = 'profile_$userId.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child(userId)
          .child(fileName);

      print('🎯 Storage path: profile_pictures/$userId/$fileName');
      print('🔐 Checking storage permissions...');

      // Upload the file with timeout
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      print('⏳ Uploading... Please wait');

      // Wait for upload to complete with progress tracking
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your internet connection and try again.');
        },
      );
      
      print('✅ Upload complete, getting download URL...');
      
      // Wait a moment for Firebase to process the file
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Get download URL with retry logic
      String downloadURL = '';
      int retries = 3;
      
      for (int i = 0; i < retries; i++) {
        try {
          downloadURL = await snapshot.ref.getDownloadURL();
          
          // Verify the URL is accessible by getting metadata
          final metadata = await snapshot.ref.getMetadata();
          print('✅ File metadata verified: ${metadata.size} bytes');
          print('🔗 Download URL: $downloadURL');
          break;
        } catch (e) {
          print('⚠️ Attempt ${i + 1}/$retries failed: $e');
          if (i < retries - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            // Last attempt - get URL anyway even if metadata fails
            downloadURL = await snapshot.ref.getDownloadURL();
            print('🔗 Download URL (without metadata verification): $downloadURL');
          }
        }
      }
      
      print('✅ Profile picture uploaded successfully');
      
      return downloadURL;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      
      if (e.toString().contains('object-not-found')) {
        throw Exception('Firebase Storage is not properly configured. Please contact support.');
      } else if (e.toString().contains('permission-denied') || e.toString().contains('unauthorized')) {
        print('⚠️ Permission denied - checking authentication...');
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('You are not logged in. Please login and try again.');
        } else {
          print('⚠️ User is authenticated but storage rules are blocking upload');
          print('⚠️ User ID: ${user.uid}');
          throw Exception('Storage permission denied. Please check Firebase Storage rules or contact support.');
        }
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('Authentication required. Please logout and login again.');
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      }
      rethrow;
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String photoURL) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return;
      }

      // Validate the URL is a Firebase Storage URL (check for both correct and typo versions)
      if (!photoURL.contains('firebasestorage.googleapis.com') && 
          !photoURL.contains('ffirebasestorage.googleapis.com')) {
        print('⚠️ Not a valid Firebase Storage URL, skipping delete');
        return;
      }
      
      // Fix typo in URL if present
      if (photoURL.contains('ffirebasestorage')) {
        photoURL = photoURL.replaceAll('ffirebasestorage', 'firebasestorage');
        print('🔧 Fixed typo in URL');
      }

      print('🗑️ Deleting profile picture: $photoURL');

      // Get reference from URL
      final Reference storageRef = _storage.refFromURL(photoURL);
      
      // Delete the file
      await storageRef.delete();
      
      print('✅ Profile picture deleted successfully');
    } catch (e) {
      print('⚠️ Could not delete profile picture (this is OK): $e');
      // Don't throw error - file might not exist or already deleted
      // This is not critical, we can continue with upload
    }
  }

  // Update profile picture (upload new first, then delete old)
  Future<String?> updateProfilePicture({
    required File newImageFile,
    String? oldPhotoURL,
  }) async {
    try {
      print('🔄 Starting profile picture update...');
      
      // First, upload the new picture
      print('📤 Uploading new profile picture...');
      final String? newPhotoURL = await uploadProfilePicture(newImageFile);
      
      if (newPhotoURL == null) {
        print('❌ Upload failed - no URL returned');
        return null;
      }
      
      print('✅ New profile picture uploaded successfully: $newPhotoURL');
      
      // Wait a bit to ensure new file is fully accessible before deleting old one
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Then try to delete old picture if it exists and is different
      if (oldPhotoURL != null && 
          oldPhotoURL.isNotEmpty && 
          oldPhotoURL != newPhotoURL &&
          oldPhotoURL.contains('firebasestorage.googleapis.com')) {
        try {
          print('🗑️ Attempting to delete old profile picture...');
          print('🗑️ Old URL: $oldPhotoURL');
          print('🗑️ New URL: $newPhotoURL');
          
          // Make sure we're not deleting the new file
          if (!oldPhotoURL.contains(newPhotoURL.split('?')[0])) {
            await deleteProfilePicture(oldPhotoURL);
            print('✅ Old profile picture deleted');
          } else {
            print('⚠️ Skipping delete - URLs match');
          }
        } catch (e) {
          print('⚠️ Could not delete old profile picture (this is OK): $e');
          // This is fine - old image might not exist or might be in use
          // Continue anyway since new upload succeeded
        }
      }
      
      return newPhotoURL;
    } catch (e) {
      print('❌ Error updating profile picture: $e');
      rethrow;
    }
  }

  // Get profile picture metadata
  Future<FullMetadata?> getProfilePictureMetadata() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return null;
      }

      final String fileName = 'profile_$currentUserId.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child(currentUserId!)
          .child(fileName);

      final FullMetadata metadata = await storageRef.getMetadata();
      return metadata;
    } catch (e) {
      print('❌ Error getting profile picture metadata: $e');
      return null;
    }
  }

  // Check if profile picture exists
  Future<bool> profilePictureExists() async {
    try {
      final metadata = await getProfilePictureMetadata();
      return metadata != null;
    } catch (e) {
      return false;
    }
  }

  // Get storage usage for user
  Future<int> getUserStorageUsage() async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return 0;
      }

      final Reference userRef = _storage
          .ref()
          .child('profile_pictures')
          .child(currentUserId!);

      final ListResult result = await userRef.listAll();
      
      int totalSize = 0;
      for (var item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += (metadata.size ?? 0).toInt();
      }

      return totalSize;
    } catch (e) {
      print('❌ Error getting storage usage: $e');
      return 0;
    }
  }

  // Upload cover photo
  Future<String?> uploadCoverPhoto(File imageFile, {int index = 1}) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return null;
      }

      print('📤 Uploading cover photo $index for user: $currentUserId');

      // Create a reference to the file location with index
      final String fileName = 'cover_${currentUserId}_$index.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('cover_photos')
          .child(currentUserId!)
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
            'index': index.toString(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      print('✅ Cover photo $index uploaded successfully');
      print('🔗 Download URL: $downloadURL');
      
      return downloadURL;
    } catch (e) {
      print('❌ Error uploading cover photo $index: $e');
      rethrow;
    }
  }

  // Delete cover photo
  Future<void> deleteCoverPhoto(String coverURL) async {
    try {
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        return;
      }

      print('🗑️ Deleting cover photo: $coverURL');

      // Get reference from URL
      final Reference storageRef = _storage.refFromURL(coverURL);
      
      // Delete the file
      await storageRef.delete();
      
      print('✅ Cover photo deleted successfully');
    } catch (e) {
      print('⚠️ Could not delete cover photo: $e');
      // Don't throw error - file might not exist or already deleted
      // This is not critical, we can continue with upload
    }
  }

  // Update cover photo (delete old, upload new)
  Future<String?> updateCoverPhoto({
    required File newImageFile,
    String? oldCoverURL,
    int index = 1,
  }) async {
    try {
      // Delete old cover photo if exists
      if (oldCoverURL != null && oldCoverURL.isNotEmpty) {
        try {
          await deleteCoverPhoto(oldCoverURL);
        } catch (e) {
          print('⚠️ Could not delete old cover photo $index: $e');
          // Continue with upload even if delete fails
        }
      }

      // Upload new cover photo with index
      final String? newCoverURL = await uploadCoverPhoto(newImageFile, index: index);
      
      return newCoverURL;
    } catch (e) {
      print('❌ Error updating cover photo $index: $e');
      rethrow;
    }
  }

  // Upload chat image
  Future<String?> uploadChatImage(File imageFile, String userId) async {
    try {
      print('📤 Uploading chat image for user: $userId');

      // Create unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'chat_${userId}_$timestamp.jpg';
      
      final Reference storageRef = _storage
          .ref()
          .child('chat_images')
          .child(userId)
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      print('✅ Chat image uploaded successfully');
      print('🔗 Download URL: $downloadURL');
      
      return downloadURL;
    } catch (e) {
      print('❌ Error uploading chat image: $e');
      return null;
    }
  }

  // Upload payment proof screenshot
  Future<String?> uploadPaymentProof(File imageFile, String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        throw Exception('User not authenticated. Please login again.');
      }
      final userId = user.uid;
      final String fileName = 'payment_proof_${requestId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('payment_proofs')
          .child(userId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'requestId': requestId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('❌ Error uploading payment proof: $e');
      return null;
    }
  }
}

