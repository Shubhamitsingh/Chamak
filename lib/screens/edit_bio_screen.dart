import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

/// Full-screen editor for user's bio (no popup). Max 150 words.
class EditBioScreen extends StatefulWidget {
  final String initialBio;
  static const int maxWords = 150;

  const EditBioScreen({
    super.key,
    required this.initialBio,
  });

  @override
  State<EditBioScreen> createState() => _EditBioScreenState();
}

class _EditBioScreenState extends State<EditBioScreen> {
  late final TextEditingController _controller;

  static int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  static String _truncateToWords(String text, int maxWords) {
    if (_wordCount(text) <= maxWords) return text;
    final words = text.trim().split(RegExp(r'\s+'));
    return words.take(maxWords).join(' ');
  }

  @override
  void initState() {
    super.initState();
    final initial = _truncateToWords(widget.initialBio, EditBioScreen.maxWords);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.bio,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 159,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (_wordCount(newValue.text) <= EditBioScreen.maxWords) {
                        return newValue;
                      }
                      final truncated = _truncateToWords(newValue.text, EditBioScreen.maxWords);
                      return TextEditingValue(
                        text: truncated,
                        selection: TextSelection.collapsed(offset: truncated.length),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.tellUsAboutYourself,
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '${_wordCount(_controller.text)} / ${EditBioScreen.maxWords} ${AppLocalizations.of(context)!.words}',
                    counterStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1B7C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(260, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
