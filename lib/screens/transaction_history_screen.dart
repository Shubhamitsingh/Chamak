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

  String _selectedFilter = 'all'; // 'all', 'earnings', 'withdrawals'

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip('all', 'All'),
          _buildFilterChip('earnings', 'Earnings'),
          _buildFilterChip('withdrawals', 'Withdrawals'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
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
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildTransactionsList(String userId) {
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: _withdrawalService.getUserWithdrawalRequests(userId),
      builder: (context, withdrawalSnapshot) {
        return StreamBuilder<List<GiftModel>>(
          stream: _giftService.getHostReceivedGifts(userId),
          builder: (context, giftSnapshot) {
            if (giftSnapshot.connectionState == ConnectionState.waiting ||
                withdrawalSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (giftSnapshot.hasError || withdrawalSnapshot.hasError) {
              return Center(
                child: Text('Error: ${giftSnapshot.error ?? withdrawalSnapshot.error}'),
              );
            }

            final gifts = giftSnapshot.data ?? [];
            final withdrawals = withdrawalSnapshot.data ?? [];

            // Combine and sort transactions
            List<dynamic> combined = [];
            
            if (_selectedFilter == 'all' || _selectedFilter == 'earnings') {
              combined.addAll(gifts);
            }
            if (_selectedFilter == 'all' || _selectedFilter == 'withdrawals') {
              combined.addAll(withdrawals);
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

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final inrAmount = request.amount * 0.04;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: request.paymentProofURL != null
            ? () => _showPaymentProof(request.paymentProofURL!)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawal Request',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(request.requestDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (request.paidDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Paid: ${_formatDate(request.paidDate!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                    if (request.paymentProofURL != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.image, size: 14, color: Colors.blue[300]),
                          const SizedBox(width: 4),
                          Text(
                            'Payment proof available',
                            style: TextStyle(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-C ${request.amount}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    '≈ ₹${inrAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
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

