import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  final void Function(Locale) onLanguageSelected;

  const LanguagePage({super.key, required this.onLanguageSelected});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  Locale? _selectedLocale;

  final List<Map<String, dynamic>> languages = [
    {'name': 'English', 'locale': const Locale('en'), 'flag': '🇬🇧'},
    {'name': 'हिन्दी (Hindi)', 'locale': const Locale('hi'), 'flag': '🇮🇳'},
    {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'locale': const Locale('pa'), 'flag': '🇮🇳'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Safe to access Localizations here
    _selectedLocale ??= Localizations.localeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        title: const Text(
          'Select Language',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected =
                      _selectedLocale?.languageCode ==
                      (lang['locale'] as Locale).languageCode;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Text(
                        lang['flag'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        lang['name'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? primaryColor : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_off_outlined,
                        color: isSelected ? primaryColor : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLocale = lang['locale'] as Locale;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: _selectedLocale == null
                  ? null
                  : () {
                      widget.onLanguageSelected(_selectedLocale!);
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
