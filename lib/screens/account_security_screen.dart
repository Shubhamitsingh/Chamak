import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'otp_screen.dart';
import 'kyc_verification_screen.dart';
import '../services/database_service.dart';

class AccountSecurityScreen extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  
  const AccountSecurityScreen({
    super.key,
    required this.phoneNumber,
    required this.userId,
  });

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
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
          AppLocalizations.of(context)!.accountSecurity,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSettingItem(
            title: AppLocalizations.of(context)!.id,
            value: widget.userId,
            onTap: () async {
              try {
                await Clipboard.setData(ClipboardData(text: widget.userId));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.idCopiedToClipboard),
                    backgroundColor: const Color(0xFF6C63FF),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                debugPrint('Error copying to clipboard: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.errorOccurred),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          
          _buildSettingItem(
            title: AppLocalizations.of(context)!.phoneNumber,
            value: widget.phoneNumber,
            onTap: () => _showUpdatePhoneDialog(),
          ),
          
          _buildSettingItem(
            title: AppLocalizations.of(context)!.kycVerification,
            onTap: () => _showKYCDialog(),
          ),
          
          _buildSettingItem(
            title: AppLocalizations.of(context)!.switchAccount,
            onTap: () => _showSwitchAccountDialog(),
          ),
          
          _buildSettingItem(
            title: AppLocalizations.of(context)!.deleteAccount,
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(),
          ),
          
          const SizedBox(height: 30),
          
          // Logout Button in centered container
          Center(
            child: GestureDetector(
              onTap: () => _showLogoutDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  Widget _buildSettingItem({
    required String title,
    String? value,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructive ? const Color.fromARGB(240, 240, 52, 38) : Colors.black87,
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  // ========== DIALOGS ==========
  void _showUpdatePhoneDialog() {
    final TextEditingController phoneController = TextEditingController();
    
    // Extract current country from phone number (default to India)
    Country currentCountry = Country.parse('IN');
    if (widget.phoneNumber.isNotEmpty) {
      // Try to detect country code from existing phone number
      // The phone number format should be like: +91XXXXXXXXXX
      String phoneNum = widget.phoneNumber.startsWith('+') 
          ? widget.phoneNumber.substring(1) 
          : widget.phoneNumber;
      
      // Common country codes to check
      final commonCountryCodes = {
        '91': 'IN',   // India
        '1': 'US',    // USA (also Canada)
        '44': 'GB',   // UK
        '61': 'AU',   // Australia
        '971': 'AE',  // UAE
        '65': 'SG',   // Singapore
        '60': 'MY',   // Malaysia
        '92': 'PK',   // Pakistan
        '880': 'BD',  // Bangladesh
      };
      
      // Try to match country code
      for (var entry in commonCountryCodes.entries) {
        if (phoneNum.startsWith(entry.key)) {
          try {
            currentCountry = Country.parse(entry.value);
            break;
          } catch (e) {
            debugPrint('Error parsing country: $e');
          }
        }
      }
    }
    
    if (!mounted) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _PhoneUpdateDialog(
            phoneController: phoneController,
            currentCountry: currentCountry,
            parentContext: context,
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing phone update dialog: $e');
    }
  }

  void _showKYCDialog() {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5FFF5)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF04B104).withValues(alpha:0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF04B104).withValues(alpha:0.1),
                            const Color(0xFF04B104).withValues(alpha:0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF04B104), Color(0xFF06D906), Color(0xFF04B104)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF04B104).withValues(alpha:0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.verified_user, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF04B104), Color(0xFF06D906)],
                          ).createShader(bounds),
                          child: Text(
                            AppLocalizations.of(context)!.kycVerification,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.completeKYCDescription,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildModernBenefitCard(
                          icon: Icons.security_rounded,
                          text: AppLocalizations.of(context)!.enhancedSecurity,
                          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
                        ),
                        const SizedBox(height: 8),
                        _buildModernBenefitCard(
                          icon: Icons.account_balance_wallet_rounded,
                          text: AppLocalizations.of(context)!.higherTransactionLimits,
                          gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFFD54F)]),
                        ),
                        const SizedBox(height: 8),
                        _buildModernBenefitCard(
                          icon: Icons.verified_rounded,
                          text: AppLocalizations.of(context)!.verifiedBadge,
                          gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  try {
                                    Navigator.pop(context);
                                  } catch (e) {
                                    debugPrint('Error closing KYC dialog: $e');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey[300]!, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF04B104), Color(0xFF06D906), Color(0xFF04B104)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF04B104).withValues(alpha:0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    try {
                                      Navigator.pop(context);
                                      // Navigate to KYC Verification Screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const KycVerificationScreen(),
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Error navigating to KYC screen: $e');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          AppLocalizations.of(context)!.startVerification,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      );
    } catch (e) {
      debugPrint('Error showing KYC dialog: $e');
    }
  }
  
  // Build modern benefit card with gradient
  Widget _buildModernBenefitCard({
    required IconData icon,
    required String text,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha:0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF04B104).withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 14,
              color: Color(0xFF04B104),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwitchAccountDialog() {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.switchAccountConfirmation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        try {
                          Navigator.pop(context);
                        } catch (e) {
                          debugPrint('Error closing switch account dialog: $e');
                        }
                      },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      try {
                        Navigator.pop(context);
                        FirebaseAuth.instance.signOut().then((_) {
                          try {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          } catch (e) {
                            debugPrint('Error navigating to login after sign out: $e');
                          }
                        }).catchError((e) {
                          debugPrint('Error signing out: $e');
                          try {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          } catch (navError) {
                            debugPrint('Error navigating to login: $navError');
                          }
                        });
                      } catch (e) {
                        debugPrint('Error in switch account: $e');
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.switchAccount,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      );
    } catch (e) {
      debugPrint('Error showing switch account dialog: $e');
    }
  }

  void _showDeleteAccountDialog() {
    if (!mounted) return;
    final TextEditingController confirmController = TextEditingController();
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Use dialogContext to avoid conflicts
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 400,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFFFF5F5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha:0.2),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400,
                            Colors.red.shade600,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha:0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.deleteAccount,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.typeDeleteToConfirm,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Clear and unfocus first
                              confirmController.clear();
                              FocusManager.instance.primaryFocus?.unfocus();
                              
                              // Use post-frame callback to ensure unfocus completes before closing
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                try {
                                  // Close dialog after unfocus is complete
                                  if (Navigator.canPop(dialogContext)) {
                                    Navigator.pop(dialogContext);
                                  }
                                  // Dispose controller after dialog is fully closed
                                  Future.delayed(const Duration(milliseconds: 400), () {
                                    try {
                                      confirmController.dispose();
                                    } catch (e) {
                                      // Ignore dispose errors - controller will be GC'd
                                      debugPrint('Controller dispose error (ignored): $e');
                                    }
                                  });
                                } catch (e) {
                                  debugPrint('Error closing dialog: $e');
                                  // Fallback: dispose after delay
                                  Future.delayed(const Duration(milliseconds: 400), () {
                                    try {
                                      confirmController.dispose();
                                    } catch (e2) {
                                      debugPrint('Fallback dispose error: $e2');
                                    }
                                  });
                                }
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey[300]!, width: 2),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha:0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (confirmController.text == 'DELETE') {
                                  try {
                                    Navigator.pop(dialogContext);
                                    confirmController.dispose();
                                    try {
                                      // Use the original context from the state
                                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                    } catch (e) {
                                      debugPrint('Error navigating to login after account deletion: $e');
                                    }
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(AppLocalizations.of(context)!.accountDeletedSuccessfully),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint('Error deleting account: $e');
                                    confirmController.dispose();
                                  }
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.pleaseTypeDeleteToConfirm),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                              child: Text(
                                AppLocalizations.of(context)!.confirm,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),
          ),
        );
        },
      );
    } catch (e) {
      debugPrint('Error showing delete account dialog: $e');
    }
  }

  void _showLogoutDialog() {
    if (!mounted) return;
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.logoutConfirmation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        try {
                          Navigator.pop(context);
                        } catch (e) {
                          debugPrint('Error closing logout dialog: $e');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        try {
                          Navigator.pop(context);
                          FirebaseAuth.instance.signOut().then((_) {
                            try {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            } catch (e) {
                              debugPrint('Error navigating to login after logout: $e');
                            }
                          }).catchError((e) {
                            debugPrint('Error signing out: $e');
                            try {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            } catch (navError) {
                              debugPrint('Error navigating to login: $navError');
                            }
                          });
                        } catch (e) {
                          debugPrint('Error in logout: $e');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.confirm,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF04B104),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing logout dialog: $e');
    }
  }
}

