import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

// Add Coach Note Bottom Sheet
class AddCoachNoteBottomSheet extends StatefulWidget {
  const AddCoachNoteBottomSheet({super.key});

  @override
  State<AddCoachNoteBottomSheet> createState() => _AddCoachNoteBottomSheetState();
}

class _AddCoachNoteBottomSheetState extends State<AddCoachNoteBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  String _selectedCategory = 'General';
  bool _loading = false;
  bool _saving = false;

  final List<String> _categories = ['Progress', 'Concern', 'Achievement', 'General'];
  final Map<String, IconData> _categoryIcons = {
    'Progress': Icons.trending_up,
    'Concern': Icons.warning,
    'Achievement': Icons.star,
    'General': Icons.note,
  };

  @override
  void initState() {
    super.initState();
    _loadClients();
    // Auto-focus text field after sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noteFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      // Load connected clients
      final links = await supabase
          .from('coach_clients')
          .select('client_id')
          .eq('coach_id', user.id);

      if (links.isNotEmpty) {
        List<String> clientIds = links.map((row) => row['client_id'] as String).toList();

        final clients = await supabase
            .from('profiles')
            .select('id, name, email, avatar_url')
            .inFilter('id', clientIds);

        setState(() {
          _clients = List<Map<String, dynamic>>.from(clients);
          // Auto-select first client if available
          if (_clients.isNotEmpty) {
            _selectedClientId = _clients.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load clients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty || _selectedClientId == null) {
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      await supabase.from('coach_notes').insert({
        'coach_id': user.id,
        'client_id': _selectedClientId,
        'content': _noteController.text.trim(),
        'category': _selectedCategory.toLowerCase(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Coach note saved successfully'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to save note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note_add,
                            color: AppTheme.accentGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Coach Note',
                            style: TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_loading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Client Selector
                              const Text(
                                'Select Client',
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: DesignTokens.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedClientId,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: AppTheme.lightGrey,
                                    ),
                                    dropdownColor: DesignTokens.cardBackground,
                                    style: const TextStyle(
                                      color: AppTheme.neutralWhite,
                                      fontSize: 16,
                                    ),
                                    items: _clients.map((client) {
                                      return DropdownMenuItem<String>(
                                        value: client['id'],
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: AppTheme.accentGreen,
                                                backgroundImage: client['avatar_url'] != null
                                                    ? NetworkImage(client['avatar_url'])
                                                    : null,
                                                child: client['avatar_url'] == null
                                                    ? Text(
                                                        (client['name'] ?? 'U')[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          color: AppTheme.neutralWhite,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      client['name'] ?? 'Unknown',
                                                      style: const TextStyle(
                                                        color: AppTheme.neutralWhite,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (client['email'] != null)
                                                      Text(
                                                        client['email'],
                                                        style: TextStyle(
                                                          color: AppTheme.lightGrey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedClientId = value;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Category Selector
                              const Text(
                                'Category',
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategory == category;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                      unawaited(HapticFeedback.selectionClick());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.accentGreen.withValues(alpha: 0.2)
                                            : DesignTokens.cardBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.accentGreen
                                              : Colors.white.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _categoryIcons[category],
                                            color: isSelected
                                                ? AppTheme.accentGreen
                                                : AppTheme.lightGrey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppTheme.accentGreen
                                                  : AppTheme.lightGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 24),

                              // Note Input
                              const Text(
                                'Note Content',
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: DesignTokens.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: TextField(
                                  controller: _noteController,
                                  focusNode: _noteFocusNode,
                                  maxLines: 6,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    hintText: 'Add details about client progress, concerns, or achievements...',
                                    hintStyle: TextStyle(
                                      color: AppTheme.lightGrey.withValues(alpha: 0.7),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    counterStyle: TextStyle(
                                      color: AppTheme.lightGrey,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: AppTheme.neutralWhite,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                    // Action Buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _saving ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: (_saving ||
                                         _noteController.text.trim().isEmpty ||
                                         _selectedClientId == null)
                                  ? null
                                  : _saveNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: AppTheme.neutralWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.neutralWhite,
                                      ),
                                    )
                                  : const Text(
                                      'Save Note',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Add Supplement Bottom Sheet
class AddSupplementBottomSheet extends StatefulWidget {
  const AddSupplementBottomSheet({super.key});

  @override
  State<AddSupplementBottomSheet> createState() => _AddSupplementBottomSheetState();
}

class _AddSupplementBottomSheetState extends State<AddSupplementBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  String? _selectedSupplement;
  String _frequency = 'Daily';
  int _duration = 30;
  bool _loading = false;
  bool _saving = false;

  final List<String> _commonSupplements = [
    'Whey Protein', 'Creatine', 'Multivitamin', 'Omega-3', 'Vitamin D',
    'Magnesium', 'Zinc', 'B-Complex', 'Probiotics', 'Caffeine',
  ];

  final List<String> _frequencies = ['Daily', 'Twice Daily', 'Three Times Daily', 'Weekly', 'As Needed'];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    // Same client loading logic as AddCoachNoteBottomSheet
    // Implementation would be identical
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: AppTheme.accentGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Supplement',
                            style: TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Coming Soon Content
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.construction,
                              color: AppTheme.accentOrange,
                              size: 64,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Supplement management is currently\nunder development.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.lightGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Close Button
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.neutralWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Import Program Bottom Sheet
class ImportProgramBottomSheet extends StatefulWidget {
  const ImportProgramBottomSheet({super.key});

  @override
  State<ImportProgramBottomSheet> createState() => _ImportProgramBottomSheetState();
}

class _ImportProgramBottomSheetState extends State<ImportProgramBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppTheme.accentGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Import Program',
                            style: TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Available in existing implementation
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.accentGreen,
                              size: 64,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Already Available',
                              style: TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Program import functionality is already\navailable in the existing implementation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.lightGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Close Button
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.neutralWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}