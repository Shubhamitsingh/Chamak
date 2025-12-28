import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gift_service.dart';
import '../services/withdrawal_service.dart';
import '../models/gift_model.dart';
import '../models/withdrawal_request_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GiftService _giftService = GiftService();
  final WithdrawalService _withdrawalService = WithdrawalService();

  String _selectedFilter = 'all'; // 'all', 'payment_request', 'withdrawals'
  bool _useFallback = false; // Use fallback queries if index error occurs

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Please login to view history'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildTransactionsList(currentUser.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildFilterChip('all', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('payment_request', 'Payment Request'),
          const SizedBox(width: 8),
          _buildFilterChip('withdrawals', 'Withdrawals'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFFF1B7C),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildTransactionsList(String userId) {
    // Use fallback methods if index error occurred
    final withdrawalStream = _useFallback
        ? _withdrawalService.getUserWithdrawalRequestsFallback(userId)
        : _withdrawalService.getUserWithdrawalRequests(userId);
    
    final giftStream = _useFallback
        ? _giftService.getHostReceivedGiftsFallback(userId)
        : _giftService.getHostReceivedGifts(userId);
    
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: withdrawalStream,
      builder: (context, withdrawalSnapshot) {
        return StreamBuilder<List<GiftModel>>(
          stream: giftStream,
          builder: (context, giftSnapshot) {
            if (giftSnapshot.connectionState == ConnectionState.waiting ||
                withdrawalSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (giftSnapshot.hasError || withdrawalSnapshot.hasError) {
              final error = giftSnapshot.error ?? withdrawalSnapshot.error;
              final errorString = error.toString();
              
              // Check if it's an index error - use fallback automatically
              if ((errorString.contains('index') || errorString.contains('failed-precondition')) && !_useFallback) {
                // Automatically switch to fallback queries
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _useFallback = true;
                    });
                  }
                });
                // Show loading while switching to fallback
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              // If fallback also fails or other error
              if (_useFallback) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load transaction history. Please check your internet connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _useFallback = false; // Reset and retry with index
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF1B7C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Other errors
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Error Loading Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load transaction history. Please try again later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            // Force rebuild to retry
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1B7C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final gifts = giftSnapshot.data ?? [];
            final withdrawals = withdrawalSnapshot.data ?? [];

            // Filter withdrawals by status
            List<WithdrawalRequestModel> paymentRequests = withdrawals
                .where((w) => w.status != 'paid') // pending or approved
                .toList();
            
            List<WithdrawalRequestModel> paidWithdrawals = withdrawals
                .where((w) => w.status == 'paid') // only paid
                .toList();

            // Combine and sort transactions based on filter
            List<dynamic> combined = [];
            
            if (_selectedFilter == 'all') {
              // Show everything: earnings + all withdrawal requests
              combined.addAll(gifts);
              combined.addAll(withdrawals);
            } else if (_selectedFilter == 'payment_request') {
              // Show only pending/approved payment requests (not paid yet)
              combined.addAll(paymentRequests);
            } else if (_selectedFilter == 'withdrawals') {
              // Show only paid withdrawal requests
              combined.addAll(paidWithdrawals);
            }

            // Sort by timestamp (newest first)
            combined.sort((a, b) {
              DateTime? dateA;
              DateTime? dateB;

              if (a is GiftModel) dateA = a.timestamp;
              if (a is WithdrawalRequestModel) dateA = a.requestDate;

              if (b is GiftModel) dateB = b.timestamp;
              if (b is WithdrawalRequestModel) dateB = b.requestDate;

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;

              return dateB.compareTo(dateA);
            });

            if (combined.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: combined.length,
              itemBuilder: (context, index) {
                final item = combined[index];
                if (item is GiftModel) {
                  return _buildGiftTransactionItem(item);
                } else if (item is WithdrawalRequestModel) {
                  return _buildWithdrawalRequestItem(item);
                }
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGiftTransactionItem(GiftModel gift) {
    final cCoinsEarned = gift.cCoinsEarned ?? 0;
    final timestamp = gift.timestamp;
    String formattedDate = timestamp != null ? _formatDate(timestamp) : 'Unknown Date';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earnings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+C $cCoinsEarned',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'RECEIVED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalRequestItem(WithdrawalRequestModel request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color backgroundColor;

    switch (request.status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFFF9800); // Orange
        statusIcon = Icons.access_time_rounded;
        statusText = 'Pending';
        backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
        break;
      case 'approved':
        statusColor = const Color(0xFF2196F3); // Blue
        statusIcon = Icons.verified_rounded;
        statusText = 'Approved';
        backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
        break;
      case 'paid':
        statusColor = const Color(0xFF04B104); // Green
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Paid';
        backgroundColor = const Color(0xFF04B104).withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = request.status.toUpperCase();
        backgroundColor = Colors.grey.withOpacity(0.1);
    }

    final inrAmount = request.amount * 0.04;
    final methodIcon = request.withdrawalMethod == 'UPI'
        ? Icons.account_balance_wallet_rounded
        : request.withdrawalMethod == 'Bank Transfer'
            ? Icons.account_balance_rounded
            : Icons.currency_bitcoin_rounded;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: request.paymentProofURL != null
            ? () => _showPaymentProof(request.paymentProofURL!)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.5),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Status Badge + Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'C ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${request.amount}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '≈ ₹${inrAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Details Section - Compact Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Method Icon
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        methodIcon,
                        color: statusColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Method & Date Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.withdrawalMethod}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDate(request.requestDate),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (request.approvedDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 10,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDate(request.approvedDate!),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              if (request.paidDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 10,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDate(request.paidDate!),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Payment Proof Indicator
                if (request.paymentProofURL != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Payment proof - Tap to view',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _showPaymentProof(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 12),
                          Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

