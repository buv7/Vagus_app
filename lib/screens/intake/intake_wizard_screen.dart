import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/intake/intake_service.dart';
import '../../theme/design_tokens.dart';

class IntakeWizardScreen extends StatefulWidget {
  final String? formId;
  final bool showRequiredBanner;

  const IntakeWizardScreen({
    super.key,
    this.formId,
    this.showRequiredBanner = false,
  });

  @override
  State<IntakeWizardScreen> createState() => _IntakeWizardScreenState();
}

class _IntakeWizardScreenState extends State<IntakeWizardScreen> {
  final IntakeService _intakeService = IntakeService();
  final PageController _pageController = PageController();
  
  Map<String, dynamic>? _formData;
  Map<String, dynamic>? _responseData;
  Map<String, dynamic> _answers = {};
  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('role, coach_id')
          .eq('id', userId)
          .single();

      String formId = widget.formId ?? '';
      
      if (formId.isEmpty) {
        // Get default form for coach
        if (userProfile['role'] == 'client' && userProfile['coach_id'] != null) {
          final defaultForm = await _intakeService.getDefaultFormForCoach(userProfile['coach_id']);
          if (defaultForm != null) {
            formId = defaultForm['id'];
            _formData = defaultForm;
          }
        }
      } else {
        // Load specific form
        final form = await Supabase.instance.client
            .from('intake_forms')
            .select('*, intake_form_versions(*)')
            .eq('id', formId)
            .single();
        _formData = form;
      }

