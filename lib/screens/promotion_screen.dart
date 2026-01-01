import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../services/promotion_service.dart';
import '../services/promotion_reward_service.dart';
import '../models/promotion_model.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  final PromotionService _promotionService = PromotionService();
  final PromotionRewardService _rewardService = PromotionRewardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _appLink;
  String? _qrCodeData;
  List<PromotionModel> _promotions = [];
  
  // Local asset images for promotion carousel
  final List<String> _localPromoImages = [
    'assets/images/promoimage.jpg',
    'assets/images/promoimage1.jpg',
    'assets/images/promobaner.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load app link and QR code data
      _appLink = await _promotionService.generateAppLink(userId);
      _qrCodeData = await _promotionService.generateQRCodeData(userId);

      // Load user's promotional images
      _promotionService.getUserPromotions(userId).listen((promotions) {
        if (mounted) {
          setState(() {
            _promotions = promotions;
            if (_promotions.isEmpty) {
              _loadDefaultPromotions();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading promotion data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDefaultPromotions() async {
    try {
      final defaults = await _promotionService.getDefaultPromotions();
      if (mounted) {
        setState(() {
          _promotions = defaults;
        });
      }
    } catch (e) {
      debugPrint('Error loading default promotions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
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
          'Promotion',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // 4% of screen width
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Carousel
                  _buildImageCarousel(screenHeight, screenWidth),
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  
                  // Attractive Text
                  _buildAttractiveText(screenWidth),
                  SizedBox(height: screenHeight * 0.04), // 4% of screen height
                  
                  // Action Buttons
                  _buildActionButtons(screenWidth),
                  SizedBox(height: screenHeight * 0.025), // 2.5% of screen height
                ],
              ),
            ),
    );
  }

  Widget _buildImageCarousel(double screenHeight, double screenWidth) {
    // Always use local asset images
    final List<String> imagesToShow = _localPromoImages;
    
    // Responsive carousel height: 40-50% of screen height, min 300, max 500
    final carouselHeight = (screenHeight * 0.45).clamp(300.0, 500.0);
    
    // Responsive horizontal margin: 8-10% of screen width, min 24, max 60 (further reduced container width)
    final horizontalMargin = (screenWidth * 0.09).clamp(24.0, 60.0);

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: imagesToShow.length,
            itemBuilder: (context, index) {
              final imagePath = imagesToShow[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imagesToShow.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFFFF1B7C)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttractiveText(double screenWidth) {
    // Responsive font sizes based on screen width
    final titleFontSize = (screenWidth * 0.045).clamp(16.0, 20.0);
    final subtitleFontSize = (screenWidth * 0.033).clamp(12.0, 14.0);
    
    // Responsive padding: 4-6% of screen width
    final horizontalPadding = (screenWidth * 0.05).clamp(16.0, 24.0);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        children: [
          Text(
            'Invite friends. Earn instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your referral link and get rewarded for every friend who joins!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    // Responsive button width: 30-35% of screen width, min 120, max 160
    final buttonWidth = (screenWidth * 0.32).clamp(120.0, 160.0);
    
    // Responsive font size
    final buttonFontSize = (screenWidth * 0.035).clamp(13.0, 15.0);
    
    // Responsive button height
    final buttonHeight = (screenWidth * 0.11).clamp(44.0, 50.0);
    
    // Responsive spacing between buttons
    final buttonSpacing = (screenWidth * 0.03).clamp(8.0, 16.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Share URL Button
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: _handleShareURL,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(buttonWidth, buttonHeight),
            ),
            child: Text(
              'Share URL',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: buttonSpacing),
        // Save QR Code Button
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: _handleSaveQRCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1B7C), // Pink - matches app theme
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(buttonWidth, buttonHeight),
            ),
            child: Text(
              AppLocalizations.of(context)!.saveQRCode,
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleShareURL() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _appLink == null) {
      _showError('Unable to generate share link');
      return;
    }

    try {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: _appLink!));

      // Get the first promo image and add watermark
      final promoImagePath = _localPromoImages[0];
      final watermarkedImage = await _addWatermarkToAssetImage(promoImagePath);
      
      if (watermarkedImage != null) {
        // Save watermarked image to temp file
        final directory = await getApplicationDocumentsDirectory();
        final tempFilePath = '${directory.path}/share_promo_${DateTime.now().millisecondsSinceEpoch}.png';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(watermarkedImage);

        // Share image along with text
        await Share.shareXFiles(
          [XFile(tempFilePath)],
          text: 'Check out Chamakz! Download the app: $_appLink',
          subject: 'Chamakz App',
        );
      } else {
        // Fallback to text-only share if watermarking fails
        await Share.share(
          'Check out Chamakz! Download the app: $_appLink',
          subject: 'Chamakz App',
        );
      }

      // Calculate and award reward
      final reward = await _rewardService.calculateReward(
        userId: userId,
        shareType: 'url',
      );
      await _rewardService.awardReward(
        userId: userId,
        rewardAmount: reward,
        shareType: 'url',
        appLink: _appLink!,
      );

      if (mounted) {
        _showSuccess('App link copied and shared! You earned $reward coins!');
      }
    } catch (e) {
      debugPrint('Error sharing URL: $e');
      if (mounted) {
        _showError('Failed to share URL');
      }
    }
  }

  Future<void> _handleSaveQRCode() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _qrCodeData == null) {
      _showError('Unable to generate QR code');
      return;
    }

    try {
      // Generate QR code image
      final qrImage = await _generateQRCodeImage(_qrCodeData!);
      if (qrImage == null) {
        throw Exception('Failed to generate QR code image');
      }

      // Save to device gallery
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(qrImage);

      // Share to save (this will allow user to save to gallery)
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Chamakz QR Code',
      );

      // Calculate and award reward
      final reward = await _rewardService.calculateReward(
        userId: userId,
        shareType: 'qr_code',
      );
      await _rewardService.awardReward(
        userId: userId,
        rewardAmount: reward,
        shareType: 'qr_code',
        appLink: _qrCodeData!,
      );

      if (mounted) {
        _showSuccess('${AppLocalizations.of(context)!.qrCodeSaved} You earned $reward coins!');
      }
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      if (mounted) {
        _showError('Failed to save QR code');
      }
    }
  }

  /// Add watermark (app logo) to an asset image
  Future<Uint8List?> _addWatermarkToAssetImage(String assetPath) async {
    try {
      // Load the base image from assets
      final ByteData baseImageData = await rootBundle.load(assetPath);
      final Uint8List baseImageBytes = baseImageData.buffer.asUint8List();
      final ui.Codec baseCodec = await ui.instantiateImageCodec(baseImageBytes);
      final ui.FrameInfo baseFrameInfo = await baseCodec.getNextFrame();
      final ui.Image baseImage = baseFrameInfo.image;

      // Load the watermark logo from assets
      final ByteData logoData = await rootBundle.load('assets/images/logopink.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final ui.Codec logoCodec = await ui.instantiateImageCodec(logoBytes);
      final ui.FrameInfo logoFrameInfo = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrameInfo.image;

      // Calculate watermark size (10% of image width, maintain aspect ratio)
      final double watermarkWidth = baseImage.width * 0.15;
      final double watermarkHeight = (logoImage.height / logoImage.width) * watermarkWidth;

      // Create a canvas to draw the watermarked image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Draw the base image
      canvas.drawImage(baseImage, Offset.zero, ui.Paint());
      
      // Draw watermark in top-left corner with padding
      const double padding = 12.0;
      final ui.Rect watermarkRect = ui.Rect.fromLTWH(
        padding,
        padding,
        watermarkWidth,
        watermarkHeight,
      );
      
      // Draw watermark with slight transparency for better visibility
      canvas.drawImageRect(
        logoImage,
        ui.Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        watermarkRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image watermarkedImage = await picture.toImage(
        baseImage.width,
        baseImage.height,
      );

      // Convert to bytes
      final ByteData? byteData = await watermarkedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Dispose images
      baseImage.dispose();
      logoImage.dispose();
      watermarkedImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error adding watermark to asset image: $e');
      return null;
    }
  }

  Future<Uint8List?> _generateQRCodeImage(String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('Invalid QR code data');
      }

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(picRecorder);
      const size = 500.0;
      painter.paint(canvas, const Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating QR code image: $e');
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
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
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF1B7C), // Pink - matches app theme
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
