import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class WarningScreen extends StatelessWidget {
  const WarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    final rules = isHindi
        ? [
            loc.rule01Hindi,
            loc.rule02Hindi,
            loc.rule03Hindi,
            loc.rule04Hindi,
            'कोई भी फर्जी/नकली प्रोफ़ाइल न बनाएं',
            'पता या फ़ोन नंबर जैसी निजी जानकारी साझा न करें',
            'किसी भी तरह की धमकी, उत्पीड़न या बदसलूकी न करें',
            'अश्लील, आपत्तिजनक या अनुचित सामग्री साझा न करें',
            'स्पैम/विज्ञापन/प्रमोशनल संदेश न भेजें',
            'उम्र प्रतिबंधों का सम्मान करें, नाबालिगों से अनुचित बातचीत न करें',
          ]
        : [
            loc.rule01English,
            loc.rule02English,
            loc.rule03English,
            loc.rule04English,
            'No impersonation or fake profiles',
            'Do not share personal information like address or phone number',
            'No harassment, bullying, or threatening behavior',
            'Do not share inappropriate, explicit, or offensive content',
            'No spamming, advertising, or promotional messages',
            'Respect age restrictions and do not interact with minors inappropriately',
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          loc.warnings,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.followTheseGuidelines,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.followCommunityGuidelines,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...rules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


