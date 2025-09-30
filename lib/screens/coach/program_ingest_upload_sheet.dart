import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/coach/program_ingest_service.dart';
import 'program_ingest_preview_screen.dart';

class ProgramIngestUploadSheet extends StatefulWidget {
  final String? preselectedClientId;

  const ProgramIngestUploadSheet({
    super.key,
    this.preselectedClientId,
  });

  @override
  State<ProgramIngestUploadSheet> createState() => _ProgramIngestUploadSheetState();
}

class _ProgramIngestUploadSheetState extends State<ProgramIngestUploadSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final ProgramIngestService _ingestService = ProgramIngestService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late TabController _tabController;
  String? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];
  bool _loadingClients = true;
  bool _submitting = false;
  String? _selectedFile;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedClientId = widget.preselectedClientId;
    _loadClients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get clients connected to this coach
      final response = await _supabase
          .from('user_coach_links')
          .select('''
            client_id,
            profiles!user_coach_links_client_id_fkey(
              id,
              full_name,
              name
            )
          ''')
          .eq('coach_id', user.id);

      setState(() {
        _clients = (response as List)
            .map((item) => {
              'id': item['client_id'],
              'name': item['profiles']?['full_name'] ?? 
                     item['profiles']?['name'] ?? 
                     'Unknown Client',
            })
            .toList();
        _loadingClients = false;
      });
    } catch (e) {
      setState(() {
        _loadingClients = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (file != null) {
        setState(() {
          _pickedFile = file;
          _selectedFile = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }

  Future<void> _submitText() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create job from text
      final jobId = await _ingestService.createJobFromText(
        clientId: _selectedClientId!,
        coachId: user.id,
        text: _textController.text,
      );

      // Trigger processing
      await _ingestService.triggerEdge(jobId);

      if (mounted) {
        Navigator.of(context).pop();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProgramIngestPreviewScreen(jobId: jobId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _submitFile() async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create job from file
      final jobId = await _ingestService.createJobFromFile(
        clientId: _selectedClientId!,
        coachId: user.id,
        file: _pickedFile!,
      );

      // Trigger processing
      await _ingestService.triggerEdge(jobId);

      if (mounted) {
        Navigator.of(context).pop();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProgramIngestPreviewScreen(jobId: jobId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radius20),
          topRight: Radius.circular(DesignTokens.radius20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.space12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Row(
              children: [
                const Text(
                  'Import Program',
                  style: TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.accentGreen,
            unselectedLabelColor: AppTheme.lightGrey,
            indicatorColor: AppTheme.accentGreen,
            tabs: const [
              Tab(text: 'Paste Text'),
              Tab(text: 'Upload File'),
            ],
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildFileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Selection
            _buildClientSelector(),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Text Input
            const Text(
              'Program Text',
              style: TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            
            Expanded(
              child: TextFormField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Paste your program text here...\n\nExample:\n- Workout: Push day\n  Bench press: 3x8\n  Shoulder press: 3x10\n\n- Supplements:\n  Protein: 30g post-workout\n  Creatine: 5g daily\n\n- Nutrition:\n  Calories: 2500\n  Protein: 150g',
                  hintStyle: TextStyle(color: AppTheme.lightGrey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.mediumGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.accentGreen),
                  ),
                ),
                style: const TextStyle(color: AppTheme.neutralWhite),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter program text';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                      )
                    : const Text(
                        'Process Text',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTab() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Selection
          _buildClientSelector(),
          
          const SizedBox(height: DesignTokens.space24),
          
          // File Selection
          const Text(
            'Program File',
            style: TextStyle(
              color: AppTheme.neutralWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: AppTheme.lightGrey,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: _selectedFile != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description,
                            color: AppTheme.accentGreen,
                            size: 32,
                          ),
                          const SizedBox(height: DesignTokens.space8),
                          Text(
                            _selectedFile!,
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          const Text(
                            'Tap to change file',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppTheme.lightGrey,
                            size: 32,
                          ),
                          SizedBox(height: DesignTokens.space8),
                          Text(
                            'Tap to select file',
                            style: TextStyle(color: AppTheme.lightGrey),
                          ),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            'Supports PDF, images, and text files',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                    )
                  : const Text(
                      'Process File',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Client',
          style: TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        
        if (_loadingClients)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          )
        else if (_clients.isEmpty)
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: const Center(
              child: Text(
                'No clients found. Please connect with clients first.',
                style: TextStyle(color: AppTheme.lightGrey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.mediumGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accentGreen),
              ),
            ),
            dropdownColor: AppTheme.cardBackground,
            style: const TextStyle(color: AppTheme.neutralWhite),
            items: _clients.map<DropdownMenuItem<String>>((client) {
              return DropdownMenuItem<String>(
                value: client['id'] as String,
                child: Text(
                  client['name'] as String,
                  style: const TextStyle(color: AppTheme.neutralWhite),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClientId = value;
              });
            },
          ),
      ],
    );
  }
}
