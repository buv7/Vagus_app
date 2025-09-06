// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import '../../models/supplements/supplement_models.dart';

// Minimal, additive template model for UI only.
class SupplementTemplate {
  final String name;
  final String notes; // coach-facing description to prefill coach notes
  final String dosage; // default dosage suggestion
  final String category; // default category
  final List<TimeOfDay> fixedTimes; // prefer fixed-time schedule as a sensible default
  const SupplementTemplate({
    required this.name,
    required this.notes,
    required this.dosage,
    required this.category,
    required this.fixedTimes,
  });

  // Build a prefilled Supplement for the editor sheet.
  Supplement toPrefilledSupplement(String createdBy, String? clientId) {
    return Supplement.create(
      name: name,
      dosage: dosage,
      instructions: notes,
      category: category,
      createdBy: createdBy,
      clientId: clientId,
    );
  }

  // Build a prefilled schedule for the supplement
  SupplementSchedule toPrefilledSchedule(String supplementId, String createdBy) {
    final now = DateTime.now();
    return SupplementSchedule.create(
      supplementId: supplementId,
      scheduleType: 'fixed_times',
      frequency: 'daily',
      timesPerDay: fixedTimes.length,
      specificTimes: fixedTimes.map((t) => DateTime(2024, 1, 1, t.hour, t.minute)).toList(),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // All days
      startDate: DateTime(now.year, now.month, now.day),
      endDate: null,
      createdBy: createdBy,
    );
  }
}

const _morningStack = SupplementTemplate(
  name: 'Morning stack',
  notes: 'Daily AM stack: D3 + Omega-3 + Magnesium.',
  dosage: '1 capsule each',
  category: 'vitamin',
  fixedTimes: <TimeOfDay>[TimeOfDay(hour: 8, minute: 0)],
);

const _sleepStack = SupplementTemplate(
  name: 'Sleep stack',
  notes: 'Magnesium + L-Theanine + Glycine before bed.',
  dosage: '1 capsule each',
  category: 'mineral',
  fixedTimes: <TimeOfDay>[TimeOfDay(hour: 21, minute: 30)],
);

const _recoveryStack = SupplementTemplate(
  name: 'Recovery stack',
  notes: 'Creatine + electrolytes post-workout.',
  dosage: '5g creatine + 1 electrolyte tablet',
  category: 'protein',
  fixedTimes: <TimeOfDay>[TimeOfDay(hour: 17, minute: 30)],
);

const _gutHealth = SupplementTemplate(
  name: 'Gut health',
  notes: 'Probiotic + fiber daily.',
  dosage: '1 probiotic + 1 fiber capsule',
  category: 'probiotic',
  fixedTimes: <TimeOfDay>[TimeOfDay(hour: 9, minute: 0)],
);

const kSupplementTemplates = <SupplementTemplate>[
  _morningStack,
  _sleepStack,
  _recoveryStack,
  _gutHealth,
];
