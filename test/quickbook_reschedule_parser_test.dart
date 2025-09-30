import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/coach/quickbook_reschedule_service.dart';

void main() {
  group('QuickBookRescheduleService Parser Tests', () {
    late QuickBookRescheduleService service;

    setUp(() {
      service = QuickBookRescheduleService.instance;
    });

    group('parseOptionSelection', () {
      test('should parse "option one" variants', () {
        expect(service.parseOptionSelection('option one'), 1);
        expect(service.parseOptionSelection('Option One'), 1);
        expect(service.parseOptionSelection('OPTION ONE'), 1);
        expect(service.parseOptionSelection('I choose option one'), 1);
        expect(service.parseOptionSelection('option one works'), 1);
      });

      test('should parse \'option 1\' variants', () {
        expect(service.parseOptionSelection('option 1'), 1);
        expect(service.parseOptionSelection('Option 1'), 1);
        expect(service.parseOptionSelection('I want option 1'), 1);
        expect(service.parseOptionSelection('option 1 please'), 1);
      });

      test('should parse "first" variants', () {
        expect(service.parseOptionSelection('first'), 1);
        expect(service.parseOptionSelection('First'), 1);
        expect(service.parseOptionSelection('the first one'), 1);
        expect(service.parseOptionSelection('first option'), 1);
        expect(service.parseOptionSelection('I prefer the first'), 1);
      });

      test('should parse Arabic/Kurdish \'first\' variants', () {
        expect(service.parseOptionSelection('أول'), 1);
        expect(service.parseOptionSelection('الأول'), 1);
        expect(service.parseOptionSelection('أول واحد'), 1);
      });

      test('should parse "option two" variants', () {
        expect(service.parseOptionSelection('option two'), 2);
        expect(service.parseOptionSelection('Option Two'), 2);
        expect(service.parseOptionSelection('I choose option two'), 2);
        expect(service.parseOptionSelection('option two works'), 2);
      });

      test('should parse \'option 2\' variants', () {
        expect(service.parseOptionSelection('option 2'), 2);
        expect(service.parseOptionSelection('Option 2'), 2);
        expect(service.parseOptionSelection('I want option 2'), 2);
        expect(service.parseOptionSelection('option 2 please'), 2);
      });

      test('should parse "second" variants', () {
        expect(service.parseOptionSelection('second'), 2);
        expect(service.parseOptionSelection('Second'), 2);
        expect(service.parseOptionSelection('the second one'), 2);
        expect(service.parseOptionSelection('second option'), 2);
        expect(service.parseOptionSelection('I prefer the second'), 2);
      });

      test('should parse Arabic/Kurdish \'second\' variants', () {
        expect(service.parseOptionSelection('ثاني'), 2);
        expect(service.parseOptionSelection('الثاني'), 2);
        expect(service.parseOptionSelection('ثاني واحد'), 2);
      });

      test('should parse numeric variants', () {
        expect(service.parseOptionSelection('1'), 1);
        expect(service.parseOptionSelection('2'), 2);
        expect(service.parseOptionSelection('١'), 1); // Arabic numeral
        expect(service.parseOptionSelection('٢'), 2); // Arabic numeral
        expect(service.parseOptionSelection('I want 1'), 1);
        expect(service.parseOptionSelection('I want 2'), 2);
      });

      test('should return null for invalid inputs', () {
        expect(service.parseOptionSelection(''), null);
        expect(service.parseOptionSelection('   '), null);
        expect(service.parseOptionSelection('option 3'), null);
        expect(service.parseOptionSelection('third'), null);
        expect(service.parseOptionSelection('maybe'), null);
        expect(service.parseOptionSelection('I dont know'), null);
        expect(service.parseOptionSelection('option'), null);
        expect(service.parseOptionSelection('one two'), null);
      });

      test('should handle mixed case and whitespace', () {
        expect(service.parseOptionSelection('  OPTION ONE  '), 1);
        expect(service.parseOptionSelection('\tfirst\n'), 1);
        expect(service.parseOptionSelection('  Option 2  '), 2);
        expect(service.parseOptionSelection('\nsecond\t'), 2);
      });

      test('should prioritize first match in ambiguous cases', () {
        // If both '1' and '2' are present, should return the first one found
        expect(service.parseOptionSelection('I want 1 or 2'), 1);
        expect(service.parseOptionSelection('option 2 or option 1'), 2);
        expect(service.parseOptionSelection('first and second'), 1);
      });

      test('should handle empty and whitespace-only inputs', () {
        expect(service.parseOptionSelection(''), null);
        expect(service.parseOptionSelection('   '), null);
        expect(service.parseOptionSelection('\t\n'), null);
      });
    });

    group('parseOptionFromLastMessage', () {
      test('should parse from last message only', () {
        final history = [
          'Hello coach',
          'I need to reschedule',
          'option 1 works for me'
        ];
        expect(service.parseOptionFromLastMessage(history), 1);
      });

      test('should ignore earlier messages with option selections', () {
        final history = [
          'option 2 please',
          'Actually, let me think',
          'option 1 is better'
        ];
        expect(service.parseOptionFromLastMessage(history), 1);
      });

      test('should return null for empty history', () {
        expect(service.parseOptionFromLastMessage([]), null);
      });

      test('should return null if last message has no option selection', () {
        final history = [
          'option 1 please',
          'Actually, let me think about it'
        ];
        expect(service.parseOptionFromLastMessage(history), null);
      });

      test('should handle single message history', () {
        final history = ['option 2'];
        expect(service.parseOptionFromLastMessage(history), 2);
      });
    });

    group('isRescheduleIntent', () {
      test('should detect English reschedule intents', () {
        expect(service.isRescheduleIntent('can\'t make it'), true);
        expect(service.isRescheduleIntent('can\'t make it'), true);
        expect(service.isRescheduleIntent('cannot make it'), true);
        expect(service.isRescheduleIntent('need to move'), true);
        expect(service.isRescheduleIntent('reschedule'), true);
        expect(service.isRescheduleIntent('resched'), true);
        expect(service.isRescheduleIntent('push it back'), true);
        expect(service.isRescheduleIntent('change time'), true);
        expect(service.isRescheduleIntent('later time'), true);
        expect(service.isRescheduleIntent('earlier time'), true);
        expect(service.isRescheduleIntent('can we move'), true);
        expect(service.isRescheduleIntent('delay'), true);
        expect(service.isRescheduleIntent('postpone'), true);
        expect(service.isRescheduleIntent('move it'), true);
        expect(service.isRescheduleIntent('shift it'), true);
        expect(service.isRescheduleIntent('reschedule it'), true);
        expect(service.isRescheduleIntent('change it'), true);
        expect(service.isRescheduleIntent('different time'), true);
      });

      test('should detect Arabic/Kurdish reschedule intents', () {
        expect(service.isRescheduleIntent('أجل'), true);
        expect(service.isRescheduleIntent('تأجيل'), true);
        expect(service.isRescheduleIntent('غير الموعد'), true);
        expect(service.isRescheduleIntent('مو أگدر'), true);
        expect(service.isRescheduleIntent('تغيير الموعد'), true);
        expect(service.isRescheduleIntent('تأخير'), true);
      });

      test('should handle case insensitive detection', () {
        expect(service.isRescheduleIntent('CAN\'T MAKE IT'), true);
        expect(service.isRescheduleIntent('Reschedule'), true);
        expect(service.isRescheduleIntent('RESCHED'), true);
        expect(service.isRescheduleIntent('أجل'), true);
      });

      test('should return false for non-reschedule intents', () {
        expect(service.isRescheduleIntent(''), false);
        expect(service.isRescheduleIntent('   '), false);
        expect(service.isRescheduleIntent('I can make it'), false);
        expect(service.isRescheduleIntent('sounds good'), false);
        expect(service.isRescheduleIntent('confirmed'), false);
        expect(service.isRescheduleIntent('yes'), false);
        expect(service.isRescheduleIntent('no problem'), false);
        expect(service.isRescheduleIntent('see you then'), false);
      });

      test('should handle partial matches correctly', () {
        expect(service.isRescheduleIntent('I can\'t make it tomorrow'), true);
        expect(service.isRescheduleIntent('Need to reschedule this'), true);
        expect(service.isRescheduleIntent('Can we change the time?'), true);
        expect(service.isRescheduleIntent('I can make it'), false);
        expect(service.isRescheduleIntent('I can schedule it'), false);
      });
    });
  });
}
