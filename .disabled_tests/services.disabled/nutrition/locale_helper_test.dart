import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/nutrition/locale_helper.dart';

void main() {
  group('LocaleHelper', () {
    group('Translation', () {
      test('t() returns correct English translation', () {
        expect(LocaleHelper.t('nutrition', 'en'), equals('Nutrition'));
        expect(LocaleHelper.t('add_food', 'en'), equals('Add Food'));
        expect(LocaleHelper.t('protein', 'en'), equals('Protein'));
        expect(LocaleHelper.t('carbs', 'en'), equals('Carbs'));
      });

      test('t() returns correct Arabic translation', () {
        expect(LocaleHelper.t('nutrition', 'ar'), equals('التغذية'));
        expect(LocaleHelper.t('add_food', 'ar'), equals('إضافة طعام'));
        expect(LocaleHelper.t('protein', 'ar'), equals('بروتين'));
      });

      test('t() returns correct Kurdish translation', () {
        expect(LocaleHelper.t('nutrition', 'ku'), equals('خۆراک'));
        expect(LocaleHelper.t('add_food', 'ku'), equals('خۆراک زیاد بکە'));
        expect(LocaleHelper.t('protein', 'ku'), equals('پرۆتین'));
      });

      test('t() falls back to English for unknown key', () {
        expect(LocaleHelper.t('unknown_key', 'en'), equals('unknown_key'));
      });

      test('t() falls back to English for unknown locale', () {
        expect(LocaleHelper.t('nutrition', 'fr'), equals('Nutrition'));
      });
    });

    group('RTL Detection', () {
      test('isRTL() returns true for Arabic', () {
        expect(LocaleHelper.isRTL('ar'), isTrue);
      });

      test('isRTL() returns true for Kurdish', () {
        expect(LocaleHelper.isRTL('ku'), isTrue);
      });

      test('isRTL() returns false for English', () {
        expect(LocaleHelper.isRTL('en'), isFalse);
      });
    });

    group('Number Normalization', () {
      test('normalizeNumber() converts Arabic-Indic digits', () {
        expect(LocaleHelper.normalizeNumber('٠١٢٣٤٥٦٧٨٩'), equals('0123456789'));
      });

      test('normalizeNumber() converts Persian digits', () {
        expect(LocaleHelper.normalizeNumber('۰۱۲۳۴۵۶۷۸۹'), equals('0123456789'));
      });

      test('normalizeNumber() preserves Western digits', () {
        expect(LocaleHelper.normalizeNumber('0123456789'), equals('0123456789'));
      });

      test('normalizeNumber() handles mixed digits', () {
        expect(LocaleHelper.normalizeNumber('١٢۳456'), equals('123456'));
      });
    });

    group('Number Formatting', () {
      test('formatNumber() formats with default decimal places', () {
        expect(LocaleHelper.formatNumber(123.456), equals('123.5'));
      });

      test('formatNumber() formats with custom decimal places', () {
        expect(LocaleHelper.formatNumber(123.456, decimalPlaces: 2), equals('123.46'));
        expect(LocaleHelper.formatNumber(123.456, decimalPlaces: 0), equals('123'));
      });

      test('formatNumber() handles integers', () {
        expect(LocaleHelper.formatNumber(123), equals('123.0'));
      });
    });

    group('Language Display Names', () {
      test('getLanguageDisplayName() returns correct names', () {
        expect(LocaleHelper.getLanguageDisplayName('en'), equals('English'));
        expect(LocaleHelper.getLanguageDisplayName('ar'), equals('العربية'));
        expect(LocaleHelper.getLanguageDisplayName('ku'), equals('کوردی'));
      });

      test('getLanguageDisplayName() falls back for unknown language', () {
        expect(LocaleHelper.getLanguageDisplayName('fr'), equals('English'));
      });
    });

    group('Supported Languages', () {
      test('getSupportedLanguages() returns all supported locales', () {
        final languages = LocaleHelper.getSupportedLanguages();

        expect(languages, contains('en'));
        expect(languages, contains('ar'));
        expect(languages, contains('ku'));
        expect(languages.length, equals(3));
      });
    });

    group('Translation Coverage', () {
      test('all keys exist in all languages', () {
        final supportedLanguages = LocaleHelper.getSupportedLanguages();

        // Sample keys to check
        final keysToCheck = [
          'nutrition',
          'add_food',
          'protein',
          'carbs',
          'fat',
          'calories',
          'breakfast',
          'lunch',
          'dinner',
          'save',
          'cancel',
        ];

        for (final lang in supportedLanguages) {
          for (final key in keysToCheck) {
            final translation = LocaleHelper.t(key, lang);
            expect(translation, isNotEmpty, reason: 'Key "$key" missing in language "$lang"');
            expect(translation, isNot(equals(key)), reason: 'Key "$key" not translated in language "$lang"');
          }
        }
      });
    });
  });
}