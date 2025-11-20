import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'notification_settings_screen.dart';
import 'language_selection_screen.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

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
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
          children: [
          Expanded(
            child: ListView(
          children: [
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.language,
                  subtitle: Provider.of<LanguageProvider>(context).currentLanguageNativeName,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to language selection: $e');
                    }
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.notification,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to notification settings: $e');
                    }
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.aboutUs,
                  onTap: _showAboutDialog,
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.termsConditions,
                  onTap: () => _showPolicyDialog('terms'),
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.privacyPolicy,
              onTap: () => _showPolicyDialog('privacy'),
            ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.feedback,
                  onTap: _showFeedbackDialog,
            ),
          ],
        ),
      ),
          
          // Fixed App Name and Version at Bottom
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Column(
          children: [
                Text(
              AppLocalizations.of(context)!.appName,
              style: TextStyle(
                    fontSize: 16,
                fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${AppLocalizations.of(context)!.appVersion} 1.0.0',
              style: TextStyle(
                fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(AppLocalizations.of(context)!.aboutUs),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.diamond, color: Color(0xFF9C27B0), size: 60),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.appName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.appDescription,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.features,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(AppLocalizations.of(context)!.liveStreaming),
              Text(AppLocalizations.of(context)!.realTimeChat),
              Text(AppLocalizations.of(context)!.virtualGifts),
              Text(AppLocalizations.of(context)!.hostViewerModes),
              Text(AppLocalizations.of(context)!.securePayments),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              try {
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error closing about dialog: $e');
              }
            },
            child: Text(
              AppLocalizations.of(context)!.close,
              style: const TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
      );
    } catch (e) {
      debugPrint('Error showing about dialog: $e');
    }
  }

  void _showPolicyDialog(String type) {
    if (!mounted) return;
    final title = type == 'terms' 
        ? AppLocalizations.of(context)!.termsConditions 
        : AppLocalizations.of(context)!.privacyPolicy;
    
    try {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'privacy'
                    ? AppLocalizations.of(context)!.privacyPolicyContent
                    : AppLocalizations.of(context)!.termsConditionsContent,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              try {
                Navigator.pop(context);
              } catch (e) {
                debugPrint('Error closing policy dialog: $e');
              }
            },
            child: Text(
              AppLocalizations.of(context)!.close,
              style: const TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
      );
    } catch (e) {
      debugPrint('Error showing policy dialog: $e');
    }
  }

  void _showFeedbackDialog() {
    if (!mounted) return;
    final TextEditingController feedbackController = TextEditingController();
    
    try {
      showDialog(
        context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.feedback),
          content: TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.writeFeedbackHere,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                try {
                  feedbackController.dispose();
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('Error closing feedback dialog: $e');
                  feedbackController.dispose();
                }
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (feedbackController.text.trim().isNotEmpty) {
                  try {
                    feedbackController.dispose();
                    Navigator.pop(context);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.thankYouForFeedback),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error submitting feedback: $e');
                    feedbackController.dispose();
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.send),
            ),
          ],
        );
      },
      );
    } catch (e) {
      debugPrint('Error showing feedback dialog: $e');
    }
  }
}
