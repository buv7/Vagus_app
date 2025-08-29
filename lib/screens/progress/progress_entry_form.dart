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
  final _chestController = TextEditingController();
  final _rightArmController = TextEditingController();
  final _leftArmController = TextEditingController();
  final _rightThighController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightCalfController = TextEditingController();
  final _leftCalfController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _hipsController = TextEditingController();
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
    _chestController.dispose();
    _rightArmController.dispose();
    _leftArmController.dispose();
    _rightThighController.dispose();
    _leftThighController.dispose();
    _rightCalfController.dispose();
    _leftCalfController.dispose();
    _shouldersController.dispose();
    _hipsController.dispose();
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
        chestCm: double.tryParse(_chestController.text),
        rightArmCm: double.tryParse(_rightArmController.text),
        leftArmCm: double.tryParse(_leftArmController.text),
        rightThighCm: double.tryParse(_rightThighController.text),
        leftThighCm: double.tryParse(_leftThighController.text),
        rightCalfCm: double.tryParse(_rightCalfController.text),
        leftCalfCm: double.tryParse(_leftCalfController.text),
        shouldersCm: double.tryParse(_shouldersController.text),
        hipsCm: double.tryParse(_hipsController.text),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                labelText: 'Body Fat (%) - Optional',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pie_chart),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

            // Body Measurements Section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.straighten, color: Colors.blue),
                title: const Text(
                  'Body Measurements (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Tap to expand and add detailed measurements'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Waist
                        TextFormField(
                          controller: _waistController,
                          decoration: const InputDecoration(
                            labelText: 'Waist (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                        // Chest
                        TextFormField(
                          controller: _chestController,
                          decoration: const InputDecoration(
                            labelText: 'Chest (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.accessibility),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final chest = double.tryParse(value);
                              if (chest == null || chest < 50 || chest > 200) {
                                return 'Please enter a valid chest measurement (50-200 cm)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Shoulders
                        TextFormField(
                          controller: _shouldersController,
                          decoration: const InputDecoration(
                            labelText: 'Shoulders (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.accessibility),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final shoulders = double.tryParse(value);
                              if (shoulders == null || shoulders < 50 || shoulders > 200) {
                                return 'Please enter a valid shoulder measurement (50-200 cm)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Hips
                        TextFormField(
                          controller: _hipsController,
                          decoration: const InputDecoration(
                            labelText: 'Hips (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.accessibility),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final hips = double.tryParse(value);
                              if (hips == null || hips < 50 || hips > 200) {
                                return 'Please enter a valid hip measurement (50-200 cm)';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Arms Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rightArmController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Arm (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final arm = double.tryParse(value);
                                    if (arm == null || arm < 20 || arm > 100) {
                                      return 'Please enter a valid arm measurement (20-100 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _leftArmController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Arm (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final arm = double.tryParse(value);
                                    if (arm == null || arm < 20 || arm > 100) {
                                      return 'Please enter a valid arm measurement (20-100 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Thighs Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rightThighController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Thigh (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final thigh = double.tryParse(value);
                                    if (thigh == null || thigh < 30 || thigh > 150) {
                                      return 'Please enter a valid thigh measurement (30-150 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _leftThighController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Thigh (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final thigh = double.tryParse(value);
                                    if (thigh == null || thigh < 30 || thigh > 150) {
                                      return 'Please enter a valid thigh measurement (30-150 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Calves Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rightCalfController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Calf (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final calf = double.tryParse(value);
                                    if (calf == null || calf < 20 || calf > 100) {
                                      return 'Please enter a valid calf measurement (20-100 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _leftCalfController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Calf (cm)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.accessibility),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final calf = double.tryParse(value);
                                    if (calf == null || calf < 20 || calf > 100) {
                                      return 'Please enter a valid calf measurement (20-100 cm)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
