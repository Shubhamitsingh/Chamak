import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          AppLocalizations.of(context)!.termsConditions,
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

