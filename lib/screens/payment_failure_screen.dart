import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'wallet_screen.dart';

/// Payment Failure Screen
/// 
/// Shows when payment fails with retry option
class PaymentFailureScreen extends StatefulWidget {
  final String? failureReason;
  final double amount;
  final int coins;
  final String? paymentMethod;
  final String? transactionId;
  final String? paymentId;
  final String phoneNumber;
  final VoidCallback? onRetry; // Optional retry callback

  const PaymentFailureScreen({
    super.key,
    this.failureReason,
    required this.amount,
    required this.coins,
    this.paymentMethod,
    this.transactionId,
    this.paymentId,
    required this.phoneNumber,
    this.onRetry,
  });

  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> {
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

  String _getFailureMessage() {
    if (widget.failureReason != null && widget.failureReason!.isNotEmpty) {
      return widget.failureReason!;
    }
    return 'Payment could not be completed. Please try again.';
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
                
                // Failure Icon with Red Circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Failure message
                Text(
                  _getFailureMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
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
                    border: Border.all(color: Colors.grey[300]!),
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
                      if (widget.transactionId != null || widget.paymentId != null)
                        _buildDetailRow(
                          label: 'Transaction ID',
                          value: widget.transactionId ?? widget.paymentId ?? 'N/A',
                        ),
                      
                      if (widget.transactionId != null || widget.paymentId != null)
                        const SizedBox(height: 16),
                      
                      // Amount
                      _buildDetailRow(
                        label: 'Amount',
                        value: '₹${NumberFormat('#,##0').format(widget.amount)}',
                        valueColor: Colors.red,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Coins
                      _buildDetailRow(
                        label: 'Coins',
                        value: '${widget.coins} coins',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Method
                      if (widget.paymentMethod != null)
                        _buildDetailRow(
                          label: 'Payment Method',
                          value: _getPaymentMethodName(widget.paymentMethod),
                        ),
                      
                      if (widget.paymentMethod != null)
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
                
                // Try Again Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // If retry callback provided, use it
                      if (widget.onRetry != null) {
                        widget.onRetry!();
                      } else {
                        // Otherwise, go back to wallet
                        _navigateToWallet();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1B7C), // Pink
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Go Back Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _navigateToWallet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back to Wallet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
