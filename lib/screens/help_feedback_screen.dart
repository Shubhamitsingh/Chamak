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
        'question': localizations.faqWithdrawEarningsDetailed,
        'answer': localizations.faqWithdrawEarningsDetailedAnswer,
        'category': 'popular',
        'order': 1,
      },
      {
        'id': 'faq_2',
        'question': localizations.faqGetStreamingPermission,
        'answer': localizations.faqGetStreamingPermissionAnswer,
        'category': 'popular',
        'order': 2,
      },
      {
        'id': 'faq_3',
        'question': localizations.faqUCoinsVsCCoins,
        'answer': localizations.faqUCoinsVsCCoinsAnswer,
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
        'question': localizations.faqPurchaseUCoins,
        'answer': localizations.faqPurchaseUCoinsAnswer,
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
        'question': localizations.faqCantWithdrawEarnings,
        'answer': localizations.faqCantWithdrawEarningsAnswer,
        'category': 'payment',
        'order': 3,
      },
      {
        'id': 'faq_10',
        'question': localizations.faqWhereSeeEarnings,
        'answer': localizations.faqWhereSeeEarningsAnswer,
        'category': 'payment',
        'order': 4,
      },
      {
        'id': 'faq_11',
        'question': localizations.faqGiftPrices,
        'answer': localizations.faqGiftPricesAnswer,
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
        'question': localizations.faqChangeProfilePicture,
        'answer': localizations.faqChangeProfilePictureAnswer,
        'category': 'account',
        'order': 4,
      },
      
      // Live Streaming Issues
      {
        'id': 'faq_16',
        'question': localizations.faqGoLive,
        'answer': localizations.faqGoLiveAnswer,
        'category': 'live_streaming',
        'order': 1,
      },
      {
        'id': 'faq_17',
        'question': localizations.faqSendGiftsLiveStream,
        'answer': localizations.faqSendGiftsLiveStreamAnswer,
        'category': 'live_streaming',
        'order': 2,
      },
      {
        'id': 'faq_18',
        'question': localizations.faqRequestPrivateCall,
        'answer': localizations.faqRequestPrivateCallAnswer,
        'category': 'live_streaming',
        'order': 3,
      },
      {
        'id': 'faq_19',
        'question': localizations.faqCantSendMessagesChat,
        'answer': localizations.faqCantSendMessagesChatAnswer,
        'category': 'live_streaming',
        'order': 4,
      },
      {
        'id': 'faq_20',
        'question': localizations.faqFollowHostLiveStream,
        'answer': localizations.faqFollowHostLiveStreamAnswer,
        'category': 'live_streaming',
        'order': 5,
      },
      
      // Coins & Earnings
      {
        'id': 'faq_21',
        'question': localizations.faqEarnCCoinsHost,
        'answer': localizations.faqEarnCCoinsHostAnswer,
        'category': 'gaming',
        'order': 1,
      },
      {
        'id': 'faq_22',
        'question': localizations.faqWhatHappensSendGift,
        'answer': localizations.faqWhatHappensSendGiftAnswer,
        'category': 'gaming',
        'order': 2,
      },
      {
        'id': 'faq_23',
        'question': localizations.faqGetUCoins,
        'answer': localizations.faqGetUCoinsAnswer,
        'category': 'gaming',
        'order': 3,
      },
      
      // Partnership
      {
        'id': 'faq_24',
        'question': localizations.faqBecomePartner,
        'answer': localizations.faqBecomePartnerAnswer,
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
        'question': localizations.faqContactCustomerService,
        'answer': localizations.faqContactCustomerServiceAnswer,
        'category': 'other',
        'order': 3,
      },
      {
        'id': 'faq_28',
        'question': localizations.faqNumbersBlockedChat,
        'answer': localizations.faqNumbersBlockedChatAnswer,
        'category': 'other',
        'order': 4,
      },
      {
        'id': 'faq_29',
        'question': localizations.faqSearchUsers,
        'answer': localizations.faqSearchUsersAnswer,
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
            fontWeight: FontWeight.w600,
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
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.hereToHelp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w600,
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
                                  AppLocalizations.of(context)!.noFaqsInThisCategory,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.trySelectingDifferentCategory,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Number Badge
                                Text(
                                  '$displayIndex.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    faq['question'].toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.unableToOpenFeedbackScreen),
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
                  child: Text(
                    AppLocalizations.of(context)!.feedback,
                    style: const TextStyle(
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

  // Get localized category name
  String _getCategoryName(BuildContext context, String categoryId) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryId) {
      case 'popular':
        return l10n.popularQuestions;
      case 'payment':
        return l10n.paymentIssues;
      case 'account':
        return l10n.account;
      case 'live_streaming':
        return l10n.liveStreamingIssues;
      case 'gaming':
        return l10n.gamingIssues;
      case 'partnership':
        return l10n.partnershipRelated;
      case 'other':
        return l10n.otherIssues;
      default:
        return categoryId;
    }
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
                    _getCategoryName(context, category.id),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
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








