import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/intake/intake_form.dart';
import '../../services/intake_forms_service.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class IntakeFormFillScreen extends StatefulWidget {
  final String formId;

  const IntakeFormFillScreen({super.key, required this.formId});

  @override
  State<IntakeFormFillScreen> createState() => _IntakeFormFillScreenState();
}

class _IntakeFormFillScreenState extends State<IntakeFormFillScreen> {
  final IntakeFormsService _intakeService = IntakeFormsService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  IntakeForm? _form;
  final Map<String, dynamic> _answers = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // For now, we'll get the default form for the client's coach
      // In a real implementation, you'd fetch the specific form by ID
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get client's coach
      final profileResponse = await _supabase
          .from('profiles')
          .select('coach_id')
          .eq('id', user.id)
          .single();

      final coachId = profileResponse['coach_id'] as String?;
      if (coachId == null) throw Exception('No coach assigned');

      final form = await _intakeService.getDefaultFormForCoach(coachId);
      setState(() {
        _form = form;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_form == null) return;

    // Validate required fields
    final requiredQuestions = _form!.questions.where((q) => q.required).toList();
    for (final question in requiredQuestions) {
      if (!_answers.containsKey(question.id) || 
          _answers[question.id] == null || 
          _answers[question.id].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please answer: ${question.title}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      setState(() {
        _submitting = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = IntakeResponse(
        id: '',
        formId: _form!.id,
        clientId: user.id,
        answers: _answers,
        createdAt: DateTime.now(),
      );

      await _intakeService.submitResponse(response);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intake form submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(title: Text('Intake Form')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading form',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadForm,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _form == null
                  ? const Center(
                      child: Text(
                        'No form found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryDark,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _form!.schema['title'] ?? 'Client Intake Form',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _form!.schema['description'] ?? 'Please fill out this form to help your coach create a personalized program for you.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ..._form!.questions.map((question) => _buildQuestionWidget(question)),
                                
                                const SizedBox(height: 24),
                                
                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Submit Form',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildQuestionWidget(FormQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question title
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                if (question.required)
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            
            // Question description
            if (question.description != null && question.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                question.description!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Answer input based on question type
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(FormQuestion question) {
    switch (question.type) {
      case 'text':
        return TextFormField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your answer...',
          ),
          onChanged: (value) {
            _answers[question.id] = value;
          },
        );
        
      case 'textarea':
        return TextFormField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your answer...',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          onChanged: (value) {
            _answers[question.id] = value;
          },
        );
        
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select an option...'),
          items: question.choiceOptions.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            _answers[question.id] = value;
          },
        );
        
      case 'checkbox':
        return Column(
          children: question.choiceOptions.map((option) {
            return CheckboxListTile(
              title: Text(option),
              value: (_answers[question.id] as List<dynamic>?)?.contains(option) ?? false,
              onChanged: (value) {
                setState(() {
                  final currentList = List<String>.from(_answers[question.id] ?? []);
                  if (value == true) {
                    currentList.add(option);
                  } else {
                    currentList.remove(option);
                  }
                  _answers[question.id] = currentList;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
        
      default:
        return TextFormField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your answer...',
          ),
          onChanged: (value) {
            _answers[question.id] = value;
          },
        );
    }
  }
}
