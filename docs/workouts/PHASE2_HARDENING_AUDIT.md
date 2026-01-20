# PHASE 2 HARDENING AUDIT - Enum Data Loss Risk Assessment

**Date:** 2025-01-20  
**Purpose:** Identify enums that need raw string preservation to prevent data loss

---

## TASK 0: ENUM DATA-LOSS RISK CHECK

| Enum | Comes from DB? | Saved back? | Needs raw preservation? | Where used | Risk Level |
|------|----------------|-------------|-------------------------|------------|------------|
| **TrainingMethod** | ❌ No (EnhancedExercise has no fromMap) | ✅ Yes (`toMap()` line 221: `'training_method': trainingMethod.value`) | ⚠️ **YES** - If data exists in DB with unknown value, it would be lost on save | `EnhancedExercise.trainingMethod` | 🟡 MEDIUM |
| **PyramidScheme** | ❌ No (EnhancedExercise has no fromMap) | ✅ Yes (`toMap()` line 218: `'pyramid_scheme': pyramidScheme!.value`) | ⚠️ **YES** - If data exists in DB with unknown value, it would be lost on save | `EnhancedExercise.pyramidScheme` (nullable) | 🟡 MEDIUM |
| **IsometricPosition** | ❌ No (EnhancedExercise has no fromMap) | ✅ Yes (`toMap()` line 213: `'isometric_position': isometricPosition!.value`) | ⚠️ **YES** - If data exists in DB with unknown value, it would be lost on save | `EnhancedExercise.isometricPosition` (nullable) | 🟡 MEDIUM |
| **CardioType** | ❌ No (EnhancedExercise has no fromMap) | ✅ Yes (`toMap()` line 224: `'cardio_type': cardioType!.value`) | ⚠️ **YES** - If data exists in DB with unknown value, it would be lost on save | `EnhancedExercise.cardioType` (nullable) | 🟡 MEDIUM |

**Note:** `EnhancedExercise` doesn't currently have a `fromMap()` factory constructor, so these enums are only written to DB, not read. However, if someone manually inserts data with unknown enum values, or if `fromMap()` is added in the future, data loss would occur. **For safety and future-proofing, these should have raw preservation.**

---

## RECOMMENDATION

All 4 enums listed above should have raw string preservation added following the same pattern as `ExerciseGroupType` and `DifficultyLevel`:
1. Add `unknown` enum member (or handle gracefully)
2. Add `_enumNameRaw` private field to `EnhancedExercise`
3. Update `toMap()` to prefer raw string when present
4. Update `copyWith()` to preserve raw string

**Priority:** Medium (not critical since EnhancedExercise doesn't read from DB yet, but recommended for future-proofing)

---

**END OF AUDIT**
