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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectionScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.notification,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
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
              'Chamak Live',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(AppLocalizations.of(context)!.aboutUs),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.diamond, color: Color(0xFF9C27B0), size: 60),
              SizedBox(height: 15),
              Text(
                'Chamak Live',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Connect with people around the world through live streaming, chat, and share amazing moments.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 15),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text('• Live streaming'),
              Text('• Real-time chat'),
              Text('• Virtual gifts'),
              Text('• Host & viewer modes'),
              Text('• Secure payments'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: const TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog(String type) {
    final title = type == 'terms' 
        ? AppLocalizations.of(context)!.termsConditions 
        : AppLocalizations.of(context)!.privacyPolicy;
    
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
                    ? 'We respect your privacy and are committed to protecting your personal data. '
                        'This policy describes how we collect, use, and share your information.\n\n'
                        '1. Information Collection\n'
                        '2. Data Usage\n'
                        '3. Data Sharing\n'
                        '4. Security Measures\n'
                        '5. Your Rights\n\n'
                        'Last updated: January 2025'
                    : 'By using Chamak Live, you agree to these terms and conditions.\n\n'
                        '1. Account Registration\n'
                        '2. User Conduct\n'
                        '3. Content Guidelines\n'
                        '4. Payment Terms\n'
                        '5. Termination\n\n'
                        'Last updated: January 2025',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: const TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
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
                feedbackController.dispose();
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (feedbackController.text.trim().isNotEmpty) {
                  feedbackController.dispose();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.thankYouForFeedback),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.send),
            ),
          ],
        );
      },
    );
  }
}
