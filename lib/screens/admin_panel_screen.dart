import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

/// Admin Panel Screen for managing user coins
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _coinsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _adminActions = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadAdminActions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _coinsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Check if current user is admin
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isCheckingAdmin = true;
    });

    final isAdmin = await _adminService.isAdmin();

    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });

    if (!isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Unauthorized: Only admins can access this panel'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: const Color(0xFF04B104),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
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
        title: const Text('Admin Panel - Add U Coins'),
        backgroundColor: const Color(0xFF04B104),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                child: Center(child: CircularProgressIndicator()),
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
}

