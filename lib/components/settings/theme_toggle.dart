import 'package:flutter/material.dart';
import '../../services/settings/settings_controller.dart';

class ThemeToggle extends StatelessWidget {
  final SettingsController settingsController;

  const ThemeToggle({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        return Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('System'),
              selected: settingsController.themeMode == ThemeMode.system,
              onSelected: (selected) {
                if (selected) {
                  settingsController.setThemeMode(ThemeMode.system);
                }
              },
            ),
            ChoiceChip(
              label: const Text('Light'),
              selected: settingsController.themeMode == ThemeMode.light,
              onSelected: (selected) {
                if (selected) {
                  settingsController.setThemeMode(ThemeMode.light);
                }
              },
            ),
            ChoiceChip(
              label: const Text('Dark'),
              selected: settingsController.themeMode == ThemeMode.dark,
              onSelected: (selected) {
                if (selected) {
                  settingsController.setThemeMode(ThemeMode.dark);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
