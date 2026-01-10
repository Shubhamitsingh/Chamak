import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import '../models/user_model.dart';
import '../services/search_service.dart';
import '../services/follow_service.dart';
import 'user_profile_view_screen.dart';

enum SearchFilter { all, userId, username, country }

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final FollowService _followService = FollowService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  SearchFilter _currentFilter = SearchFilter.all;
  String? _selectedCountry;
  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    // If country filter is selected and no query, search by country only
    if (_selectedCountry != null && query.trim().isEmpty) {
      await _searchByCountry(_selectedCountry!);
      return;
    }

    if (query.trim().isEmpty && _selectedCountry == null) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      List<UserModel> results = [];

      switch (_currentFilter) {
        case SearchFilter.userId:
          // Search only by numeric ID
          if (RegExp(r'^\d+$').hasMatch(query.trim())) {
            final user = await _searchService.searchUserByNumericId(query.trim());
            if (user != null) results = [user];
          }
          break;

        case SearchFilter.username:
          // Search only by name
          results = await _searchService.searchUsersByName(query.trim());
          break;

        case SearchFilter.country:
          // Search by country (from filter dropdown)
          if (_selectedCountry != null) {
            results = await _searchService.searchUsersByCountry(_selectedCountry!);
          }
          break;

        case SearchFilter.all:
          // Combined search: ID, Name, and optionally Country
          results = await _searchService.searchWithSuggestions(
            query.trim(),
            searchById: true,
            searchByName: true,
            searchByCountry: _selectedCountry != null,
            countryFilter: _selectedCountry,
          );
          break;
      }

      // Filter out current user from results
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final filteredResults = results.where((user) => user.uid != currentUserId).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('❌ Search error: $e');
    }
  }

  Future<void> _searchByCountry(String country) async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _searchService.searchUsersByCountry(country);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final filteredResults = results.where((user) => user.uid != currentUserId).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('❌ Country search error: $e');
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      favorite: ['IN', 'US', 'GB', 'CA', 'AU', 'AE', 'SG', 'MY', 'PK', 'BD'],
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        searchTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search Country',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF1B7C)),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFFFF1B7C).withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF1B7C)),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
        _searchByCountry(country.name);
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Users',
          style: TextStyle(
            color: Color(0xFFFF1B7C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Section - Filter Chips FIRST, then Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filter Chips (FIRST) - Equal spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildFilterChip('All', SearchFilter.all),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _buildFilterChip('User ID', SearchFilter.userId),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _buildFilterChip('Username', SearchFilter.username),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _buildFilterChip('Country', SearchFilter.country),
                    ),
                  ],
                ),

                // Country Filter Button (shown when country filter is selected)
                if (_currentFilter == SearchFilter.country) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showCountryPicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1B7C).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFFF1B7C).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCountry ?? 'Select Country',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedCountry != null ? Colors.black87 : Colors.grey[600],
                              fontWeight: _selectedCountry != null ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFFFF1B7C), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Search Text Field (AFTER filter chips) - Hide when Country filter is selected
                if (_currentFilter != SearchFilter.country)
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _performSearch(value);
                      }
                    });
                  },
                  onSubmitted: _performSearch,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _getSearchHint(),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF1B7C), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Search Hint / Loading / Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchFilter filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false, // Remove checkmark icon
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
          if (filter != SearchFilter.country) {
            _selectedCountry = null;
          }
          _hasSearched = false;
          _searchResults = [];
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
      selectedColor: const Color(0xFFFF1B7C).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFF1B7C) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? const Color(0xFFFF1B7C) : Colors.transparent,
        width: 1.5,
      ),
    );
  }

  Widget _buildContent() {
    // Show suggested users when no search
    if (!_hasSearched) {
      return _buildSuggestedUsers();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF1B7C),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildSuggestedUsers() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Search for users',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a search term to find users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    // Get user level (real-time from Firestore)
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.userId).snapshots(),
      builder: (context, snapshot) {
        int userLevel = user.userLevel;
        int hostLevel = user.hostLevel;
        bool isHost = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          userLevel = (userData?['userLevel'] ?? userData?['level'] ?? userLevel) as int;
          hostLevel = (userData?['hostLevel'] ?? userData?['level'] ?? hostLevel) as int;
          isHost = userData?['isHost'] ?? false;
        }

        final displayLevel = isHost ? hostLevel : userLevel;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(user: user),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Image
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFFF1B7C).withValues(alpha: 0.15),
                      backgroundImage: user.profileImage.isNotEmpty
                          ? NetworkImage(user.profileImage)
                          : null,
                      child: user.profileImage.isEmpty
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Color(0xFFFF1B7C),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // Online indicator (if needed - can be added later)
                  ],
                ),

                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with Level Badge and Host Badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF1B7C),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'Host',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF1B7C), Color(0xFFE91E63)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lv.$displayLevel',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // User ID and Followers
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            user.numericUserId.length >= 7
                                ? user.numericUserId.substring(0, 7)
                                : user.numericUserId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.people, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          StreamBuilder<DocumentSnapshot>(
                            stream: _firestore.collection('users').doc(user.userId).snapshots(),
                            builder: (context, followerSnapshot) {
                              int followerCount = user.followersCount;
                              if (followerSnapshot.hasData && followerSnapshot.data!.exists) {
                                final userData = followerSnapshot.data!.data() as Map<String, dynamic>?;
                                followerCount = userData?['followersCount'] as int? ?? user.followersCount;
                              }
                              return Text(
                                '$followerCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Country & City
                      if (user.country != null || user.city != null)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [user.city, user.country].where((e) => e != null && e.isNotEmpty).join(', '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Follow Button or Arrow
                if (_currentUserId != null && _currentUserId != user.userId)
                  FutureBuilder<bool>(
                    future: _followService.isFollowing(_currentUserId!, user.userId),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;
                      return _buildFollowButton(user, isFollowing);
                    },
                  )
                else
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(UserModel user, bool isFollowing) {
    return InkWell(
      onTap: () async {
        if (_currentUserId == null) return;
        
        try {
          if (isFollowing) {
            await _followService.unfollowUser(_currentUserId!, user.userId);
          } else {
            await _followService.followUser(_currentUserId!, user);
          }
          setState(() {}); // Refresh to update button state
        } catch (e) {
          debugPrint('❌ Follow/Unfollow error: $e');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey[200] : const Color(0xFFFF1B7C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isFollowing ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }


  String _getSearchHint() {
    switch (_currentFilter) {
      case SearchFilter.userId:
        return 'Enter 7-digit User ID';
      case SearchFilter.username:
        return 'Enter username to search';
      case SearchFilter.country:
        return 'Select country from dropdown';
      case SearchFilter.all:
        return 'Search by ID, Username, or Country';
    }
  }
}
