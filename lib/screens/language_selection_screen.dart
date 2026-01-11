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
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        itemCount: LanguageService.supportedLanguages.length,
        itemBuilder: (context, index) {
          final languageCode = LanguageService.supportedLanguages.keys.elementAt(index);
          final languageData = LanguageService.supportedLanguages[languageCode]!;
          final isSelected = currentLanguage == languageCode;
          final accent = _getLanguageColor(languageCode);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Text(
                languageData['nativeName']!.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            title: Text(
              languageData['nativeName']!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              languageData['name']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: accent, size: 20)
                : const Icon(Icons.radio_button_unchecked, size: 18, color: Colors.grey),
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
                Navigator.pop(context);
              }
            },
          );
        },
      ),
    );
  }
}

