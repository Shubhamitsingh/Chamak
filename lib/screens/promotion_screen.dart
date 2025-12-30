import 'dart:io';
import 'dart:ui' as ui;
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),
                  const SizedBox(height: 24),
                  
                  // Attractive Text
                  _buildAttractiveText(),
                  const SizedBox(height: 36),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildImageCarousel() {
    // Always use local asset images
    final List<String> imagesToShow = _localPromoImages;

    return Column(
      children: [
        SizedBox(
          height: 400, // Increased height
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: imagesToShow.length,
            itemBuilder: (context, index) {
              final imagePath = imagesToShow[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 40), // Reduced width with more margin
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

  Widget _buildAttractiveText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(
            'Invite friends. Earn instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
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
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Share URL Button
        SizedBox(
          width: 140,
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
              minimumSize: const Size(140, 44),
            ),
            child: const Text(
              'Share URL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Save QR Code Button
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: _handleSaveQRCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1B7C), // Pink - matches app theme
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(140, 44),
            ),
            child: Text(
              AppLocalizations.of(context)!.saveQRCode,
              style: const TextStyle(
                fontSize: 14,
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

      // Share using native share dialog
      await Share.share(
        'Check out Chamakz! Download the app: $_appLink',
        subject: 'Chamakz App',
      );

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
      final canvas = Canvas(picRecorder);
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
