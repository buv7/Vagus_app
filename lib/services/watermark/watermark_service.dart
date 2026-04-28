import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min/return_code.dart';

import '../../models/watermark/watermark_models.dart';
import '../subscription/tier_service.dart';

// Storage buckets — these must be created in Supabase with appropriate RLS.
const _kOriginalsBucket = 'media-originals';
const _kWatermarkedBucket = 'media-watermarked';

// Max fraction of media area the watermark may occupy (hard rule).
const _kMaxAreaFraction = 0.15;

// Logo width as a fraction of the media width.
const _kLogoWidthFraction = 0.10;

class WatermarkService {
  WatermarkService._();
  static final WatermarkService instance = WatermarkService._();

  SupabaseClient get _db => Supabase.instance.client;
  final _tier = TierService.instance;

  // ─── Policy ────────────────────────────────────────────────────────────────

  Future<WatermarkPolicy> policyForCurrentUser() async {
    final tier = await _tier.currentTier();
    return WatermarkPolicy.forTier(tier);
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  Future<WatermarkSettings> loadSettings() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return WatermarkSettings.defaultFree;

      final row = await _db
          .from('watermark_settings')
          .select('enabled, template, opacity')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row == null) return WatermarkSettings.defaultPaid;
      return WatermarkSettings.fromJson(row);
    } catch (e) {
      debugPrint('WatermarkService.loadSettings: $e');
      return WatermarkSettings.defaultPaid;
    }
  }

  Future<void> saveSettings(WatermarkSettings settings) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;

      // Server-side RLS prevents free users from disabling — but we also
      // guard client-side so the UI reflects the correct state immediately.
      final policy = await policyForCurrentUser();
      final effectiveEnabled =
          policy.mandatory ? true : settings.enabled;

      await _db.from('watermark_settings').upsert({
        'user_id': user.id,
        'enabled': effectiveEnabled,
        'template': settings.template.name,
        'opacity': settings.opacity.clamp(0.4, 1.0),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WatermarkService.saveSettings: $e');
    }
  }

  // ─── Render spec resolution ─────────────────────────────────────────────────

  Future<WatermarkRenderSpec> resolveSpec() async {
    final policy = await policyForCurrentUser();
    final settings = await loadSettings();

    final apply = policy.mandatory || settings.enabled;
    return WatermarkRenderSpec(
      apply: apply,
      template: settings.template,
      opacity: settings.opacity.clamp(0.4, 1.0),
    );
  }

  // ─── Image watermarking ────────────────────────────────────────────────────

  /// Stamps [inputPath] with the watermark defined by [spec] and returns the
  /// output path.  The original is preserved; a new file is written to the
  /// system temp directory.
  Future<String> stampImage(
    String inputPath,
    WatermarkRenderSpec spec,
  ) async {
    if (!spec.apply) return inputPath;

    final bytes = await File(inputPath).readAsBytes();
    final base = img.decodeImage(bytes);
    if (base == null) throw Exception('Cannot decode image: $inputPath');

    final stamped = await _compositeWatermark(base, spec);

    final tmpDir = await getTemporaryDirectory();
    final outPath =
        '${tmpDir.path}/wm_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(stamped, quality: 92));
    return outPath;
  }

  // ─── Image storage ─────────────────────────────────────────────────────────

  /// Uploads both the original and the watermarked versions to Supabase
  /// Storage.  Returns `{ 'original': url, 'watermarked': url }`.
  Future<Map<String, String>> uploadWithWatermark(
    String localPath, {
    required String fileName,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final spec = await resolveSpec();

    // 1. Upload original (always preserved).
    final originalKey = '${user.id}/$fileName';
    await _db.storage
        .from(_kOriginalsBucket)
        .upload(originalKey, File(localPath));
    final originalUrl =
        _db.storage.from(_kOriginalsBucket).getPublicUrl(originalKey);

    // 2. Upload watermarked version.
    final wmPath = await stampImage(localPath, spec);
    final wmKey = '${user.id}/${_withSuffix(fileName, '_wm')}';
    await _db.storage
        .from(_kWatermarkedBucket)
        .upload(wmKey, File(wmPath));
    final wmUrl =
        _db.storage.from(_kWatermarkedBucket).getPublicUrl(wmKey);

    return {'original': originalUrl, 'watermarked': wmUrl};
  }

  // ─── Video watermarking ────────────────────────────────────────────────────

  /// Stamps [inputPath] on the first and last 3 seconds using FFmpeg (min/LGPL-2.1
  /// build).  Progress 0.0–1.0 is reported via [onProgress].
  ///
  /// Runs in a background isolate so the UI stays responsive.
  /// Expected to complete in <30 s for a 1-minute clip on a modern device.
  Future<String> stampVideo(
    String inputPath,
    WatermarkRenderSpec spec, {
    void Function(double progress)? onProgress,
  }) async {
    if (!spec.apply) return inputPath;

    final tmpDir = await getTemporaryDirectory();
    final outPath =
        '${tmpDir.path}/wm_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Write watermark PNG to a temp file so FFmpeg can read it.
    final logoBytes = await _logoBytes(spec.template, spec.opacity);
    final logoPath = '${tmpDir.path}/wm_logo_tmp.png';
    await File(logoPath).writeAsBytes(logoBytes);

    // Probe duration + video width.
    final (durationSec, videoWidth) = await _probeVideo(inputPath);
    final logoW = (videoWidth * _kLogoWidthFraction).round().clamp(24, 400);
    final durMinus3 = (durationSec - 3.0).clamp(3.0, durationSec);

    final enableExpr =
        'lte(t,3)+gte(t,$durMinus3)';

    final command = [
      '-i', inputPath,
      '-i', logoPath,
      '-filter_complex',
      '[1:v]scale=$logoW:-1,format=rgba[wm];'
          '[0:v][wm]overlay=W-w-8:H-h-8:enable=\'$enableExpr\'[out]',
      '-map', '[out]',
      '-map', '0:a?',
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-crf', '23',
      '-c:a', 'copy',
      '-y', outPath,
    ].join(' ');

    final durationMs = (durationSec * 1000).round();

    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final rc = await session.getReturnCode();
        if (!ReturnCode.isSuccess(rc)) {
          final logs = await session.getLogsAsString();
          throw Exception('FFmpeg failed: $logs');
        }
      },
      null,
      (statistics) {
        if (durationMs > 0) {
          onProgress?.call(
              (statistics.getTime() / durationMs).clamp(0.0, 1.0));
        }
      },
    );

    return outPath;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<img.Image> _compositeWatermark(
    img.Image base,
    WatermarkRenderSpec spec,
  ) async {
    final mediaArea = base.width * base.height;
    var logoW =
        (base.width * _kLogoWidthFraction).round().clamp(16, base.width ~/ 2);

    // Enforce the 15% area cap.
    while (logoW * logoW > mediaArea * _kMaxAreaFraction && logoW > 16) {
      logoW = (logoW * 0.9).round();
    }

    // Load + resize logo.
    final logoRaw = await _decodeLogo();
    var logo = img.copyResize(logoRaw, width: logoW);
    logo = _applyOpacity(logo, spec.opacity);

    // x/y: bottom-right, 8px padding.
    final composited = base.clone();
    final x = base.width - logo.width - 8;
    final y = base.height - logo.height - 8;

    // Add text for prominent / brand-first templates.
    if (spec.template == WatermarkTemplate.prominent ||
        spec.template == WatermarkTemplate.brandFirst) {
      final textY = y - 18;
      if (textY > 0) {
        img.drawString(
          composited,
          'Made with Vagus',
          font: img.arial14,
          x: x,
          y: textY,
          color: img.ColorRgba8(255, 255, 255,
              (255 * spec.opacity).round()),
        );
      }
      if (spec.template == WatermarkTemplate.brandFirst) {
        final subY = y - 32;
        if (subY > 0) {
          img.drawString(
            composited,
            'vagus.app',
            font: img.arial14,
            x: x + logo.width + 4,
            y: subY,
            color: img.ColorRgba8(200, 200, 200,
                (255 * spec.opacity).round()),
          );
        }
      }
    }

    img.compositeImage(composited, logo, dstX: x, dstY: y);
    return composited;
  }

  Future<img.Image> _decodeLogo() async {
    final data =
        await rootBundle.load('assets/branding/vagus_logo_white.png');
    final decoded = img.decodeImage(data.buffer.asUint8List());
    if (decoded == null) throw Exception('Failed to decode Vagus logo');
    return decoded;
  }

  img.Image _applyOpacity(img.Image src, double opacity) {
    final result = src.clone();
    for (final pixel in result) {
      pixel.a = (pixel.a * opacity).round();
    }
    return result;
  }

  // Returns raw PNG bytes for the watermark logo at [opacity], sized for FFmpeg
  // use (not scaled — FFmpeg will scale via the filter).
  Future<Uint8List> _logoBytes(
      WatermarkTemplate template, double opacity) async {
    final raw = await _decodeLogo();
    final withOpacity = _applyOpacity(raw, opacity);
    return Uint8List.fromList(img.encodePng(withOpacity));
  }

  Future<(double duration, int width)> _probeVideo(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      final dur = double.tryParse(info?.getDuration() ?? '') ?? 60.0;
      final streams = info?.getStreams() ?? [];
      for (final s in streams) {
        final w = s.getWidth();
        if (w != null && w > 0) return (dur, w);
      }
      return (dur, 1280);
    } catch (_) {
      return (60.0, 1280);
    }
  }

  String _withSuffix(String fileName, String suffix) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return '$fileName$suffix';
    return '${fileName.substring(0, dot)}$suffix${fileName.substring(dot)}';
  }
}
