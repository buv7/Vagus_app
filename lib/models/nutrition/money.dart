import 'dart:math';

/// Immutable Money class for handling currency amounts with safe rounding
class Money {
  final double amount;
  final String currency;

  const Money(this.amount, this.currency);

  /// Create Money from cents (useful for database storage)
  factory Money.fromCents(int cents, String currency) {
    return Money(cents / 100.0, currency);
  }

  /// Convert to cents (useful for database storage)
  int toCents() {
    return (amount * 100).round();
  }

  /// Add two Money amounts (must be same currency)
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies: $currency + ${other.currency}');
    }
    return Money(_safeRound(amount + other.amount), currency);
  }

  /// Subtract two Money amounts (must be same currency)
  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot subtract different currencies: $currency - ${other.currency}');
    }
    return Money(_safeRound(amount - other.amount), currency);
  }

  /// Multiply Money by a scalar
  Money operator *(double multiplier) {
    return Money(_safeRound(amount * multiplier), currency);
  }

  /// Divide Money by a scalar
  Money operator /(double divisor) {
    if (divisor == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Money(_safeRound(amount / divisor), currency);
  }

  /// Check if this Money is greater than another
  bool operator >(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare different currencies: $currency vs ${other.currency}');
    }
    return amount > other.amount;
  }

  /// Check if this Money is less than another
  bool operator <(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare different currencies: $currency vs ${other.currency}');
    }
    return amount < other.amount;
  }

  /// Check if this Money is greater than or equal to another
  bool operator >=(Money other) {
    return this > other || this == other;
  }

  /// Check if this Money is less than or equal to another
  bool operator <=(Money other) {
    return this < other || this == other;
  }

  /// Check if this Money is zero
  bool get isZero => amount == 0.0;

  /// Check if this Money is positive
  bool get isPositive => amount > 0.0;

  /// Check if this Money is negative
  bool get isNegative => amount < 0.0;

  /// Get absolute value
  Money abs() {
    return Money(amount.abs(), currency);
  }

  /// Get negative value
  Money negate() {
    return Money(-amount, currency);
  }

  /// Format as short string (e.g., "$2.10", "€1.50")
  String toStringShort() {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format as full string with currency code
  String toStringFull() {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// Format for display in UI (respects locale)
  String toStringDisplay({String? locale}) {
    final symbol = _getCurrencySymbol(currency);
    final formattedAmount = amount.toStringAsFixed(2);
    
    // For RTL languages, put currency symbol after amount
    if (locale != null && _isRTLLocale(locale)) {
      return '$formattedAmount $symbol';
    }
    
    return '$symbol$formattedAmount';
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency,
    };
  }

  /// Create from Map
  factory Money.fromMap(Map<String, dynamic> map) {
    return Money(
      (map['amount'] ?? 0.0).toDouble(),
      map['currency'] ?? 'USD',
    );
  }

  /// Copy with new values
  Money copyWith({
    double? amount,
    String? currency,
  }) {
    return Money(
      amount ?? this.amount,
      currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money &&
        other.amount == amount &&
        other.currency == currency;
  }

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;

  @override
  String toString() => toStringFull();

  /// Safe rounding to avoid floating point precision issues
  double _safeRound(double value) {
    return (value * 100).round() / 100.0;
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'CHF';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'BRL':
        return 'R\$';
      case 'MXN':
        return '\$';
      case 'KRW':
        return '₩';
      case 'SGD':
        return 'S\$';
      case 'HKD':
        return 'HK\$';
      case 'NZD':
        return 'NZ\$';
      case 'SEK':
        return 'kr';
      case 'NOK':
        return 'kr';
      case 'DKK':
        return 'kr';
      case 'PLN':
        return 'zł';
      case 'CZK':
        return 'Kč';
      case 'HUF':
        return 'Ft';
      case 'RUB':
        return '₽';
      case 'TRY':
        return '₺';
      case 'ZAR':
        return 'R';
      case 'AED':
        return 'د.إ';
      case 'SAR':
        return 'ر.س';
      case 'EGP':
        return '£';
      case 'QAR':
        return 'ر.ق';
      case 'KWD':
        return 'د.ك';
      case 'BHD':
        return 'د.ب';
      case 'OMR':
        return 'ر.ع.';
      case 'JOD':
        return 'د.ا';
      case 'LBP':
        return 'ل.ل';
      case 'IQD':
        return 'د.ع';
      default:
        return currency;
    }
  }

  /// Check if locale is RTL
  bool _isRTLLocale(String locale) {
    const rtlLocales = ['ar', 'he', 'fa', 'ur', 'ku'];
    return rtlLocales.contains(locale.toLowerCase());
  }

  /// Common currency constants
  static const Money zeroUSD = Money(0.0, 'USD');
  static const Money zeroEUR = Money(0.0, 'EUR');
  static const Money zeroGBP = Money(0.0, 'GBP');

  /// Create zero money for a given currency
  static Money zero(String currency) {
    return Money(0.0, currency);
  }

  /// Parse money from string (e.g., "$2.50", "€1.20")
  static Money? parse(String value) {
    if (value.isEmpty) return null;
    
    // Remove whitespace
    value = value.trim();
    
    // Try to extract currency symbol and amount
    final symbolMatch = RegExp(r'^([^\d\s]+)?\s*(\d+(?:\.\d{1,2})?)\s*([^\d\s]+)?$').firstMatch(value);
    if (symbolMatch == null) return null;
    
    final prefixSymbol = symbolMatch.group(1);
    final amountStr = symbolMatch.group(2);
    final suffixSymbol = symbolMatch.group(3);
    
    if (amountStr == null) return null;
    
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;
    
    // Determine currency from symbol
    String currency = 'USD'; // default
    if (prefixSymbol != null) {
      currency = _symbolToCurrency(prefixSymbol);
    } else if (suffixSymbol != null) {
      currency = _symbolToCurrency(suffixSymbol);
    }
    
    return Money(amount, currency);
  }

  /// Convert currency symbol to currency code
  static String _symbolToCurrency(String symbol) {
    switch (symbol) {
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      case 'C\$':
        return 'CAD';
      case 'A\$':
        return 'AUD';
      case 'CHF':
        return 'CHF';
      case '₹':
        return 'INR';
      case 'R\$':
        return 'BRL';
      case '₩':
        return 'KRW';
      case 'S\$':
        return 'SGD';
      case 'HK\$':
        return 'HKD';
      case 'NZ\$':
        return 'NZD';
      case 'kr':
        return 'SEK';
      case 'zł':
        return 'PLN';
      case 'Kč':
        return 'CZK';
      case 'Ft':
        return 'HUF';
      case '₽':
        return 'RUB';
      case '₺':
        return 'TRY';
      case 'R':
        return 'ZAR';
      case 'د.إ':
        return 'AED';
      case 'ر.س':
        return 'SAR';
      case 'ر.ق':
        return 'QAR';
      case 'د.ك':
        return 'KWD';
      case 'د.ب':
        return 'BHD';
      case 'ر.ع.':
        return 'OMR';
      case 'د.ا':
        return 'JOD';
      case 'ل.ل':
        return 'LBP';
      case 'د.ع':
        return 'IQD';
      default:
        return 'USD';
    }
  }
}
