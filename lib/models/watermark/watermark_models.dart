import '../../services/subscription/tier_service.dart';

enum WatermarkTemplate {
  minimal,    // logo only, subtle
  prominent,  // logo + "Made with Vagus" text
  brandFirst, // logo + "Made with Vagus" + "vagus.app"
}

class WatermarkSettings {
  final bool enabled;
  final WatermarkTemplate template;
  // 0.0–1.0; enforced floor of 0.4 for free tier even if persisted lower
  final double opacity;

  const WatermarkSettings({
    this.enabled = true,
    this.template = WatermarkTemplate.minimal,
    this.opacity = 0.7,
  });

  WatermarkSettings copyWith({
    bool? enabled,
    WatermarkTemplate? template,
    double? opacity,
  }) =>
      WatermarkSettings(
        enabled: enabled ?? this.enabled,
        template: template ?? this.template,
        opacity: opacity ?? this.opacity,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'template': template.name,
        'opacity': opacity,
      };

  factory WatermarkSettings.fromJson(Map<String, dynamic> json) =>
      WatermarkSettings(
        enabled: json['enabled'] as bool? ?? true,
        template: WatermarkTemplate.values.firstWhere(
          (t) => t.name == (json['template'] as String?),
          orElse: () => WatermarkTemplate.minimal,
        ),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 0.7,
      );

  static const WatermarkSettings defaultFree = WatermarkSettings(
    enabled: true,
    template: WatermarkTemplate.minimal,
    opacity: 0.7,
  );

  static const WatermarkSettings defaultPaid = WatermarkSettings(
    enabled: true,
    template: WatermarkTemplate.minimal,
    opacity: 0.7,
  );
}

/// Computed policy for a user — callers should ask the service for this rather
/// than branching on [UserTier] directly.
class WatermarkPolicy {
  final bool mandatory;
  final bool canToggle;
  final UserTier tier;

  const WatermarkPolicy({
    required this.mandatory,
    required this.canToggle,
    required this.tier,
  });

  factory WatermarkPolicy.forTier(UserTier tier) => WatermarkPolicy(
        mandatory: tier == UserTier.free,
        canToggle: tier != UserTier.free,
        tier: tier,
      );

  bool get watermarkRequired => mandatory;
}

/// Lightweight description of a watermark render for the UI preview and
/// the image/video stamping code.  The service resolves this from
/// [WatermarkSettings] + [WatermarkPolicy].
class WatermarkRenderSpec {
  final bool apply;
  final WatermarkTemplate template;
  final double opacity;
  // Resolved at render time from the media dimensions
  final double maxAreaFraction; // hard cap: 0.15

  const WatermarkRenderSpec({
    required this.apply,
    required this.template,
    required this.opacity,
    this.maxAreaFraction = 0.15,
  });
}
