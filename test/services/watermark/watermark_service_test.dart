import 'package:flutter_test/flutter_test.dart';

import 'package:vagus_app/models/watermark/watermark_models.dart';
import 'package:vagus_app/models/subscription/tier.dart';

void main() {
  // ── WatermarkSettings serialisation ──────────────────────────────────────

  group('WatermarkSettings', () {
    test('round-trips through JSON', () {
      const orig = WatermarkSettings(
        enabled: false,
        template: WatermarkTemplate.prominent,
        opacity: 0.6,
      );
      final decoded = WatermarkSettings.fromJson(orig.toJson());
      expect(decoded.enabled, orig.enabled);
      expect(decoded.template, orig.template);
      expect(decoded.opacity, orig.opacity);
    });

    test('fromJson falls back to defaults for missing keys', () {
      final decoded = WatermarkSettings.fromJson({});
      expect(decoded.enabled, isTrue);
      expect(decoded.template, WatermarkTemplate.minimal);
      expect(decoded.opacity, 0.7);
    });

    test('fromJson falls back to minimal for unknown template name', () {
      final decoded =
          WatermarkSettings.fromJson({'template': 'nonexistent'});
      expect(decoded.template, WatermarkTemplate.minimal);
    });
  });

  // ── WatermarkPolicy ───────────────────────────────────────────────────────

  group('WatermarkPolicy.forTier', () {
    test('free → mandatory=true, canToggle=false', () {
      final p = WatermarkPolicy.forTier(Tier.free);
      expect(p.mandatory, isTrue);
      expect(p.canToggle, isFalse);
      expect(p.watermarkRequired, isTrue);
    });

    test('pro → mandatory=false, canToggle=true', () {
      final p = WatermarkPolicy.forTier(Tier.pro);
      expect(p.mandatory, isFalse);
      expect(p.canToggle, isTrue);
    });

    test('ultimate → mandatory=false, canToggle=true', () {
      final p = WatermarkPolicy.forTier(Tier.ultimate);
      expect(p.mandatory, isFalse);
      expect(p.canToggle, isTrue);
    });
  });

  // ── WatermarkRenderSpec ───────────────────────────────────────────────────

  group('WatermarkRenderSpec', () {
    test('maxAreaFraction defaults to 0.15', () {
      const spec = WatermarkRenderSpec(
        apply: true,
        template: WatermarkTemplate.minimal,
        opacity: 0.7,
      );
      expect(spec.maxAreaFraction, 0.15);
    });

    test('apply=false short-circuits — no watermark needed', () {
      const spec = WatermarkRenderSpec(
        apply: false,
        template: WatermarkTemplate.prominent,
        opacity: 1.0,
      );
      expect(spec.apply, isFalse);
    });
  });

  // ── Area-cap arithmetic ───────────────────────────────────────────────────

  group('Watermark area cap', () {
    // The service targets 10% of image width for the logo.
    // Even at extreme aspect ratios the logo must remain below 15% of area.
    void checkCap(int imageW, int imageH) {
      final logoW = (imageW * 0.10).round().clamp(16, imageW ~/ 2);
      final logoH = logoW; // worst-case: square logo
      final area = imageW * imageH;
      final logoArea = logoW * logoH;
      expect(
        logoArea / area,
        lessThan(0.15),
        reason:
            'Logo ($logoW×$logoH) exceeds 15% of ${imageW}×$imageH image',
      );
    }

    test('1920×1080 (Full HD)', () => checkCap(1920, 1080));
    test('720×480 (SD)', () => checkCap(720, 480));
    test('1080×1920 (portrait)', () => checkCap(1080, 1920));
    test('200×200 (thumbnail)', () => checkCap(200, 200));
    test('4000×3000 (camera)', () => checkCap(4000, 3000));
  });
}
