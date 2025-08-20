import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/progress/progress_service.dart';

class ProgressEntryForm extends StatefulWidget {
  final String userId;
  final VoidCallback? onSaved;

  const ProgressEntryForm({
    super.key,
    required this.userId,
    this.onSaved,
  });

  @override
  State<ProgressEntryForm> createState() => _ProgressEntryFormState();
}

class _ProgressEntryFormState extends State<ProgressEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _notesController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _potassiumController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  final ProgressService _progressService = ProgressService();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _notesController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _progressService.addMetric(
        userId: widget.userId,
        date: _selectedDate,
        weightKg: double.tryParse(_weightController.text),
        bodyFatPercent: double.tryParse(_bodyFatController.text),
        waistCm: double.tryParse(_waistController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        sodiumMg: int.tryParse(_sodiumController.text),
        potassiumMg: int.tryParse(_potassiumController.text),
      );

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Progress entry saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save entry: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Progress Entry'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 20 || weight > 500) {
                    return 'Please enter a valid weight (20-500 kg)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Body Fat
            TextFormField(
              controller: _bodyFatController,
              decoration: const InputDecoration(
                labelText: 'Body Fat (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pie_chart),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final bf = double.tryParse(value);
                  if (bf == null || bf < 0 || bf > 50) {
                    return 'Please enter a valid body fat % (0-50)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Waist
            TextFormField(
              controller: _waistController,
              decoration: const InputDecoration(
                labelText: 'Waist (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final waist = double.tryParse(value);
                  if (waist == null || waist < 50 || waist > 200) {
                    return 'Please enter a valid waist measurement (50-200 cm)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sodium
            TextFormField(
              controller: _sodiumController,
              decoration: const InputDecoration(
                labelText: 'Sodium (mg) - Optional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final sodium = int.tryParse(value);
                  if (sodium == null || sodium < 0 || sodium > 10000) {
                    return 'Please enter a valid sodium amount (0-10000 mg)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Potassium
            TextFormField(
              controller: _potassiumController,
              decoration: const InputDecoration(
                labelText: 'Potassium (mg) - Optional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final potassium = int.tryParse(value);
                  if (potassium == null || potassium < 0 || potassium > 10000) {
                    return 'Please enter a valid potassium amount (0-10000 mg)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
