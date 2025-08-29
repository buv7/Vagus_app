import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/intake/intake_service.dart';
import '../../../services/google/google_apps_service.dart';
import '../../../models/google/google_models.dart';
import '../../../theme/design_tokens.dart';


class CoachFormsScreen extends StatefulWidget {
  const CoachFormsScreen({super.key});

  @override
  State<CoachFormsScreen> createState() => _CoachFormsScreenState();
}

class _CoachFormsScreenState extends State<CoachFormsScreen> {
  final IntakeService _intakeService = IntakeService();
  final GoogleAppsService _googleService = GoogleAppsService();
  
  List<Map<String, dynamic>> _forms = [];
  List<Map<String, dynamic>> _responses = [];
  List<FormsMapping> _googleFormsMappings = [];
  bool _isLoading = true;
  bool _isLoadingResponses = false;
  bool _isLoadingGoogleMappings = false;
  String? _selectedFormId;
  String? _selectedStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForms();
    _loadGoogleFormsMappings();
  }

  Future<void> _loadForms() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final forms = await _intakeService.getCoachForms(userId);
      
      setState(() {
        _forms = forms;
        _isLoading = false;
      });
      
      if (forms.isNotEmpty) {
        _selectedFormId = forms.first['id'];
        unawaited(_loadResponses());
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load forms: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadResponses() async {
    if (_selectedFormId == null) return;
    
    try {
      setState(() => _isLoadingResponses = true);
      
      final responses = await _intakeService.getFormResponses(
        formId: _selectedFormId!,
        status: _selectedStatus,
      );
      
      setState(() {
        _responses = responses;
        _isLoadingResponses = false;
      });
    } catch (e) {
      setState(() => _isLoadingResponses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load responses: $e')),
        );
      }
    }
  }

  Future<void> _loadGoogleFormsMappings() async {
    try {
      setState(() => _isLoadingGoogleMappings = true);
      
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final mappings = await _googleService.listFormsMappings(userId);
      
      setState(() {
        _googleFormsMappings = mappings;
        _isLoadingGoogleMappings = false;
      });
    } catch (e) {
      setState(() => _isLoadingGoogleMappings = false);
      debugPrint('Error loading Google Forms mappings: $e');
    }
  }

  Future<void> _saveGoogleFormsMapping() async {
    final externalIdController = TextEditingController();
    final mapJsonController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Google Forms Mapping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: externalIdController,
              decoration: const InputDecoration(
                labelText: 'External Form ID',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mapJsonController,
              decoration: const InputDecoration(
                labelText: 'Mapping JSON (optional)',
                border: OutlineInputBorder(),
                hintText: '{"field1": "name", "field2": "email"}',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (externalIdController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'externalId': externalIdController.text,
                  'mapJson': mapJsonController.text,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final mapJson = result['mapJson']!.isNotEmpty 
            ? Map<String, dynamic>.from(
                Map.fromEntries(
                  result['mapJson']!.split(',').map((e) {
                    final parts = e.trim().split(':');
                    return MapEntry(parts[0].trim(), parts[1].trim());
                  })
                )
              )
            : <String, dynamic>{};

        final success = await _googleService.saveFormsMapping(
          userId,
          result['externalId']!,
          mapJson,
        );

        if (success && mounted) {
          await _loadGoogleFormsMappings();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Forms mapping saved!')),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save mapping')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _createForm() async {
    final titleController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Form'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Form Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(titleController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final newForm = await _intakeService.createOrCloneForm(
          coachId: userId,
          title: result,
        );
        if (!mounted) return;
        
        if (newForm != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form created successfully')),
          );
          unawaited(_loadForms());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create form: $e')),
          );
        }
      }
    }
  }

  Future<void> _cloneForm(Map<String, dynamic> form) async {
    final titleController = TextEditingController(text: '${form['title']} (Copy)');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clone Form'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Form Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(titleController.text),
            child: const Text('Clone'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final newForm = await _intakeService.createOrCloneForm(
          coachId: userId,
          title: result,
          sourceFormId: form['id'],
        );
        if (!mounted) return;
        
        if (newForm != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form cloned successfully')),
          );
          unawaited(_loadForms());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clone form: $e')),
          );
        }
      }
    }
  }

  Future<void> _publishForm(Map<String, dynamic> form) async {
    try {
      // For now, we'll use the default schema
      // In a real app, you'd have a form builder UI
      final defaultSchema = {
        'sections': [
          {
            'id': 'profile',
            'title': 'Profile Information',
            'fields': [
              {'id': 'name', 'type': 'text', 'label': 'Full Name', 'required': true},
              {'id': 'email', 'type': 'email', 'label': 'Email', 'required': true},
              {'id': 'phone', 'type': 'tel', 'label': 'Phone Number', 'required': false},
            ]
          },
          {
            'id': 'goals',
            'title': 'Fitness Goals',
            'fields': [
              {'id': 'primary_goal', 'type': 'select', 'label': 'Primary Goal', 'options': ['Weight Loss', 'Muscle Gain', 'General Fitness'], 'required': true},
              {'id': 'goal_description', 'type': 'textarea', 'label': 'Describe your goals', 'required': false},
            ]
          }
        ]
      };
      
      final success = await _intakeService.publishVersion(
        formId: form['id'],
        schemaJson: defaultSchema,
        waiverMd: '# Waiver\n\nBy signing this form, you agree to...',
      );
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form published successfully')),
        );
        unawaited(_loadForms());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish form: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultForm(Map<String, dynamic> form) async {
    try {
      final success = await _intakeService.setDefaultForm(form['id']);
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default form updated')),
        );
        unawaited(_loadForms());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default form: $e')),
        );
      }
    }
  }

  Future<void> _approveResponse(Map<String, dynamic> response) async {
    try {
      final success = await _intakeService.approveResponse(response['id']);
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response approved')),
        );
        unawaited(_loadResponses());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve response: $e')),
        );
      }
    }
  }

  Future<void> _rejectResponse(Map<String, dynamic> response) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Response'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
                         style: ElevatedButton.styleFrom(
               backgroundColor: DesignTokens.danger,
               foregroundColor: Colors.white,
             ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      try {
        final success = await _intakeService.rejectResponse(
          responseId: response['id'],
          reason: result,
        );
        if (!mounted) return;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Response rejected')),
          );
          unawaited(_loadResponses());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject response: $e')),
          );
        }
      }
    }
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
        appBar: AppBar(title: const Text('Intake Forms')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadForms,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intake Forms'),
        backgroundColor: DesignTokens.ink50,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _createForm,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Form selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFormId,
                    decoration: const InputDecoration(
                      labelText: 'Select Form',
                      border: OutlineInputBorder(),
                    ),
                    items: _forms.map((form) {
                      return DropdownMenuItem<String>(
                        value: form['id'] as String,
                        child: Text(form['title'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFormId = value);
                      _loadResponses();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _selectedFormId != null ? () => _loadResponses() : null,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          
          // Form actions
          if (_selectedFormId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final form = _forms.firstWhere((f) => f['id'] == _selectedFormId);
                        _cloneForm(form);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Clone'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final form = _forms.firstWhere((f) => f['id'] == _selectedFormId);
                        _publishForm(form);
                      },
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final form = _forms.firstWhere((f) => f['id'] == _selectedFormId);
                        _setDefaultForm(form);
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Set Default'),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Status filter
          if (_selectedFormId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Filter by status: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    hint: const Text('All'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      const DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                      const DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      const DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _loadResponses();
                    },
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Responses list
          if (_selectedFormId != null)
            Expanded(
              child: _isLoadingResponses
                  ? const Center(child: CircularProgressIndicator())
                  : _responses.isEmpty
                      ? const Center(
                          child: Text('No responses found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _responses.length,
                          itemBuilder: (context, index) {
                            final response = _responses[index];
                            final client = response['profiles'] ?? {};
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(client['full_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(client['email'] ?? ''),
                                    Text(
                                      'Status: ${response['status']}',
                                      style: TextStyle(
                                        color: _getStatusColor(response['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Submitted: ${_formatDate(response['created_at'])}',
                                      style: DesignTokens.bodySmall.copyWith(
                                        color: DesignTokens.ink500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: response['status'] == 'submitted'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => _approveResponse(response),
                                            icon: const Icon(
                                              Icons.check,
                                              color: DesignTokens.success,
                                            ),
                                            tooltip: 'Approve',
                                          ),
                                          IconButton(
                                            onPressed: () => _rejectResponse(response),
                                            icon: const Icon(
                                              Icons.close,
                                              color: DesignTokens.danger,
                                            ),
                                            tooltip: 'Reject',
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () => _viewResponse(response),
                              ),
                            );
                          },
                        ),
            ),
          // Google Forms section
          _buildGoogleFormsSection(),
        ],
      ),
    );
  }

  Widget _buildGoogleFormsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: DesignTokens.blue500),
                const SizedBox(width: 8),
                Text(
                  'Google Forms Integration',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Add new mapping button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveGoogleFormsMapping,
                icon: const Icon(Icons.add),
                label: const Text('Add Google Forms Mapping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.blue500,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Existing mappings
            if (_isLoadingGoogleMappings)
              const Center(child: CircularProgressIndicator())
            else if (_googleFormsMappings.isEmpty)
              const Center(
                child: Text('No Google Forms mappings found'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _googleFormsMappings.length,
                itemBuilder: (context, index) {
                  final mapping = _googleFormsMappings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Form ID: ${mapping.externalId}',
                                  style: DesignTokens.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Webhook URL:',
                            style: DesignTokens.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'https://your-app.com/webhook/google-forms/${mapping.id}',
                              style: DesignTokens.bodySmall.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Secret: ',
                                style: DesignTokens.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  mapping.webhookSecret,
                                  style: DesignTokens.bodySmall.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: mapping.webhookSecret,
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Secret copied to clipboard'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${_formatDate(mapping.createdAt.toIso8601String())}',
                            style: DesignTokens.bodySmall.copyWith(
                              color: DesignTokens.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
              return DesignTokens.ink500;
    case 'submitted':
      return DesignTokens.warn;
    case 'approved':
      return DesignTokens.success;
    case 'rejected':
      return DesignTokens.danger;
    default:
              return DesignTokens.ink500;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _viewResponse(Map<String, dynamic> response) {
    // TODO: Implement response viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Response Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${response['status']}'),
              const SizedBox(height: 8),
              Text('Submitted: ${_formatDate(response['created_at'])}'),
              const SizedBox(height: 16),
              const Text('Answers:'),
              const SizedBox(height: 8),
              Text(
                response['answers_json']?.toString() ?? 'No answers',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
