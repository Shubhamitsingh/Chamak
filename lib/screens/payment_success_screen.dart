import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'wallet_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final int coins;
  final int amount;
  final String? transactionId;
  final String? paymentId;
  final String? paymentMethod;
  final String phoneNumber;

  const PaymentSuccessScreen({
    super.key,
    required this.coins,
    required this.amount,
    this.transactionId,
    this.paymentId,
    this.paymentMethod,
    required this.phoneNumber,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to wallet after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToWallet();
      }
    });
  }

  void _navigateToWallet() {
    if (!mounted) return;
    
    // Remove all previous routes and navigate to wallet
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => WalletScreen(
          phoneNumber: widget.phoneNumber,
          showBackButton: true,
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  String _getPaymentMethodName(String? method) {
    if (method == null) return 'Online Payment';
    
    switch (method.toLowerCase()) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card Payment';
      default:
        return 'Online Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('M/d/yyyy, h:mm:ss a').format(now);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Success Icon with Pink Circle and Green Badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main Pink Circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF69B4), // Pink/Magenta
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    // Green Badge Overlay (top-right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF69B4), // Pink
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Thank you message
                Text(
                  'Thank you for your purchase',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment has been processed successfully. You will receive a confirmation email shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Payment Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transaction ID
                      _buildDetailRow(
                        label: 'Transaction ID',
                        value: widget.transactionId ?? widget.paymentId ?? 'N/A',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Amount Paid
                      _buildDetailRow(
                        label: 'Amount Paid',
                        value: '₹${NumberFormat('#,##0').format(widget.amount)}',
                        valueColor: const Color(0xFFFF69B4), // Pink
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Method
                      _buildDetailRow(
                        label: 'Payment Method',
                        value: _getPaymentMethodName(widget.paymentMethod),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date & Time
                      _buildDetailRow(
                        label: 'Date & Time',
                        value: formattedDate,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Done Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _navigateToWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4), // Pink
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Wallet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Auto-navigate hint
                Text(
                  'Redirecting to wallet in 5 seconds...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}