import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'notification_settings_screen.dart';
import 'language_selection_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
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
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to about screen: $e');
                    }
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.termsConditions,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsConditionsScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to terms & conditions: $e');
                    }
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.privacyPolicy,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to privacy policy: $e');
                    }
                  },
                ),
                _buildSettingItem(
                  title: AppLocalizations.of(context)!.feedback,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to feedback screen: $e');
                    }
                  },
                ),
          ],
        ),
      ),
          
          // Fixed App Name and Version at Bottom
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Column(
          children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Chamakz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${AppLocalizations.of(context)!.appVersion} 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
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
}
