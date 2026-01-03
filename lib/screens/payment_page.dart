import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/payment_gateway_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_success_screen.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> package;
  final int packageIndex;

  const PaymentPage({
    super.key,
    required this.package,
    required this.packageIndex,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  final PaymentGatewayApiService _paymentGatewayService = PaymentGatewayApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isProcessingPayment = false;
  String? _selectedPaymentMethod;
  String? _paymentUrl;
  String? _orderId;
  String? _paymentId;
  int? _currentPaymentCoins;
  Timer? _paymentStatusTimer;
  StreamSubscription<DocumentSnapshot>? _paymentListener;
  StreamSubscription<QuerySnapshot>? _paymentsQueryListener;

  // Payment method data
  String? _upiIntentUrl;
  String? _gpayUrl;
  String? _phonepeUrl;
  String? _paytmUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePayment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentStatusTimer?.cancel();
    _paymentListener?.cancel();
    _paymentsQueryListener?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_orderId != null && _paymentId != null && _currentPaymentCoins != null) {
        _verifyPaymentStatus();
      }
    }
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to purchase coins'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final int coins = widget.package['coins'];
      final int inr = widget.package['inr'];
      final String packageId = 'package_${widget.packageIndex}_${coins}_${inr}';

      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userName = userData?['displayName'] as String? ?? '';
      String userPhone = userData?['phoneNumber'] as String? ?? '';
      if (userPhone.isEmpty) {
        userPhone = currentUser.phoneNumber ?? '';
      }
      final userEmail = currentUser.email;

      // Create payment order
      final result = await _paymentGatewayService.createPaymentOrder(
        coins: coins,
        amount: inr,
        packageId: packageId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          final paymentUrl = result['paymentUrl'] as String?;
          _orderId = result['orderId'] as String?;
          _paymentId = result['paymentId'] as String?;
          _currentPaymentCoins = coins;
          _paymentUrl = paymentUrl;

          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            await _fetchPaymentMethods(paymentUrl);
            // Setup real-time listener for payment status
            _setupPaymentStatusListener();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create payment order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchPaymentMethods(String paymentUrl) async {
    try {
      print('📥 Fetching payment methods from: $paymentUrl');
      final response = await http.get(Uri.parse(paymentUrl));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('📥 Payment methods received:');
        print('   UPI: ${jsonData['upi_intent_url'] != null ? "Available" : "Not available"}');
        print('   GPay: ${jsonData['gpay_upi_intent_url'] != null ? "Available" : "Not available"}');
        print('   PhonePe: ${jsonData['phonepe_upi_intent_url'] != null ? "Available" : "Not available"}');
        print('   Paytm: ${jsonData['paytm_upi_intent_url'] != null ? "Available" : "Not available"}');
        
        setState(() {
          _upiIntentUrl = jsonData['upi_intent_url'] as String?;
          _gpayUrl = jsonData['gpay_upi_intent_url'] as String?;
          _phonepeUrl = jsonData['phonepe_upi_intent_url'] as String?;
          _paytmUrl = jsonData['paytm_upi_intent_url'] as String?;
        });
        
        // Log actual URLs for debugging
        if (_phonepeUrl != null) {
          print('   PhonePe URL: ${_phonepeUrl!.substring(0, _phonepeUrl!.length > 100 ? 100 : _phonepeUrl!.length)}...');
        }
        if (_paytmUrl != null) {
          print('   Paytm URL: ${_paytmUrl!.substring(0, _paytmUrl!.length > 100 ? 100 : _paytmUrl!.length)}...');
        }
      } else {
        print('❌ Failed to fetch payment methods: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching payment methods: $e');
    }
  }

  Future<void> _handlePaymentMethodSelection(String method) async {
    if (_isProcessingPayment) return;

    setState(() {
      _selectedPaymentMethod = method;
      _isProcessingPayment = true;
    });

    String? urlToLaunch;

    switch (method) {
      case 'phonepe':
        urlToLaunch = _phonepeUrl;
        // Fallback to generic UPI if PhonePe URL not available
        if (urlToLaunch == null || urlToLaunch.isEmpty) {
          urlToLaunch = _upiIntentUrl;
          print('⚠️ PhonePe URL not available, using generic UPI URL');
        }
        break;
      case 'paytm':
        urlToLaunch = _paytmUrl;
        // Fallback to generic UPI if Paytm URL not available
        if (urlToLaunch == null || urlToLaunch.isEmpty) {
          urlToLaunch = _upiIntentUrl;
          print('⚠️ Paytm URL not available, using generic UPI URL');
        }
        break;
      case 'gpay':
        urlToLaunch = _gpayUrl;
        // Fallback to generic UPI if GPay URL not available
        if (urlToLaunch == null || urlToLaunch.isEmpty) {
          urlToLaunch = _upiIntentUrl;
          print('⚠️ GPay URL not available, using generic UPI URL');
        }
        break;
      case 'upi':
        urlToLaunch = _upiIntentUrl;
        break;
      case 'card':
        // For card payment, open PayPrime checkout page
        urlToLaunch = _paymentUrl;
        break;
    }

    if (urlToLaunch != null && urlToLaunch.isNotEmpty) {
      print('🚀 Launching payment for $method');
      print('   URL available: ${urlToLaunch.substring(0, urlToLaunch.length > 100 ? 100 : urlToLaunch.length)}...');
      await _launchPaymentGateway(urlToLaunch, method);
      // Start automatic status checking
      _startPaymentStatusPolling();
    } else {
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method not available. Please try another.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _launchPaymentGateway(String url, String method) async {
    try {
      print('🚀 Launching $method');
      print('   Original URL: $url');
      
      String urlToLaunch = url;

      // Handle Android Intent URLs (for PhonePe, Paytm)
      if (url.contains('#Intent;')) {
        print('📱 Detected Android Intent URL');
        
        // Extract the UPI URL from Intent format: intent://pay?... #Intent;scheme=upi;...
        // We need to convert: intent://pay?pa=...&tr=...&am=...&cu=INR#Intent;scheme=upi;...
        // To: upi://pay?pa=...&tr=...&am=...&cu=INR
        
        // First, try to extract existing UPI scheme if present
        final upiSchemeMatch = RegExp(r'upi://[^;#]+').firstMatch(url);
        if (upiSchemeMatch != null) {
          urlToLaunch = upiSchemeMatch.group(0)!;
          print('   Extracted UPI scheme: $urlToLaunch');
        } else if (url.startsWith('intent://')) {
          // Extract the query part from intent://pay?... before #Intent
          final intentMatch = RegExp(r'intent://([^#]+)').firstMatch(url);
          if (intentMatch != null) {
            final queryPart = intentMatch.group(1)!;
            // Convert intent:// to upi://
            urlToLaunch = 'upi://$queryPart';
            print('   Converted Intent to UPI: $urlToLaunch');
          } else {
            // Try fallback URL
            final fallbackMatch = RegExp(r'S\.browser_fallback_url=([^;#]+)').firstMatch(url);
            if (fallbackMatch != null) {
              urlToLaunch = Uri.decodeComponent(fallbackMatch.group(1)!);
              print('   Extracted fallback URL: $urlToLaunch');
            }
          }
        } else {
          // Try fallback URL
          final fallbackMatch = RegExp(r'S\.browser_fallback_url=([^;#]+)').firstMatch(url);
          if (fallbackMatch != null) {
            urlToLaunch = Uri.decodeComponent(fallbackMatch.group(1)!);
            print('   Extracted fallback URL: $urlToLaunch');
          }
        }
      }

      print('   Final URL to launch: $urlToLaunch');
      final uri = Uri.parse(urlToLaunch);
      
      // Try launching with external application mode
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ Payment gateway launched: $method');
      } else {
        // If externalApplication fails, try platformDefault
        print('⚠️ ExternalApplication failed, trying platformDefault...');
        final launched2 = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        
        if (launched2) {
          print('✅ Payment gateway launched via platformDefault: $method');
        } else {
          setState(() {
            _isProcessingPayment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $method. Please install the app or try another method.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error launching $method: $e');
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startPaymentStatusPolling() {
    _paymentStatusTimer?.cancel();
    
    // Poll more frequently initially (every 2 seconds for first 30 seconds)
    // Then every 5 seconds for up to 2 minutes
    int pollCount = 0;
    const maxPolls = 60; // 2 minutes max (60 polls * 2 seconds)
    
    _paymentStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      pollCount++;
      
      if (pollCount > maxPolls) {
        print('⏱️ Payment polling timeout after ${maxPolls * 2} seconds');
        _stopPaymentStatusPolling();
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification is taking longer than expected. Please check your wallet balance.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (_orderId != null && _paymentId != null) {
        print('🔄 Polling payment status (attempt $pollCount/$maxPolls)...');
        final result = await _paymentGatewayService.verifyPayment(
          orderId: _orderId!,
          paymentId: _paymentId!,
        );

        if (result['success'] == true && mounted) {
          print('✅ Payment verified successfully!');
          _stopPaymentStatusPolling();
          _showPaymentSuccessScreen(_currentPaymentCoins!);
        } else if (result['pending'] == true) {
          // Still pending, continue polling
          print('⏳ Payment still pending, continuing to poll...');
        }
      } else {
        _stopPaymentStatusPolling();
      }
    });
  }

  void _stopPaymentStatusPolling() {
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
  }

  Future<void> _verifyPaymentStatus() async {
    if (_orderId == null || _paymentId == null) return;

    _stopPaymentStatusPolling();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
        ),
      ),
    );

    try {
      final result = await _paymentGatewayService.verifyPayment(
        orderId: _orderId!,
        paymentId: _paymentId!,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        if (result['success'] == true) {
          _showPaymentSuccessScreen(_currentPaymentCoins!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment verification failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Setup real-time Firestore listener to detect when payment is completed
  /// This listens to both orders and payments collections
  void _setupPaymentStatusListener() {
    if (_orderId == null) return;

    print('👂 Setting up real-time payment status listener...');

    // 1. Listen to order document changes
    _paymentListener = _firestore
        .collection('orders')
        .doc(_orderId!)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      if (snapshot.exists) {
        final data = snapshot.data();
        final status = data?['status'] as String?;
        
        print('📦 Order status changed: $status');
        
        if (status == 'completed' && _currentPaymentCoins != null) {
          print('✅ Order completed detected via real-time listener!');
          _stopPaymentStatusPolling();
          _paymentListener?.cancel();
          _paymentsQueryListener?.cancel();
          _showPaymentSuccessScreen(_currentPaymentCoins!);
        }
      }
    });

    // 2. Listen to payments collection for this order
    _paymentsQueryListener = _firestore
        .collection('payments')
        .where('orderId', isEqualTo: _orderId!)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      if (snapshot.docs.isNotEmpty && _currentPaymentCoins != null) {
        print('✅ Payment completed detected via real-time listener!');
        _stopPaymentStatusPolling();
        _paymentListener?.cancel();
        _paymentsQueryListener?.cancel();
        _showPaymentSuccessScreen(_currentPaymentCoins!);
      }
    });

    print('✅ Real-time listeners active');
  }

  void _showPaymentSuccessScreen(int coins) async {
    if (!mounted) return;
    
    // Get user phone number
    final currentUser = _auth.currentUser;
    String userPhone = '';
    if (currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        final userData = userDoc.data();
        userPhone = userData?['phoneNumber'] as String? ?? '';
        if (userPhone.isEmpty) {
          userPhone = currentUser.phoneNumber ?? '';
        }
      } catch (e) {
        userPhone = currentUser.phoneNumber ?? '';
      }
    }
    
    // Get amount from package
    final int amount = widget.package['inr'];
    
    // Navigate to payment success screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            coins: coins,
            amount: amount,
            transactionId: _orderId,
            paymentId: _paymentId,
            paymentMethod: _selectedPaymentMethod,
            phoneNumber: userPhone,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int coins = widget.package['coins'];
    final int inr = widget.package['inr'];
    final dynamic bonusValue = widget.package['bonus'];
    final int bonus = (bonusValue is int) ? bonusValue : (bonusValue is String) ? int.tryParse(bonusValue) ?? 0 : 0;
    final String badge = widget.package['badge'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing payment...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  
                  // Package Details Section - Compact & Professional with Coin Icon
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Coin Icon (No Background)
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.monetization_on,
                              color: Colors.orange[700],
                              size: 32,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        
                        // Middle: Coins & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge
                              if (badge.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.grey[700],
                                        size: 9,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        badge,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (badge.isNotEmpty) const SizedBox(height: 6),
                              
                              // Coins
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Coins',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              
                              // Price
                              Row(
                                children: [
                                  Text(
                                    '₹',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    inr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Right: Bonus Badge
                        if (bonus > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.green[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  color: Colors.green[700],
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '+$bonus%',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Methods Section - Professional UPI Selection
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          child: const Text(
                            'UPI Options',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        
                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[200],
                        ),
                        
                        // Payment Options (Order: GPay, PhonePe, Paytm, Pay by Any UPI, Card Payment)
                        _buildUPIOptionCard(
                          imagePath: 'assets/images/gpay.png',
                          title: 'GPay',
                          subtitle: null,
                          method: 'gpay',
                          isAvailable: _gpayUrl != null && _gpayUrl!.isNotEmpty,
                          showDivider: true,
                        ),
                        _buildUPIOptionCard(
                          imagePath: 'assets/images/phonepay.png',
                          title: 'PhonePe',
                          subtitle: null,
                          method: 'phonepe',
                          isAvailable: _phonepeUrl != null && _phonepeUrl!.isNotEmpty,
                          showDivider: true,
                        ),
                        _buildUPIOptionCard(
                          imagePath: 'assets/images/paytm.png',
                          title: 'Paytm',
                          subtitle: null,
                          method: 'paytm',
                          isAvailable: _paytmUrl != null && _paytmUrl!.isNotEmpty,
                          showDivider: true,
                        ),
                        _buildUPIOptionCard(
                          imagePath: 'assets/images/upi.png',
                          title: 'Pay by Any UPI app',
                          subtitle: 'Use any UPI app on your phone to pay',
                          method: 'upi',
                          isAvailable: _upiIntentUrl != null && _upiIntentUrl!.isNotEmpty,
                          showDivider: true,
                        ),
                        _buildUPIOptionCard(
                          imagePath: 'assets/images/visa.png',
                          title: 'Card Payment',
                          subtitle: 'Credit/Debit Card',
                          method: 'card',
                          isAvailable: _paymentUrl != null && _paymentUrl!.isNotEmpty,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildUPIOptionCard({
    required String imagePath,
    required String title,
    required String? subtitle,
    required String method,
    required bool isAvailable,
    required bool showDivider,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    final isDisabled = !isAvailable || _isProcessingPayment;

    return Column(
      children: [
        GestureDetector(
          onTap: isDisabled ? null : () => _handlePaymentMethodSelection(method),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.transparent,
            child: Row(
              children: [
                // Image Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: isDisabled
                        ? Opacity(
                            opacity: 0.4,
                            child: Image.asset(
                              imagePath,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.payment,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[50],
                                child: Icon(
                                  Icons.payment,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDisabled ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Radio Button
                if (isDisabled)
                  Icon(
                    Icons.block,
                    color: Colors.grey[400],
                    size: 20,
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1976D2) : Colors.grey[400]!,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
                    child: isSelected
                        ? Container(
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1976D2),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[200],
            indent: 78, // Align with content
          ),
      ],
    );
  }
}
