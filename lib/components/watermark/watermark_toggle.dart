import 'package:flutter/material.dart';

import '../../models/watermark/watermark_models.dart';
import '../../services/watermark/watermark_service.dart';

/// Toggle + template selector shown in share sheets and settings.
///
/// Free tier: shows the watermark preview locked, explains why it's mandatory.
/// Pro/Ultimate: shows a switch + 3 template options.
class WatermarkToggle extends StatefulWidget {
  const WatermarkToggle({super.key});

  @override
  State<WatermarkToggle> createState() => _WatermarkToggleState();
}

class _WatermarkToggleState extends State<WatermarkToggle> {
  final _svc = WatermarkService.instance;

  WatermarkPolicy? _policy;
  WatermarkSettings _settings = const WatermarkSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final policy = await _svc.policyForCurrentUser();
    final settings = await _svc.loadSettings();
    if (!mounted) return;
    setState(() {
      _policy = policy;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(WatermarkSettings next) async {
    setState(() => _settings = next);
    await _svc.saveSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final policy = _policy!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(policy: policy, settings: _settings, onToggle: _save),
        if (policy.canToggle && _settings.enabled) ...[
          const SizedBox(height: 16),
          _TemplateSelector(
            selected: _settings.template,
            onSelect: (t) => _save(_settings.copyWith(template: t)),
          ),
          const SizedBox(height: 12),
          _OpacitySlider(
            value: _settings.opacity,
            onChange: (v) => _save(_settings.copyWith(opacity: v)),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final WatermarkPolicy policy;
  final WatermarkSettings settings;
  final ValueChanged<WatermarkSettings> onToggle;

  const _Header({
    required this.policy,
    required this.settings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Watermark',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                policy.mandatory
                    ? 'Required on Free — upgrade to remove'
                    : '"Made with Vagus" on your shared content',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (policy.canToggle)
          Switch(
            value: settings.enabled,
            onChanged: (v) => onToggle(settings.copyWith(enabled: v)),
          )
        else
          Tooltip(
            message: 'Upgrade to Pro to remove',
            child: Icon(Icons.lock_outline,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  final WatermarkTemplate selected;
  final ValueChanged<WatermarkTemplate> onSelect;

  const _TemplateSelector({required this.selected, required this.onSelect});

  static const _labels = {
    WatermarkTemplate.minimal: 'Minimal',
    WatermarkTemplate.prominent: 'Prominent',
    WatermarkTemplate.brandFirst: 'Brand-first',
  };

  static const _subtitles = {
    WatermarkTemplate.minimal: 'Logo only',
    WatermarkTemplate.prominent: 'Logo + text',
    WatermarkTemplate.brandFirst: 'Logo + text + URL',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: WatermarkTemplate.values.map((t) {
            final isSelected = t == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        Text(_labels[t]!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text(_subtitles[t]!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OpacitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChange;

  const _OpacitySlider({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Opacity',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('${(value * 100).round()}%',
                style: theme.textTheme.labelSmall),
          ],
        ),
        Slider(
          value: value,
          min: 0.4,
          max: 1.0,
          divisions: 12,
          onChanged: onChange,
        ),
      ],
    );
  }
}

/// Compact badge for in-line share button previews (not the full settings sheet).
class WatermarkBadge extends StatelessWidget {
  const WatermarkBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Made with Vagus',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

/// Progress UI shown during video watermarking (displayed in the share sheet).
class VideoWatermarkProgress extends StatelessWidget {
  final double progress;
  final VoidCallback? onCancel;

  const VideoWatermarkProgress({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Adding watermark… $pct%',
                  style: theme.textTheme.bodySmall),
            ),
            if (onCancel != null)
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
