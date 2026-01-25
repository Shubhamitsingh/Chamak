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
        'question': 'How can I withdraw coins?',
        'answer': '1. Go to [Wallet]: Open the wallet in your account.\n2. Select [Withdraw]: Tap the "Withdraw" button to proceed.\n3. Check the Requirements:\n   - Your balance must be above the minimum withdrawal amount.\n   - The minimum withdrawal is 1000 coins for fiat withdraw.\n   - The minimum withdrawal is 5 USDT (4250 coins) for crypto withdraw.\n   - Your Points balance must be 0 (withdrawal may be blocked if there are any remaining Points).\n4. Submit the Request: Enter the amount and follow the instructions to complete the withdrawal.\n\nNote: Processing time may vary depending on your payment method. If you face any problems then contact us.',
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
        'question': localizations.faqSendMessages,
        'answer': localizations.faqSendMessagesAnswer,
        'category': 'popular',
        'order': 3,
      },
      {
        'id': 'faq_4',
        'question': localizations.faqFollowers,
        'answer': localizations.faqFollowersAnswer,
        'category': 'popular',
        'order': 4,
      },
      
      // Payment Issues
      {
        'id': 'faq_5',
        'question': localizations.faqRechargeWallet,
        'answer': localizations.faqRechargeWalletAnswer,
        'category': 'payment',
        'order': 1,
      },
      {
        'id': 'faq_6',
        'question': localizations.faqWithdrawEarnings,
        'answer': localizations.faqWithdrawEarningsAnswer,
        'category': 'payment',
        'order': 2,
      },
      {
        'id': 'faq_7',
        'question': 'How can I unlock rupees?',
        'answer': 'To unlock rupees, you need to complete certain tasks or reach specific milestones. Check your wallet for unlock requirements.',
        'category': 'payment',
        'order': 3,
      },
      {
        'id': 'faq_8',
        'question': 'How can I withdraw unlocked rupees?',
        'answer': 'Once rupees are unlocked, go to Wallet → Withdraw → Select unlocked rupees → Enter amount → Submit request.',
        'category': 'payment',
        'order': 4,
      },
      
      // Account Issues
      {
        'id': 'faq_9',
        'question': localizations.faqUpdateProfile,
        'answer': localizations.faqUpdateProfileAnswer,
        'category': 'account',
        'order': 1,
      },
      {
        'id': 'faq_10',
        'question': localizations.faqChangePhone,
        'answer': localizations.faqChangePhoneAnswer,
        'category': 'account',
        'order': 2,
      },
      {
        'id': 'faq_11',
        'question': localizations.faqDeleteAccount,
        'answer': localizations.faqDeleteAccountAnswer,
        'category': 'account',
        'order': 3,
      },
      
      // Live Streaming Issues
      {
        'id': 'faq_12',
        'question': 'How can I enable paid live rooms?',
        'answer': 'To enable paid live rooms:\n1. Go to Settings → Live Streaming\n2. Enable "Paid Rooms" option\n3. Set your room price\n4. Start your live stream with paid access enabled.',
        'category': 'live_streaming',
        'order': 1,
      },
      {
        'id': 'faq_13',
        'question': 'How to go live?',
        'answer': 'To start a live stream:\n1. Tap the "Go Live" button\n2. Grant camera and microphone permissions\n3. Set your stream title and settings\n4. Tap "Start Live" to begin streaming.',
        'category': 'live_streaming',
        'order': 2,
      },
      
      // Gaming Issues
      {
        'id': 'faq_14',
        'question': 'How can I earn coins?',
        'answer': 'You can earn coins by:\n1. Watching live streams\n2. Sending gifts to streamers\n3. Completing daily tasks\n4. Participating in games\n5. Referring friends',
        'category': 'gaming',
        'order': 1,
      },
      {
        'id': 'faq_15',
        'question': 'How can I increase my wealth level?',
        'answer': 'To increase your wealth level:\n1. Earn more coins through activities\n2. Complete missions and tasks\n3. Stay active on the platform\n4. Engage with content regularly',
        'category': 'gaming',
        'order': 2,
      },
      
      // Partnership
      {
        'id': 'faq_16',
        'question': 'How to become a partner?',
        'answer': 'To become a partner, contact our partnership team through the support section. We will review your application and get back to you.',
        'category': 'partnership',
        'order': 1,
      },
      
      // Other Issues
      {
        'id': 'faq_17',
        'question': localizations.faqEnableNotifications,
        'answer': localizations.faqEnableNotificationsAnswer,
        'category': 'other',
        'order': 1,
      },
      {
        'id': 'faq_18',
        'question': localizations.faqAppNotWorking,
        'answer': localizations.faqAppNotWorkingAnswer,
        'category': 'other',
        'order': 2,
      },
      {
        'id': 'faq_19',
        'question': 'How can I contact customer service?',
        'answer': 'You can contact customer service by:\n1. Using the "Contact Support" button in Help & Feedback\n2. Sending a message through the app\n3. Email us at support@chamakz.com',
        'category': 'other',
        'order': 3,
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
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha:0.2),
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








