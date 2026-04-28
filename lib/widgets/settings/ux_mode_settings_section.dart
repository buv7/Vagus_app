import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ux_mode_provider.dart';
import '../../services/ux/ux_mode_service.dart';

/// Settings card that lets the user override their UX mode.
/// Designed to fit inside the glassmorphic UserSettingsScreen cards.
class UxModeSettingsSection extends StatelessWidget {
  const UxModeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UxModeProvider>();
    if (!provider.isLoaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interface Complexity',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          provider.isOverridden
              ? 'Manual override active'
              : 'Auto (${provider.autoMode.label}) — based on ${_hoursLabel(provider)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...UxMode.values.map((mode) => _ModeTile(mode: mode, provider: provider)),
        if (provider.isOverridden) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => provider.setOverride(null),
            icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white70),
            label: const Text(
              'Reset to auto',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  String _hoursLabel(UxModeProvider provider) {
    // We can't easily await here in build, so show the auto mode tier name.
    switch (provider.autoMode) {
      case UxMode.simple:
        return '< 5 hours of use';
      case UxMode.default_:
        return '5–50 hours of use';
      case UxMode.insane:
        return '50 + hours of use';
    }
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.provider});

  final UxMode mode;
  final UxModeProvider provider;

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.mode == mode;
    final isOverriddenToThis = provider.overrideMode == mode;

    return Semantics(
      label: '${mode.label} mode: ${mode.description}',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () => provider.setOverride(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Icon(_icon(mode), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      mode.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  isOverriddenToThis ? Icons.check_circle : Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(UxMode mode) {
    switch (mode) {
      case UxMode.simple:
        return Icons.spa_outlined;
      case UxMode.default_:
        return Icons.tune;
      case UxMode.insane:
        return Icons.bolt;
    }
  }
}
