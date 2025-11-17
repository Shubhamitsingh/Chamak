import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  /// Get color for each language
  Color _getLanguageColor(String languageCode) {
    switch (languageCode) {
      case 'en': // English
        return const Color(0xFF3B82F6); // Blue
      case 'hi': // Hindi
        return const Color(0xFFFF6B35); // Orange
      case 'ta': // Tamil
        return const Color(0xFF10B981); // Green
      case 'te': // Telugu
        return const Color(0xFF8B5CF6); // Purple
      case 'ml': // Malayalam
        return const Color(0xFFEF4444); // Red
      case 'mr': // Marathi
        return const Color(0xFFF59E0B); // Amber
      case 'ur': // Urdu
        return const Color(0xFF06B6D4); // Cyan
      case 'kn': // Kannada
        return const Color(0xFFEC4899); // Pink
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.selectLanguage,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
        itemCount: LanguageService.supportedLanguages.length,
        itemBuilder: (context, index) {
          final languageCode = LanguageService.supportedLanguages.keys.elementAt(index);
          final languageData = LanguageService.supportedLanguages[languageCode]!;
          final isSelected = currentLanguage == languageCode;

          final languageColor = _getLanguageColor(languageCode);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? languageColor.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? languageColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await languageProvider.changeLanguage(languageCode);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Language changed to ${languageData['name']}'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF04B104),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    // Pop back to settings
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Language Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? languageColor.withOpacity(0.2) 
                              : languageColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            languageData['nativeName']!.substring(0, 2).toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: languageColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Language Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              languageData['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? languageColor : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              languageData['nativeName']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: languageColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Selection Indicator
                      isSelected
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: languageColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

