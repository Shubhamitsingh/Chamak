import 'package:facebook_app_events/facebook_app_events.dart';

/// Service for logging Meta (Facebook) App Events
/// Used for tracking conversions and optimizing Meta ad campaigns
class MetaEventsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  /// Log complete_registration event
  /// Call this after user successfully registers/creates account
  static Future<void> logCompleteRegistration({
    String? method,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'complete_registration',
        parameters: {
          if (method != null) 'method': method,
        },
      );
      print('✅ Meta Event: complete_registration logged successfully');
    } catch (e) {
      print('❌ Error logging complete_registration event: $e');
      // Don't throw - event logging failures shouldn't break app flow
    }
  }

  /// Log purchase event
  /// Call this after successful payment/purchase
  /// Includes Dynamic Product Ads parameters for better campaign optimization
  static Future<void> logPurchase({
    required double amount,
    required String currency,
    String? productId, // Product ID for Dynamic Product Ads
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Merge Dynamic Product Ads parameters with custom parameters
      final params = <String, dynamic>{
        // Dynamic Product Ads required parameters
        'fb_content_type': 'product',
        if (productId != null) 'fb_content_id': productId,
        // Merge with custom parameters (custom params take precedence)
        ...?parameters,
      };
      
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: params,
      );
      print('✅ Meta Event: purchase logged successfully');
      print('   Amount: $amount $currency');
      if (productId != null) {
        print('   Product ID: $productId');
      }
      if (params.isNotEmpty) {
        print('   Parameters: $params');
      }
    } catch (e) {
      print('❌ Error logging purchase event: $e');
      // Don't throw - event logging failures shouldn't break app flow
    }
  }

  /// Log ViewContent event for Dynamic Product Ads
  /// Call this when user views a product/content
  static Future<void> logViewContent({
    required String productId,
    double? value,
    String currency = 'INR',
    Map<String, dynamic>? additionalParameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_content_view',
        parameters: {
          'fb_content_type': 'product',
          'fb_content_id': productId,
          'fb_currency': currency,
          if (value != null) 'fb_value': value,
          ...?additionalParameters,
        },
      );
      print('✅ Meta Event: ViewContent logged successfully');
      print('   Product ID: $productId');
    } catch (e) {
      print('❌ Error logging ViewContent event: $e');
      // Don't throw - event logging failures shouldn't break app flow
    }
  }

  /// Log AddToCart event for Dynamic Product Ads
  /// Call this when user adds a product to cart
  static Future<void> logAddToCart({
    required String productId,
    required double value,
    String currency = 'INR',
    int? quantity,
    Map<String, dynamic>? additionalParameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_add_to_cart',
        parameters: {
          'fb_content_type': 'product',
          'fb_content_id': productId,
          'fb_currency': currency,
          'fb_value': value,
          if (quantity != null) 'fb_num_items': quantity,
          ...?additionalParameters,
        },
      );
      print('✅ Meta Event: AddToCart logged successfully');
      print('   Product ID: $productId');
      print('   Value: $value $currency');
    } catch (e) {
      print('❌ Error logging AddToCart event: $e');
      // Don't throw - event logging failures shouldn't break app flow
    }
  }

  /// Log custom event
  /// Use this for any custom events you want to track
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: name,
        parameters: parameters ?? {},
      );
      print('✅ Meta Event: $name logged successfully');
      if (parameters != null) {
        print('   Parameters: $parameters');
      }
    } catch (e) {
      print('❌ Error logging event $name: $e');
      // Don't throw - event logging failures shouldn't break app flow
    }
  }
}