class _PhoneUpdateDialog extends StatefulWidget {
  final TextEditingController phoneController;
  final Country currentCountry;
  final BuildContext parentContext;
  
  const _PhoneUpdateDialog({
    required this.phoneController,
    required this.currentCountry,
    required this.parentContext,
  });
  
  @override
  State<_PhoneUpdateDialog> createState() => _PhoneUpdateDialogState();
}

class _PhoneUpdateDialogState extends State<_PhoneUpdateDialog> {
  late Country selectedCountry;
  
  @override
  void initState() {
    super.initState();
    selectedCountry = widget.currentCountry;
  }
  
  void _showCountryPicker() {
    if (!mounted) return;
    try {
      showCountryPicker(
        context: context,
        favorite: ['IN', 'US', 'GB', 'CA', 'AU', 'AE', 'SG', 'MY', 'PK', 'BD'],
        countryListTheme: CountryListThemeData(
          flagSize: 25,
          backgroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          searchTextStyle: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          inputDecoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.selectCountry,
            hintText: 'Start typing to search',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF9C27B0),
                width: 2,
              ),
            ),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        onSelect: (Country country) {
          if (!mounted) return;
          setState(() {
            selectedCountry = country;
          });
        },
      );
    } catch (e) {
      debugPrint('Error showing country picker: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  AppLocalizations.of(context)!.updatePhoneNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 15),
                
                // Description
                Text(
                  AppLocalizations.of(context)!.enterNewPhoneNumberDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 25),
                
                // Country Code Selector and Phone Input Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Country Code Selector
                      InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedCountry.flagEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${selectedCountry.phoneCode}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Phone Number Input
                      Expanded(
                        child: TextField(
                          controller: widget.phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterNewPhoneNumber,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          try {
                            Navigator.pop(context);
                            widget.phoneController.dispose();
                          } catch (e) {
                            debugPrint('Error closing phone update dialog: $e');
                            widget.phoneController.dispose();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 15),
                    
                    // Send OTP Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (widget.phoneController.text.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.pleaseEnterPhoneNumber),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          if (widget.phoneController.text.length < 10) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.pleaseEnterValidPhoneNumber),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // Get and clean the new phone number
                          // Clean phone number: remove spaces, dashes, and other non-digit characters
                          String newPhone = widget.phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
                          newPhone = newPhone.replaceAll(RegExp(r'[^\d]'), '');
                          
                          // Remove leading zero if present
                          while (newPhone.startsWith('0') && newPhone.length > 1) {
                            newPhone = newPhone.substring(1);
                          }
                          
                          // Validate cleaned number length
                          if (newPhone.length < 10) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.pleaseEnterValidPhoneNumber),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // E.164 format: +[country code][subscriber number]
                          final fullPhoneNumber = '+${selectedCountry.phoneCode}$newPhone';
                          
                          debugPrint('📱 Phone Update - E.164 Format: $fullPhoneNumber');
                          
                          // Get parent context reference
                          final parentContext = widget.parentContext;
                          
                          // Close dialog
                          try {
                            Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Error closing phone update dialog: $e');
                          }
                          
                          // Show loading indicator using parent context
                          if (parentContext.mounted) {
                            try {
                              showDialog(
                                context: parentContext,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF04B104),
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint('Error showing loading dialog: $e');
                            }
                          }
                          
                          try {
                            // Send OTP via Firebase
                            await FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: fullPhoneNumber,
                              verificationCompleted: (PhoneAuthCredential credential) async {
                                // Auto-verification (instant verification on some devices)
                                try {
                                  await FirebaseAuth.instance.signInWithCredential(credential);
                                  
                                  // Update phone number in database
                                  final dbService = DatabaseService();
                                  await dbService.updatePhoneNumber(
                                    phoneNumber: newPhone,
                                    countryCode: '+${selectedCountry.phoneCode}',
                                  );
                                  
                                  debugPrint('✅ Phone number auto-verified and updated in database');
                                } catch (e) {
                                  debugPrint('❌ Error in auto-verification: $e');
                                }
                                if (parentContext.mounted) {
                                  try {
                                    Navigator.pop(parentContext); // Close loading
                                  } catch (e) {
                                    debugPrint('Error closing loading dialog: $e');
                                  }
                                }
                              },
                              verificationFailed: (FirebaseAuthException e) {
                                if (parentContext.mounted) {
                                  try {
                                    Navigator.pop(parentContext); // Close loading
                                  } catch (navError) {
                                    debugPrint('Error closing loading dialog: $navError');
                                  }
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Verification failed: ${e.message ?? 'Unknown error'}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              },
                              codeSent: (String verificationId, int? resendToken) {
                                if (parentContext.mounted) {
                                  try {
                                    Navigator.pop(parentContext); // Close loading
                                  } catch (navError) {
                                    debugPrint('Error closing loading dialog: $navError');
                                  }
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(parentContext)!.otpSentToNewNumber),
                                      backgroundColor: const Color(0xFF04B104),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  
                                  // Navigate to OTP screen with verification ID
                                  try {
                                    Navigator.push(
                                      parentContext,
                                      MaterialPageRoute(
                                        builder: (context) => OtpScreen(
                                          phoneNumber: newPhone,
                                          countryCode: '+${selectedCountry.phoneCode}',
                                          verificationId: verificationId,
                                          resendToken: resendToken,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint('Error navigating to OTP screen: $e');
                                  }
                                }
                              },
                              codeAutoRetrievalTimeout: (String verificationId) {
                                // Auto-resolution timed out
                              },
                              timeout: const Duration(seconds: 60),
                            );
                          } catch (e) {
                            // Handle any unexpected errors
                            if (parentContext.mounted) {
                              try {
                                Navigator.pop(parentContext); // Close loading
                              } catch (navError) {
                                debugPrint('Error closing loading dialog: $navError');
                              }
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } finally {
                            // Dispose controller after all operations
                            widget.phoneController.dispose();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF04B104),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.sendOTP,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

