import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:Chamak/generated/l10n/app_localizations.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  // TODO: Fetch this from Firestore/database
  int currentWarnings = 0;
  int maxWarnings = 5;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    final rules = isHindi
        ? [
            loc.rule01Hindi,
            loc.rule02Hindi,
            loc.rule03Hindi,
            loc.rule04Hindi,
            'कोई भी फर्जी/नकली प्रोफ़ाइल न बनाएं',
            'पता या फ़ोन नंबर जैसी निजी जानकारी साझा न करें',
            'किसी भी तरह की धमकी, उत्पीड़न या बदसलूकी न करें',
            'अश्लील, आपत्तिजनक या अनुचित सामग्री साझा न करें',
            'स्पैम/विज्ञापन/प्रमोशनल संदेश न भेजें',
            'उम्र प्रतिबंधों का सम्मान करें, नाबालिगों से अनुचित बातचीत न करें',
          ]
        : [
            loc.rule01English,
            loc.rule02English,
            loc.rule03English,
            loc.rule04English,
            'No impersonation or fake profiles',
            'Do not share personal information like address or phone number',
            'No harassment, bullying, or threatening behavior',
            'Do not share inappropriate, explicit, or offensive content',
            'No spamming, advertising, or promotional messages',
            'Respect age restrictions and do not interact with minors inappropriately',
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          loc.warnings,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Warning Title
            Text(
              'Warning for',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'permanent block',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 25),
            
            // Semi-circular Warning Meter
            _buildWarningMeter(),
            
            const SizedBox(height: 40),
            
            // Rules Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.followTheseGuidelines,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.followCommunityGuidelines,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...rules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rule = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rule,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningMeter() {
    final progress = currentWarnings / maxWarnings;
    final currentWarningsStr = currentWarnings.toString().padLeft(2, '0');
    final maxWarningsStr = maxWarnings.toString().padLeft(2, '0');

    return SizedBox(
      width: 280,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Semi-circular arc background
          CustomPaint(
            size: const Size(280, 140),
            painter: _SemiCirclePainter(
              progress: progress,
              trackColor: Colors.grey[300]!,
              progressColor: const Color(0xFFFF1B7C), // Pink/Red
              strokeWidth: 12,
            ),
          ),
          
          // Center text: Current warnings / Max warnings
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentWarningsStr,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF1B7C), // Pink/Red
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/$maxWarningsStr',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Current warnings',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for semi-circular progress
class _SemiCirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _SemiCirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    // Draw background arc (full semi-circle)
    final backgroundPath = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        math.pi, // Start at 180 degrees (left)
        math.pi, // Sweep 180 degrees (to right)
        false,
      );
    canvas.drawPath(backgroundPath, paint);

    // Draw progress arc (filled portion)
    if (progress > 0) {
      paint.color = progressColor;
      final progressPath = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          math.pi, // Start at 180 degrees (left)
          math.pi * progress, // Sweep based on progress
          false,
        );
      canvas.drawPath(progressPath, paint);
    }
  }

  @override
  bool shouldRepaint(_SemiCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
