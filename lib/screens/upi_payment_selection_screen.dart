import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// UPI Payment Selection Screen
/// 
/// Shows available payment options and lets user choose their preferred method
class UpiPaymentSelectionScreen extends StatefulWidget {
  final Map<String, String> upiUrls;
  final double amount;
  final int coins;
  final String paymentId;
  final String orderId;

  const UpiPaymentSelectionScreen({
    super.key,
    required this.upiUrls,
    required this.amount,
    required this.coins,
    required this.paymentId,
    required this.orderId,
  });

  @override
  State<UpiPaymentSelectionScreen> createState() => _UpiPaymentSelectionScreenState();
}

class _UpiPaymentSelectionScreenState extends State<UpiPaymentSelectionScreen> {
  String? _selectedMethod;
  StreamSubscription<DocumentSnapshot>? _paymentSubscription;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    // Auto-select GPay if available, otherwise generic UPI option
    if (widget.upiUrls.containsKey('gpay_upi_intent_url')) {
      _selectedMethod = 'gpay_upi_intent_url';
    } else if (widget.upiUrls.containsKey('upi_intent_url')) {
      _selectedMethod = 'upi_intent_url';
    }
    
    // Setup Firestore listener to monitor payment status
    _setupPaymentListener();
  }

  /// Setup Firestore listener to monitor payment status
  /// This is the SINGLE SOURCE OF TRUTH for payment confirmation
  void _setupPaymentListener() {
    final paymentRef = FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.paymentId);

    _paymentSubscription = paymentRef.snapshots().listen(
      (DocumentSnapshot snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String?;

        debugPrint('📊 Payment status update: $status');

        // Check if payment reached final state
        if (status != null && (status == 'SUCCESS' || status == 'FAILED')) {
          if (!_paymentCompleted && mounted) {
            _paymentCompleted = true;
            _handlePaymentCompletion(status);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Error listening to payment status: $error');
      },
    );
  }

  /// Handle payment completion (success or failure)
  void _handlePaymentCompletion(String status) {
    if (!mounted) return;
    
    if (status == 'SUCCESS') {
      // Show success dialog first
      _showSuccessDialog();
    } else {
      // Show failure message and close
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      // Close screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      });
    }
  }

  /// Show success dialog and then navigate back
  void _showSuccessDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // Success message
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.coins} coins have been added to your wallet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    
    // Auto-close dialog and navigate back after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(true); // Close payment screen and return success
      }
    });
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }

  /// Extract UPI parameters from Android Intent URL and create generic UPI URL
  String? _extractUpiUrlFromIntent(String intentUrl) {
    try {
      // Intent URL format: intent://pay?pa=...&tr=...&am=...&cu=INR#Intent;scheme=upi;package=...;end;
      if (!intentUrl.contains('intent://')) {
        return null;
      }

      // Extract the query part before #Intent
      final queryPart = intentUrl.split('#Intent')[0];
      if (queryPart.startsWith('intent://')) {
        // Remove 'intent://' prefix
        final queryString = queryPart.substring(9);
        
        // Create generic UPI URL
        final genericUpiUrl = 'upi://pay?$queryString';
        debugPrint('📱 Extracted generic UPI URL from intent: $genericUpiUrl');
        return genericUpiUrl;
      }
    } catch (e) {
      debugPrint('❌ Error extracting UPI URL from intent: $e');
    }
    return null;
  }

  Future<void> _launchPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!widget.upiUrls.containsKey(_selectedMethod!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final paymentUrl = widget.upiUrls[_selectedMethod!]!;
    
    try {
      final uri = Uri.parse(paymentUrl);
      debugPrint('🚀 Launching UPI app: $uri');
      debugPrint('   URL scheme: ${uri.scheme}');
      debugPrint('   Selected method: $_selectedMethod');
      
      // Determine launch mode based on URL type
      LaunchMode launchMode;
      if (paymentUrl.startsWith('intent://')) {
        // Android Intent URLs work better with platformDefault
        launchMode = LaunchMode.platformDefault;
        debugPrint('   Using LaunchMode.platformDefault for intent:// URL');
      } else {
        // Direct UPI URLs (gpay://, upi://) work with externalApplication
        launchMode = LaunchMode.externalApplication;
        debugPrint('   Using LaunchMode.externalApplication for direct UPI URL');
      }
      
      // Try launching the URL
      try {
        final launched = await launchUrl(
          uri,
          mode: launchMode,
        );
        
        if (launched) {
          debugPrint('✅ UPI app launched successfully');
          // Don't close screen - let user complete payment
          // Firestore listener will close it when payment completes
          return;
        } else {
          // launchUrl returned false - try alternative launch mode
          debugPrint('⚠️ First launch attempt returned false, trying alternative mode...');
          
          final alternativeMode = launchMode == LaunchMode.externalApplication
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication;
          
          try {
            final retryLaunched = await launchUrl(
              uri,
              mode: alternativeMode,
            );
            
            if (retryLaunched) {
              debugPrint('✅ UPI app launched successfully with alternative mode');
              return;
            } else {
              debugPrint('❌ Both launch modes returned false');
              // Try fallback to generic UPI
              await _tryGenericUpiFallback(paymentUrl);
            }
          } catch (retryError) {
            debugPrint('❌ Retry launch exception: $retryError');
            // Check if it's ACTIVITY_NOT_FOUND error
            if (retryError.toString().contains('ACTIVITY_NOT_FOUND')) {
              debugPrint('📱 App not installed, trying generic UPI fallback...');
              await _tryGenericUpiFallback(paymentUrl);
            } else {
              _showLaunchError();
            }
          }
        }
      } catch (launchError) {
        // Launch threw an exception - check if app is not installed
        debugPrint('⚠️ Launch exception: $launchError');
        
        // Check if it's ACTIVITY_NOT_FOUND (app not installed)
        if (launchError.toString().contains('ACTIVITY_NOT_FOUND')) {
          debugPrint('📱 App not installed, trying generic UPI fallback...');
          await _tryGenericUpiFallback(paymentUrl);
        } else {
          // Try alternative launch mode for other errors
          debugPrint('   Trying alternative launch mode...');
          
          try {
            final alternativeMode = launchMode == LaunchMode.externalApplication
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication;
            
            final retryLaunched = await launchUrl(
              uri,
              mode: alternativeMode,
            );
            
            if (retryLaunched) {
              debugPrint('✅ UPI app launched successfully with alternative mode after error');
              return;
            } else {
              debugPrint('❌ Alternative mode also failed');
              await _tryGenericUpiFallback(paymentUrl);
            }
          } catch (retryError) {
            debugPrint('❌ Alternative mode also threw exception: $retryError');
            if (retryError.toString().contains('ACTIVITY_NOT_FOUND')) {
              await _tryGenericUpiFallback(paymentUrl);
            } else {
              _showLaunchError();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing/launching UPI URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening payment app: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Try to launch generic UPI URL as fallback
  Future<void> _tryGenericUpiFallback(String originalUrl) async {
    try {
      // Try to extract generic UPI URL from intent
      final genericUpiUrl = _extractUpiUrlFromIntent(originalUrl);
      
      if (genericUpiUrl != null) {
        debugPrint('🔄 Trying generic UPI URL: $genericUpiUrl');
        final genericUri = Uri.parse(genericUpiUrl);
        
        try {
          final launched = await launchUrl(
            genericUri,
            mode: LaunchMode.externalApplication,
          );
          
          if (launched) {
            debugPrint('✅ Generic UPI URL launched successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening UPI payment. Please select your preferred UPI app.'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('❌ Generic UPI launch also failed: $e');
        }
      }
      
      // If generic UPI also fails, check if we have a generic UPI URL in the list
      if (widget.upiUrls.containsKey('upi_intent_url')) {
        debugPrint('🔄 Trying fallback generic UPI URL from list...');
        final fallbackUrl = widget.upiUrls['upi_intent_url']!;
        final fallbackUri = Uri.parse(fallbackUrl);
        
        try {
          final launched = await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
          
          if (launched) {
            debugPrint('✅ Fallback generic UPI URL launched successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening UPI payment. Please select your preferred UPI app.'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('❌ Fallback generic UPI also failed: $e');
        }
      }
      
      // All attempts failed
      debugPrint('❌ All UPI launch attempts failed');
      _showLaunchError();
    } catch (e) {
      debugPrint('❌ Error in generic UPI fallback: $e');
      _showLaunchError();
    }
  }

  void _showLaunchError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open payment app. The selected app may not be installed. Please install the app or try a different payment method.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _launchPayment(); // Retry
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Show exit confirmation dialog
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: const Color(0xFFFF1B7C),
          foregroundColor: Colors.white,
          centerTitle: true, // Center the title
          toolbarHeight: 50, // Reduced height
          leading: IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: () {
              _showExitConfirmationDialog();
            },
          ),
        ),
      body: Column(
        children: [
          // Payment info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFF1B7C).withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coins: ${widget.coins}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Payment options list
          Expanded(
            child: ListView(
              children: [
                // GPay
                if (widget.upiUrls.containsKey('gpay_upi_intent_url'))
                  _buildPaymentOption(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.blue,
                    title: 'GPay',
                    subtitle: 'Google Pay',
                    value: 'gpay_upi_intent_url',
                    imagePath: 'assets/images/gpay.png',
                  ),

                // Generic UPI (Pay by Any UPI app)
                if (widget.upiUrls.containsKey('upi_intent_url'))
                  _buildPaymentOption(
                    icon: Icons.qr_code_scanner,
                    iconColor: const Color(0xFF6C25FF),
                    title: 'Pay by Any UPI app',
                    subtitle: 'Use any UPI app on your phone to pay',
                    value: 'upi_intent_url',
                    imagePath: 'assets/images/upi.png',
                  ),
              ],
            ),
          ),

          // Pay button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // White container background
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _launchPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1B7C), // Pink button
                    foregroundColor: Colors.white, // White text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF1B7C).withValues(alpha: 0.5),
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Show exit confirmation dialog - Professional Design
  void _showExitConfirmationDialog() {
    if (!mounted) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Icon and Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Warning Icon - Professional Design
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF1B7C).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Color(0xFFFF1B7C),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title and Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Exit Payment?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You are just one step away from completing payment.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Going back will cancel the payment process.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Buttons Row - Professional Layout
                      Row(
                        children: [
                          // Cancel/Stay Button (Primary - Pink)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF1B7C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Continue Payment',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Exit Button (Secondary - Outlined)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.of(context).pop(false); // Exit payment screen
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                foregroundColor: Colors.grey[700],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Exit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    String? imagePath,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon or Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: imagePath == null ? iconColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        imagePath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Icon(
                            icon,
                            color: iconColor,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Radio button
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (newValue) {
                setState(() {
                  _selectedMethod = newValue;
                });
              },
              activeColor: const Color(0xFFFF1B7C),
            ),
          ],
        ),
      ),
    );
  }
}
