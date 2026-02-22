import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:country_picker/country_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import 'edit_name_screen.dart';
import 'edit_bio_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final String phoneNumber;
  
  const EditProfileScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  
  bool _isSaving = false;
  bool _isLoading = false; // Start with false to show content immediately
  bool _isGettingLocation = false;
  String? _locationStatus; // inline status message below Detect button
  
  // Profile picture
  File? _profileImage;
  String? _currentPhotoURL;
  bool _avatarRemoved = false; // user tapped Remove in avatar dialog
  final ImagePicker _picker = ImagePicker();
  
  // Cover photos (8 slots for grid)
  File? _coverImage1;
  File? _coverImage2;
  File? _coverImage3;
  File? _coverImage4;
  File? _coverImage5;
  File? _coverImage6;
  File? _coverImage7;
  File? _coverImage8;
  String? _currentCoverURL1;
  String? _currentCoverURL2;
  String? _currentCoverURL3;
  String? _currentCoverURL4;
  String? _currentCoverURL5;
  String? _currentCoverURL6;
  String? _currentCoverURL7;
  String? _currentCoverURL8;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  String _selectedGender = 'Male';
  Country _selectedCountry = Country.parse('IN'); // Default to India
  String _selectedLanguage = 'Hindi';
  final List<String> _languages = [
    'Hindi',
    'English',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Kannada',
    'Odia',
    'Malayalam',
    'Punjabi',
    'Assamese',
    'Maithili',
    'Sanskrit',
    'Konkani',
    'Nepali',
    'Sindhi',
    'Dogri',
    'Kashmiri',
    'Manipuri',
    'Santali',
    'Bodo',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Add listener to rebuild when city text changes
    _cityController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _databaseService.getCurrentUserData();
      if (userData != null && mounted) {
        setState(() {
          _nameController.text = userData.displayName ?? '';
          _ageController.text = userData.age?.toString() ?? '';
          _cityController.text = userData.city ?? '';
          _bioController.text = userData.bio ?? '';
          // Only accept Male or Female, default to Male if invalid
          _selectedGender = (userData.gender == 'Male' || userData.gender == 'Female') 
              ? userData.gender! 
              : 'Male';
          // Load country - try to find by name, default to India
          if (userData.country != null && userData.country!.isNotEmpty) {
            try {
              // Try to find country by name
              final countries = CountryService().getAll();
              final found = countries.where((c) => c.name == userData.country).toList();
              if (found.isNotEmpty) {
                _selectedCountry = found.first;
              }
            } catch (e) {
              debugPrint('Could not find country: ${userData.country}');
            }
          }
          _selectedLanguage = userData.language ?? 'Hindi';
          _currentPhotoURL = userData.photoURL;
          // Load cover photos from comma-separated string
          if (userData.coverURL != null && userData.coverURL!.isNotEmpty) {
            final coverURLs = userData.coverURL!.split(',');
            if (coverURLs.isNotEmpty) _currentCoverURL1 = coverURLs[0];
            if (coverURLs.length > 1) _currentCoverURL2 = coverURLs[1];
            if (coverURLs.length > 2) _currentCoverURL3 = coverURLs[2];
            if (coverURLs.length > 3) _currentCoverURL4 = coverURLs[3];
            if (coverURLs.length > 4) _currentCoverURL5 = coverURLs[4];
            if (coverURLs.length > 5) _currentCoverURL6 = coverURLs[5];
            if (coverURLs.length > 6) _currentCoverURL7 = coverURLs[6];
            if (coverURLs.length > 7) _currentCoverURL8 = coverURLs[7];
          }
          _isLoading = false;
        });
        
        // Auto-fill location if city is empty
        if (userData.city == null || userData.city!.isEmpty) {
          debugPrint('🌍 City is empty, auto-detecting location...');
          await _getCurrentLocation();
        } else {
          debugPrint('✅ City already set: ${userData.city}');
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        // Auto-fill location for new users
        debugPrint('🆕 New user, auto-detecting location...');
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () {
            try {
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Error navigating back: $e');
            }
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF1B7C), // solid pink
                ),
              )
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Photo section (reference UI)
                        _buildPhotoSection(),
                        const SizedBox(height: 16),
                        // Profile Details section (reference UI – list rows)
                        _buildProfileDetailsSection(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
        ),
    );
  }

  // ========== PHOTO SECTION (reference UI) ==========
  static const double _photoGap = 4.0;

  Widget _buildPhotoSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        // Row 1: 2*large + gap = maxW. Rows 2 & 3: 4*cell + 3*gap = maxW.
        final cell = ((maxW - 3 * _photoGap) / 4).clamp(52.0, 100.0);
        final large = cell * 2;
        final smallCell = (large - _photoGap) / 2; // 4 small in row1 right: 2*smallCell + gap = large
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.photo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Row 1: avatar + 4 small equal containers (2x2 in same space)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLargeAvatarBox(size: large),
                SizedBox(width: _photoGap),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildCoverSlot(1, smallCell),
                        SizedBox(width: _photoGap),
                        _buildCoverSlot(2, smallCell),
                      ],
                    ),
                    SizedBox(height: _photoGap),
                    Row(
                      children: [
                        _buildCoverSlot(3, smallCell),
                        SizedBox(width: _photoGap),
                        _buildCoverSlot(4, smallCell),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: _photoGap),
            // Row 2: cover slots 5–8
            Row(
              children: [
                _buildCoverSlot(5, cell),
                SizedBox(width: _photoGap),
                _buildCoverSlot(6, cell),
                SizedBox(width: _photoGap),
                _buildCoverSlot(7, cell),
                SizedBox(width: _photoGap),
                _buildCoverSlot(8, cell),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.clickToChangeOrDeletePhoto,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLargeAvatarBox({double size = 128}) {
    bool hasImage = _profileImage != null ||
        (_currentPhotoURL != null && _currentPhotoURL!.isNotEmpty);
    return GestureDetector(
      onTap: _changeProfilePicture,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          image: hasImage
              ? DecorationImage(
                  image: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : NetworkImage(_currentPhotoURL!) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (!hasImage)
              const Center(
                child: Icon(Icons.person, size: 48, color: Colors.white54),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Text(
                AppLocalizations.of(context)!.avatar,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _removeAvatarDirectly,
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// One of 8 cover slots: shows image or add placeholder; tap to change/delete.
  Widget _buildCoverSlot(int index, double size) {
    assert(index >= 1 && index <= 8);
    File? coverImage;
    String? currentCoverURL;
    switch (index) {
      case 1:
        coverImage = _coverImage1;
        currentCoverURL = _currentCoverURL1;
        break;
      case 2:
        coverImage = _coverImage2;
        currentCoverURL = _currentCoverURL2;
        break;
      case 3:
        coverImage = _coverImage3;
        currentCoverURL = _currentCoverURL3;
        break;
      case 4:
        coverImage = _coverImage4;
        currentCoverURL = _currentCoverURL4;
        break;
      case 5:
        coverImage = _coverImage5;
        currentCoverURL = _currentCoverURL5;
        break;
      case 6:
        coverImage = _coverImage6;
        currentCoverURL = _currentCoverURL6;
        break;
      case 7:
        coverImage = _coverImage7;
        currentCoverURL = _currentCoverURL7;
        break;
      case 8:
        coverImage = _coverImage8;
        currentCoverURL = _currentCoverURL8;
        break;
    }
    final bool hasImage = coverImage != null ||
        (currentCoverURL != null && currentCoverURL.isNotEmpty);
    return GestureDetector(
      onTap: () => _changeCoverPhoto(index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasImage ? Colors.grey[300] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          image: hasImage
              ? DecorationImage(
                  image: coverImage != null
                      ? FileImage(coverImage) as ImageProvider
                      : NetworkImage(currentCoverURL!) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeCoverDirectly(index),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Icon(Icons.add, color: Colors.grey, size: size * 0.375),
      ),
    );
  }

  // ========== PROFILE DETAILS SECTION (reference UI – list rows) ==========
  Widget _buildProfileDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.profileDetails,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.fullName,
          value: _nameController.text.isEmpty
              ? null
              : _nameController.text,
          onTap: () => _openEditNameScreen(),
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.gender,
          trailingWidget: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _selectedGender == 'Male'
                  ? Colors.blue
                  : const Color(0xFFE91E63),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedGender == 'Male' ? Icons.male : Icons.female,
              size: 14,
              color: Colors.white,
            ),
          ),
          onTap: _showGenderBottomSheet,
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.birthday,
          value: _ageController.text.isEmpty ? null : '${_ageController.text} ${AppLocalizations.of(context)!.years}',
          onTap: _showBirthdayDatePicker,
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.countryRegion,
          trailingWidget: Text(
            _selectedCountry.flagEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          onTap: _showCountryPicker,
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.bio,
          value: _bioController.text.isEmpty ? null : _bioController.text,
          onTap: () => _openEditBioScreen(),
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.socialLinks,
          value: null,
          onTap: () {},
        ),
        _buildDetailRow(
          label: AppLocalizations.of(context)!.panels,
          value: null,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? value,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 8),
              ] else if (value != null && value.isNotEmpty)
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else
                Text(
                  '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditNameScreen() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNameScreen(initialName: _nameController.text),
      ),
    );
    if (result != null && mounted) {
      setState(() => _nameController.text = result);
    }
  }

  Future<void> _showBirthdayDatePicker() async {
    final now = DateTime.now();
    final age = int.tryParse(_ageController.text);
    final initialDate = age != null && age >= 13 && age <= 100
        ? DateTime(now.year - age, now.month, now.day)
        : DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF1B7C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textTheme: Theme.of(context).textTheme.copyWith(
              titleSmall: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
              bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              labelSmall: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 380),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && mounted) {
      final years = now.year - picked.year;
      final adjust = (now.month < picked.month) || (now.month == picked.month && now.day < picked.day);
      final ageYears = adjust ? years - 1 : years;
      setState(() {
        _ageController.text = ageYears.clamp(0, 120).toString();
      });
    }
  }

  Future<void> _openEditBioScreen() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditBioScreen(initialBio: _bioController.text),
      ),
    );
    if (result != null && mounted) {
      setState(() => _bioController.text = result);
    }
  }

  // ========== COVER PHOTO FIELD (4 Images) ==========
  Widget _buildCoverPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.coverPhotos,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        // Horizontal scrollable row
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCoverPhotoBox(1),
              const SizedBox(width: 8),
              _buildCoverPhotoBox(2),
              const SizedBox(width: 8),
              _buildCoverPhotoBox(3),
              const SizedBox(width: 8),
              _buildCoverPhotoBox(4),
            ],
          ),
        ),
      ],
    );
  }

  // Build individual cover photo box
  Widget _buildCoverPhotoBox(int index) {
    File? coverImage;
    String? currentCoverURL;
    
    switch (index) {
      case 1:
        coverImage = _coverImage1;
        currentCoverURL = _currentCoverURL1;
        break;
      case 2:
        coverImage = _coverImage2;
        currentCoverURL = _currentCoverURL2;
        break;
      case 3:
        coverImage = _coverImage3;
        currentCoverURL = _currentCoverURL3;
        break;
      case 4:
        coverImage = _coverImage4;
        currentCoverURL = _currentCoverURL4;
        break;
      case 5:
        coverImage = _coverImage5;
        currentCoverURL = _currentCoverURL5;
        break;
      case 6:
        coverImage = _coverImage6;
        currentCoverURL = _currentCoverURL6;
        break;
      case 7:
        coverImage = _coverImage7;
        currentCoverURL = _currentCoverURL7;
        break;
      case 8:
        coverImage = _coverImage8;
        currentCoverURL = _currentCoverURL8;
        break;
    }

    bool hasImage = coverImage != null || (currentCoverURL != null && currentCoverURL.isNotEmpty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeCoverPhoto(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: hasImage ? Colors.grey[50] : const Color(0xFFFF1B7C).withValues(alpha:0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasImage
                  ? Colors.grey[300]!
                  : const Color(0xFFFF1B7C).withValues(alpha:0.4),
              width: 1.5,
            ),
            image: coverImage != null
                ? DecorationImage(
                    image: FileImage(coverImage),
                    fit: BoxFit.cover,
                  )
                : (currentCoverURL != null && currentCoverURL.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(currentCoverURL),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('Error loading cover image: $exception');
                        },
                      )
                    : null),
          ),
          child: !hasImage
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo $index',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF1B7C),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  // ========== PROFILE PICTURE SECTION ==========
  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          // Smaller circular avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!) as ImageProvider
                : (_currentPhotoURL != null && _currentPhotoURL!.isNotEmpty
                    ? NetworkImage(_currentPhotoURL!) as ImageProvider
                    : null),
            onBackgroundImageError: _currentPhotoURL != null && _currentPhotoURL!.isNotEmpty
                ? (exception, stackTrace) {
                    debugPrint('Error loading profile image: $exception');
                  }
                : null,
            child: _profileImage == null && (_currentPhotoURL == null || _currentPhotoURL!.isEmpty)
                ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                : null,
          ),
          // Smaller camera button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _changeProfilePicture,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DFF1B7C),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== EDIT FORM ==========
  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              
              // Name Field
              _buildModernTextField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.fullName,
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF6C63FF),
                hint: AppLocalizations.of(context)!.enterYourName,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.nameRequired;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // Age Field
              _buildModernTextField(
                controller: _ageController,
                label: AppLocalizations.of(context)!.age,
                icon: Icons.cake_outlined,
                iconColor: const Color(0xFFFF6B9D),
                hint: AppLocalizations.of(context)!.enterYourAge,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.ageRequired;
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return AppLocalizations.of(context)!.validAge;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // Language Selection (Popup)
              _buildLanguageField(),
              
              const SizedBox(height: 12),
              
              // Gender Selection (Popup)
              _buildGenderField(),
              
              const SizedBox(height: 12),
              
              // Country Selection (Popup with Flags)
              _buildCountryField(),
              
              const SizedBox(height: 12),
              
              // City Field - Auto-filled
              _buildCityField(),
              
              const SizedBox(height: 12),
              
              // Bio Field (without icon)
              _buildModernTextField(
                controller: _bioController,
                label: AppLocalizations.of(context)!.bio,
                hint: AppLocalizations.of(context)!.tellUsAboutYourself,
                maxLines: 6,
                maxLength: 150,
                validator: (value) {
                  if (value != null && value.length > 150) {
                    return AppLocalizations.of(context)!.bioMaxLength;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // Cover Photo Section
              _buildCoverPhotoField(),
          ],
        ),
      ),
    );
  }

  // ========== COUNTRY FIELD (Popup with Flags) ==========
  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.country,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  _selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry.name,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== COUNTRY PICKER (Popup with Flags) ==========
  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      favorite: ['IN', 'US', 'GB', 'CA', 'AU', 'AE', 'SG', 'MY', 'PK', 'BD'],
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        searchTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        inputDecoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.searchCountry,
          hintText: AppLocalizations.of(context)!.startTypingToSearch,
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF1B7C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFFF1B7C).withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  // ========== GENDER FIELD (Popup) ==========
  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.gender,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showGenderBottomSheet,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _selectedGender == 'Male' ? Icons.male : Icons.female,
                  color: _selectedGender == 'Male' 
                      ? const Color(0xFF2196F3) 
                      : const Color(0xFFE91E63),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedGender,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== GENDER BOTTOM SHEET (Popup) ==========
  void _showGenderBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(dialogContext).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.selectGender,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            // Horizontal Gender Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // Male Container - Blue
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = 'Male';
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: _selectedGender == 'Male' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.male,
                              color: Color(0xFF2196F3),
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.male,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Female Container - Pink
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = 'Female';
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE91E63),
                            width: _selectedGender == 'Female' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.female,
                              color: Color(0xFFE91E63),
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.female,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ========== LANGUAGE FIELD (Popup) ==========
  Widget _buildLanguageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mother Tongue',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showLanguageBottomSheet,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.language_outlined, color: Color(0xFFFF1B7C), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedLanguage,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== LANGUAGE BOTTOM SHEET (Popup) ==========
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selectedLanguage == lang;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFFF1B7C).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          lang.isNotEmpty ? lang.substring(0, 1) : '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected 
                                ? const Color(0xFFFF1B7C)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFF1B7C) : Colors.black87,
                      ),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Color(0xFFFF1B7C))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                      Navigator.pop(dialogContext);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ========== CITY FIELD - AUTO-FILLED WITH MANUAL REFRESH ==========
  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.city,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // Manual Location Refresh Button
            if (_isGettingLocation)
              Row(
                children: const [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF1B7C),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Detecting...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF1B7C),
                    ),
                  ),
                ],
              )
            else
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _getCurrentLocation,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF1B7C).withValues(alpha:0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 14,
                          color: Color(0xFFFF1B7C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.detect,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF1B7C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_locationStatus != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1B7C).withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF1B7C).withValues(alpha:0.3),
                ),
              ),
              child: Text(
                _locationStatus!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF1B7C),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextFormField(
          controller: _cityController,
          enabled: !_isGettingLocation,
          style: const TextStyle(fontSize: 13),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.cityRequired;
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.yourCityWillBeAutoDetected,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
            suffixIcon: _cityController.text.isNotEmpty
                ? const Icon(Icons.check_circle, size: 18, color: Color(0xFFFF1B7C))
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ========== SIMPLE TEXT FIELD ==========
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    Color? iconColor,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: iconColor, size: 18) : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // ========== SAVE BUTTON ==========
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: _isSaving ? Colors.grey[400] : const Color(0xFFFF1B7C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSaving ? null : _saveProfile,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.saveChanges,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== CHANGE COVER PHOTO DIALOG (simple form) ==========
  void _changeCoverPhoto(int index) {
    if (!mounted) return;
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickCoverImageFromGallery(index);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.chooseFromAlbum,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickCoverImageFromCamera(index);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.takePhoto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  if (_coverSlotHasImage(index)) ...[
                    Divider(height: 1, color: Colors.grey[300]),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (mounted) await _removeCoverDirectly(index);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          AppLocalizations.of(context)!.removePhoto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                  Divider(height: 1, color: Colors.grey[300]),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing cover photo dialog: $e');
    }
  }

  bool _coverSlotHasImage(int index) {
    switch (index) {
      case 1: return _coverImage1 != null || (_currentCoverURL1 != null && _currentCoverURL1!.isNotEmpty);
      case 2: return _coverImage2 != null || (_currentCoverURL2 != null && _currentCoverURL2!.isNotEmpty);
      case 3: return _coverImage3 != null || (_currentCoverURL3 != null && _currentCoverURL3!.isNotEmpty);
      case 4: return _coverImage4 != null || (_currentCoverURL4 != null && _currentCoverURL4!.isNotEmpty);
      case 5: return _coverImage5 != null || (_currentCoverURL5 != null && _currentCoverURL5!.isNotEmpty);
      case 6: return _coverImage6 != null || (_currentCoverURL6 != null && _currentCoverURL6!.isNotEmpty);
      case 7: return _coverImage7 != null || (_currentCoverURL7 != null && _currentCoverURL7!.isNotEmpty);
      case 8: return _coverImage8 != null || (_currentCoverURL8 != null && _currentCoverURL8!.isNotEmpty);
      default: return false;
    }
  }

  String? _getCoverURLForIndex(int index) {
    switch (index) {
      case 1: return _currentCoverURL1;
      case 2: return _currentCoverURL2;
      case 3: return _currentCoverURL3;
      case 4: return _currentCoverURL4;
      case 5: return _currentCoverURL5;
      case 6: return _currentCoverURL6;
      case 7: return _currentCoverURL7;
      case 8: return _currentCoverURL8;
      default: return null;
    }
  }

  void _clearCoverSlot(int index) {
    setState(() {
      switch (index) {
        case 1: _coverImage1 = null; _currentCoverURL1 = null; break;
        case 2: _coverImage2 = null; _currentCoverURL2 = null; break;
        case 3: _coverImage3 = null; _currentCoverURL3 = null; break;
        case 4: _coverImage4 = null; _currentCoverURL4 = null; break;
        case 5: _coverImage5 = null; _currentCoverURL5 = null; break;
        case 6: _coverImage6 = null; _currentCoverURL6 = null; break;
        case 7: _coverImage7 = null; _currentCoverURL7 = null; break;
        case 8: _coverImage8 = null; _currentCoverURL8 = null; break;
      }
    });
  }

  /// Removes avatar directly (no confirmation). Used by delete icon and by "Remove photo" in bottom sheet.
  Future<void> _removeAvatarDirectly() async {
    final oldURL = _currentPhotoURL;
    setState(() {
      _profileImage = null;
      _currentPhotoURL = null;
      _avatarRemoved = true;
    });
    if (oldURL != null && oldURL.isNotEmpty && oldURL.contains('firebasestorage')) {
      try {
        await _storageService.deleteProfilePicture(oldURL);
      } catch (e) {
        debugPrint('Could not delete old profile picture: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.photoRemoved} ${AppLocalizations.of(context)!.tapSaveToApply}'),
          backgroundColor: const Color(0xFFFF1B7C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Removes cover photo at [index] directly (no confirmation). Used by delete icon and by "Remove photo" in bottom sheet.
  Future<void> _removeCoverDirectly(int index) async {
    final oldURL = _getCoverURLForIndex(index);
    _clearCoverSlot(index);
    if (oldURL != null && oldURL.isNotEmpty && oldURL.contains('firebasestorage')) {
      try {
        await _storageService.deleteCoverPhoto(oldURL);
      } catch (e) {
        debugPrint('Could not delete cover photo: $e');
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.photoRemoved} ${AppLocalizations.of(context)!.tapSaveToApply}'),
          backgroundColor: const Color(0xFFFF1B7C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ========== CHANGE PROFILE PICTURE DIALOG (simple form) ==========
  void _changeProfilePicture() {
    if (!mounted) return;
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.chooseFromAlbum,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.takePhoto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  if (_profileImage != null || (_currentPhotoURL != null && _currentPhotoURL!.isNotEmpty)) ...[
                    Divider(height: 1, color: Colors.grey[300]),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (mounted) await _removeAvatarDirectly();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          AppLocalizations.of(context)!.removePhoto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                  Divider(height: 1, color: Colors.grey[300]),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  } catch (e) {
      debugPrint('Error showing profile picture dialog: $e');
    }
  }

  // ========== SAVE PROFILE ==========
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        String? photoURL = _currentPhotoURL;
        if (_avatarRemoved) {
          photoURL = '';
        } else if (_profileImage != null) {
          debugPrint('📤 Uploading new profile picture...');
          photoURL = await _storageService.updateProfilePicture(
            newImageFile: _profileImage!,
            oldPhotoURL: _currentPhotoURL,
          );
          debugPrint('✅ Profile picture uploaded: $photoURL');
        }

        // Upload cover photos
        List<String> coverURLs = [];
        
        if (_coverImage1 != null) {
          debugPrint('📤 Uploading cover photo 1...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage1!,
            oldCoverURL: _currentCoverURL1,
            index: 1,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL1 != null && _currentCoverURL1!.isNotEmpty) {
          coverURLs.add(_currentCoverURL1!);
        }
        
        if (_coverImage2 != null) {
          debugPrint('📤 Uploading cover photo 2...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage2!,
            oldCoverURL: _currentCoverURL2,
            index: 2,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL2 != null && _currentCoverURL2!.isNotEmpty) {
          coverURLs.add(_currentCoverURL2!);
        }
        
        if (_coverImage3 != null) {
          debugPrint('📤 Uploading cover photo 3...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage3!,
            oldCoverURL: _currentCoverURL3,
            index: 3,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL3 != null && _currentCoverURL3!.isNotEmpty) {
          coverURLs.add(_currentCoverURL3!);
        }
        
        if (_coverImage4 != null) {
          debugPrint('📤 Uploading cover photo 4...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage4!,
            oldCoverURL: _currentCoverURL4,
            index: 4,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL4 != null && _currentCoverURL4!.isNotEmpty) {
          coverURLs.add(_currentCoverURL4!);
        }
        if (_coverImage5 != null) {
          debugPrint('📤 Uploading cover photo 5...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage5!,
            oldCoverURL: _currentCoverURL5,
            index: 5,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL5 != null && _currentCoverURL5!.isNotEmpty) {
          coverURLs.add(_currentCoverURL5!);
        }
        if (_coverImage6 != null) {
          debugPrint('📤 Uploading cover photo 6...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage6!,
            oldCoverURL: _currentCoverURL6,
            index: 6,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL6 != null && _currentCoverURL6!.isNotEmpty) {
          coverURLs.add(_currentCoverURL6!);
        }
        if (_coverImage7 != null) {
          debugPrint('📤 Uploading cover photo 7...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage7!,
            oldCoverURL: _currentCoverURL7,
            index: 7,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL7 != null && _currentCoverURL7!.isNotEmpty) {
          coverURLs.add(_currentCoverURL7!);
        }
        if (_coverImage8 != null) {
          debugPrint('📤 Uploading cover photo 8...');
          final url = await _storageService.updateCoverPhoto(
            newImageFile: _coverImage8!,
            oldCoverURL: _currentCoverURL8,
            index: 8,
          );
          if (url != null) coverURLs.add(url);
        } else if (_currentCoverURL8 != null && _currentCoverURL8!.isNotEmpty) {
          coverURLs.add(_currentCoverURL8!);
        }
        
        // Combine all cover URLs into comma-separated string
        String? coverURL = coverURLs.isNotEmpty ? coverURLs.join(',') : '';

        // Update profile in Firestore
        debugPrint('💾 Saving profile to Firestore...');
        await _databaseService.updateUserProfile(
          displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          photoURL: photoURL,
          coverURL: coverURL,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          age: int.tryParse(_ageController.text),
          gender: _selectedGender,
          country: _selectedCountry.name,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          language: _selectedLanguage,
        );
        debugPrint('✅ Profile saved successfully!');
        if (mounted) setState(() {
          _avatarRemoved = false;
        });

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Profile updated successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              ),
              backgroundColor: const Color(0xFFFF1B7C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(18),
            duration: const Duration(seconds: 2),
          ),
        );
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          try {
            Navigator.pop(context);
          } catch (e) {
            debugPrint('Error navigating back: $e');
          }
        }
        }
      } catch (e) {
        debugPrint('❌ Error saving profile: $e');
        
        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error saving profile: ${e.toString()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(18),
              duration: const Duration(seconds: 3),
            ),
          );
          }
        }
      }
    }
  }

  // ========== GET CURRENT LOCATION ==========
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    if (mounted) {
      setState(() {
        _isGettingLocation = true;
        _locationStatus = null;
      });
    }

    debugPrint('📍 Starting location detection...');

    try {
      Map<String, String> location = await _locationService.getCurrentCityAndCountry();
      
      debugPrint('✅ Location detected: ${location['city']}, ${location['country']}');
      
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
        _cityController.text = location['city'] ?? '';
        
        // Update country if detected
        String countryName = location['country'] ?? '';
        if (countryName.isNotEmpty) {
          try {
            // Try to find country by name
            final countries = CountryService().getAll();
            final found = countries.where((c) => c.name == countryName).toList();
            if (found.isNotEmpty) {
              _selectedCountry = found.first;
            }
          } catch (e) {
            debugPrint('Could not find country: $countryName');
          }
        }
        
        _isGettingLocation = false;
        });
      }

      // Show inline success message just below the Detect button
      if (mounted && location['city']?.isNotEmpty == true) {
        if (mounted) {
          setState(() {
            _locationStatus = '📍 ${location['city']}, ${location['country']}';
          });
        }

        // Auto-hide the status after a short delay
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          if (mounted) {
            setState(() {
              _locationStatus = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Location error: $e');
      
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }

      String errorMessage = 'Location unavailable - Please enter manually';
      
      if (e.toString().contains('permission')) {
        errorMessage = 'Location permission needed';
      } else if (e.toString().contains('disabled') || e.toString().contains('services')) {
        errorMessage = 'Enable location services';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.location_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ========== IMAGE PICKER METHODS ==========
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        // Verify file exists before cropping
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Image file not found. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                margin: EdgeInsets.all(18),
              ),
            );
          }
          return;
        }
        
        // Open cropper directly (no separate screen)
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          // Square aspect ratio for profile pictures
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          // UI Settings for Android
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.white,
              toolbarWidgetColor: Colors.black87,
              statusBarColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Lock to square for profile
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
              backgroundColor: Colors.black,
              activeControlsWidgetColor: const Color(0xFFFF1B7C),
              dimmedLayerColor: Colors.black.withOpacity(0.8),
              cropFrameColor: Colors.white,
              cropFrameStrokeWidth: 2,
              cropGridColor: Colors.white.withOpacity(0.5),
              cropGridStrokeWidth: 1,
              showCropGrid: true,
              hideBottomControls: true, // Hide scale slider/controls
              cropStyle: CropStyle.rectangle,
            ),
            // UI Settings for iOS
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
              resetAspectRatioEnabled: false,
              rotateButtonsHidden: false,
              rotateClockwiseButtonHidden: false,
              hidesNavigationBar: false,
              showCancelConfirmationDialog: true,
              cancelButtonTitle: AppLocalizations.of(context)!.cancel,
              doneButtonTitle: AppLocalizations.of(context)!.done,
            ),
          ],
          // Compression settings
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90,
        );
        
        // Set cropped image if user completed cropping
        if (croppedFile != null && mounted) {
          setState(() {
            _profileImage = File(croppedFile.path);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Profile picture updated successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFFF1B7C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.all(18),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        // Verify file exists before cropping
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Image file not found. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                margin: EdgeInsets.all(18),
              ),
            );
          }
          return;
        }
        
        // Open cropper directly (no separate screen)
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          // Square aspect ratio for profile pictures
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          // UI Settings for Android
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.white,
              toolbarWidgetColor: Colors.black87,
              statusBarColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Lock to square for profile
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
              backgroundColor: Colors.black,
              activeControlsWidgetColor: const Color(0xFFFF1B7C),
              dimmedLayerColor: Colors.black.withOpacity(0.8),
              cropFrameColor: Colors.white,
              cropFrameStrokeWidth: 2,
              cropGridColor: Colors.white.withOpacity(0.5),
              cropGridStrokeWidth: 1,
              showCropGrid: true,
              hideBottomControls: true, // Hide scale slider/controls
              cropStyle: CropStyle.rectangle,
            ),
            // UI Settings for iOS
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
              resetAspectRatioEnabled: false,
              rotateButtonsHidden: false,
              rotateClockwiseButtonHidden: false,
              hidesNavigationBar: false,
              showCancelConfirmationDialog: true,
              cancelButtonTitle: AppLocalizations.of(context)!.cancel,
              doneButtonTitle: AppLocalizations.of(context)!.done,
            ),
          ],
          // Compression settings
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90,
        );
        
        // Set cropped image if user completed cropping
        if (croppedFile != null && mounted) {
          setState(() {
            _profileImage = File(croppedFile.path);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Profile picture updated successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFFF1B7C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.all(18),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }


  // ========== COVER IMAGE PICKER METHODS ==========
  Future<void> _pickCoverImageFromCamera(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          switch (index) {
            case 1:
              _coverImage1 = File(image.path);
              break;
            case 2:
              _coverImage2 = File(image.path);
              break;
            case 3:
              _coverImage3 = File(image.path);
              break;
            case 4:
              _coverImage4 = File(image.path);
              break;
            case 5:
              _coverImage5 = File(image.path);
              break;
            case 6:
              _coverImage6 = File(image.path);
              break;
            case 7:
              _coverImage7 = File(image.path);
              break;
            case 8:
              _coverImage8 = File(image.path);
              break;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cover photo $index updated successfully!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFFF1B7C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(18),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }

  Future<void> _pickCoverImageFromGallery(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          switch (index) {
            case 1:
              _coverImage1 = File(image.path);
              break;
            case 2:
              _coverImage2 = File(image.path);
              break;
            case 3:
              _coverImage3 = File(image.path);
              break;
            case 4:
              _coverImage4 = File(image.path);
              break;
            case 5:
              _coverImage5 = File(image.path);
              break;
            case 6:
              _coverImage6 = File(image.path);
              break;
            case 7:
              _coverImage7 = File(image.path);
              break;
            case 8:
              _coverImage8 = File(image.path);
              break;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cover photo $index updated successfully!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFFF1B7C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(18),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }
}
