import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';
import '../models/user_model.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileSettingsScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _user;
  bool _isLoading = true;
  List<String> _coverImages = [];
  late TabController _tabController;
  late PageController _coverImagePageController;
  int _currentCoverImageIndex = 0;

  static const double _cardOverlap = 40.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _coverImagePageController = PageController();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _coverImagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _databaseService.getCurrentUserData();
      if (mounted) {
        setState(() {
          _user = userData;
          if (userData?.coverURL != null && userData!.coverURL!.isNotEmpty) {
            _coverImages =
                userData.coverURL!.split(',').where((url) => url.trim().isNotEmpty).toList();
          } else {
            _coverImages = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(phoneNumber: widget.phoneNumber),
      ),
    ).then((_) {
      if (mounted) _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
            )
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noUserDataFound,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1B7C),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  clipBehavior: Clip.none,
                  slivers: [
                    _buildHeaderAndCardSliver(),
                    _buildContentArea(),
                  ],
                ),
    );
  }

  /// Single sliver: cover image + white card. Card rounded top never clipped.
  Widget _buildHeaderAndCardSliver() {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.40;
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: headerHeight + _cardOverlap,
            child: _buildCoverSection(),
          ),
          Transform.translate(
            offset: const Offset(0, -_cardOverlap),
            child: _buildProfileInfoCardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_coverImages.isNotEmpty)
          PageView.builder(
            controller: _coverImagePageController,
            onPageChanged: (index) =>
                setState(() => _currentCoverImageIndex = index),
            itemCount: _coverImages.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: _coverImages[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF1B7C)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 50),
              ),
            ),
          )
        else
          Container(
            color: Colors.grey[300],
            child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 50)),
          ),
        if (_coverImages.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _coverImages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCoverImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.black87, size: 18),
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToEditProfile,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.black87, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCardContent() {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _user!.displayName ??
                          AppLocalizations.of(context)!.setYourName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_user!.gender != null && _user!.gender!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _user!.gender!.toLowerCase() == 'male'
                            ? Colors.blue
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _user!.gender!.toLowerCase() == 'male'
                            ? Icons.male
                            : Icons.female,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lv.${_user!.userLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'ID ${IdGeneratorService.getDisplayId(_user!.numericUserId)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final displayId =
                          IdGeneratorService.getDisplayId(_user!.numericUserId);
                      Clipboard.setData(ClipboardData(text: displayId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(AppLocalizations.of(context)!.idCopiedMessage(displayId)),
                            ],
                          ),
                          backgroundColor: const Color(0xFFFF1B7C),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Icon(Icons.copy, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_user!.followersCount} ${AppLocalizations.of(context)!.followers}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  Text(
                    '${_user!.followingCount} ${AppLocalizations.of(context)!.following}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _user!.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1B7C),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 20),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.post,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF1B7C),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFFFF1B7C),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.post),
                  Tab(text: AppLocalizations.of(context)!.sub),
                  Tab(text: AppLocalizations.of(context)!.about),
                  Tab(text: AppLocalizations.of(context)!.fans),
                ],
              ),
            ],
          ),
    );
  }

  /// Same single scroll: cover + card + tab content scroll together.
  Widget _buildContentArea() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -_cardOverlap),
        child: Container(
          color: Colors.white,
          constraints: BoxConstraints(minHeight: screenHeight),
          child: _getCurrentTabContent(),
        ),
      ),
    );
  }

  Widget _getCurrentTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildPostTab();
      case 1:
        return _buildSubTab();
      case 2:
        return _buildAboutTab();
      case 3:
        return _buildFansTab();
      default:
        return _buildPostTab();
    }
  }

  /// Post tab: empty state or post list – all kept inside this same white container.
  Widget _buildPostTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_on, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noPostsYet,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noSubscriptionsYet,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutItem(Icons.info_outline, AppLocalizations.of(context)!.about, _user!.bio ?? ''),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
      IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFansTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noFansYet,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    