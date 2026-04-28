// PRISM golden-test harness.
// Wraps any widget in the full app shell (theme, locale, providers) so that
// each snapshot reflects exactly what users see in production.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vagus_app/services/settings/reduce_motion.dart';
import 'package:vagus_app/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Device surface — standard iPhone 14 Pro logical size.
// ---------------------------------------------------------------------------
const Size kGoldenSize = Size(390, 844);

// ---------------------------------------------------------------------------
// Locales under test.
// ---------------------------------------------------------------------------
const List<Locale> kGoldenLocales = [
  Locale('en'),
  Locale('ar'),
  Locale('ku'),
];

// ---------------------------------------------------------------------------
// One-time Supabase init for golden tests.
// Screens reference Supabase.instance.client at field-init time; without this
// they throw a StateError before the widget tree is built.
// ---------------------------------------------------------------------------
bool _supabaseReady = false;

Future<void> prismSetUp() async {
  if (_supabaseReady) return;
  HttpOverrides.global = _BlockNetworkHttpOverrides();
  try {
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9'
          '.CRFA0NiK7kyqd6rPRfCCrk4zFPSF0BjsYc8PJ9M2bBY',
      debug: false,
    );
  } catch (_) {
    // Already initialized from a previous test in the same run.
  }
  _supabaseReady = true;
}

// ---------------------------------------------------------------------------
// App shell widget.
// ---------------------------------------------------------------------------
class PrismTestApp extends StatelessWidget {
  const PrismTestApp({
    super.key,
    required this.child,
    this.locale = const Locale('en'),
  });

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReduceMotion()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('ku'),
        ],
        home: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Golden-test generator helper.
// Registers one testGoldens per locale for the given screen.
// ---------------------------------------------------------------------------
void screenGoldens(
  String name,
  Widget Function(String locale) builder,
) {
  for (final locale in kGoldenLocales) {
    final tag = locale.languageCode;
    testGoldens('$name [$tag]', (tester) async {
      await loadAppFonts();
      await prismSetUp();
      await tester.pumpWidgetBuilder(
        PrismTestApp(locale: locale, child: builder(tag)),
        surfaceSize: kGoldenSize,
      );
      // One extra pump gives initState async callbacks a chance to run
      // (screens show loading skeleton / spinner rather than blank frame).
      await tester.pump(const Duration(milliseconds: 50));
      await screenMatchesGolden(tester, '${name}_$tag');
    });
  }
}

// ---------------------------------------------------------------------------
// Placeholder for screens not yet implemented.
// Generates a minimal scaffold so that the golden infrastructure is in place
// and the golden file can be updated when the real screen lands.
// ---------------------------------------------------------------------------
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 48),
            const SizedBox(height: 16),
            Text('$title — coming soon',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blocks all outbound HTTP so Supabase requests fail fast instead of hanging.
// ---------------------------------------------------------------------------
class _BlockNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _BlockingHttpClient();
  }
}

class _BlockingHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  // --- remaining interface stubs (unused in tests) ---
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f) {}
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  set keyLog(Function(String line)? callback) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> headUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      Future.error(const SocketException('network blocked in golden tests'));

  @override
  Future<HttpClientRequest> putUrl(Uri url) =>
      Future.error(const SocketException('network blocked in golden tests'));
}
