import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../services/promotion_service.dart';
import '../services/promotional_frame_service.dart';
import '../services/promotion_reward_service.dart';
import '../models/promotion_model.dart';
import 'image_crop_screen.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  final PromotionService _promotionService = PromotionService();
  final PromotionalFrameService _frameService = PromotionalFrameService();
  final PromotionRewardService _rewardService = PromotionRewardService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _appLink;
  String? _qrCodeData;
  int _gameRate = 70;
  int _giftRate = 70;
  List<PromotionModel> _promotions = [];

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

      // Load earning rates
      final rates = await _rewardService.getDownlineRates(userId);
      if (mounted) {
        setState(() {
          _gameRate = rates['gameRate'] ?? 70;
          _giftRate = rates['giftRate'] ?? 70;
        });
      }
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),
                  const SizedBox(height: 20),
                  
                  // Custom Share Template Button
                  _buildCustomShareButton(),
                  const SizedBox(height: 20),
                  
                  // Earning Rate Information
                  _buildEarningRateSection(),
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildImageCarousel() {
    if (_promotions.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No promotional images available'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promotion = _promotions[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                  child: Image.network(
                    promotion.imageUrl,
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
            _promotions.length,
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

  Widget _buildCustomShareButton() {
    return OutlinedButton.icon(
      onPressed: _handleCustomShareTemplate,
      icon: const Icon(Icons.add_photo_alternate, size: 20),
      label: const Text('Custom share template'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey[400]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEarningRateSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Downline Rate: Game $_gameRate% Gift $_giftRate%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (_gameRate == 0 || _giftRate == 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'When rate is 0%, the downline have no earnings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Share URL Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleShareURL,
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share URL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Save QR Code Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleSaveQRCode,
            icon: const Icon(Icons.qr_code, size: 20),
            label: Text(AppLocalizations.of(context)!.saveQRCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF04B104),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCustomShareTemplate() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showError('Please login to continue');
      return;
    }

    // Show image source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      // Navigate to crop screen
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropScreen(
            imageFile: File(pickedFile.path),
            isProfilePicture: false,
          ),
        ),
      );

      if (croppedFile == null) {
        return;
      }
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = true);

      // Generate QR code data
      final qrData = await _promotionService.generateQRCodeData(userId);
      final appLink = await _promotionService.generateAppLink(userId);

      // Apply promotional frame
      final framedImage = await _frameService.applyPromotionalFrame(
        imageFile: croppedFile,
        qrCodeData: qrData,
      );

      // Upload to Firebase Storage
      final imageUrl = await _promotionService.uploadPromotionalImage(
        framedImage.path,
        userId,
      );

      // Save promotion to Firestore
      final promotion = PromotionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        imageUrl: imageUrl,
        appLink: appLink,
        referralCode: await _promotionService.getUserReferralCode(userId),
        createdAt: DateTime.now(),
        isCustom: true,
      );

      await _promotionService.savePromotion(promotion);

      if (mounted) {
        _showSuccess('Image uploaded successfully!');
        _loadData();
      }
    } catch (e) {
      debugPrint('Error creating custom template: $e');
      if (mounted) {
        _showError('Failed to create template: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
