import 'dart:typed_data';

abstract class ProviderClient {
  String get providerId;

  Future<String> complete(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  });

  Stream<String> stream(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? options,
  });

  Future<String> vision(Uint8List imageBytes, String prompt);

  Future<List<double>> embed(String input);
}

class ProviderQuotaExceededException implements Exception {
  const ProviderQuotaExceededException(this.provider);

  final String provider;

  @override
  String toString() => 'ProviderQuotaExceededException: $provider daily limit reached';
}
