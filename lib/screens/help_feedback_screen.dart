import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'contact_support_screen.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen>
    with SingleTickerProviderStateMixin {
  int? _expandedIndex;
  
  // FAQ Data Structure
  List<Map<String, String>> _getFaqData(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      {
        'question': localizations.faqUpdateProfile,
        'answer': localizations.faqUpdateProfileAnswer,
      },
      {
        'question': localizations.faqRechargeWallet,
        'answer': localizations.faqRechargeWalletAnswer,
      },
      {
        'question': localizations.faqSendMessages,
        'answer': localizations.faqSendMessagesAnswer,
      },
      {
        'question': localizations.faqFollowers,
        'answer': localizations.faqFollowersAnswer,
      },
      {
        'question': localizations.faqLevelSystem,
        'answer': localizations.faqLevelSystemAnswer,
      },
      {
        'question': localizations.faqChangePhone,
        'answer': localizations.faqChangePhoneAnswer,
      },
      {
        'question': localizations.faqWithdrawEarnings,
        'answer': localizations.faqWithdrawEarningsAnswer,
      },
      {
        'question': localizations.faqDeleteAccount,
        'answer': localizations.faqDeleteAccountAnswer,
      },
      {
        'question': localizations.faqEnableNotifications,
        'answer': localizations.faqEnableNotificationsAnswer,
      },
      {
        'question': localizations.faqAppNotWorking,
        'answer': localizations.faqAppNotWorkingAnswer,
      },
    ];
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
            const SizedBox(height: 16),

            // Header Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha:0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.hereToHelp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.findAnswersCommon,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                  
                  // FAQ Items
                  ...(_getFaqData(context).asMap().entries.map((entry) {
                    final index = entry.key;
                    final faq = entry.value;
                    final isExpanded = _expandedIndex == index;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpanded 
                              ? const Color(0xFF6366F1).withValues(alpha:0.3)
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            // Question
                            InkWell(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  _expandedIndex = isExpanded ? null : index;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha:0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.help_outline,
                                        color: Color(0xFF6366F1),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        faq['question']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey[600],
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Answer (Expandable with Animation)
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha:0.03),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6366F1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        faq['answer']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: isExpanded 
                                  ? CrossFadeState.showSecond 
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                              sizeCurve: Curves.easeInOut,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Still Need Help Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF04B104).withValues(alpha:0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF04B104).withValues(alpha:0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF04B104),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.stillNeedHelp,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.supportTeamHereForYou,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.contactSupport,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF04B104),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
}

