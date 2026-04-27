// Single chokepoint between caller code and the URL of a stored media object.
//
// Today (v1): passthrough to Supabase Storage `getPublicUrl`.
// Tomorrow  : redirect to ImageKit / Cloudflare R2 / Bunny CDN by editing
// this one file. Every caller already routes through `resolveMediaUrl()`,
// so the swap is a one-place change with no caller refactor.
//
// SWAP PROCEDURE — moving from Supabase passthrough to a CDN
// ----------------------------------------------------------
//   1. Provision the CDN to read from the same Supabase Storage origin.
//      ImageKit and Bunny both support arbitrary HTTP origins; for R2,
//      mirror the bucket via S3-compatible sync (rclone) or a pull-zone.
//
//   2. At build time, set MEDIA_CDN_BASE via `--dart-define`. Example:
//        flutter build apk --dart-define=MEDIA_CDN_BASE=https://cdn.vagus.app
//      An empty string disables the CDN and the resolver falls back to
//      Supabase — i.e. you can ship the swap as an opt-in flag, then flip
//      the default once the CDN is warm.
//
//   3. Implement / extend `_buildCdnUrl` below for the chosen vendor's
//      transform query string (ImageKit: `?tr=w-800,q-80`; Bunny: `?width=800`).
//      The current implementation uses ImageKit conventions as a placeholder.
//
//   4. No caller changes. Every callsite already imports this file.

import 'package:supabase_flutter/supabase_flutter.dart';

const String _kCdnBase = String.fromEnvironment('MEDIA_CDN_BASE');

/// Returns a URL for a stored media object.
///
/// `bucket` and `path` identify the object in Supabase Storage (the same
/// arguments you would pass to `supabase.storage.from(bucket).getPublicUrl(path)`).
///
/// `transform` requests an on-the-fly resize/format conversion. Honoured only
/// when a CDN is configured — the Supabase passthrough silently ignores it.
String resolveMediaUrl({
  required String bucket,
  required String path,
  bool transform = false,
}) {
  if (path.isEmpty) {
    throw ArgumentError.value(path, 'path', 'must not be empty');
  }
  if (bucket.isEmpty) {
    throw ArgumentError.value(bucket, 'bucket', 'must not be empty');
  }
  if (isAbsoluteMediaUrl(path)) return path;
  if (_kCdnBase.isNotEmpty) {
    return _buildCdnUrl(bucket: bucket, path: path, transform: transform);
  }
  return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
}

/// True if `s` is already a fully-qualified URL — used for avatar / image
/// columns that historically stored a full URL instead of a storage key.
bool isAbsoluteMediaUrl(String s) =>
    s.startsWith('http://') || s.startsWith('https://');

/// Build the CDN URL. v1.1 swap target — see SWAP PROCEDURE above.
///
/// Default implementation: `<MEDIA_CDN_BASE>/<bucket>/<path>[?tr=w-800,q-80]`,
/// which works as-is for ImageKit configured with a pull-zone pointing at
/// the Supabase Storage origin.
String _buildCdnUrl({
  required String bucket,
  required String path,
  required bool transform,
}) {
  final base = _stripTrailingSlash(_kCdnBase);
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  final query = transform ? '?tr=w-800,q-80' : '';
  return '$base/$bucket/$cleanPath$query';
}

String _stripTrailingSlash(String s) =>
    s.endsWith('/') ? s.substring(0, s.length - 1) : s;
