import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Screen for manually cropping images
/// User must manually adjust the crop area before confirming
class ImageCropScreen extends StatefulWidget {
  final File imageFile;
  final bool isProfilePicture; // If true, uses square (1:1) aspect ratio
  
  const ImageCropScreen({
    super.key,
    required this.imageFile,
    this.isProfilePicture = true,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  bool _isCropping = false;
  bool _isCropInterfaceOpen = false;
  bool _shouldShowAppBar = true; // Control AppBar visibility

  @override
  void initState() {
    super.initState();
    // Automatically open crop interface immediately when screen loads
    // No preview page - go straight to native cropper
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _shouldShowAppBar = false; // Hide AppBar before opening crop interface
          });
          if (mounted) {
            _cropImage();
          }
        }
      });
    });
  }

  Future<void> _cropImage() async {
    if (_isCropping) return;
    
    // Validate file exists
    if (!await widget.imageFile.exists()) {
      debugPrint('Error: Image file does not exist at path: ${widget.imageFile.path}');
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
        Navigator.of(context).pop(null);
      }
      return;
    }
    
    setState(() {
      _isCropping = true;
      _isCropInterfaceOpen = true;
    });

    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imageFile.path,
        // Square aspect ratio for profile pictures, free for others
        aspectRatio: widget.isProfilePicture 
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : null,
        // UI Settings for Android
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF9C27B0),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: widget.isProfilePicture 
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.original,
            lockAspectRatio: widget.isProfilePicture, // Lock to square for profile
            aspectRatioPresets: widget.isProfilePicture
                ? [
                    CropAspectRatioPreset.square,
                  ]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF9C27B0),
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            cropFrameColor: Colors.white,
            cropFrameStrokeWidth: 2,
            cropGridColor: Colors.white.withOpacity(0.5),
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            hideBottomControls: true, // Hide scale slider/controls
            // Manual crop controls - user must adjust themselves
            cropStyle: CropStyle.rectangle,
            // Add activity configuration to prevent crashes
            statusBarColor: const Color(0xFF9C27B0),
          ),
          // UI Settings for iOS
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: widget.isProfilePicture,
            aspectRatioPresets: widget.isProfilePicture
                ? [
                    CropAspectRatioPreset.square,
                  ]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            resetAspectRatioEnabled: !widget.isProfilePicture,
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

      if (!mounted) return;

      if (croppedFile != null) {
        // Return cropped image to previous screen
        Navigator.of(context).pop(File(croppedFile.path));
      } else {
        // User cancelled cropping
        Navigator.of(context).pop(null);
      }
    } catch (e, stackTrace) {
      debugPrint('Error cropping image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      
      // Show error and return null
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cropping image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(18),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Wait a bit before popping to show error message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCropping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if AppBar should be visible
    final bool showAppBar = _shouldShowAppBar && !_isCropInterfaceOpen;
    
    return Scaffold(
      backgroundColor: Colors.black,
      // Hide AppBar when crop interface is open
      appBar: showAppBar ? _buildAppBar() : null,
      body: SafeArea(
        child: _isCropping && !_isCropInterfaceOpen
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF9C27B0),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Opening crop interface...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(), // Hide UI when crop interface is open
      ),
      bottomNavigationBar: null, // No bottom bar - native cropper handles it
    );
  }

  // ========== PROFESSIONAL TOP APP BAR ==========
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120), // Increased height further to prevent icon clipping
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C27B0),
              Color(0xFF7B1FA2),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
            child: Row(
              children: [
                // Close icon on left
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pop(null);
                    }
                  },
                  tooltip: 'Cancel',
                  padding: const EdgeInsets.all(12),
                ),
                // Spacer to push text to center
                const Expanded(
                  child: Center(
                    child: Text(
                      'Crop Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Invisible spacer on right to balance the left icon
                SizedBox(
                  width: 48, // Same width as IconButton (28 icon + 12 padding * 2)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

