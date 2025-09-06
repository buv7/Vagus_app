// lib/models/nutrition/money_compat.dart
import 'money.dart';

extension MoneyFormatCompat on Money {
  /// Graceful fallback if callers use `.format()`.
  String format({String? locale}) => toString();
}
