import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Policy',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE91E63), // Pink color
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFE91E63),
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              Tab(
                text: AppLocalizations.of(context)!.privacyPolicy,
              ),
              Tab(
                text: AppLocalizations.of(context)!.termsConditions,
              ),
              const Tab(
                text: 'Child Safety',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrivacyPolicyContent(),
          _buildTermsConditionsContent(),
          _buildChildSafetyPolicyContent(),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyContent() {
    return SingleChildScrollView(
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
                        fontWeight: FontWeight.w400,
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
                          color: Colors.white,
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
    );
  }

  Widget _buildTermsConditionsContent() {
    return SingleChildScrollView(
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
            
            // Introduction
            _buildParagraph(
              'Welcome to Chamakz! These Terms & Conditions ("Terms") govern your use of the Chamakz mobile application and services. By accessing or using Chamakz, you agree to be bound by these Terms. If you do not agree with these Terms, please do not use Chamakz.',
            ),
            
            const SizedBox(height: 32),
            
            // Section 1: Acceptance of Terms
            _buildSection(
              title: '1. Acceptance of Terms',
              children: [
                _buildParagraph(
                  'By downloading, installing, accessing, or using Chamakz, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. These Terms form a legally binding agreement between you and Chamakz.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'If you are using Chamakz on behalf of an organization, you represent and warrant that you have the authority to bind that organization to these Terms.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 2: Eligibility and Account Registration
            _buildSection(
              title: '2. Eligibility and Account Registration',
              children: [
                _buildParagraph(
                  'To use Chamakz, you must:',
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Be at least 18 years of age or the age of majority in your jurisdiction'),
                _buildBulletPoint('Have the legal capacity to enter into binding contracts'),
                _buildBulletPoint('Provide accurate, current, and complete information during registration'),
                _buildBulletPoint('Maintain and promptly update your account information'),
                const SizedBox(height: 12),
                _buildParagraph(
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must immediately notify us of any unauthorized use of your account.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 3: User Conduct and Responsibilities
            _buildSection(
              title: '3. User Conduct and Responsibilities',
              children: [
                _buildParagraph(
                  'You agree to use Chamakz in a lawful and appropriate manner. You agree NOT to:',
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Violate any applicable laws, regulations, or third-party rights'),
                _buildBulletPoint('Post, share, or transmit any content that is illegal, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable'),
                _buildBulletPoint('Impersonate any person or entity or falsely state or misrepresent your affiliation with any person or entity'),
                _buildBulletPoint('Collect, store, or share personal information of other users without their explicit consent'),
                _buildBulletPoint('Engage in any activity that interferes with or disrupts the service or servers'),
                _buildBulletPoint('Use automated systems, bots, or scripts to access or use Chamakz'),
                _buildBulletPoint('Attempt to gain unauthorized access to any portion of Chamakz or any other systems'),
                _buildBulletPoint('Sell, rent, lease, or otherwise transfer your account to another party'),
                _buildBulletPoint('Use Chamakz for any commercial purposes without our prior written consent'),
                _buildBulletPoint('Reverse engineer, decompile, or disassemble any aspect of Chamakz'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 4: Content Guidelines
            _buildSection(
              title: '4. Content Guidelines',
              children: [
                _buildParagraph(
                  'You retain ownership of any content you post, upload, or share on Chamakz ("Your Content"). However, by posting Your Content, you grant Chamakz a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, adapt, publish, and display Your Content for the purpose of operating and providing the service.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'You are solely responsible for Your Content. You represent and warrant that:',
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('You own or have the necessary rights to Your Content'),
                _buildBulletPoint('Your Content does not infringe upon the rights of any third party'),
                _buildBulletPoint('Your Content complies with these Terms and all applicable laws'),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Chamakz reserves the right to remove, edit, or disable access to any content that violates these Terms or is otherwise objectionable, at our sole discretion.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 5: Virtual Currency and Payments
            _buildSection(
              title: '5. Virtual Currency and Payments',
              children: [
                _buildParagraph(
                  'Chamakz uses virtual currency ("Coins") that can be purchased through in-app purchases. Important terms regarding Coins:',
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Coins have no real-world value and are not redeemable for cash'),
                _buildBulletPoint('All purchases of Coins are final and non-refundable, except as required by law'),
                _buildBulletPoint('Coins cannot be transferred between accounts or exchanged with other users'),
                _buildBulletPoint('Chamakz reserves the right to modify, suspend, or discontinue Coins at any time'),
                _buildBulletPoint('Refunds are subject to platform policies (Google Play Store, Apple App Store)'),
                const SizedBox(height: 12),
                _buildParagraph(
                  'By making a purchase, you confirm that you are authorized to use the payment method. You are responsible for all charges incurred under your account.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 6: Intellectual Property Rights
            _buildSection(
              title: '6. Intellectual Property Rights',
              children: [
                _buildParagraph(
                  'The Chamakz service, including its design, graphics, logos, text, software, and other materials, is owned by Chamakz or its licensors and is protected by copyright, trademark, and other intellectual property laws.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'You may not copy, reproduce, distribute, modify, create derivative works of, publicly display, or otherwise use any part of Chamakz without our prior written consent.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 7: Privacy and Data Protection
            _buildSection(
              title: '7. Privacy and Data Protection',
              children: [
                _buildParagraph(
                  'Your privacy is important to us. Our collection, use, and protection of your personal information is governed by our Privacy Policy, which is incorporated into these Terms by reference. By using Chamakz, you consent to the collection and use of your information as described in our Privacy Policy.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 8: Disclaimers and Limitations of Liability
            _buildSection(
              title: '8. Disclaimers and Limitations of Liability',
              children: [
                _buildParagraph(
                  'Chamakz is provided "as is" and "as available" without warranties of any kind, either express or implied. We do not guarantee that:',
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('The service will be uninterrupted, secure, or error-free'),
                _buildBulletPoint('Defects will be corrected'),
                _buildBulletPoint('The service is free from viruses or other harmful components'),
                const SizedBox(height: 12),
                _buildParagraph(
                  'To the maximum extent permitted by law, Chamakz shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the service.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 9: Termination
            _buildSection(
              title: '9. Termination',
              children: [
                _buildParagraph(
                  'You may terminate your account at any time by deleting it through the app settings or by contacting us.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'We reserve the right to suspend or terminate your account immediately, without prior notice, if you violate these Terms or engage in any fraudulent, illegal, or harmful activity.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Upon termination, your right to use Chamakz will immediately cease. All provisions of these Terms that by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, and limitations of liability.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 10: Changes to Terms
            _buildSection(
              title: '10. Changes to Terms',
              children: [
                _buildParagraph(
                  'We reserve the right to modify these Terms at any time. If we make material changes, we will notify you through the app, via email, or by posting a notice on our website. Your continued use of Chamakz after such modifications constitutes your acceptance of the updated Terms.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 11: Governing Law and Disputes
            _buildSection(
              title: '11. Governing Law and Disputes',
              children: [
                _buildParagraph(
                  'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Chamakz operates, without regard to its conflict of law provisions.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Any disputes arising out of or relating to these Terms or the service shall be resolved through good faith negotiations. If such negotiations fail, disputes may be resolved through binding arbitration or in the courts of competent jurisdiction.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 12: Contact Information
            _buildSection(
              title: '12. Contact Information',
              children: [
                _buildParagraph(
                  'If you have any questions about these Terms & Conditions, please contact us at:',
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
                        fontWeight: FontWeight.w400,
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
                          color: Colors.white,
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
            fontWeight: FontWeight.w700,
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
            fontSize: 16,
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
        fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSafetyPolicyContent() {
    return SingleChildScrollView(
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
            
            // Title
            _buildSection(
              title: 'Child Sexual Abuse Policy',
              children: [
                _buildParagraph(
                  'Chamakz has a Zero Tolerance Policy against child sexual abuse content or any content that can be harmful to minors. Users may not use Chamakz\'s services to create, publish, reproduce, transmit, distribute, or store such content, which includes but is not limited to:',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section 1: Prohibited Content
            _buildSection(
              title: '1. Prohibited Content',
              children: [
                // Sexualization of minors
                _buildSubSection(
                  title: 'Sexualization of minors:',
                  content: 'Sexually explicit content featuring minors and content that sexually exploits minors.',
                ),
                const SizedBox(height: 16),
                
                // Sexual acts involving minors
                _buildSubSection(
                  title: 'Sexual acts involving minors:',
                  content: 'Content showing a minor participating in sexual activities or encouraging minors to do sexual activities.',
                ),
                const SizedBox(height: 16),
                
                // Misleading content
                _buildSubSection(
                  title: 'Misleading content:',
                  content: 'Content that targets young minors, but contains:\n• Sexual content\n• Sexual violence\n• Obscenity\n• Other contents containing adult or age-inappropriate themes such as violence, sex, and more.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 2: Our Response
            _buildSection(
              title: '2. Our Response',
              children: [
                _buildParagraph(
                  'If we are made aware that our services have been used to store and/or transmit any content of that kind, we act immediately to remove any and all such content, block the user accounts involved and report all related activity to authorities.',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Chamakz hereby reserves the right to take further action including but not limited to cooperation with law enforcement agencies and/or government bodies to assist them in prosecuting those involved.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 3: Reporting
            _buildSection(
              title: '3. Reporting Violations',
              children: [
                _buildParagraph(
                  'If you are aware of child sexual abuse content or illegal content on the Chamakz platform, please report to:',
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
                        fontWeight: FontWeight.w400,
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Please provide information reasonably sufficient to permit Chamakz to locate the material.',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section 4: Additional Resources
            _buildSection(
              title: '4. Additional Resources',
              children: [
                _buildParagraph(
                  'If you become aware of child exploitation or abuse of minors elsewhere on the internet or offline, we recommend you contact one of the following, based on your location:',
                ),
                const SizedBox(height: 16),
                
                _buildSubSection(
                  title: 'North America, Australia, New Zealand:',
                  content: 'National Center for Missing & Exploited Children (NCMEC)',
                ),
                const SizedBox(height: 16),
                
                _buildSubSection(
                  title: 'Europe:',
                  content: 'Law Enforcement Reporting Channels for Child Sexual Coercion and Extortion',
                ),
                const SizedBox(height: 16),
                
                _buildSubSection(
                  title: 'South America and other locales:',
                  content: 'International Centre for Missing & Exploited Children global hotline',
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Important Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important Notice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chamakz takes child safety extremely seriously. Any violation of this policy will result in immediate account termination and reporting to law enforcement authorities.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[900],
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
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
