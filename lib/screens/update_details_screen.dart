import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_model.dart';

/// Screen to display app update details
class UpdateDetailsScreen extends StatelessWidget {
  final UpdateModel updateModel;

  const UpdateDetailsScreen({
    super.key,
    required this.updateModel,
  });

  /// Play Store URL for the app
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.chamakz.app';

  /// Open Play Store to update the app
  Future<void> _openPlayStore() async {
    try {
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch Play Store URL');
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdateAvailable = updateModel.updateAvailable;

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
          isUpdateAvailable ? 'Update Available' : 'App Version',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // App Logo Section
            Center(
              child: Image.asset(
                'assets/images/logopink.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF1B7C),
                          const Color(0xFFFF69B4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.apps,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // Status Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    isUpdateAvailable
                        ? Icons.system_update_rounded
                        : Icons.check_circle_rounded,
                    color: isUpdateAvailable
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF6366F1),
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUpdateAvailable
                        ? 'New Version Available!'
                        : 'App is Up to Date',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Version: ${updateModel.currentVersion}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  if (isUpdateAvailable) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Latest Version: ${updateModel.latestVersion}',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isUpdateAvailable) ...[
              const SizedBox(height: 24),

              // Update Message
              if (updateModel.updateMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF6366F1),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            updateModel.updateMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Content Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Features Section
                    if (updateModel.features.isNotEmpty) ...[
                      _buildSectionTitle('New Features', Icons.star_rounded, const Color(0xFFFFA726)),
                      const SizedBox(height: 12),
                      ...updateModel.features.map((feature) => _buildListItem(
                            feature,
                            Icons.add_circle_rounded,
                            const Color(0xFF6366F1),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Improvements Section
                    if (updateModel.improvements.isNotEmpty) ...[
                      _buildSectionTitle('Improvements', Icons.trending_up_rounded, const Color(0xFF6366F1)),
                      const SizedBox(height: 12),
                      ...updateModel.improvements.map((improvement) => _buildListItem(
                            improvement,
                            Icons.upgrade_rounded,
                            const Color(0xFF6366F1),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Bug Fixes Section
                    if (updateModel.bugFixes.isNotEmpty) ...[
                      _buildSectionTitle('Bug Fixes', Icons.bug_report_rounded, const Color(0xFFFF6B6B)),
                      const SizedBox(height: 12),
                      ...updateModel.bugFixes.map((fix) => _buildListItem(
                            fix,
                            Icons.check_circle_rounded,
                            const Color(0xFFFF6B6B),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),

              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _openPlayStore,
                    icon: const Icon(Icons.download_rounded, size: 22),
                    label: const Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  updateModel.updateMessage.isNotEmpty
                      ? updateModel.updateMessage
                      : 'You are using the latest version of the app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
