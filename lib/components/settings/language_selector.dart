import 'package:flutter/material.dart';
import '../../services/settings/settings_controller.dart';

class LanguageSelector extends StatelessWidget {
  final SettingsController settingsController;

  const LanguageSelector({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        final isRTL = settingsController.locale.languageCode == 'ar';
        
        Widget content = Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('English'),
              selected: settingsController.locale.languageCode == 'en',
              onSelected: (selected) {
                if (selected) {
                  settingsController.setLanguage(const Locale('en'));
                }
              },
            ),
            ChoiceChip(
              label: const Text('العربية'),
              selected: settingsController.locale.languageCode == 'ar',
              onSelected: (selected) {
                if (selected) {
                  settingsController.setLanguage(const Locale('ar'));
                }
              },
            ),
            ChoiceChip(
              label: const Text('کوردی'),
              selected: settingsController.locale.languageCode == 'ku',
              onSelected: (selected) {
                if (selected) {
                  settingsController.setLanguage(const Locale('ku'));
                }
              },
            ),
          ],
        );

        // Wrap in RTL directionality for Arabic
        if (isRTL) {
          content = Directionality(
            textDirection: TextDirection.rtl,
            child: content,
          );
        }

        return content;
      },
    );
  }
}
