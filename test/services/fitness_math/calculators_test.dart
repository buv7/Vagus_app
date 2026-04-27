import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/fitness_math/calculators.dart';

void main() {
  group('OneRepMax', () {
    test('all formulas: 1 rep returns weight', () {
      expect(OneRepMax.epley(100, 1), 100);
      expect(OneRepMax.brzycki(100, 1), 100);
      expect(OneRepMax.lombardi(100, 1), 100);
      expect(OneRepMax.lander(100, 1), 100);
      expect(OneRepMax.mayhew(100, 1), 100);
      expect(OneRepMax.oconner(100, 1), 100);
      expect(OneRepMax.wathan(100, 1), 100);
      expect(OneRepMax.average(100, 1), 100);
    });

    test('Epley (1985): 100kg x 5 = 116.667', () {
      expect(OneRepMax.epley(100, 5), closeTo(116.667, 0.01));
    });

    test('Brzycki (1993): 100kg x 5 = 112.5', () {
      expect(OneRepMax.brzycki(100, 5), closeTo(112.5, 0.01));
    });

    test('Brzycki throws at reps >= 37', () {
      expect(() => OneRepMax.brzycki(100, 37), throwsArgumentError);
      expect(() => OneRepMax.brzycki(100, 50), throwsArgumentError);
    });

    test('Lombardi (1989): 100kg x 5 ≈ 117.46', () {
      expect(OneRepMax.lombardi(100, 5), closeTo(117.46, 0.01));
    });

    test('Lander (1985): 100kg x 5 ≈ 113.71', () {
      expect(OneRepMax.lander(100, 5), closeTo(113.71, 0.05));
    });

    test('Mayhew (1992): 100kg x 5 ≈ 119.0', () {
      expect(OneRepMax.mayhew(100, 5), closeTo(119.0, 0.1));
    });

    test("O'Conner (1989): 100kg x 5 = 112.5", () {
      expect(OneRepMax.oconner(100, 5), closeTo(112.5, 0.01));
    });

    test('Wathan (1994): 100kg x 5 ≈ 116.59', () {
      expect(OneRepMax.wathan(100, 5), closeTo(116.59, 0.1));
    });

    test('average is monotonic in reps for fixed weight', () {
      final r3 = OneRepMax.average(100, 3);
      final r5 = OneRepMax.average(100, 5);
      final r8 = OneRepMax.average(100, 8);
      expect(r3, lessThan(r5));
      expect(r5, lessThan(r8));
    });

    test('throws on bad inputs', () {
      expect(() => OneRepMax.epley(0, 5), throwsArgumentError);
      expect(() => OneRepMax.epley(-10, 5), throwsArgumentError);
      expect(() => OneRepMax.epley(100, 0), throwsArgumentError);
      expect(() => OneRepMax.epley(100, -1), throwsArgumentError);
    });
  });

  group('Strength', () {
    test('DOTS male 200kg @ 90kg ≈ 129.32', () {
      expect(Strength.dots(200, 90, Sex.male), closeTo(129.32, 0.5));
    });

    test('DOTS female 100kg @ 60kg gives plausible score', () {
      final score = Strength.dots(100, 60, Sex.female);
      expect(score, greaterThan(50));
      expect(score, lessThan(200));
    });

    test('DOTS scales linearly with lift at fixed bodyweight', () {
      final s1 = Strength.dots(100, 80, Sex.male);
      final s2 = Strength.dots(200, 80, Sex.male);
      expect(s2, closeTo(2 * s1, 0.001));
    });

    test('Wilks male 200kg @ 90kg ≈ 127.7', () {
      expect(Strength.wilks(200, 90, Sex.male), closeTo(127.7, 0.5));
    });

    test('IPF GL male squat 250kg @ 90kg ≈ 33.24', () {
      expect(
        Strength.ipfgl(250, 90, Sex.male, Lift.squat),
        closeTo(33.24, 0.2),
      );
    });

    test('IPF GL female bench 100kg @ 60kg ≈ 85.92', () {
      expect(
        Strength.ipfgl(100, 60, Sex.female, Lift.bench),
        closeTo(85.92, 0.5),
      );
    });

    test('IPF GL gives positive scores for all lifts', () {
      for (final sex in Sex.values) {
        for (final lift in Lift.values) {
          final score = Strength.ipfgl(150, 75, sex, lift);
          expect(score, greaterThan(0), reason: '$sex $lift produced $score');
        }
      }
    });

    test('throws on non-positive bodyweight', () {
      expect(() => Strength.dots(100, 0, Sex.male), throwsArgumentError);
      expect(() => Strength.wilks(100, -1, Sex.male), throwsArgumentError);
      expect(
        () => Strength.ipfgl(100, 0, Sex.male, Lift.squat),
        throwsArgumentError,
      );
    });
  });

  group('Volume (RP landmarks)', () {
    test('intermediate chest: MEV=8, MAV=16, MRV=22', () {
      expect(Volume.mev(Experience.intermediate, MuscleGroup.chest), 8);
      expect(Volume.mav(Experience.intermediate, MuscleGroup.chest), 16);
      expect(Volume.mrv(Experience.intermediate, MuscleGroup.chest), 22);
    });

    test('beginner volumes are lower than intermediate', () {
      for (final mg in MuscleGroup.values) {
        final beg = Volume.mav(Experience.beginner, mg);
        final inter = Volume.mav(Experience.intermediate, mg);
        expect(beg, lessThanOrEqualTo(inter), reason: '$mg');
      }
    });

    test('advanced volumes are >= intermediate', () {
      for (final mg in MuscleGroup.values) {
        final inter = Volume.mrv(Experience.intermediate, mg);
        final adv = Volume.mrv(Experience.advanced, mg);
        expect(adv, greaterThanOrEqualTo(inter), reason: '$mg');
      }
    });

    test('MEV <= MAV <= MRV for every muscle/experience pair', () {
      for (final exp in Experience.values) {
        for (final mg in MuscleGroup.values) {
          final mev = Volume.mev(exp, mg);
          final mav = Volume.mav(exp, mg);
          final mrv = Volume.mrv(exp, mg);
          expect(mev, lessThanOrEqualTo(mav), reason: '$exp $mg');
          expect(mav, lessThanOrEqualTo(mrv), reason: '$exp $mg');
        }
      }
    });
  });

  group('Energy', () {
    test('Mifflin-St Jeor male 80kg 180cm 30y = 1780 kcal', () {
      expect(
        Energy.mifflinStJeor(
          weightKg: 80,
          heightCm: 180,
          age: 30,
          sex: Sex.male,
        ),
        closeTo(1780, 0.01),
      );
    });

    test('Mifflin-St Jeor female 65kg 165cm 25y = 1395.25 kcal', () {
      expect(
        Energy.mifflinStJeor(
          weightKg: 65,
          heightCm: 165,
          age: 25,
          sex: Sex.female,
        ),
        closeTo(1395.25, 0.01),
      );
    });

    test('Katch-McArdle 80kg @ 15% body fat = 1838.8 kcal', () {
      expect(
        Energy.katchMcArdle(weightKg: 80, bodyFatPct: 0.15),
        closeTo(1838.8, 0.01),
      );
    });

    test('Katch-McArdle rejects out-of-range body fat', () {
      expect(
        () => Energy.katchMcArdle(weightKg: 80, bodyFatPct: -0.1),
        throwsArgumentError,
      );
      expect(
        () => Energy.katchMcArdle(weightKg: 80, bodyFatPct: 1.0),
        throwsArgumentError,
      );
    });

    test('TDEE: 1780 * 1.55 = 2759', () {
      expect(Energy.tdee(1780, 1.55), closeTo(2759, 0.01));
    });

    test('TDEE rejects out-of-range activity factor', () {
      expect(() => Energy.tdee(1780, 0.5), throwsArgumentError);
      expect(() => Energy.tdee(1780, 3.0), throwsArgumentError);
    });

    test('Mifflin rejects bad inputs', () {
      expect(
        () => Energy.mifflinStJeor(
          weightKg: 0,
          heightCm: 180,
          age: 30,
          sex: Sex.male,
        ),
        throwsArgumentError,
      );
      expect(
        () => Energy.mifflinStJeor(
          weightKg: 80,
          heightCm: 0,
          age: 30,
          sex: Sex.male,
        ),
        throwsArgumentError,
      );
    });
  });
}
