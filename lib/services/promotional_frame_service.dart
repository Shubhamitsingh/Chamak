import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class PromotionalFrameService {

  /// Apply promotional frame to image
  /// This adds app logo (top-left) and QR code (bottom-right) to the image
  Future<File> applyPromotionalFrame({
    required File imageFile,
    required String qrCodeData,
    String? logoPath,
  }) async {
    try {
      // Load the original image
      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // Note: User level can be used for frame style selection in future
      // Currently using simple frame with logo and QR code

      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw the original image
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        paint,
      );

      // Calculate overlay sizes (proportional to image size)
      final imageWidth = originalImage.width.toDouble();
      final imageHeight = originalImage.height.toDouble();
      final logoSize = imageWidth * 0.15; // 15% of image width
      final qrCodeSize = imageWidth * 0.20; // 20% of image width

      // Position: top-left with padding
      final logoX = imageWidth * 0.05; // 5% from left
      final logoY = imageHeight * 0.05; // 5% from top

      // Draw app logo (top-left)
      if (logoPath != null) {
        try {
          final logoBytes = await rootBundle.load(logoPath);
          final logoCodec = await ui.instantiateImageCodec(logoBytes.buffer.asUint8List());
          final logoFrame = await logoCodec.getNextFrame();
          final logoImage = logoFrame.image;

          // Draw logo with rounded background
          final logoRect = Rect.fromLTWH(logoX, logoY, logoSize, logoSize);
          final roundedRect = RRect.fromRectAndRadius(logoRect, const Radius.circular(12));
          
          // White background for logo
          canvas.drawRRect(
            roundedRect,
            Paint()..color = Colors.white.withOpacity(0.9),
          );

          // Draw logo image
          canvas.drawImageRect(
            logoImage,
            Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
            logoRect,
            paint,
          );
        } catch (e) {
          debugPrint('Error loading logo: $e');
          // Draw text logo as fallback
          _drawTextLogo(canvas, logoX, logoY, logoSize);
        }
      } else {
        // Draw text logo as fallback
        _drawTextLogo(canvas, logoX, logoY, logoSize);
      }

      // Generate and draw QR code (bottom-right)
      final qrCodeImage = await _generateQRCodeImage(qrCodeData, qrCodeSize.toInt());
      if (qrCodeImage != null) {
        final qrX = imageWidth - qrCodeSize - (imageWidth * 0.05); // 5% from right
        final qrY = imageHeight - qrCodeSize - (imageHeight * 0.05); // 5% from top

        // White background for QR code
        final qrRect = Rect.fromLTWH(qrX, qrY, qrCodeSize, qrCodeSize);
        final qrRoundedRect = RRect.fromRectAndRadius(qrRect, const Radius.circular(12));
        
        canvas.drawRRect(
          qrRoundedRect,
          Paint()..color = Colors.white.withOpacity(0.95),
        );

        // Draw QR code
        canvas.drawImageRect(
          qrCodeImage,
          Rect.fromLTWH(0, 0, qrCodeImage.width.toDouble(), qrCodeImage.height.toDouble()),
          qrRect,
          paint,
        );
      }

      // Convert canvas to image
      final picture = recorder.endRecording();
      final framedImage = await picture.toImage(originalImage.width, originalImage.height);
      final byteData = await framedImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final outputFile = File('${tempDir.path}/promotional_${DateTime.now().millisecondsSinceEpoch}.png');
      await outputFile.writeAsBytes(pngBytes);

      // Dispose images
      originalImage.dispose();
      framedImage.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error applying promotional frame: $e');
      rethrow;
    }
  }

  /// Generate QR code as image
  Future<ui.Image?> _generateQRCodeImage(String data, int size) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (!qrValidationResult.isValid) {
        debugPrint('Invalid QR code data: ${qrValidationResult.error}');
        return null;
      }

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      // Create a picture recorder for QR code
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final qrSize = Size(size.toDouble(), size.toDouble());
      
      painter.paint(canvas, qrSize);
      
      final picture = recorder.endRecording();
      final qrImage = await picture.toImage(size, size);
      
      return qrImage;
    } catch (e) {
      debugPrint('Error generating QR code image: $e');
      return null;
    }
  }

  /// Draw text logo as fallback
  void _drawTextLogo(Canvas canvas, double x, double y, double size) {
      final textPainter = TextPainter(
      text: TextSpan(
        text: 'Chamakz',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background
    final bgRect = Rect.fromLTWH(x, y, size, size * 0.4);
      final roundedRect = RRect.fromRectAndRadius(bgRect, Radius.circular(8));
    canvas.drawRRect(
      roundedRect,
      Paint()..color = const Color(0xFF9C27B0).withOpacity(0.9),
    );

    // Draw text
    textPainter.paint(canvas, Offset(x + (size - textPainter.width) / 2, y + 8));
  }

  /// Get frame template based on user level
  String getFrameTemplateForLevel(int level) {
    if (level >= 90) return 'ultimate';
    if (level >= 80) return 'gem';
    if (level >= 70) return 'crown';
    if (level >= 60) return 'doubleWing';
    if (level >= 50) return 'wing';
    if (level >= 40) return 'star';
    if (level >= 30) return 'corner';
    if (level >= 20) return 'spike';
    if (level >= 10) return 'dot';
    return 'simple';
  }
}















