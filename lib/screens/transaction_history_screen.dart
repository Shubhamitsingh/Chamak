import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/withdrawal_service.dart';
import '../models/withdrawal_request_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A), // Dark background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.white,
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
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A), // Dark grey container
      ),
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
      selectedColor: const Color(0xFFFF1B7C), // App theme pink
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[400],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildTransactionsList(String userId) {
    // Use getUserWithdrawalRequests which now uses fallback by default (no index needed)
    final withdrawalStream = _withdrawalService.getUserWithdrawalRequests(userId);
    
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: withdrawalStream,
      builder: (context, withdrawalSnapshot) {
            if (withdrawalSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1B7C)));
            }

            if (withdrawalSnapshot.hasError) {
              final error = withdrawalSnapshot.error;
              final errorString = error!.toString();
              
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
                  child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load transaction history. Please check your internet connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load transaction history. Please try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
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

            final withdrawals = withdrawalSnapshot.data ?? [];

            // Filter withdrawals by status
            List<WithdrawalRequestModel> paymentRequests = withdrawals
                .where((w) => w.status != 'paid') // pending or approved
                .toList();
            
            List<WithdrawalRequestModel> paidWithdrawals = withdrawals
                .where((w) => w.status == 'paid') // only paid
                .toList();

            // Combine and sort transactions based on filter
            // NOTE: Only show withdrawal requests, NOT gift earnings
            List<dynamic> combined = [];
            
            if (_selectedFilter == 'all') {
              // Show all withdrawal requests only (pending, approved, paid)
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

              if (a is WithdrawalRequestModel) dateA = a.requestDate;
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your withdrawal history will appear here',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: combined.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = combined[index];
                // Only show withdrawal requests now
                if (item is WithdrawalRequestModel) {
                  return _buildWithdrawalRequestItem(item);
                }
                return const SizedBox.shrink();
              },
            );
      },
    );
  }

  Widget _buildWithdrawalRequestItem(WithdrawalRequestModel request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFFF9800); // Orange
        statusIcon = Icons.access_time_rounded;
        statusText = 'Pending';
        break;
      case 'approved':
        statusColor = const Color(0xFF2196F3); // Blue
        statusIcon = Icons.verified_rounded;
        statusText = 'Approved';
        break;
      case 'paid':
        statusColor = const Color(0xFF04B104); // Green
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Paid';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = request.status.toUpperCase();
    }

    // Amount is now stored directly in INR (not C Coins)
    // Backward compatibility: old records were C Coins, model converts them to INR
    final inrAmount = request.amount; // Already in INR from model
    final methodIcon = request.withdrawalMethod == 'UPI'
        ? Icons.account_balance_wallet_rounded
        : request.withdrawalMethod == 'Bank Transfer'
            ? Icons.account_balance_rounded
            : Icons.currency_bitcoin_rounded;

    return InkWell(
      onTap: request.paymentProofURL != null
          ? () => _showPaymentProof(request.paymentProofURL!)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // Light grey container
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon with Status Color
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                methodIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Description and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Withdrawal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.withdrawalMethod} • ${_formatDate(request.requestDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                  if (request.paymentProofURL != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 12,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Payment proof available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Amount on Right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${inrAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor == const Color(0xFF04B104) 
                        ? const Color(0xFF04B104) // Green for paid
                        : Colors.white, // White for pending/approved
                  ),
                ),
              ],
            ),
          ],
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

