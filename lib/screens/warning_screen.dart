import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:Chamak/generated/l10n/app_localizations.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen>
    with TickerProviderStateMixin {
  // Mock data - Replace with real data from Firebase
  final int currentWarnings = 0;
  final int maxWarnings = 5;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for warning indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Slide animation for rules
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Color _getWarningColor() {
    if (currentWarnings == 0) return const Color(0xFF10B981); // Green
    if (currentWarnings < 3) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  Color _getWarningLightColor() {
    if (currentWarnings == 0) return const Color(0xFF10B981).withValues(alpha: 0.1);
    if (currentWarnings < 3) return const Color(0xFFF59E0B).withValues(alpha: 0.1);
    return const Color(0xFFEF4444).withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 16,
            ),
          ),
          onPressed: () {
            try {
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Error navigating back: $e');
            }
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.warningForPermanentBlock,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          children: [
            // Warning Counter Card
            _buildWarningCounter(),
            
            const SizedBox(height: 24),
            
            // Rules Section
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _slideController,
                child: _buildRulesSection(),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCounter() {
    final double progress = currentWarnings / maxWarnings;
    final warningColor = _getWarningColor();
    final warningLightColor = _getWarningLightColor();
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                warningLightColor,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: warningColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated Circular Progress with Pulse Effect
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: currentWarnings >= 3 ? _pulseAnimation.value : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow effect for high warnings
                        if (currentWarnings >= 3)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: warningColor.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        
                        // Background circle
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[50],
                          ),
                        ),
                        
                        // Progress indicator
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: Stack(
                            children: [
                              // Background circle
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                ),
                              ),
                              // Animated progress
                              Transform.rotate(
                                angle: -math.pi / 2,
                                child: CircularProgressIndicator(
                                  value: animatedProgress,
                                  strokeWidth: 14,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    warningColor,
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: currentWarnings),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedValue, child) {
                                return Text(
                                  '${animatedValue.toString().padLeft(2, '0')}/${maxWarnings.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: warningColor,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.currentWarnings,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 28),
              
              // Warning Status Card with Animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - opacity)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: warningLightColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: warningColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: warningColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: warningColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                currentWarnings == 0
                                    ? Icons.check_circle_rounded
                                    : currentWarnings < 3
                                        ? Icons.info_rounded
                                        : Icons.warning_rounded,
                                color: warningColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentWarnings == 0
                                        ? AppLocalizations.of(context)!.greatNoWarnings
                                        : currentWarnings < 3
                                            ? AppLocalizations.of(context)!.followCommunityGuidelines
                                            : AppLocalizations.of(context)!.riskOfPermanentBlock,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: warningColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (currentWarnings > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)!.warningsRemaining(maxWarnings - currentWarnings),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRulesSection() {
    final rules = [
      {
        'number': '01',
        'title': AppLocalizations.of(context)!.rule01Hindi,
        'subtitle': AppLocalizations.of(context)!.rule01English,
        'icon': Icons.gavel_rounded,
      },
      {
        'number': '02',
        'title': AppLocalizations.of(context)!.rule02Hindi,
        'subtitle': AppLocalizations.of(context)!.rule02English,
        'icon': Icons.people_outline_rounded,
      },
      {
        'number': '03',
        'title': AppLocalizations.of(context)!.rule03Hindi,
        'subtitle': AppLocalizations.of(context)!.rule03English,
        'icon': Icons.block_rounded,
      },
      {
        'number': '04',
        'title': AppLocalizations.of(context)!.rule04Hindi,
        'subtitle': AppLocalizations.of(context)!.rule04English,
        'icon': Icons.security_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
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
                      AppLocalizations.of(context)!.toAvoidWarnings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.followTheseGuidelines,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 28),
          
          // Rules List with staggered animations
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - opacity)),
                    child: Column(
                      children: [
                        _buildRuleItem(
                          number: rule['number'] as String,
                          title: rule['title'] as String,
                          subtitle: rule['subtitle'] as String,
                          icon: rule['icon'] as IconData,
                          index: index,
                        ),
                        if (index < rules.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey[200],
                              indent: 48,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required int index,
  }) {
    final gradientColors = [
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
    ];
    
    final colors = gradientColors[index % gradientColors.length];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number badge with icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icon
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.3),
                size: 28,
              ),
              // Number
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


