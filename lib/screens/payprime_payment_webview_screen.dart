import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'payment_failure_screen.dart';
import '../services/meta_events_service.dart';

/// PayPrime Payment WebView Screen
/// 
/// This screen displays the PayPrime payment page in an in-app WebView.
/// It listens to Firestore for payment status changes and automatically
/// closes when payment is completed (success or failure).

// ⚠️ CRITICAL FIX: Payment status enum (must be outside class)
enum PaymentStatus {
  initiating,
  redirecting,
  verifying,
  completed,
  failed,
  timeout,
}

class PayPrimePaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentId;
  final String orderId;
  final double amount;
  final int coins;

  const PayPrimePaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.coins,
  });

  @override
  State<PayPrimePaymentWebViewScreen> createState() => _PayPrimePaymentWebViewScreenState();
}

class _PayPrimePaymentWebViewScreenState extends State<PayPrimePaymentWebViewScreen> {
  WebViewController? _webViewController;
  StreamSubscription<DocumentSnapshot>? _paymentSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  bool _paymentCompleted = false;
  bool _isUpiUrl = false;
  
  // ⚠️ CRITICAL FIX: Payment status tracking
  Timer? _paymentTimeoutTimer; // Timeout after 10 minutes
  Timer? _statusPollingTimer; // Poll status every 5 seconds (fallback)
  PaymentStatus _currentStatus = PaymentStatus.initiating;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _paymentTimeoutTimer?.cancel(); // ⚠️ CRITICAL FIX: Cancel timeout
    _statusPollingTimer?.cancel(); // ⚠️ CRITICAL FIX: Cancel polling
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _setupPaymentListener();
    _startStatusPolling(); // ⚠️ CRITICAL FIX: Start polling fallback
    _startPaymentTimeout(); // ⚠️ CRITICAL FIX: Start timeout timer
  }

  void _initializeWebView() {
    // Check if paymentUrl is a UPI intent URL (not HTTP/HTTPS)
    final uri = Uri.parse(widget.paymentUrl);
    final isUpiUrl = !uri.scheme.startsWith('http');
    
    if (isUpiUrl) {
      // It's a UPI URL, launch it directly without WebView
      debugPrint('🔗 Payment URL is a UPI intent URL, launching directly...');
      debugPrint('   URL: ${widget.paymentUrl}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchUpiApp(widget.paymentUrl);
      });
      return;
    }
    
    // It's an HTTP/HTTPS URL, load it in WebView
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 WebView: Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            debugPrint('✅ WebView: Page finished loading: $url');
            
            // Check if page contains JSON with UPI URLs
            try {
              // Try to get JSON from page - it might be in body text or as a JSON response
              final content = await _webViewController?.runJavaScriptReturningResult(
                "document.body.innerText"
              );
              
              String contentStr = content.toString();
              debugPrint('📄 Page content preview: ${contentStr.length > 200 ? contentStr.substring(0, 200) : contentStr}');
              
              // Remove surrounding quotes if the content is a stringified JSON
              contentStr = contentStr.trim();
              if (contentStr.startsWith('"') && contentStr.endsWith('"')) {
                // It's a stringified JSON, unescape it
                contentStr = contentStr.substring(1, contentStr.length - 1);
                // Unescape JSON string
                contentStr = contentStr.replaceAll('\\"', '"').replaceAll('\\/', '/');
                debugPrint('📝 Unescaped JSON: ${contentStr.length > 200 ? contentStr.substring(0, 200) : contentStr}');
              }
              
              // Try to parse as JSON
              if (contentStr.trim().startsWith('{')) {
                await _handleJsonResponse(contentStr);
              }
            } catch (e) {
              debugPrint('⚠️ Could not read page content: $e');
            }
            
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView Error: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load payment page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept UPI intent URLs
            final url = request.url;
            if (url.startsWith('upi://') || url.startsWith('gpay://') || url.startsWith('tez://') || url.startsWith('paytmmp://') || url.startsWith('intent://')) {
              debugPrint('🔗 Intercepted UPI URL: $url');
              _launchUpiApp(url);
              return NavigationDecision.prevent; // Prevent WebView from handling it
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }
  
  /// Handle JSON response from PayPrime
  Future<void> _handleJsonResponse(String jsonContent) async {
    try {
      // The content might be a stringified JSON, so try to decode it first
      dynamic parsed;
      
      // First, try to parse it directly
      try {
        parsed = jsonDecode(jsonContent);
      } catch (e) {
        // If that fails, it might be double-encoded (stringified JSON)
        // Try decoding twice
        try {
          final firstDecode = jsonDecode(jsonContent) as String;
          parsed = jsonDecode(firstDecode);
        } catch (e2) {
          debugPrint('❌ Failed to parse JSON: $e2');
          return;
        }
      }
      
      if (parsed is! Map<String, dynamic>) {
        debugPrint('⚠️ Parsed content is not a JSON object');
        return;
      }
      
      final json = parsed;
      debugPrint('📦 Parsed JSON response from PayPrime');
      debugPrint('   Keys: ${json.keys.join(", ")}');
      
      // Try different possible UPI URL fields (prioritize GPay, then PhonePe, then Paytm, then generic)
      String? upiUrl;
      
      if (json.containsKey('gpay_upi_intent_url')) {
        upiUrl = json['gpay_upi_intent_url'] as String?;
        debugPrint('   Using GPay UPI URL');
      } else if (json.containsKey('phonepe_upi_intent_url')) {
        upiUrl = json['phonepe_upi_intent_url'] as String?;
        debugPrint('   Using PhonePe UPI URL');
      } else if (json.containsKey('paytm_upi_intent_url')) {
        upiUrl = json['paytm_upi_intent_url'] as String?;
        debugPrint('   Using Paytm UPI URL');
      } else if (json.containsKey('upi_intent_url')) {
        upiUrl = json['upi_intent_url'] as String?;
        debugPrint('   Using generic UPI URL');
      }
      
      if (upiUrl != null && upiUrl.isNotEmpty) {
        debugPrint('✅ Found UPI URL: $upiUrl');
        await _launchUpiApp(upiUrl);
      } else {
        debugPrint('⚠️ No UPI URL found in JSON response');
        debugPrint('   Available keys: ${json.keys.join(", ")}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing JSON: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }
  
  /// Launch UPI payment app
  Future<void> _launchUpiApp(String upiUrl) async {
    try {
      final uri = Uri.parse(upiUrl);
      debugPrint('🚀 Launching UPI app: $uri');
      
      // Try to launch directly - canLaunchUrl may not work for UPI URLs
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          debugPrint('✅ UPI app launched successfully');
        } else {
          debugPrint('❌ Failed to launch UPI URL');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open payment app. Please make sure you have a UPI app installed.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (launchError) {
        // Launch error - try canLaunchUrl as fallback check
        debugPrint('⚠️ Launch error: $launchError');
        final canLaunch = await canLaunchUrl(uri);
        
        if (!canLaunch) {
          debugPrint('❌ Cannot launch UPI URL: $upiUrl');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please install a UPI payment app (GPay, PhonePe, Paytm)'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error launching UPI app: $e');
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
          if (!_paymentCompleted) {
            _paymentCompleted = true;
            _cancelTimers(); // Cancel timeout and polling
            _handlePaymentCompletion(status);
          }
        } else if (status == 'PROCESSING' || status == 'PENDING') {
          // Update status to verifying
          if (mounted && _currentStatus != PaymentStatus.verifying) {
            setState(() {
              _currentStatus = PaymentStatus.verifying;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Error listening to payment status: $error');
        
        // ✅ FIX: Handle permission-denied gracefully
        final errorString = error.toString();
        if (errorString.contains('permission-denied')) {
          debugPrint('⚠️ Permission denied - user may have logged out');
          // Cancel listener to prevent crashes
          _paymentSubscription?.cancel();
          return;
        }
        
        // If listener fails, polling will handle it
      },
    );
  }
  
  /// ⚠️ CRITICAL FIX: Start status polling as fallback
  /// Polls payment status every 5 seconds if real-time listener fails
  void _startStatusPolling() {
    _statusPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (_paymentCompleted || !mounted) {
          timer.cancel();
          return;
        }
        
        try {
          debugPrint('🔄 Polling payment status...');
          
          // Manually check payment status
          final paymentDoc = await FirebaseFirestore.instance
            .collection('payments')
            .doc(widget.paymentId)
            .get();
          
          if (paymentDoc.exists) {
            final data = paymentDoc.data() as Map<String, dynamic>?;
            final status = data?['status'] as String?;
            
            if (status == 'SUCCESS' || status == 'FAILED') {
              timer.cancel();
              if (!_paymentCompleted && mounted) {
                _paymentCompleted = true;
                _cancelTimers();
                _handlePaymentCompletion(status ?? 'FAILED');
              }
            } else if (status == 'PROCESSING' || status == 'PENDING') {
              // Update status to verifying
              if (mounted && _currentStatus != PaymentStatus.verifying) {
                setState(() {
                  _currentStatus = PaymentStatus.verifying;
                });
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error polling payment status: $e');
          // Continue polling even on error
        }
      },
    );
  }
  
  /// ⚠️ CRITICAL FIX: Start payment timeout (10 minutes)
  void _startPaymentTimeout() {
    _paymentTimeoutTimer = Timer(
      const Duration(minutes: 10),
      () {
        if (!_paymentCompleted && mounted) {
          debugPrint('⏱️ Payment timeout - 10 minutes elapsed');
          _handlePaymentTimeout();
        }
      },
    );
  }
  
  /// ⚠️ CRITICAL FIX: Handle payment timeout
  void _handlePaymentTimeout() {
    if (_paymentCompleted || !mounted) return;
    
    _paymentCompleted = true;
    _cancelTimers();
    
    setState(() {
      _currentStatus = PaymentStatus.timeout;
    });
    
    // Navigate to failure screen with timeout reason
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentFailureScreen(
          failureReason: 'Payment verification is taking longer than expected. Please check your payment status or contact support.',
          amount: widget.amount,
          coins: widget.coins,
          paymentMethod: 'UPI',
          paymentId: widget.paymentId,
          phoneNumber: _auth.currentUser?.phoneNumber ?? '',
        ),
      ),
    );
  }
  
  /// Cancel all timers
  void _cancelTimers() {
    _paymentTimeoutTimer?.cancel();
    _statusPollingTimer?.cancel();
  }
  
  /// ⚠️ CRITICAL FIX: Manual status check
  Future<void> _checkPaymentStatusManually() async {
    if (!mounted) return;
    
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Check payment status
      final paymentDoc = await FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.paymentId)
        .get();
      
      // Close loading
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (paymentDoc.exists) {
        final data = paymentDoc.data() as Map<String, dynamic>?;
        final status = data?['status'] as String?;
        
        if (status == 'SUCCESS' || status == 'FAILED') {
          if (!_paymentCompleted && mounted) {
            _paymentCompleted = true;
            _cancelTimers();
            _handlePaymentCompletion(status ?? 'FAILED');
          }
        } else {
          // Still processing
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment is still being processed. Please wait...'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Payment not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment not found. Please contact support.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking payment status: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Get status message for current status
  String _getStatusMessage() {
    switch (_currentStatus) {
      case PaymentStatus.initiating:
        return 'Initiating Payment...';
      case PaymentStatus.redirecting:
        return 'Redirecting to Payment App...';
      case PaymentStatus.verifying:
        return 'Verifying Payment Status...';
      case PaymentStatus.completed:
        return 'Payment Successful!';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.timeout:
        return 'Payment Timeout';
    }
  }

  /// Handle payment completion (success or failure)
  /// ⚠️ CRITICAL FIX: Navigate to failure screen instead of SnackBar
  void _handlePaymentCompletion(String status) {
    if (!mounted) return;
    
    if (status == 'SUCCESS') {
      setState(() {
        _currentStatus = PaymentStatus.completed;
      });
      // Show success dialog first
      _showSuccessDialog();
    } else {
      setState(() {
        _currentStatus = PaymentStatus.failed;
      });
      
      // ⚠️ CRITICAL FIX: Navigate to PaymentFailureScreen instead of SnackBar
      final failureReason = _getFailureReason(status);
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(
            failureReason: failureReason,
            amount: widget.amount,
            coins: widget.coins,
            paymentMethod: 'UPI',
            paymentId: widget.paymentId,
            phoneNumber: _auth.currentUser?.phoneNumber ?? '',
            onRetry: () {
              // Retry payment - go back to wallet
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }
  
  /// Get failure reason message
  String _getFailureReason(String status) {
    // You can enhance this based on actual failure reasons from payment gateway
    if (status == 'FAILED') {
      return 'Payment could not be completed. Please check your balance and try again.';
    } else if (status == 'CANCELLED') {
      return 'Payment was cancelled. Please try again if you want to complete the payment.';
    } else if (status == 'TIMEOUT') {
      return 'Payment verification is taking longer than expected. Please check your payment status or contact support.';
    }
    return 'Payment failed. Please try again.';
  }

  /// Show success dialog and then navigate back
  void _showSuccessDialog() {
    if (!mounted) return;
    
    // Log Meta purchase event with Dynamic Product Ads parameters
    MetaEventsService.logPurchase(
      amount: widget.amount,
      currency: 'INR',
      productId: 'coin_package_${widget.coins}', // Product ID for Dynamic Product Ads
      parameters: {
        'coins': widget.coins,
        'payment_id': widget.paymentId,
        'order_id': widget.orderId,
        'payment_method': 'payprime',
      },
    ).catchError((e) {
      debugPrint('⚠️ Failed to log Meta purchase event: $e');
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              // Success message
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.coins} coins have been added to your wallet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ⚠️ CRITICAL FIX: Add manual status check button
        actions: [
          if (!_paymentCompleted && _currentStatus != PaymentStatus.completed && _currentStatus != PaymentStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Check Payment Status',
              onPressed: _checkPaymentStatusManually,
            ),
        ],
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF1B7C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Show confirmation dialog before closing
            _showCloseConfirmation();
          },
        ),
      ),
      body: Stack(
        children: [
          // WebView (only show if WebView is initialized)
          if (_errorMessage == null && _webViewController != null)
            WebViewWidget(controller: _webViewController!)
          else if (_errorMessage == null && _isUpiUrl)
            // UPI URL - show loading message
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFFF1B7C),
                  ),
                  const SizedBox(height: 16),
                  // ⚠️ CRITICAL FIX: Show status progression
                  Text(
                    _getStatusMessage(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please complete payment in the app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            _buildErrorView()
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF1B7C),
              ),
            ),

          // ⚠️ CRITICAL FIX: Loading overlay with status progression
          if ((_isLoading || _currentStatus == PaymentStatus.verifying) && _errorMessage == null && !_paymentCompleted)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFFFF1B7C),
                    ),
                    const SizedBox(height: 24),
                    // ⚠️ CRITICAL FIX: Show status progression
                    Text(
                      _getStatusMessage(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStatus == PaymentStatus.verifying
                          ? 'This may take a few seconds'
                          : 'Please wait...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ⚠️ CRITICAL FIX: Manual status check button
                    if (_currentStatus == PaymentStatus.verifying)
                      ElevatedButton.icon(
                        onPressed: _checkPaymentStatusManually,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Check Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1B7C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Payment info banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFF1B7C).withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Coins: ${widget.coins}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.lock,
                    color: Color(0xFFFF1B7C),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Payment Page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _webViewController?.reload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1B7C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? '
          'You can complete it later from your payment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Close WebView
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }
}
