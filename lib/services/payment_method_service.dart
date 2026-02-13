import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method_model.dart';
import '../utils/app_logger.dart';

/// Service for managing saved payment methods
/// Collection: users/{userId}/payment_methods/{methodId}
class PaymentMethodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a new payment method
  Future<String?> savePaymentMethod({
    required String userId,
    required String type,
    required String displayName,
    required Map<String, dynamic> details,
    bool setAsDefault = false,
  }) async {
    try {
      // If setting as default, unset other defaults first
      if (setAsDefault) {
        await _unsetOtherDefaults(userId);
      }

      // If this is the first payment method, make it default
      final existingMethods = await getUserPaymentMethods(userId).first;
      final isFirstMethod = existingMethods.isEmpty;

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
        'userId': userId,
        'type': type,
        'displayName': displayName,
        'details': details,
        'isDefault': setAsDefault || isFirstMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': null,
      });

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error saving payment method', e);
      return null;
    }
  }

  /// Get all payment methods for a user
  /// Sorted: Default first, then by creation date (newest first)
  Stream<List<PaymentMethodModel>> getUserPaymentMethods(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) {
          final methods = snapshot.docs
              .map((doc) => PaymentMethodModel.fromFirestore(doc))
              .toList();
          
          // Sort in memory: Default first, then by creation date (newest first)
          methods.sort((a, b) {
            // First sort by isDefault (default methods first)
            if (a.isDefault != b.isDefault) {
              return b.isDefault ? 1 : -1; // true comes first
            }
            // Then sort by createdAt (newest first)
            return b.createdAt.compareTo(a.createdAt);
          });
          
          return methods;
        });
  }

  /// Get default payment method
  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // If no default, get the first one
        final allMethods = await getUserPaymentMethods(userId).first;
        return allMethods.isNotEmpty ? allMethods.first : null;
      }

      return PaymentMethodModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Error getting default payment method', e);
      return null;
    }
  }

  /// Update payment method
  Future<bool> updatePaymentMethod({
    required String userId,
    required String methodId,
    String? displayName,
    Map<String, dynamic>? details,
    bool? setAsDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      if (details != null) {
        updateData['details'] = details;
      }

      if (setAsDefault == true) {
        await _unsetOtherDefaults(userId);
        updateData['isDefault'] = true;
      } else if (setAsDefault == false) {
        updateData['isDefault'] = false;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(methodId)
          .update(updateData);

      return true;
    } catch (e) {
      AppLogger.error('Error updating payment method', e);
      return false;
    }
  }

  /// Delete payment method
  Future<bool> deletePaymentMethod({
    required String userId,
    required String methodId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(methodId)
          .delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting payment method', e);
      return false;
    }
  }

  /// Set payment method as default
  Future<bool> setDefaultPaymentMethod({
    required String userId,
    required String methodId,
  }) async {
    try {
      // Unset all other defaults
      await _unsetOtherDefaults(userId);

      // Set this one as default
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(methodId)
          .update({'isDefault': true});

      return true;
    } catch (e) {
      AppLogger.error('Error setting default payment method', e);
      return false;
    }
  }

  /// Update last used timestamp
  Future<void> updateLastUsed({
    required String userId,
    required String methodId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(methodId)
          .update({'lastUsed': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.error('Error updating last used', e);
    }
  }

  /// Helper: Unset all default flags for user
  Future<void> _unsetOtherDefaults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .where('isDefault', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Error unsetting defaults', e);
    }
  }
}
