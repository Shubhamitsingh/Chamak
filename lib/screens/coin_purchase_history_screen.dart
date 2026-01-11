import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CoinPurchaseHistoryScreen extends StatefulWidget {
  const CoinPurchaseHistoryScreen({super.key});

  @override
  State<CoinPurchaseHistoryScreen> createState() => _CoinPurchaseHistoryScreenState();
}

class _CoinPurchaseHistoryScreenState extends State<CoinPurchaseHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _selectedDate; // null means "All"

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CustomDatePickerDialog(
        initialDate: _selectedDate ?? DateTime.now(),
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
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
      body: currentUser == null 
          ? _buildEmptyState()
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: _buildTransactionsList(currentUser.uid),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'All Transactions'
                            : DateFormat('MMM d, y').format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: _clearDateFilter,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, paymentSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('callTransactions')
              .where('callerId', isEqualTo: userId)
              .limit(100)
              .snapshots(),
          builder: (context, callSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('gifts')
                  .where('senderId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, giftSnapshot) {
                // Loading state
                if (paymentSnapshot.connectionState == ConnectionState.waiting ||
                    callSnapshot.connectionState == ConnectionState.waiting ||
                    giftSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                  );
                }

            // Combine transactions
            List<Map<String, dynamic>> allTransactions = [];

            // Add payment transactions
            if (paymentSnapshot.hasData && paymentSnapshot.data != null) {
              for (var doc in paymentSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt = data['createdAt'] as Timestamp?;
                
                allTransactions.add({
                  'type': 'purchase',
                  'id': doc.id,
                  'coins': data['coins'] as int? ?? 0,
                  'amount': data['amount'] as int? ?? 0,
                  'utrNumber': data['utrNumber'] as String? ?? '',
                  'status': data['status'] as String? ?? 'pending',
                  'timestamp': createdAt,
                  'createdAt': createdAt,
                  'completedAt': data['completedAt'] as Timestamp?,
                });
              }
            }

            // Add call deduction transactions
            if (callSnapshot.hasData && callSnapshot.data != null) {
              for (var doc in callSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                Timestamp? transactionTimestamp;
                
                // Handle timestamp - can be Timestamp, String, or DateTime
                if (data['timestamp'] != null) {
                  if (data['timestamp'] is Timestamp) {
                    transactionTimestamp = data['timestamp'] as Timestamp;
                  } else if (data['timestamp'] is String) {
                    try {
                      final dateTime = DateTime.parse(data['timestamp'] as String);
                      transactionTimestamp = Timestamp.fromDate(dateTime);
                    } catch (e) {
                      debugPrint('Error parsing timestamp string: $e');
                      transactionTimestamp = Timestamp.now();
                    }
                  } else if (data['timestamp'] is DateTime) {
                    transactionTimestamp = Timestamp.fromDate(data['timestamp'] as DateTime);
                  } else {
                    transactionTimestamp = Timestamp.now();
                  }
                } else {
                  transactionTimestamp = Timestamp.now();
                }
                
                allTransactions.add({
                  'type': 'deduction',
                  'id': doc.id,
                  'coins': data['uCoinsDeducted'] as int? ?? 0,
                  'timestamp': transactionTimestamp,
                  'duration': data['durationSeconds'] as int? ?? 0,
                  'hostId': data['hostId'] as String? ?? '',
                });
              }
            }

            // Add gift spending transactions
            if (giftSnapshot.hasData && giftSnapshot.data != null) {
              for (var doc in giftSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                Timestamp? giftTimestamp;
                
                // Handle timestamp - can be Timestamp, String, or DateTime
                if (data['timestamp'] != null) {
                  if (data['timestamp'] is Timestamp) {
                    giftTimestamp = data['timestamp'] as Timestamp;
                  } else if (data['timestamp'] is String) {
                    try {
                      final dateTime = DateTime.parse(data['timestamp'] as String);
                      giftTimestamp = Timestamp.fromDate(dateTime);
                    } catch (e) {
                      debugPrint('Error parsing gift timestamp string: $e');
                      giftTimestamp = Timestamp.now();
                    }
                  } else if (data['timestamp'] is DateTime) {
                    giftTimestamp = Timestamp.fromDate(data['timestamp'] as DateTime);
                  } else {
                    giftTimestamp = Timestamp.now();
                  }
                } else {
                  giftTimestamp = Timestamp.now();
                }
                
                allTransactions.add({
                  'type': 'gift',
                  'id': doc.id,
                  'coins': data['uCoinsSpent'] as int? ?? 0,
                  'timestamp': giftTimestamp,
                  'giftType': data['giftType'] as String? ?? '',
                  'receiverName': data['receiverName'] as String? ?? '',
                  'receiverId': data['receiverId'] as String? ?? '',
                });
              }
            }

            // Sort by timestamp (newest first)
            allTransactions.sort((a, b) {
              Timestamp? aTime = a['timestamp'] as Timestamp?;
              Timestamp? bTime = b['timestamp'] as Timestamp?;
              
              // Fallback to createdAt for purchases
              if (aTime == null && a['createdAt'] != null) {
                aTime = a['createdAt'] as Timestamp?;
              }
              if (bTime == null && b['createdAt'] != null) {
                bTime = b['createdAt'] as Timestamp?;
              }
              
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            // Filter by date if selected
            final filteredTransactions = _selectedDate == null
                ? allTransactions
                : allTransactions.where((transaction) {
                    Timestamp? timestamp = transaction['timestamp'] as Timestamp?;
                    if (timestamp == null && transaction['createdAt'] != null) {
                      timestamp = transaction['createdAt'] as Timestamp?;
                    }
                    if (timestamp == null) return false;
                    
                    final transactionDate = timestamp.toDate();
                    final selectedDate = _selectedDate!;
                    
                    // Check if transaction date matches selected date (ignore time)
                    return transactionDate.year == selectedDate.year &&
                           transactionDate.month == selectedDate.month &&
                           transactionDate.day == selectedDate.day;
                  }).toList();

            // Show empty state if no transactions after filtering
            if (filteredTransactions.isEmpty) {
              return _buildEmptyState();
            }

            // Display filtered transactions
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final type = transaction['type'] as String;
                
                if (type == 'purchase') {
                  return _buildPurchaseTransactionItem(
                    coins: transaction['coins'] as int,
                    amount: transaction['amount'] as int,
                    utrNumber: transaction['utrNumber'] as String,
                    status: transaction['status'] as String,
                    createdAt: (transaction['createdAt'] as Timestamp?)?.toDate(),
                    completedAt: (transaction['completedAt'] as Timestamp?)?.toDate(),
                  );
                } else if (type == 'gift') {
                  // Gift spending transaction
                  final timestamp = transaction['timestamp'] as Timestamp?;
                  return _buildGiftTransactionItem(
                    coins: transaction['coins'] as int,
                    timestamp: timestamp?.toDate(),
                    giftType: transaction['giftType'] as String? ?? '',
                    receiverName: transaction['receiverName'] as String? ?? '',
                  );
                } else {
                  // Deduction transaction (call)
                  final timestamp = transaction['timestamp'] as Timestamp?;
                  return _buildDeductionTransactionItem(
                    coins: transaction['coins'] as int,
                    timestamp: timestamp?.toDate(),
                    duration: transaction['duration'] as int,
                  );
                }
              },
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Transaction History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your transaction history will appear here once you make purchases or use coins.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseTransactionItem({
    required int coins,
    required int amount,
    required String utrNumber,
    required String status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    final isCompleted = status.toLowerCase() == 'completed';
    final statusColor = isCompleted ? const Color(0xFF04B104) : const Color(0xFFFF9800);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator (left colored bar)
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Amount and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: Color(0xFFFFB800),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.decimalPattern().format(coins),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Amount in rupees
                Text(
                  '₹${NumberFormat.decimalPattern().format(amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                // Date and UTR
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (utrNumber.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.receipt,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          utrNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionTransactionItem({
    required int coins,
    DateTime? timestamp,
    required int duration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator (left colored bar)
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Amount and Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: Color(0xFFFFB800),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.decimalPattern().format(coins),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Duration and Date
                Row(
                  children: [
                    Icon(
                      Icons.phone_in_talk,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(timestamp ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftTransactionItem({
    required int coins,
    DateTime? timestamp,
    required String giftType,
    required String receiverName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator (left colored bar)
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF69B4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Amount and Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF69B4),
                          ),
                        ),
                        Image.asset(
                          'assets/images/coin3.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: Color(0xFFFFB800),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.decimalPattern().format(coins),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Gift',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF69B4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Gift type and Date
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        giftType.isNotEmpty ? giftType : 'Gift',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (receiverName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          receiverName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(timestamp ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y • hh:mm a').format(date);
    }
  }
}

// Custom Date Picker Dialog matching the design in the image
class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _CustomDatePickerDialog({
    required this.initialDate,
  });

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstDayWeekday = firstDay.weekday;

    final List<DateTime> days = [];
    
    // Add empty cells for days before the first day of month
    for (int i = 1; i < firstDayWeekday; i++) {
      days.add(DateTime(month.year, month.month, 0 - (firstDayWeekday - 1 - i)));
    }
    
    // Add all days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    
    return days;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final fullDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pink Header with Selected Date
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF1B7C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${_selectedDate.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fullDayNames[_selectedDate.weekday % 7]}, ${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // White Section with Month Navigation and Calendar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black87),
                        onPressed: _previousMonth,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.black87),
                        onPressed: _currentMonth.year < DateTime.now().year ||
                                  (_currentMonth.year == DateTime.now().year && 
                                   _currentMonth.month < DateTime.now().month)
                            ? _nextMonth
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Day Headers
                  Row(
                    children: dayNames.map((day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final date = days[index];
                      final isCurrentMonth = date.month == _currentMonth.month;
                      final isSelected = _isSameDay(date, _selectedDate);
                      final isToday = _isSameDay(date, DateTime.now());
                      
                      // Don't allow selecting future dates
                      final canSelect = date.isBefore(DateTime.now()) || _isSameDay(date, DateTime.now());
                      
                      return InkWell(
                        onTap: canSelect && isCurrentMonth ? () {
                          setState(() {
                            _selectedDate = date;
                          });
                        } : null,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? const Color(0xFFFF1B7C)
                                : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: const Color(0xFFFF1B7C),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : !isCurrentMonth
                                        ? Colors.grey[300]
                                        : !canSelect
                                            ? Colors.grey[400]
                                            : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Color(0xFFFF1B7C),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Color(0xFFFF1B7C),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
