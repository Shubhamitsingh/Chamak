import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  // Mock data - Replace with real data from Firebase
  final int currentWarnings = 0;
  final int maxWarnings = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.warningForPermanentBlock,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Warning Counter Card
            _buildWarningCounter(),
            
            const SizedBox(height: 30),
            
            // Rules Section
            _buildRulesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCounter() {
    final double progress = currentWarnings / maxWarnings;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentWarnings == 0
                        ? Colors.green
                        : currentWarnings < 3
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${currentWarnings.toString().padLeft(2, '0')}/${maxWarnings.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: currentWarnings == 0
                          ? Colors.green
                          : currentWarnings < 3
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.currentWarnings,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Warning Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: currentWarnings == 0
                  ? Colors.green.withOpacity(0.1)
                  : currentWarnings < 3
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentWarnings == 0
                    ? Colors.green.withOpacity(0.3)
                    : currentWarnings < 3
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentWarnings == 0
                      ? Icons.check_circle
                      : currentWarnings < 3
                          ? Icons.info
                          : Icons.warning,
                  color: currentWarnings == 0
                      ? Colors.green
                      : currentWarnings < 3
                          ? Colors.orange
                          : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentWarnings == 0
                        ? AppLocalizations.of(context)!.greatNoWarnings
                        : currentWarnings < 3
                            ? AppLocalizations.of(context)!.followCommunityGuidelines
                            : AppLocalizations.of(context)!.riskOfPermanentBlock,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: currentWarnings == 0
                          ? Colors.green[700]
                          : currentWarnings < 3
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.toAvoidWarnings,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Rules List
          _buildRuleItem(
            number: '01',
            title: AppLocalizations.of(context)!.rule01Hindi,
            subtitle: AppLocalizations.of(context)!.rule01English,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          _buildRuleItem(
            number: '02',
            title: AppLocalizations.of(context)!.rule02Hindi,
            subtitle: AppLocalizations.of(context)!.rule02English,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          _buildRuleItem(
            number: '03',
            title: AppLocalizations.of(context)!.rule03Hindi,
            subtitle: AppLocalizations.of(context)!.rule03English,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
          _buildRuleItem(
            number: '04',
            title: AppLocalizations.of(context)!.rule04Hindi,
            subtitle: AppLocalizations.of(context)!.rule04English,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