      if (_formData != null) {
        // Start or resume response
        _responseData = await _intakeService.startOrResumeResponse(
          formId: formId,
          clientId: userId,
        );
        
        if (_responseData != null) {
          _answers = Map<String, dynamic>.from(_responseData!['answers_json'] ?? {});
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load form: $e';
      });
    }
  }

  Future<void> _saveDraft() async {
    if (_responseData == null) return;
    
    try {
      setState(() => _isSaving = true);
      
      await _intakeService.saveDraft(
        responseId: _responseData!['id'],
        answersPatch: _answers,
      );
      
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_responseData == null) return;
    
    try {
      setState(() => _isSubmitting = true);
      
      // Generate simple signature SVG (in real app, use proper signature widget)
      final signatureSvg = '''
        <svg width="200" height="100">
          <text x="10" y="50" font-family="Arial" font-size="16" fill="black">
            ${Supabase.instance.client.auth.currentUser!.email}
          </text>
          <line x1="10" y1="60" x2="190" y2="60" stroke="black" stroke-width="2"/>
        </svg>
      ''';
      
      final waiverHash = DateTime.now().millisecondsSinceEpoch.toString();
      
      final success = await _intakeService.submitResponse(
        responseId: _responseData!['id'],
        signatureSvg: signatureSvg,
        waiverHash: waiverHash,
      );
      
      if (!mounted || !context.mounted) return;
      
      if (success) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const IntakeSubmittedScreen(),
          ),
        );
      } else {
        throw Exception('Failed to submit form');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _getSections().length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
      unawaited(_saveDraft());
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  List<Map<String, dynamic>> _getSections() {
    if (_formData == null) return [];
    
    final versions = _formData!['intake_form_versions'] as List;
    final activeVersion = versions.firstWhere(
      (v) => v['active'] == true,
      orElse: () => versions.first,
    );
    
    return List<Map<String, dynamic>>.from(activeVersion['schema_json']['sections'] ?? []);
  }

  bool _canProceed() {
    final sections = _getSections();
    if (_currentStep >= sections.length) return false;
    
    final currentSection = sections[_currentStep];
    final fields = List<Map<String, dynamic>>.from(currentSection['fields'] ?? []);
    
    for (final field in fields) {
      if (field['required'] == true) {
        final value = _answers[field['id']];
        if (value == null || value.toString().isEmpty) {
          return false;
        }
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Intake Form')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadForm,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_formData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Intake Form')),
        body: const Center(
          child: Text('No form available'),
        ),
      );
    }

    final sections = _getSections();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_formData!['title'] ?? 'Intake Form'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.showRequiredBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: DesignTokens.warn,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Intake form required before proceeding',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < sections.length; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < sections.length - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentStep 
                            ? DesignTokens.blue600 
                            : DesignTokens.ink100,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Step ${_currentStep + 1} of ${sections.length}',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
                const Spacer(),
                if (_isSaving)
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                          DesignTokens.blue600,
                        ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saving...',
                        style: DesignTokens.bodySmall.copyWith(
                          color: DesignTokens.ink500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Form content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                return _buildSection(sections[index]);
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _nextStep : null,
                    child: Text(_currentStep == sections.length - 1 ? 'Review' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
          
          // Submit button (only on last step)
          if (_currentStep == sections.length - 1)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.success,
              foregroundColor: Colors.white,
            ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Form'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final fields = List<Map<String, dynamic>>.from(section['fields'] ?? []);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section['title'] ?? '',
            style: DesignTokens.titleSmall,
          ),
          const SizedBox(height: 24),
          ...fields.map((field) => _buildField(field)),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final fieldId = field['id'];
    final label = field['label'];
    final required = field['required'] == true;
    final fieldType = field['type'];
    
    Widget fieldWidget;
    
    switch (fieldType) {
      case 'text':
      case 'email':
      case 'tel':
        fieldWidget = TextFormField(
          initialValue: _answers[fieldId]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          keyboardType: fieldType == 'email' 
              ? TextInputType.emailAddress 
              : fieldType == 'tel' 
                  ? TextInputType.phone 
                  : TextInputType.text,
          onChanged: (value) {
            setState(() {
              _answers[fieldId] = value;
            });
          },
        );
        break;
        
      case 'textarea':
        fieldWidget = TextFormField(
          initialValue: _answers[fieldId]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) {
            setState(() {
              _answers[fieldId] = value;
            });
          },
        );
        break;
        
      case 'number':
        fieldWidget = TextFormField(
          initialValue: _answers[fieldId]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            setState(() {
              _answers[fieldId] = value;
            });
          },
        );
        break;
        
      case 'select':
        final options = List<String>.from(field['options'] ?? []);
        fieldWidget = DropdownButtonFormField<String>(
          value: _answers[fieldId]?.toString(),
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _answers[fieldId] = value;
            });
          },
        );
        break;
        
      case 'multiselect':
        final options = List<String>.from(field['options'] ?? []);
        final currentValues = List<String>.from(_answers[fieldId] ?? []);
        
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label${required ? ' *' : ''}',
              style: DesignTokens.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              return CheckboxListTile(
                title: Text(option),
                value: currentValues.contains(option),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      currentValues.add(option);
                    } else {
                      currentValues.remove(option);
                    }
                    _answers[fieldId] = currentValues;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        );
        break;
        
      case 'radio':
        final options = List<String>.from(field['options'] ?? []);
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label${required ? ' *' : ''}',
              style: DesignTokens.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _answers[fieldId]?.toString(),
                onChanged: (value) {
                  setState(() {
                    _answers[fieldId] = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        );
        break;
        
      case 'date':
        fieldWidget = TextFormField(
          initialValue: _answers[fieldId]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _answers[fieldId] = date.toIso8601String().split('T')[0];
              });
            }
          },
        );
        break;
        
      default:
        fieldWidget = TextFormField(
          initialValue: _answers[fieldId]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: label,
            suffixText: required ? '*' : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _answers[fieldId] = value;
            });
          },
        );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: fieldWidget,
    );
  }
}

class IntakeSubmittedScreen extends StatelessWidget {
  const IntakeSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Submitted'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: DesignTokens.success,
              ),
              const SizedBox(height: 24),
                              const Text(
                  'Form Submitted Successfully!',
                  style: DesignTokens.titleLarge,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
                              Text(
                  'Your intake form has been submitted and is awaiting review by your coach. You will be notified once it has been approved.',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.ink500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
