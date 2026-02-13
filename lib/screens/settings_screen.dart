import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_settings_screen.dart';
import 'language_selection_screen.dart';
import 'policy_screen.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'general_screen.dart';
import 'account_security_screen.dart';
import '../providers/language_provider.dart';
import '../services/database_service.dart';
import '../services/id_generator_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // Get phone number from Firebase Auth
      _phoneNumber = currentUser.phoneNumber ?? '';

      // Get user data from Firestore to get numericUserId
      final userData = await _databaseService.getUserData(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _userId = IdGeneratorService.getDisplayId(userData.numericUserId);
        });
      }
    } catch (e) {
      debugPrint('Error loading user data in settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to language changes to rebuild when language changes
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
                    // 1. General
                    _buildSettingItem(
                      title: AppLocalizations.of(context)!.general,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GeneralScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to general screen: $e');
                    }
                  },
                ),
                    // 2. Language
                    _buildSettingItem(
                      title: AppLocalizations.of(context)!.language,
                      subtitle: languageProvider.currentLanguageNativeName,
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
                    // 3. Account Security (moved up from position 4)
                    _buildSettingItem(
                      title: AppLocalizations.of(context)!.accountSecurity,
                      subtitle: AppLocalizations.of(context)!.phonePasswordAccountSettings,
                  onTap: () {
                    if (_phoneNumber == null || _userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.errorLoadingProfile),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountSecurityScreen(
                            phoneNumber: _phoneNumber!,
                            userId: _userId!,
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to account security: $e');
                    }
                  },
                ),
                    // 4. Notification (moved down from position 3)
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
                    // 5. About Us
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
                    // 6. Policy (consolidated Privacy Policy & Terms & Conditions)
                    _buildSettingItem(
                      title: AppLocalizations.of(context)!.policy,
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PolicyScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error navigating to policy screen: $e');
                    }
                  },
                ),
                    // 7. Feedback
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
                padding: const EdgeInsets.only(top: 30, bottom: 50),
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
                    const SizedBox(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${AppLocalizations.of(context)!.appVersion} 1.1.8',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      dense: true,
      minVerticalPadding: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
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
