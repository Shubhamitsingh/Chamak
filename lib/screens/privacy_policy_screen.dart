import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          AppLocalizations.of(context)!.privacyPolicy,
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
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated Date
              Text(
                'Updated on: ${_getCurrentDate()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              
              // Section 1: Application Scope
              _buildSection(
                title: '1. Application Scope of this Privacy Policy',
                children: [
                  _buildParagraph(
                    'By using Chamakz, you agree that we may access, collect, store, use, and share your information as described in this Privacy Policy. If you do not agree with this Privacy Policy, please do not use Chamakz.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'This Privacy Policy forms part of the Chamakz Terms of Service. Any terms used here have the same meaning as defined in the Terms of Service.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'We may update or revise this Privacy Policy from time to time. If material changes are made, we will notify you through the app, website, or email. By continuing to use Chamakz after changes become effective, you agree to the updated policy.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'Chamakz may contain links to third-party websites or services. This Privacy Policy does not apply to third-party services. We are not responsible for how third parties use your information.',
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Section 2: Information We Collect
              _buildSection(
                title: '2. Information You Provide and We Collect',
                children: [
                  _buildParagraph(
                    'To provide Chamakz services, we may access, collect, store, and use the following information:',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.1 Account Information
                  _buildSubSection(
                    title: 'Account Information:',
                    content: 'Name, gender, date of birth, age, city/area, profile photo, social media account information, and any tags or details you add.',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.2 Profile Information
                  _buildSubSection(
                    title: 'Profile Information (visible to other users):',
                    content: 'Photos, gender, city/area, and any content you upload.',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.3 Usage Information
                  _buildSubSection(
                    title: 'Usage Information:',
                    content: 'Device and connection details, IP address, device capability, bandwidth, page views and interaction statistics, network type, geographical usage data.',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.4 Technical Information
                  _buildSubSection(
                    title: 'Technical Information:',
                    content: 'Mobile carrier, IP address, location/country/region/time zone, device version & identification number, operating system, app settings, likes, dislikes, and in-app interactions.',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.5 Sensitive Personal Information
                  _buildSubSection(
                    title: 'Sensitive Personal Information:',
                    content: 'To enable certain features (e.g., live streaming, video calling), we may request access to:\n• Microphone – for audio input during calls\n• Camera – for profile photos and real-time video\n• Location – to show your region for personalized content\n\nWe access these only with your explicit permission. We do not use sensitive personal information for marketing without your consent.',
                  ),
                  const SizedBox(height: 16),
                  
                  // 2.6 Children's Information
                  _buildSubSection(
                    title: 'Children\'s Information:',
                    content: 'Chamakz is not intended for users under 18 years of age. We do not knowingly collect personal data from anyone under 18. If we discover such data, we will delete it immediately.',
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Section 3: How We Use Your Information
              _buildSection(
                title: '3. How We Use Your Information',
                children: [
                  _buildParagraph(
                    'We may use your information for the following purposes:',
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('To provide and operate Chamakz services (current and future features)'),
                  _buildBulletPoint('To improve and personalize your app experience, including content recommendations'),
                  _buildBulletPoint('To respond to inquiries and provide customer support'),
                  _buildBulletPoint('To analyze usage trends and app performance'),
                  _buildBulletPoint('To maintain safety and prevent misuse'),
                  _buildBulletPoint('To verify identity and prevent fraud/illegal activity'),
                  _buildBulletPoint('To enforce our Terms of Service and policies'),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'Any messages, photos, videos, or content you share in Chamakz may be stored on our servers. If you share them publicly or with other users, we may not be able to remove them once distributed.',
                  ),
                  const SizedBox(height: 20),
                  
                  // Transfer & Storage
                  _buildSubSection(
                    title: 'Transfer & Storage of Information:',
                    content: 'Our servers may operate in multiple countries. Your information may be stored or processed outside your jurisdiction. By using Chamakz, you consent to this data transfer.',
                  ),
                  const SizedBox(height: 20),
                  
                  // Sharing of Information
                  _buildSubSection(
                    title: 'Sharing of Information:',
                    content: 'A. Sharing within Chamakz: Public profile information is visible to any user. Your online status or activity may be visible to others.\n\nB. Sharing with Third-Party Partners:\n• Analytics Partners: Shared in aggregated or anonymous form for research and performance analysis\n• Service Providers: Companies that help us operate our services (hosting, analytics, communication tools)\n• Law Enforcement: If required by law, legal processes, or to protect our users or platform\n• New Owners: If Chamakz is acquired, merged, or reorganized, your data may be transferred\n\nWe never sell personal information to third parties.',
                  ),
                  const SizedBox(height: 20),
                  
                  // Security Measures
                  _buildSubSection(
                    title: 'Security Measures:',
                    content: 'We use administrative, technical, and physical safeguards to protect your data. However, no system is 100% secure. If a data breach occurs, we will notify you as required by law. When sharing information with third parties, we ensure they follow confidentiality and security obligations.',
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Section 4: Accessing & Managing Your Information
              _buildSection(
                title: '4. Accessing & Managing Your Information',
                children: [
                  _buildParagraph(
                    'You may access and edit your profile any time.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'If you believe information on your Chamakz profile is incorrect, you may request correction by contacting us.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'If you delete your account:',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('You will lose access to your data, messages, and history'),
                  _buildBulletPoint('Some content may remain visible if shared with other users'),
                  _buildBulletPoint('We may retain data as required by law (fraud prevention, disputes, legal compliance)'),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'Requests that are technically impossible or legally restricted may not be fulfilled.',
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Section 5: Contact Us
              _buildSection(
                title: '5. Contact Us',
                children: [
                  _buildParagraph(
                    'If you have questions about this Privacy Policy or privacy matters, you may contact us at:',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFF9C27B0), // Purple
                              Color(0xFFE91E63), // Pink
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'info@chamakz.app',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // This color will be masked by the gradient
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Extra bottom spacing for comfortable reading
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSubSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildParagraph(content),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

