import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'feedback_screen.dart';
import '../services/crashlytics_service.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

// FAQ Category Model
class FAQCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  
  const FAQCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  String? _expandedFaqId;
  String _selectedCategory = 'popular'; // Default to Popular Questions
  
  // FAQ Categories
  static const List<FAQCategory> categories = [
    FAQCategory(
      id: 'popular',
      name: 'Popular Questions',
      icon: '🔥',
      color: Colors.orange,
    ),
    FAQCategory(
      id: 'payment',
      name: 'Payment Issues',
      icon: '💳',
      color: Colors.amber,
    ),
    FAQCategory(
      id: 'account',
      name: 'Account',
      icon: '👤',
      color: Colors.blue,
    ),
    FAQCategory(
      id: 'live_streaming',
      name: 'Live Streaming Issues',
      icon: '📹',
      color: Colors.black87,
    ),
    FAQCategory(
      id: 'gaming',
      name: 'Gaming Issues',
      icon: '🎮',
      color: Colors.purple,
    ),
    FAQCategory(
      id: 'partnership',
      name: 'Partnership-Related',
      icon: '🤝',
      color: Colors.amber,
    ),
    FAQCategory(
      id: 'other',
      name: 'Other Issues',
      icon: '❓',
      color: Colors.red,
    ),
  ];
  

  // FAQ Data Structure with Categories
  List<Map<String, dynamic>> _getFaqData(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      // Popular Questions
      {
        'id': 'faq_1',
        'question': 'How can I withdraw my earnings?',
        'answer': '1. Go to [Wallet]: Open the wallet in your account.\n2. Select [Withdraw]: Tap the "Withdraw" button to proceed.\n3. Check the Requirements:\n   - Your C Coins balance must be above the minimum withdrawal amount.\n   - The minimum withdrawal is 1000 C Coins for fiat withdraw.\n   - The minimum withdrawal is 5 USDT (4250 C Coins) for crypto withdraw.\n   - Your Points balance must be 0 (withdrawal may be blocked if there are any remaining Points).\n4. Submit the Request: Enter the amount and follow the instructions to complete the withdrawal.\n\nNote: Processing time may vary depending on your payment method. If you face any problems then contact us.',
        'category': 'popular',
        'order': 1,
      },
      {
        'id': 'faq_2',
        'question': 'How can I get permission to start streaming?',
        'answer': 'Contact customer service to get permission for live streaming. Our support team will review your request and grant access.',
        'category': 'popular',
        'order': 2,
      },
      {
        'id': 'faq_3',
        'question': 'What is the difference between U Coins and C Coins?',
        'answer': 'U Coins are your wallet balance (spendable coins) that you can use to send gifts and make private calls. C Coins are your earnings that you receive when viewers send you gifts or call you during live streams. U Coins are used for spending, while C Coins are your earnings that can be withdrawn.',
        'category': 'popular',
        'order': 3,
      },
      {
        'id': 'faq_4',
        'question': localizations.faqSendMessages,
        'answer': localizations.faqSendMessagesAnswer,
        'category': 'popular',
        'order': 4,
      },
      {
        'id': 'faq_5',
        'question': localizations.faqFollowers,
        'answer': localizations.faqFollowersAnswer,
        'category': 'popular',
        'order': 5,
      },
      {
        'id': 'faq_6',
        'question': 'How do I purchase U Coins?',
        'answer': '1. Go to Wallet screen\n2. Tap "Purchase Coins" or "Recharge" button\n3. Select the amount you want to purchase\n4. Complete payment via UPI or payment gateway\n5. Coins will be added to your wallet immediately after successful payment',
        'category': 'popular',
        'order': 6,
      },
      
      // Payment Issues
      {
        'id': 'faq_7',
        'question': localizations.faqRechargeWallet,
        'answer': localizations.faqRechargeWalletAnswer,
        'category': 'payment',
        'order': 1,
      },
      {
        'id': 'faq_8',
        'question': localizations.faqWithdrawEarnings,
        'answer': localizations.faqWithdrawEarningsAnswer,
        'category': 'payment',
        'order': 2,
      },
      {
        'id': 'faq_9',
        'question': 'Why can\'t I withdraw my earnings?',
        'answer': 'You may not be able to withdraw if:\n1. Your C Coins balance is below the minimum withdrawal amount (1000 C Coins for fiat, 5 USDT for crypto)\n2. Your Points balance is not 0\n3. Your account verification is pending\n4. You already have a withdrawal request pending\n\nIf none of these apply, please contact customer support.',
        'category': 'payment',
        'order': 3,
      },
      {
        'id': 'faq_10',
        'question': 'Where can I see my earnings?',
        'answer': 'Go to "My Earnings" screen (separate from Wallet). This shows your C Coins earned from gifts and private calls. Your Wallet shows U Coins (your spendable balance). These are separate balances.',
        'category': 'payment',
        'order': 4,
      },
      {
        'id': 'faq_11',
        'question': 'How much do gifts cost?',
        'answer': 'Gift prices:\n• Rose: 10 U Coins\n• Heart: 20 U Coins\n• Diamond: 50 U Coins\n• Crown: 100 U Coins\n• Sports Car: 500 U Coins\n• Rocket: 1000 U Coins\n\nMake sure you have enough U Coins in your wallet before sending gifts.',
        'category': 'payment',
        'order': 5,
      },
      
      // Account Issues
      {
        'id': 'faq_12',
        'question': localizations.faqUpdateProfile,
        'answer': localizations.faqUpdateProfileAnswer,
        'category': 'account',
        'order': 1,
      },
      {
        'id': 'faq_13',
        'question': localizations.faqChangePhone,
        'answer': localizations.faqChangePhoneAnswer,
        'category': 'account',
        'order': 2,
      },
      {
        'id': 'faq_14',
        'question': localizations.faqDeleteAccount,
        'answer': localizations.faqDeleteAccountAnswer,
        'category': 'account',
        'order': 3,
      },
      {
        'id': 'faq_15',
        'question': 'How do I change my profile picture?',
        'answer': '1. Go to Profile screen\n2. Tap "Edit Profile"\n3. Tap on your profile picture\n4. Select new image from gallery\n5. Crop and adjust as needed\n6. Tap "Save" to update your profile picture',
        'category': 'account',
        'order': 4,
      },
      
      // Live Streaming Issues
      {
        'id': 'faq_16',
        'question': 'How do I go live?',
        'answer': '1. Tap the "Go Live" button (center button in bottom navigation)\n2. Grant camera and microphone permissions when prompted\n3. Read and accept the host rules\n4. Tap "Start Live" to begin streaming\n\nNote: You need permission from customer service first before you can go live.',
        'category': 'live_streaming',
        'order': 1,
      },
      {
        'id': 'faq_17',
        'question': 'How do I send gifts during a live stream?',
        'answer': '1. While watching a live stream, tap the gift icon\n2. Select a gift from the gift selection sheet\n3. Confirm to send the gift\n4. U Coins will be deducted from your wallet\n5. The host will receive the gift and earn C Coins',
        'category': 'live_streaming',
        'order': 2,
      },
      {
        'id': 'faq_18',
        'question': 'How do I request a private call with a host?',
        'answer': '1. While watching a live stream, tap the call icon\n2. Send a call request to the host\n3. If the host accepts, the private call will start\n4. The call costs 1000 U Coins per minute (deducted automatically)\n5. The host earns C Coins for the call duration',
        'category': 'live_streaming',
        'order': 3,
      },
      {
        'id': 'faq_19',
        'question': 'Why can\'t I send messages in live chat?',
        'answer': 'Numbers (digits) and number words (one, two, etc.) are blocked in chat for your safety. This prevents sharing phone numbers. You can send text messages, but avoid using any numbers. If you need to share contact information, use the contact support feature instead.',
        'category': 'live_streaming',
        'order': 4,
      },
      {
        'id': 'faq_20',
        'question': 'How do I follow a host during a live stream?',
        'answer': 'Tap the follow button on the live stream screen. Once you follow a host, you will receive notifications when they go live. You can also see their profile and chat history.',
        'category': 'live_streaming',
        'order': 5,
      },
      
      // Coins & Earnings
      {
        'id': 'faq_21',
        'question': 'How do I earn C Coins as a host?',
        'answer': 'You earn C Coins when:\n1. Viewers send you gifts during your live stream\n2. Viewers call you privately during your live stream\n\nCheck "My Earnings" screen to see your total C Coins balance. These earnings can be withdrawn once you meet the minimum withdrawal requirements.',
        'category': 'gaming',
        'order': 1,
      },
      {
        'id': 'faq_22',
        'question': 'What happens when I send a gift?',
        'answer': 'When you send a gift:\n1. U Coins are deducted from your wallet\n2. The host receives the gift and earns C Coins\n3. A gift animation appears on the screen\n4. The transaction is recorded in your transaction history\n\nMake sure you have enough U Coins in your wallet before sending gifts.',
        'category': 'gaming',
        'order': 2,
      },
      {
        'id': 'faq_23',
        'question': 'How do I get U Coins?',
        'answer': 'U Coins are purchased through the Wallet screen. Tap "Purchase Coins" or "Recharge" to buy U Coins. You can use U Coins to send gifts and make private calls. U Coins are your spendable balance in your wallet.',
        'category': 'gaming',
        'order': 3,
      },
      
      // Partnership
      {
        'id': 'faq_24',
        'question': 'How do I become a partner?',
        'answer': 'To become a partner, contact our partnership team through the support section. We will review your application and get back to you with partnership details and benefits.',
        'category': 'partnership',
        'order': 1,
      },
      
      // Other Issues
      {
        'id': 'faq_25',
        'question': localizations.faqEnableNotifications,
        'answer': localizations.faqEnableNotificationsAnswer,
        'category': 'other',
        'order': 1,
      },
      {
        'id': 'faq_26',
        'question': localizations.faqAppNotWorking,
        'answer': localizations.faqAppNotWorkingAnswer,
        'category': 'other',
        'order': 2,
      },
      {
        'id': 'faq_27',
        'question': 'How can I contact customer service?',
        'answer': 'You can contact customer service by:\n1. Using the "Contact Support" button in Help & Feedback screen\n2. Sending a message through the app\n3. Email us at support@chamakz.com\n\nOur support team is available to help you with any questions or issues.',
        'category': 'other',
        'order': 3,
      },
      {
        'id': 'faq_28',
        'question': 'Why are numbers blocked in chat?',
        'answer': 'Numbers (digits and number words) are blocked in chat for your safety. This prevents sharing phone numbers and protects your privacy. You can send text messages, but avoid using any numbers. If you need to share contact information, use the contact support feature instead.',
        'category': 'other',
        'order': 4,
      },
      {
        'id': 'faq_29',
        'question': 'How do I search for users?',
        'answer': '1. Tap the search icon in the top bar\n2. Enter user ID or name in the search field\n3. Tap on a user from the search results to view their profile\n4. You can follow the user or start a chat with them',
        'category': 'other',
        'order': 5,
      },
    ];
  }

  // Get filtered FAQs based on category
  List<Map<String, dynamic>> _getFilteredFaqs(BuildContext context) {
    final allFaqs = _getFaqData(context);
    
    // Filter by category
    var filtered = allFaqs.where((faq) {
      return faq['category'] == _selectedCategory;
    }).toList();
    
    // Sort by order
    filtered.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.helpAndFeedback,
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
            const SizedBox(height: 6),

            // Category Tabs (Horizontal Scrollable)
            _buildCategoryTabs(),

            const SizedBox(height: 6),

            // Compact Header Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1B7C), Color(0xFFFF69B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1B7C).withValues(alpha:0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.hereToHelp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.findAnswersCommon,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // FAQs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.frequentlyAskedQuestions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // FAQ Items (Filtered)
                  _getFilteredFaqs(context).isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No FAQs in this category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try selecting a different category',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _getFilteredFaqs(context).asMap().entries.map((entry) {
                    final displayIndex = entry.key + 1; // 1-based numbering
                    final faq = entry.value;
                    final faqId = faq['id'] as String;
                    final isExpanded = _expandedFaqId == faqId;
                    
                    return Column(
                      children: [
                        // Question Row with Number Badge
                        InkWell(
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _expandedFaqId = isExpanded ? null : faqId;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                // Number Badge
                                Text(
                                  '$displayIndex.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    faq['question'].toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded 
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Answer (Expandable with Animation)
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Text(
                              faq['answer'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ),
                          crossFadeState: isExpanded 
                              ? CrossFadeState.showSecond 
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    );
                  }).toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            // Feedback Button (at bottom of scrollable content)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: const Color(0xFF04B104),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                  onPressed: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      ).catchError((error) {
                        debugPrint('❌ Error navigating to feedback: $error');
                        CrashlyticsService.logError(
                          error,
                          StackTrace.current,
                          context: 'Navigation to feedback screen failed',
                          fatal: false,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to open feedback screen. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    } catch (e) {
                      debugPrint('❌ Error: $e');
                      CrashlyticsService.logError(
                        e,
                        StackTrace.current,
                        context: 'Error in feedback button',
                        fatal: false,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build Category Tabs (Horizontal Scrollable)
  Widget _buildCategoryTabs() {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category.id;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.id;
                _expandedFaqId = null; // Close any expanded FAQ
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.grey[600]!.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected 
                      ? Colors.grey[600]!
                      : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: isSelected 
                          ? Colors.grey[600]! 
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}








