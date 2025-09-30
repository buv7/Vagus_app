import 'package:flutter/material.dart';
import '../../services/nutrition/locale_helper.dart';

/// Result of supplement editor
class SupplementEditorResult {
  final String name;
  final String? dosage;
  final String? timing;
  final String? notes;
  
  const SupplementEditorResult({
    required this.name,
    this.dosage,
    this.timing,
    this.notes,
  });
}

/// Show supplement editor in a modal bottom sheet
Future<SupplementEditorResult?> showSupplementEditorSheet(
  BuildContext context, {
  String? initialName,
  String? initialDosage,
  String? initialTiming,
  String? initialNotes,
}) async {
  final language = Localizations.localeOf(context).languageCode;
  final nameCtrl = TextEditingController(text: initialName ?? '');
  final dosageCtrl = TextEditingController(text: initialDosage ?? '');
  final notesCtrl = TextEditingController(text: initialNotes ?? '');
  String timing = initialTiming ?? '';
  
  return showModalBottomSheet<SupplementEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleHelper.t('add_supplement', language),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: LocaleHelper.t('name', language),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
                hintText: 'e.g., 5mg, 1 tablet',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: timing.isEmpty ? null : timing,
              decoration: InputDecoration(
                labelText: LocaleHelper.t('timing', language),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('🌅 Morning')),
                DropdownMenuItem(value: 'with_meal', child: Text('🍽️ With meal')),
                DropdownMenuItem(value: 'preworkout', child: Text('💪 Pre-workout')),
                DropdownMenuItem(value: 'postworkout', child: Text('🏃 Post-workout')),
                DropdownMenuItem(value: 'bedtime', child: Text('🌙 Bedtime')),
                DropdownMenuItem(value: 'other', child: Text('💊 Other')),
              ],
              onChanged: (v) => timing = v ?? '',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: LocaleHelper.t('notes', language),
                border: const OutlineInputBorder(),
                hintText: 'Optional notes...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocaleHelper.t('cancel', language)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a supplement name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(ctx, SupplementEditorResult(
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim().isEmpty ? null : dosageCtrl.text.trim(),
                      timing: timing.isEmpty ? null : timing,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    ));
                  },
                  child: Text(LocaleHelper.t('save', language)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
