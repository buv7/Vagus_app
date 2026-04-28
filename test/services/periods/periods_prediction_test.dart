import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/models/periods/cycle_phase.dart';
import 'package:vagus_app/models/periods/menstrual_cycle.dart';
import 'package:vagus_app/services/periods/cycle_prediction_engine.dart';

void main() {
  const engine = CyclePredictionEngine();

  MenstrualCycle _cycle(DateTime start, int lengthDays) => MenstrualCycle(
        id: 'test',
        userId: 'u1',
        cycleStart: start,
        cycleEnd: start.add(Duration(days: lengthDays - 1)),
        avgLengthDays: lengthDays.toDouble(),
        irregularFlag: false,
        createdAt: start,
        updatedAt: start,
      );

  MenstrualCycle _openCycle(DateTime start) => MenstrualCycle(
        id: 'open',
        userId: 'u1',
        cycleStart: start,
        cycleEnd: null,
        avgLengthDays: null,
        irregularFlag: false,
        createdAt: start,
        updatedAt: start,
      );

  group('CyclePredictionEngine.predict', () {
    test('returns null with no cycles', () {
      expect(engine.predict([]), isNull);
    });

    test('returns null when all cycles are open', () {
      final now = DateTime.now();
      expect(engine.predict([_openCycle(now.subtract(const Duration(days: 5)))]),
          isNull);
    });

    group('regular 28-day cycle (6 completed)', () {
      final base = DateTime(2026, 1, 1);
      final completed = List.generate(6, (i) {
        final start = base.subtract(Duration(days: 28 * (6 - i)));
        return _cycle(start, 28);
      });
      // Add an open cycle starting at base (most recent, first in list)
      final cycles = [_openCycle(base), ...completed];

      final p = engine.predict(cycles)!;

      test('avg length is 28.0', () {
        expect(p.avgCycleLengthDays, closeTo(28.0, 0.1));
      });

      test('not irregular (stddev = 0)', () {
        expect(p.isIrregular, isFalse);
      });

      test('confidence interval clamped to 1 (stddev = 0)', () {
        expect(p.confidenceIntervalDays, 1);
      });

      test('ovulation is 14 days before next period', () {
        expect(p.nextPeriodStart.difference(p.ovulationEstimate).inDays, 14);
      });

      test('nextPeriodEarliest = nextPeriodStart - confidenceIntervalDays', () {
        expect(p.nextPeriodEarliest,
            p.nextPeriodStart.subtract(Duration(days: p.confidenceIntervalDays)));
      });
    });

    group('mildly irregular cycle (25–30 day range)', () {
      final lengths = [28, 26, 30, 27, 29, 25];
      var cursor = DateTime(2026, 1, 1);
      final cycles = <MenstrualCycle>[];
      for (final l in lengths) {
        cycles.add(_cycle(cursor, l));
        cursor = cursor.add(Duration(days: l));
      }
      // Add open cycle and sort newest-first (mimics service)
      cycles.insert(0, _openCycle(cursor));
      cycles.sort((a, b) => b.cycleStart.compareTo(a.cycleStart));

      final p = engine.predict(cycles)!;

      test('avg is ~27.5', () {
        expect(p.avgCycleLengthDays, closeTo(27.5, 0.5));
      });

      test('not irregular (stddev < 7)', () {
        expect(p.isIrregular, isFalse);
      });

      test('confidence interval is between 1 and 14', () {
        expect(p.confidenceIntervalDays, inInclusiveRange(1, 14));
      });
    });

    group('highly irregular cycle (stddev > 7)', () {
      final lengths = [21, 35, 20, 40, 22, 38];
      var cursor = DateTime(2026, 1, 1);
      final cycles = <MenstrualCycle>[];
      for (final l in lengths) {
        cycles.add(_cycle(cursor, l));
        cursor = cursor.add(Duration(days: l));
      }
      cycles.insert(0, _openCycle(cursor));
      cycles.sort((a, b) => b.cycleStart.compareTo(a.cycleStart));

      final p = engine.predict(cycles)!;

      test('irregular_flag is true', () {
        expect(p.isIrregular, isTrue);
      });

      test('confidence interval is > 7', () {
        expect(p.confidenceIntervalDays, greaterThan(7));
      });

      test('confidence interval is at most 14', () {
        expect(p.confidenceIntervalDays, lessThanOrEqualTo(14));
      });
    });

    group('single completed cycle fallback', () {
      final start = DateTime(2026, 4, 1);
      final openStart = start.add(const Duration(days: 30));
      final cycles = [_openCycle(openStart), _cycle(start, 30)];

      final p = engine.predict(cycles)!;

      test('avg equals the single cycle length', () {
        expect(p.avgCycleLengthDays, closeTo(30.0, 0.1));
      });

      test('confidence clamped to 1 (stddev = 0 for n=1)', () {
        expect(p.confidenceIntervalDays, 1);
      });

      test('not irregular', () {
        expect(p.isIrregular, isFalse);
      });
    });
  });

  group('CyclePhase.forCycleDay', () {
    test('day 1 → menstrual', () {
      expect(CyclePhase.forCycleDay(1, 28), CyclePhase.menstrual);
    });
    test('day 5 → menstrual', () {
      expect(CyclePhase.forCycleDay(5, 28), CyclePhase.menstrual);
    });
    test('day 6 → follicular (28-day)', () {
      expect(CyclePhase.forCycleDay(6, 28), CyclePhase.follicular);
    });
    test('day 13 → follicular (28-day)', () {
      expect(CyclePhase.forCycleDay(13, 28), CyclePhase.follicular);
    });
    test('day 14 → ovulation (28-day, ovulation at L-14=14)', () {
      expect(CyclePhase.forCycleDay(14, 28), CyclePhase.ovulation);
    });
    test('day 15 → ovulation window (28-day)', () {
      expect(CyclePhase.forCycleDay(15, 28), CyclePhase.ovulation);
    });
    test('day 16 → luteal (28-day)', () {
      expect(CyclePhase.forCycleDay(16, 28), CyclePhase.luteal);
    });
    test('day 28 → luteal (28-day)', () {
      expect(CyclePhase.forCycleDay(28, 28), CyclePhase.luteal);
    });
    test('35-day cycle: day 21 is ovulation window', () {
      expect(CyclePhase.forCycleDay(21, 35), CyclePhase.ovulation);
    });
    test('24-day cycle: day 10 is ovulation window', () {
      expect(CyclePhase.forCycleDay(10, 24), CyclePhase.ovulation);
    });
    test('24-day cycle: day 12 is luteal', () {
      expect(CyclePhase.forCycleDay(12, 24), CyclePhase.luteal);
    });
  });
}
