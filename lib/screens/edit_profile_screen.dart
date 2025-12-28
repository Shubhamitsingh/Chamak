import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:country_picker/country_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';

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
  bool _isLoading = true;
  bool _isGettingLocation = false;
  String? _locationStatus; // inline status message below Detect button
  
  // Profile picture
  File? _profileImage;
  String? _currentPhotoURL;
  final ImagePicker _picker = ImagePicker();
  
  // Cover photos (up to 4 images)
  File? _coverImage1;
  File? _coverImage2;
  File? _coverImage3;
  File? _coverImage4;
  String? _currentCoverURL1;
  String? _currentCoverURL2;
  String? _currentCoverURL3;
  String? _currentCoverURL4;
  
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
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF1B7C), // solid pink
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    
                    // Profile Picture Section
                    _buildProfilePictureSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Edit Form
                    _buildEditForm(),
                    
                    const SizedBox(height: 16),
                    
                    // Save Button
                    _buildSaveButton(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  // ========== COVER PHOTO FIELD (4 Images) ==========
  Widget _buildCoverPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Photos',
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
          labelText: 'Search Country',
          hintText: 'Start typing to search',
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
            const Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.male,
                              color: Color(0xFF2196F3),
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Male',
                              style: TextStyle(
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
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.female,
                              color: Color(0xFFE91E63),
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Female',
                              style: TextStyle(
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select Mother Tongue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                            fontWeight: FontWeight.bold,
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
            gradient: _isSaving
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: _isSaving ? Colors.grey[400] : null,
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
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  // ========== CHANGE COVER PHOTO DIALOG ==========
  void _changeCoverPhoto(int index) {
    if (!mounted) return;
    try {
      showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Change Cover Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Camera Option
                InkWell(
                  onTap: () {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error closing dialog: $e');
                    }
                    _pickCoverImageFromCamera(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withValues(alpha:0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1B7C).withValues(alpha:0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.openCamera,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.takeANewPhoto,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Gallery Option
                InkWell(
                  onTap: () {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error closing dialog: $e');
                    }
                    _pickCoverImageFromGallery(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withValues(alpha:0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1B7C).withValues(alpha:0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.openGallery,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.chooseFromGallery,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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

  // ========== CHANGE PROFILE PICTURE DIALOG ==========
  void _changeProfilePicture() {
    if (!mounted) return;
    try {
      showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Camera Option
                InkWell(
                  onTap: () async {
                    try {
                      Navigator.pop(context);
                      // Small delay to ensure bottom sheet is fully closed
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        _pickImageFromCamera();
                      }
                    } catch (e) {
                      debugPrint('Error closing dialog: $e');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withValues(alpha:0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1B7C).withValues(alpha:0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.openCamera,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.takeANewPhoto,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Gallery Option
                InkWell(
                  onTap: () async {
                    try {
                      Navigator.pop(context);
                      // Small delay to ensure bottom sheet is fully closed
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        _pickImageFromGallery();
                      }
                    } catch (e) {
                      debugPrint('Error closing dialog: $e');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1B7C).withValues(alpha:0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1B7C).withValues(alpha:0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.openGallery,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.chooseFromGallery,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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

        // Upload new profile picture if selected
        if (_profileImage != null) {
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
        
        // Combine all cover URLs into comma-separated string
        String? coverURL = coverURLs.isNotEmpty ? coverURLs.join(',') : null;

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
              toolbarColor: const Color(0xFFFF1B7C),
              toolbarWidgetColor: Colors.white,
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
              statusBarColor: const Color(0xFFFF1B7C),
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
              cancelButtonTitle: 'Cancel',
              doneButtonTitle: 'Done',
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
              toolbarColor: const Color(0xFFFF1B7C),
              toolbarWidgetColor: Colors.white,
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
              statusBarColor: const Color(0xFFFF1B7C),
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
              cancelButtonTitle: 'Cancel',
              doneButtonTitle: 'Done',
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
