import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.aboutUs,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // App Logo
            Center(
              child: Image.asset(
                'assets/images/logopink.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo not found
                  return Image.asset(
                    'assets/images/logopink.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name with Gradient
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFE91E63), // Pink
                    Color(0xFF9C27B0), // Purple
                    Color(0xFFFFA500), // Orange
                    Color(0xFFFFD700), // Gold
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: const Text(
                'Chamakz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Version
            Text(
              '${AppLocalizations.of(context)!.appVersion} 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Extra bottom spacing
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

}

