import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/payment_service.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final int coins;
  final int amount;
  final String packageId;

  const PaymentScreen({
    super.key,
    required this.coins,
    required this.amount,
    required this.packageId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _utrController = TextEditingController();
  bool _isSubmitting = false;
  
  Timer? _timer;
  int _remainingSeconds = 600; // 10 minutes in seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _utrController.dispose();
    super.dispose();
  }

  /// Generate UPI payment string for QR code
  String _generateUPIString() {
    final amountStr = widget.amount.toInt().toString();
    final upiId = PaymentService.upiId;
    final merchantName = PaymentService.merchantName;
    final encodedName = Uri.encodeComponent(merchantName);
    final encodedNote = Uri.encodeComponent('Coin Purchase');
    
    // Generate UPI payment string
    return 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
  }

  /// Open PhonePe payment app
  Future<void> _openPhonePe() async {
    try {
      final amountStr = widget.amount.toInt().toString();
      final upiId = PaymentService.upiId;
      final merchantName = PaymentService.merchantName;
      final encodedName = Uri.encodeComponent(merchantName);
      final encodedNote = Uri.encodeComponent('Coin Purchase');
      
      final phonePeLink = 'phonepe://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
      final uri = Uri.parse(phonePeLink);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic UPI
        final genericUpiLink = 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
        final genericUri = Uri.parse(genericUpiLink);
        await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open PhonePe. Please scan the QR code to pay.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Open Google Pay payment app
  Future<void> _openGooglePay() async {
    try {
      final amountStr = widget.amount.toInt().toString();
      final upiId = PaymentService.upiId;
      final merchantName = PaymentService.merchantName;
      final encodedName = Uri.encodeComponent(merchantName);
      final encodedNote = Uri.encodeComponent('Coin Purchase');
      
      final googlePayLink = 'tez://upi/pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
      final uri = Uri.parse(googlePayLink);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic UPI
        final genericUpiLink = 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
        final genericUri = Uri.parse(genericUpiLink);
        await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Pay. Please scan the QR code to pay.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Open Paytm payment app
  Future<void> _openPaytm() async {
    try {
      final amountStr = widget.amount.toInt().toString();
      final upiId = PaymentService.upiId;
      final merchantName = PaymentService.merchantName;
      final encodedName = Uri.encodeComponent(merchantName);
      final encodedNote = Uri.encodeComponent('Coin Purchase');
      
      final paytmLink = 'paytmmp://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
      final uri = Uri.parse(paytmLink);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic UPI
        final genericUpiLink = 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&cu=INR&tn=$encodedNote';
        final genericUri = Uri.parse(genericUpiLink);
        await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Paytm. Please scan the QR code to pay.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Submit UTR and add coins automatically
  Future<void> _submitUTR() async {
    if (_utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UTR number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _paymentService.submitUTR(
      utrNumber: _utrController.text.trim(),
      coins: widget.coins,
      amount: widget.amount,
      packageId: widget.packageId,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['message'] ?? 'Coins added successfully!',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      });
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['message'] ?? 'Payment failed. Please try again.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show UTR guide dialog with image
  void _showUTRGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: screenWidth * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Bar - Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'How to find UTR number',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Images - Scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // First Image - PhonePe
                          const Text(
                            'PhonePe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Image.asset(
                            'assets/images/payment.jpg',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Image not found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Second Image - Paytm
                          const Text(
                            'Paytm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Image.asset(
                            'assets/images/payment1.jpg',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Image not found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // UPI Apps Logos
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PhonePe
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openPhonePe,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 6 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F259F), // PhonePe purple
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSmallScreen ? 16 : 18,
                                height: isSmallScreen ? 16 : 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                                ),
                                child: Center(
                                  child: Text(
                                    'P',
                                    style: TextStyle(
                                      color: const Color(0xFF5F259F),
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 5),
                              Text(
                                'PhonePe',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    // Google Pay
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openGooglePay,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 6 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4), // Google Pay blue
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSmallScreen ? 16 : 18,
                                height: isSmallScreen ? 16 : 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                                ),
                                child: Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: const Color(0xFF4285F4),
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 5),
                              Text(
                                'Google Pay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    // Paytm
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openPaytm,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 6 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BAF2), // Paytm blue
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSmallScreen ? 16 : 18,
                                height: isSmallScreen ? 16 : 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 3 : 4),
                                ),
                                child: Center(
                                  child: Text(
                                    'P',
                                    style: TextStyle(
                                      color: const Color(0xFF00BAF2),
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 5),
                              Text(
                                'Paytm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // Countdown Timer
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: _remainingSeconds > 60
                        ? const Color(0xFF9C27B0)
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complete payment within: ',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      color: _remainingSeconds > 60
                          ? const Color(0xFF9C27B0)
                          : Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // QR Code Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan QR Code to Pay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan with PhonePe, Paytm, or Google Pay',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: _generateUPIString(),
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Payment Details below QR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'UPI ID:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              PaymentService.upiId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₹${NumberFormat.decimalPattern().format(widget.amount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // UPI ID Display with Instructions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      return Row(
                        children: [
                          Text(
                            'UPI ID: ',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 13 : 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              PaymentService.upiId,
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              size: screenWidth < 360 ? 18 : 20,
                              color: Colors.blue[700],
                            ),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: PaymentService.upiId));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('UPI ID copied! You can paste it in PhonePe.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Amount: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${NumberFormat.decimalPattern().format(widget.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      return Text(
                        '💡 Tip: If payment app doesn\'t open automatically, copy the UPI ID and pay manually in PhonePe/Paytm.',
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 11 : 12,
                          color: Colors.blue[800],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // UTR Input Section
            GestureDetector(
              onTap: _showUTRGuide,
              child: const Text(
                'How to find UTR number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                hintText: 'Enter UTR number from payment receipt',
                prefixIcon: const Icon(Icons.receipt_long),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9C27B0),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 8),
            Text(
              'After payment, copy the UTR number from your payment receipt and paste it here.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _isSubmitting
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFF1B7C), Color(0xFF9C27B0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: _isSubmitting ? Colors.grey[400] : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _submitUTR,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit UTR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

}

