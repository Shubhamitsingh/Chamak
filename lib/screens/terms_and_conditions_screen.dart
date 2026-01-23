import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Text(
              'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),

            // Terms Content
            _buildSection(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using the Chamakz platform, you accept and agree to be bound by the terms and conditions of this agreement. If you do not agree to these terms, please do not use our services.',
            ),

            _buildSection(
              title: '2. Creator Application',
              content:
                  'To become a creator on our platform, you must:\n\n'
                  '• Be at least 18 years old\n'
                  '• Provide accurate and complete information in your application\n'
                  '• Accept these Terms & Conditions\n'
                  '• Agree to follow all platform rules and guidelines\n\n'
                  'Applications are subject to review and approval by our admin team. We reserve the right to approve or reject any application at our discretion.',
            ),

            _buildSection(
              title: '3. Creator Responsibilities',
              content:
                  'As a creator, you agree to:\n\n'
                  '• Provide original and appropriate content\n'
                  '• Respect all users and maintain a professional demeanor\n'
                  '• Follow community guidelines and platform rules\n'
                  '• Not engage in any illegal or harmful activities\n'
                  '• Maintain the security of your account\n'
                  '• Report any violations or issues to the admin team',
            ),

            _buildSection(
              title: '4. Earnings and Payments',
              content:
                  'Creators on our platform receive 100% of their earnings with no broker fees or commissions. Payments are processed according to our withdrawal policy. We reserve the right to withhold payments in case of violations or disputes.',
            ),

            _buildSection(
              title: '5. Content Guidelines',
              content:
                  'All content must:\n\n'
                  '• Be original and owned by you\n'
                  '• Comply with local laws and regulations\n'
                  '• Not contain explicit, harmful, or offensive material\n'
                  '• Respect intellectual property rights\n'
                  '• Not promote illegal activities\n\n'
                  'Violation of content guidelines may result in immediate suspension or termination of your account.',
            ),

            _buildSection(
              title: '6. Account Security',
              content:
                  'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized access or security breach. We are not liable for any loss or damage resulting from unauthorized access to your account.',
            ),

            _buildSection(
              title: '7. Platform Rules',
              content:
                  'All users must:\n\n'
                  '• Treat others with respect and kindness\n'
                  '• Not engage in harassment, bullying, or discrimination\n'
                  '• Not share personal information of other users\n'
                  '• Not use the platform for spam or scams\n'
                  '• Follow all community guidelines\n\n'
                  'Violations may result in warnings, temporary suspension, or permanent ban.',
            ),

            _buildSection(
              title: '8. Termination',
              content:
                  'We reserve the right to suspend or terminate your account at any time for violations of these terms, platform rules, or for any other reason we deem necessary. You may also terminate your account at any time by contacting support.',
            ),

            _buildSection(
              title: '9. Limitation of Liability',
              content:
                  'The platform is provided "as is" without warranties of any kind. We are not liable for any direct, indirect, incidental, or consequential damages arising from your use of the platform.',
            ),

            _buildSection(
              title: '10. Changes to Terms',
              content:
                  'We reserve the right to modify these terms and conditions at any time. Changes will be effective immediately upon posting. Your continued use of the platform after changes constitutes acceptance of the new terms.',
            ),

            // Contact Information with gradient email
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '11. Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF1B7C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                          text: 'If you have any questions about these Terms & Conditions, please contact our support team through the app or email us at ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ShaderMask(
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
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Agreement Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1B7C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF1B7C).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF1B7C),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using our platform, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF1B7C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
