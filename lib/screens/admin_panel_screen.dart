import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/support_chat_service.dart';
import '../services/withdrawal_service.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/admin_team_message_service.dart';
import '../services/host_application_service.dart';
import '../models/withdrawal_request_model.dart';
import '../models/host_application_model.dart';
import 'admin_support_chat_screen.dart';

/// Admin Panel Screen for managing user coins
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final SupportChatService _supportChatService = SupportChatService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();
  final AdminTeamMessageService _teamMessageService = AdminTeamMessageService();
  final HostApplicationService _hostApplicationService = HostApplicationService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _coinsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _teamMessageController = TextEditingController();

  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _adminActions = [];
  
  // Tab controller for Add Coins and Support Chats
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _checkAdminStatus();
    _loadAdminActions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _coinsController.dispose();
    _reasonController.dispose();
    _teamMessageController.dispose();
    super.dispose();
  }

  /// Check if current user is admin
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isCheckingAdmin = true;
    });

    final isAdmin = await _adminService.isAdmin();
    final currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });

    if (!isAdmin) {
      if (mounted) {
        // Show detailed error with User UID
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Admin Access Denied'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You do not have admin permissions. To fix this:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('1. Go to Firebase Console → Firestore Database'),
                const Text('2. Create collection: "admins"'),
                const Text('3. Create document with ID: (your User UID below)'),
                const Text('4. Add field: isAdmin = true (boolean type)'),
                const SizedBox(height: 12),
                if (currentUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your User UID:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          currentUser.uid,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Search for users
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _adminService.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  /// Select a user
  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
    });
    _searchController.clear();
    _searchResults = [];
    _loadUserBalance(user['userId']);
  }

  /// Load user's current balance from Firestore users collection
  Future<void> _loadUserBalance(String userId) async {
    print('🔄 Loading balance for user: $userId');
    final balance = await _adminService.getUserCoinBalance(userId);
    if (balance.isNotEmpty && mounted) {
      print('📊 Balance loaded - U Coins: ${balance['uCoins']}, C Coins: ${balance['cCoins']}');
      setState(() {
        _selectedUser = {
          ..._selectedUser!,
          'uCoins': balance['uCoins'] ?? 0,
          'cCoins': balance['cCoins'] ?? 0,
          'isActive': balance['isActive'] ?? true, // Load account approval status
        };
      });
      print('✅ UI updated with new balance');
    } else {
      print('⚠️ Failed to load balance or balance data is empty');
    }
  }

  /// Add coins to selected user
  Future<void> _addCoins() async {
    if (_selectedUser == null) {
      _showError('Please select a user first');
      return;
    }

    final coinsText = _coinsController.text.trim();
    if (coinsText.isEmpty) {
      _showError('Please enter amount of coins to add');
      return;
    }

    final coinsToAdd = int.tryParse(coinsText);
    if (coinsToAdd == null || coinsToAdd <= 0) {
      _showError('Please enter a valid positive number');
      return;
    }

    print('🔵 [AdminPanel] _addCoins() called');
    print('   Selected user: ${_selectedUser!['userId']}');
    print('   Coins to add: $coinsToAdd');
    print('   Reason: ${_reasonController.text.trim().isEmpty ? "Admin coin addition" : _reasonController.text.trim()}');
    
    setState(() {
      _isLoading = true;
    });

    // Admin can only add U Coins
    print('🔵 [AdminPanel] Calling _adminService.addUCoinsToUser()...');
    final result = await _adminService.addUCoinsToUser(
      userId: _selectedUser!['userId'],
      coinsToAdd: coinsToAdd,
      reason: _reasonController.text.trim().isEmpty
          ? 'Admin coin addition'
          : _reasonController.text.trim(),
    );
    
    print('🔵 [AdminPanel] addUCoinsToUser returned:');
    print('   success: ${result['success']}');
    print('   message: ${result['message']}');
    if (result['success'] == true) {
      print('   coinsAdded: ${result['coinsAdded']}');
      print('   newBalance: ${result['newBalance']}');
    }

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      _showSuccess(
          '✅ Added ${result['coinsAdded']} U Coins to user!\n'
          'Previous: ${result['previousBalance']} → New: ${result['newBalance']}\n'
          '✅ Updated in users collection: users/${_selectedUser!['userId']}/uCoins');

      // Wait a moment for Firestore to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Update selected user balance - reload from Firestore
      await _loadUserBalance(_selectedUser!['userId']);

      // Clear form
      _coinsController.clear();
      _reasonController.clear();

      // Reload admin actions
      _loadAdminActions();

      // Force UI refresh
      setState(() {});
    } else {
      _showError(result['message'] ?? 'Failed to add coins');
    }
  }

  /// Load admin action history
  Future<void> _loadAdminActions() async {
    final actions = await _adminService.getAdminActionHistory(limit: 20);
    if (mounted) {
      setState(() {
        _adminActions = actions;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Toggle account approval status
  Future<void> _toggleAccountApproval() async {
    if (_selectedUser == null) return;

    final userId = _selectedUser!['userId'] as String;
    final currentStatus = _selectedUser!['isActive'] ?? true;
    final newStatus = !currentStatus;

    setState(() {
      _isLoading = true;
    });

    final success = await _databaseService.updateAccountApproval(
      userId: userId,
      isApproved: newStatus,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _selectedUser!['isActive'] = newStatus;
          _showSuccess(
            newStatus
                ? '✅ Account approved! User can now go live.'
                : '❌ Account disapproved. User cannot go live.',
          );
        } else {
          _showError('Failed to update account approval status.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: const Color(0xFF04B104),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text(
            '❌ Unauthorized\nOnly admins can access this panel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF04B104),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.account_balance_wallet, size: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Add Coins'),
                ],
              ),
            ),
            Tab(
              icon: StreamBuilder<int>(
                stream: _supportChatService.getAdminUnreadCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.support_agent, size: 20),
                      if (unreadCount > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              child: const Text('Support Chats'),
            ),
            Tab(
              icon: const Icon(Icons.payment, size: 20),
              child: const Text('Payments'),
            ),
            Tab(
              icon: const Icon(Icons.group, size: 20),
              child: const Text('Team Messages'),
            ),
            Tab(
              icon: const Icon(Icons.star, size: 20),
              child: const Text('Host Applications'),
            ),
            Tab(
              icon: const Icon(Icons.people, size: 20),
              child: const Text('Users'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Add Coins Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search User Section
                _buildSearchSection(),

                const SizedBox(height: 24),

                // Selected User Info
                if (_selectedUser != null) ...[
                  _buildSelectedUserCard(),
                  const SizedBox(height: 24),
                ],

                // Add Coins Section
                if (_selectedUser != null) ...[
                  _buildAddCoinsSection(),
                  const SizedBox(height: 24),
                ],

                // Admin Actions History
                _buildAdminActionsSection(),
              ],
            ),
          ),
          // Support Chats Tab
          _buildSupportChatsTab(),
          _buildPaymentsTab(),
          // Team Messages Tab
          _buildTeamMessagesTab(),
          // Host Applications Tab
          _buildHostApplicationsTab(),
          // Users List Tab
          _buildUsersListTab(),
        ],
      ),
    );
  }

  /// Build search section
  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search User',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter phone number or user ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchUsers(value);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4))),
              ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(user['displayName'] ?? 'User'),
                      subtitle: Text(
                          '${user['countryCode']}${user['phoneNumber']}'),
                      trailing: TextButton(
                        onPressed: () => _selectUser(user),
                        child: const Text('Select'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build selected user card
  Widget _buildSelectedUserCard() {
    return Card(
      color: const Color(0xFF04B104).withValues(alpha:0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF04B104)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedUser!['displayName'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedUser = null;
                      _coinsController.clear();
                      _reasonController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Phone: ${_selectedUser!['countryCode']}${_selectedUser!['phoneNumber']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'User ID: ${_selectedUser!['userId']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const Divider(height: 24),
            // Account Approval Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (_selectedUser!['isActive'] ?? true)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_selectedUser!['isActive'] ?? true)
                      ? Colors.green
                      : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_selectedUser!['isActive'] ?? true)
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: (_selectedUser!['isActive'] ?? true)
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (_selectedUser!['isActive'] ?? true)
                        ? 'Account Approved'
                        : 'Account Not Approved',
                    style: TextStyle(
                      color: (_selectedUser!['isActive'] ?? true)
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Approve/Disapprove Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _toggleAccountApproval,
                icon: Icon(
                  (_selectedUser!['isActive'] ?? true)
                      ? Icons.block
                      : Icons.check_circle,
                  color: Colors.white,
                ),
                label: Text(
                  (_selectedUser!['isActive'] ?? true)
                      ? 'Disapprove Account'
                      : 'Approve Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedUser!['isActive'] ?? true)
                      ? Colors.red
                      : const Color(0xFF04B104),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCoinBalanceChip(
                  'U Coins',
                  _selectedUser!['uCoins'] ?? 0,
                  Colors.orange,
                ),
                _buildCoinBalanceChip(
                  'C Coins',
                  _selectedUser!['cCoins'] ?? 0,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinBalanceChip(String label, int balance, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance.toString(),
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build add coins section
  Widget _buildAddCoinsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Add U Coins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin can only add U Coins. C Coins are earned by hosts through gifts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Coins Amount
            TextField(
              controller: _coinsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount of U Coins to add',
                prefixIcon: const Icon(Icons.add_circle, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reason (Optional)
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addCoins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF04B104),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Coins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build admin actions history section
  Widget _buildAdminActionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAdminActions,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_adminActions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No admin actions yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _adminActions.length,
                itemBuilder: (context, index) {
                  final action = _adminActions[index];
                  final actionType = action['actionType'] ?? '';
                  final coinsAdded = action['coinsAdded'] ?? 0;
                  final timestamp = action['timestamp'];

                  // Only show U Coins additions (filter out C Coins)
                  if (actionType != 'add_u_coins') {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha:0.2),
                      child: const Icon(
                        Icons.add_circle,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Added $coinsAdded U Coins',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'User: ${action['userPhone'] ?? 'Unknown'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: Text(
                      timestamp != null
                          ? _formatTimestamp(timestamp)
                          : 'Just now',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${difference.inDays}d ago';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // ========== SUPPORT CHATS TAB ==========
  Widget _buildSupportChatsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supportChatService.getAllSupportChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF04B104),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load support chats. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No Support Chats',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Support chats from users will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
                    final unreadCount = ((chat['unreadCount'] as Map<String, dynamic>)['admin'] as int?) ?? 0;
            final hasUnread = unreadCount > 0;
            
            return _buildSupportChatCard(chat, hasUnread, unreadCount);
          },
        );
      },
    );
  }

  Widget _buildSupportChatCard(Map<String, dynamic> chat, bool hasUnread, int unreadCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFF04B104).withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread 
              ? const Color(0xFF04B104).withValues(alpha: 0.3)
              : Colors.grey[200]!,
          width: hasUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasUnread
                ? const Color(0xFF04B104).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => AdminSupportChatScreen(
              chatId: chat['chatId'],
              userId: chat['userId'],
              numericUserId: chat['numericUserId'] ?? '',
              userName: chat['userName'],
              userPhone: chat['userPhone'],
            ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF04B104),
                    child: Text(
                      (chat['userName'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF04B104),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // User Name and Status
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat['userName'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(chat['status']).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            chat['status']?.toUpperCase() ?? 'OPEN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(chat['status']),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Numeric User ID and Phone Number
                    Row(
                      children: [
                        // Numeric User ID (for easy admin identification)
                        if (chat['numericUserId'] != null && (chat['numericUserId'] as String).isNotEmpty) ...[
                          Icon(Icons.badge_outlined, size: 14, color: const Color(0xFF04B104)),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${chat['numericUserId']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF04B104),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 12, color: Colors.grey[300]),
                          const SizedBox(width: 12),
                        ],
                        // Phone Number
                        Expanded(
                          child: Text(
                            chat['userPhone'] ?? 'No phone',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Last Message
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage']?.isNotEmpty == true
                                ? chat['lastMessage']
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: chat['lastMessage']?.isNotEmpty == true
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(chat['lastMessageTime']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF04B104).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/chat.png',
                  width: 22,
                  height: 22,
                  color: const Color(0xFF04B104),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  // ========== PAYMENTS TAB ==========
  Widget _buildPaymentsTab() {
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: _withdrawalService.getAllWithdrawalRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No withdrawal requests yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildWithdrawalRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildWithdrawalRequestCard(WithdrawalRequestModel request) {
    Color statusColor;
    String statusText;
    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusText = 'Approved';
        break;
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Paid';
        break;
      default:
        statusColor = Colors.grey;
        statusText = request.status;
    }

    // Amount is now stored directly in INR (not C Coins)
    // Backward compatibility: old records were C Coins, model converts them to INR
    final inrAmount = request.amount; // Already in INR from model
    final cCoinsEquivalent = (inrAmount / 0.04).round(); // For display if needed

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request ID: ${request.id.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: ₹${inrAmount.toStringAsFixed(2)} (${cCoinsEquivalent} C Coins)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Method: ${request.withdrawalMethod}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${_formatDate(request.requestDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Payment Details
            if (request.paymentDetails.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Payment Details:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...request.paymentDetails.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            // Action Buttons
            Row(
              children: [
                if (request.status == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _approveWithdrawal(request.id),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (request.status == 'pending') const SizedBox(width: 8),
                if (request.status == 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _markAsPaidDialog(request),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (request.status == 'paid' && request.paymentProofURL != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewPaymentProof(request.paymentProofURL!),
                      icon: const Icon(Icons.image, size: 18),
                      label: const Text('View Proof'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveWithdrawal(String requestId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) {
        _showError('Admin not authenticated');
        return;
      }
      final success = await _withdrawalService.approveWithdrawalRequest(requestId, adminId);
      if (success) {
        _showSuccess('Withdrawal request approved!');
      } else {
        _showError('Failed to approve withdrawal request');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsPaidDialog(WithdrawalRequestModel request) async {
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark as Paid'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Upload payment proof screenshot:'),
                const SizedBox(height: 12),
                if (selectedImage != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(selectedImage!, fit: BoxFit.contain),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          selectedImage = File(image.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Image'),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: selectedImage == null
                      ? null
                      : () async {
                          Navigator.pop(context); // Close dialog
                          await _markAsPaid(request, selectedImage!);
                        },
                  child: const Text('Mark as Paid'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsPaid(WithdrawalRequestModel request, File paymentProof) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) {
        _showError('Admin not authenticated');
        return;
      }
      // Upload payment proof
      final proofURL = await _storageService.uploadPaymentProof(paymentProof, request.id);
      if (proofURL == null) {
        _showError('Failed to upload payment proof');
        return;
      }
      // Mark as paid
      final success = await _withdrawalService.markAsPaid(request.id, adminId, proofURL);
      if (success) {
        _showSuccess('Payment marked as paid!');
      } else {
        _showError('Failed to mark payment as paid');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewPaymentProof(String imageUrl) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ========== TEAM MESSAGES TAB ==========
  Widget _buildTeamMessagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Send Message Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.group, color: Color(0xFFFF1B7C)),
                      SizedBox(width: 8),
                      Text(
                        'Send Team Message',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF1B7C).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFFF1B7C), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This message will be sent to all users in the app. Users will see it in the "Chamakz Team" chat.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF1B7C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Message Input
                  TextField(
                    controller: _teamMessageController,
                    decoration: InputDecoration(
                      labelText: 'Message to all users',
                      hintText: 'Enter your message here...',
                      prefixIcon: const Icon(Icons.message, color: Color(0xFFFF1B7C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
                      ),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendTeamMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1B7C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Send to All Users',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Message History Section
          const Text(
            'Message History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List>(
            stream: _teamMessageService.getMessageHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages sent yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildTeamMessageHistoryItem(message);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMessageHistoryItem(dynamic message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.senderName ?? 'Chamakz Team',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF1B7C),
                  ),
                ),
                Text(
                  _formatTeamMessageTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.message ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (message.imageUrl != null && message.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendTeamMessage() async {
    final message = _teamMessageController.text.trim();
    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _teamMessageService.sendBroadcastMessage(
      message: message,
      senderName: 'Chamakz Team',
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      _showSuccess('✅ Message sent to all users!');
      _teamMessageController.clear();
    } else {
      _showError(result['message'] ?? 'Failed to send message');
    }
  }

  String _formatTeamMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  // ========== HOST APPLICATIONS TAB ==========
  Widget _buildHostApplicationsTab() {
    return StreamBuilder<List<HostApplicationModel>>(
      stream: _hostApplicationService.getAllApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No host applications yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Group applications by status
        final pendingApps = applications.where((app) => app.isPending).toList();
        final approvedApps = applications.where((app) => app.isApproved).toList();
        final rejectedApps = applications.where((app) => app.isRejected).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard('Pending', pendingApps.length, Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard('Approved', approvedApps.length, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard('Rejected', rejectedApps.length, Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pending Applications
              if (pendingApps.isNotEmpty) ...[
                const Text(
                  'Pending Applications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...pendingApps.map((app) => _buildApplicationCard(app)),
                const SizedBox(height: 24),
              ],

              // Approved Applications
              if (approvedApps.isNotEmpty) ...[
                const Text(
                  'Approved Applications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...approvedApps.map((app) => _buildApplicationCard(app)),
                const SizedBox(height: 24),
              ],

              // Rejected Applications
              if (rejectedApps.isNotEmpty) ...[
                const Text(
                  'Rejected Applications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...rejectedApps.map((app) => _buildApplicationCard(app)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(HostApplicationModel application) {
    final statusColor = application.isPending
        ? Colors.orange
        : application.isApproved
            ? Colors.green
            : Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Profile Photo
                if (application.profilePhotoUrl != null)
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(application.profilePhotoUrl!),
                  )
                else
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFFF1B7C).withOpacity(0.2),
                    child: const Icon(Icons.person, color: Color(0xFFFF1B7C)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${application.userDisplayId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    application.statusString.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow(Icons.phone, application.phoneNumber),
            if (application.email != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.email, application.email!),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.cake,
              'DOB: ${DateFormat('dd/MM/yyyy').format(application.dateOfBirth)}',
            ),
            const SizedBox(height: 12),

            // Bio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bio:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    application.bio,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Social Media Links
            if (application.socialMediaLinks != null &&
                application.socialMediaLinks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: application.socialMediaLinks!.entries.map((entry) {
                  IconData icon;
                  switch (entry.key.toLowerCase()) {
                    case 'instagram':
                      icon = Icons.camera_alt;
                      break;
                    case 'tiktok':
                      icon = Icons.music_note;
                      break;
                    case 'youtube':
                      icon = Icons.play_circle;
                      break;
                    default:
                      icon = Icons.link;
                  }
                  return Chip(
                    avatar: Icon(icon, size: 16),
                    label: Text(entry.value),
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Submission Date
            Text(
              'Submitted: ${_formatTimestamp(application.submittedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            // Rejection Reason
            if (application.isRejected && application.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${application.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons (only for pending)
            if (application.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectApplication(application),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveApplication(application),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveApplication(HostApplicationModel application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text('Are you sure you want to approve ${application.username}\'s application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      final success = await _hostApplicationService.approveApplication(
        application.applicationId,
        currentUser.uid,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (!success) {
          // Show detailed error message
          final currentUser = FirebaseAuth.instance.currentUser;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Permission Error'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Failed to approve application due to missing permissions.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To fix this:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Go to Firebase Console → Firestore Database'),
                  const Text('2. Create collection: "admins"'),
                  const Text('3. Create document with ID: (your User UID)'),
                  const Text('4. Add field: isAdmin = true (boolean)'),
                  const SizedBox(height: 12),
                  if (currentUser != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your User UID:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            currentUser.uid,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectApplication(HostApplicationModel application) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${application.username}\'s application?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      final success = await _hostApplicationService.rejectApplication(
        application.applicationId,
        currentUser.uid,
        reasonController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Application rejected'
                  : 'Failed to reject application',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  /// Build Users List Tab
  Widget _buildUsersListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('lastActive', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final userDoc = snapshot.data!.docs[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final lastActive = userData['lastActive'] as Timestamp?;
            
            return _buildUserListTile(userDoc.id, userData, lastActive);
          },
        );
      },
    );
  }

  /// Build User List Tile with Activity Display
  Widget _buildUserListTile(String userId, Map<String, dynamic> userData, Timestamp? lastActive) {
    final displayName = userData['displayName'] ?? 'No Name';
    final phoneNumber = userData['phoneNumber'] ?? 'N/A';
    final numericId = userData['numericUserId'] ?? 'N/A';
    final isActive = userData['isActive'] ?? false;
    
    // Get activity status
    final activityStatus = _getActivityStatus(lastActive);
    final activityDisplay = _getActivityDisplay(lastActive);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: userData['photoURL'] != null
                  ? NetworkImage(userData['photoURL'])
                  : null,
              child: userData['photoURL'] == null
                  ? Text(
                      numericId.toString().isNotEmpty
                          ? numericId.toString().substring(0, 1).toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            // Online status indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: activityStatus['color'],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $numericId | Phone: $phoneNumber'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  activityStatus['icon'],
                  size: 14,
                  color: activityStatus['color'],
                ),
                const SizedBox(width: 4),
                Text(
                  activityDisplay,
                  style: TextStyle(
                    color: activityStatus['color'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
        onTap: () {
          _selectUser(userData);
        },
      ),
    );
  }

  /// Get activity status (online, offline)
  Map<String, dynamic> _getActivityStatus(Timestamp? lastActive) {
    if (lastActive == null) {
      return {
        'status': 'offline',
        'color': Colors.grey,
        'icon': Icons.circle_outlined,
      };
    }
    
    final now = DateTime.now();
    final lastActiveDate = lastActive.toDate();
    final difference = now.difference(lastActiveDate);
    final minutes = difference.inMinutes;
    
    if (minutes < 5) {
      // Currently Active (green)
      return {
        'status': 'online',
        'color': Colors.green,
        'icon': Icons.circle,
      };
    } else {
      // Not Active (gray)
      return {
        'status': 'offline',
        'color': Colors.grey,
        'icon': Icons.circle_outlined,
      };
    }
  }

  /// Get human-readable activity display
  String _getActivityDisplay(Timestamp? lastActive) {
    if (lastActive == null) {
      return 'Never active';
    }
    
    final now = DateTime.now();
    final lastActiveDate = lastActive.toDate();
    final difference = now.difference(lastActiveDate);
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;
    
    if (minutes < 5) {
      return 'Currently Active';
    } else if (minutes < 60) {
      return '$minutes mins ago';
    } else if (hours < 24) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (days < 7) {
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return 'Last seen: ${DateFormat('MM/dd/yyyy').format(lastActiveDate)}';
    }
  }
}


