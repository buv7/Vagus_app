import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../theme/design_tokens.dart';
import '../../data/exercise_library_data.dart';
import '../../models/workout/exercise.dart';
import '../../models/workout/exercise_library_models.dart';
import '../../services/workout/workout_metadata_service.dart';
import '../../services/core/logger.dart';

class ExercisePickerDialog extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;

  const ExercisePickerDialog({
    super.key,
    required this.onExerciseSelected,
  });

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  String _searchQuery = '';
  String _selectedEquipment = 'All';
  String? _selectedMuscleGroup;
  
  // Pagination state
  List<ExerciseLibraryItem> _exercises = [];
  int _currentPage = 0;
  static const int _pageSize = 50;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialLoad = true;
  
  // Debounce timer for search
  Timer? _searchDebounce;
  
  // DB-driven metadata
  List<String> _availableEquipment = [];
  List<String> _availableMuscleGroups = [];
  
  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();
  
  // Error state
  String? _errorMessage;
  bool _isRlsError = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadExercises();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreExercises();
      }
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final service = WorkoutMetadataService();
      final results = await Future.wait([
        service.getDistinctEquipment(),
        service.getDistinctPrimaryMuscles(),
      ]);
      
      if (mounted) {
        setState(() {
          _availableEquipment = results[0];
          _availableMuscleGroups = results[1];
        });
      }
    } catch (e) {
      // Fallback to seed data
      if (mounted) {
        setState(() {
          _availableEquipment = ExerciseLibraryData.equipmentTypes
              .where((e) => e != 'All').toList();
          _availableMuscleGroups = ExerciseLibraryData.muscleGroups;
        });
      }
    }
  }

  Future<void> _loadExercises({bool reset = false}) async {
    if (_isLoading) return;
    
    if (reset) {
      setState(() {
        _currentPage = 0;
        _exercises = [];
        _hasMore = true;
        _errorMessage = null;
        _isRlsError = false;
      });
    }
    
    setState(() {
      _isLoading = true;
      _initialLoad = _currentPage == 0;
    });

    try {
      final service = WorkoutMetadataService();
      
      // Build filters - ONLY apply if not "All"
      // Normalize muscle group to lowercase to match DB storage
      List<String>? muscles;
      if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
        muscles = [_selectedMuscleGroup!.toLowerCase()];
      }
      
      // Normalize equipment to lowercase to match DB storage
      List<String>? equipment;
      if (_selectedEquipment != null && _selectedEquipment != 'All' && _selectedEquipment.isNotEmpty) {
        equipment = [_selectedEquipment.toLowerCase()];
      }
      
      // Only apply search if not empty
      final searchText = _searchQuery.trim();
      final search = searchText.isEmpty ? null : searchText;
      
      // Debug logging (dev only)
      if (kDebugMode) {
        Logger.debug(
          'ExercisePicker: Loading exercises',
          data: {
            'page': _currentPage,
            'pageSize': _pageSize,
            'search': search ?? '(empty)',
            'equipment': equipment?.join(',') ?? '(All)',
            'muscles': muscles?.join(',') ?? '(All Groups)',
            'reset': reset,
          },
          tag: 'ExercisePicker',
        );
      }
      
      // Fetch current page
      final newExercises = await service.getExerciseLibraryPaginated(
        search: search,
        muscles: muscles,
        equipment: equipment,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Debug logging (dev only)
      if (kDebugMode) {
        Logger.debug(
          'ExercisePicker: Query completed',
          data: {
            'returnedCount': newExercises.length,
            'hasMore': newExercises.length >= _pageSize,
            'first3Names': newExercises.take(3).map((e) => e.name).toList(),
          },
          tag: 'ExercisePicker',
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _exercises = newExercises;
          } else {
            _exercises.addAll(newExercises);
          }
          
          _hasMore = newExercises.length >= _pageSize;
          _isLoading = false;
          _initialLoad = false;
          _errorMessage = null;
          _isRlsError = false;
        });
      }
    } catch (e, stackTrace) {
      // Check for RLS/permission errors
      final errorString = e.toString().toLowerCase();
      final isRlsError = errorString.contains('permission') ||
          errorString.contains('row level security') ||
          errorString.contains('policy') ||
          errorString.contains('401') ||
          errorString.contains('403') ||
          errorString.contains('unauthorized') ||
          errorString.contains('forbidden');
      
      // Debug logging (dev only)
      if (kDebugMode) {
        Logger.error(
          'ExercisePicker: Failed to load exercises',
          error: e,
          stackTrace: stackTrace,
          data: {
            'page': _currentPage,
            'isRlsError': isRlsError,
            'errorString': e.toString(),
          },
          tag: 'ExercisePicker',
        );
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialLoad = false;
          _errorMessage = e.toString();
          _isRlsError = isRlsError;
        });
      }
    }
  }

  Future<void> _loadMoreExercises() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final service = WorkoutMetadataService();
      
      // Build filters - ONLY apply if not "All"
      // Normalize muscle group to lowercase to match DB storage
      List<String>? muscles;
      if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
        muscles = [_selectedMuscleGroup!.toLowerCase()];
      }
      
      // Normalize equipment to lowercase to match DB storage
      List<String>? equipment;
      if (_selectedEquipment != null && _selectedEquipment != 'All' && _selectedEquipment.isNotEmpty) {
        equipment = [_selectedEquipment.toLowerCase()];
      }
      
      // Only apply search if not empty
      final searchText = _searchQuery.trim();
      final search = searchText.isEmpty ? null : searchText;
      
      final newExercises = await service.getExerciseLibraryPaginated(
        search: search,
        muscles: muscles,
        equipment: equipment,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _exercises.addAll(newExercises);
          _hasMore = newExercises.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      // Debug logging (dev only)
      if (kDebugMode) {
        Logger.error(
          'ExercisePicker: Failed to load more exercises',
          error: e,
          stackTrace: stackTrace,
          data: {'page': _currentPage},
          tag: 'ExercisePicker',
        );
      }
      
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--; // Revert page increment on error
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    // Set new debounce timer (300ms)
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      // Only trigger search if text is not empty after trim
      // Empty search should reset to show all exercises
      _loadExercises(reset: true);
    });
  }

  void _onEquipmentChanged(String equipment) {
    setState(() {
      _selectedEquipment = equipment;
    });
    _loadExercises(reset: true);
  }

  void _onMuscleGroupChanged(String? muscleGroup) {
    setState(() {
      _selectedMuscleGroup = muscleGroup;
    });
    _loadExercises(reset: true);
  }

  List<ExerciseTemplate> get _filteredExercises {
    // Convert ExerciseLibraryItem to ExerciseTemplate for UI compatibility
    return _exercises.map((item) => _libraryItemToTemplate(item)).toList();
  }

  /// Convert ExerciseLibraryItem to ExerciseTemplate for UI compatibility
  ExerciseTemplate _libraryItemToTemplate(ExerciseLibraryItem item) {
    // Get first muscle group (primary) or use category as fallback
    final muscleGroup = item.primaryMuscleGroups.isNotEmpty 
        ? item.primaryMuscleGroups.first 
        : (item.category.isNotEmpty ? item.category : 'Unknown');
    
    // Get first equipment or 'Bodyweight' as fallback
    final equipment = item.equipmentNeeded.isNotEmpty 
        ? item.equipmentNeeded.first 
        : 'Bodyweight';
    
    // Capitalize equipment names to match seed data format
    String formattedEquipment = equipment;
    if (equipment.toLowerCase() == 'dumbbells') {
      formattedEquipment = 'Dumbbell';
    } else if (equipment.toLowerCase() == 'cables') {
      formattedEquipment = 'Cable';
    } else if (equipment.toLowerCase() == 'barbell') {
      formattedEquipment = 'Barbell';
    } else if (equipment.toLowerCase() == 'machine') {
      formattedEquipment = 'Machine';
    } else if (equipment.toLowerCase() == 'bodyweight') {
      formattedEquipment = 'Bodyweight';
    }
    
    // Capitalize muscle group first letter
    final String formattedMuscleGroup = muscleGroup.isNotEmpty
        ? muscleGroup[0].toUpperCase() + muscleGroup.substring(1)
        : 'Unknown';
    
    // Default difficulty formatting
    String formattedDifficulty = item.difficultyLevel ?? 'Intermediate';
    if (formattedDifficulty.isNotEmpty) {
      formattedDifficulty = formattedDifficulty[0].toUpperCase() + 
          formattedDifficulty.substring(1);
    }
    
    return ExerciseTemplate(
      name: item.name,
      muscleGroup: formattedMuscleGroup,
      equipment: formattedEquipment,
      difficulty: formattedDifficulty,
      defaultSets: 3, // Default value
      defaultReps: '10-12', // Default value
      description: item.instructions, // Use instructions as description
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DesignTokens.glassBorder),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: DesignTokens.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: DesignTokens.neutralWhite),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: DesignTokens.textSecondary),
                  filled: true,
                  fillColor: DesignTokens.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.accentGreen),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // Equipment Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedEquipment == 'All',
                      onSelected: (selected) {
                        _onEquipmentChanged('All');
                      },
                      backgroundColor: DesignTokens.primaryDark,
                      selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: _selectedEquipment == 'All' 
                            ? DesignTokens.accentGreen 
                            : DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _selectedEquipment == 'All' 
                            ? DesignTokens.accentGreen 
                            : DesignTokens.glassBorder,
                      ),
                    ),
                  ),
                  // Equipment chips
                  ...(_availableEquipment.isEmpty
                    ? ExerciseLibraryData.equipmentTypes
                        .where((e) => e != 'All')
                        .map((equipment) => _buildEquipmentChip(equipment))
                    : _availableEquipment.map((equipment) => _buildEquipmentChip(equipment))
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Muscle Group Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All Groups'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) {
                        _onMuscleGroupChanged(null);
                      },
                      backgroundColor: DesignTokens.primaryDark,
                      selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: _selectedMuscleGroup == null 
                            ? DesignTokens.accentBlue 
                            : DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: _selectedMuscleGroup == null 
                            ? DesignTokens.accentBlue 
                            : DesignTokens.glassBorder,
                      ),
                    ),
                  ),
                  // Muscle groups
                  ...(_availableMuscleGroups.isEmpty
                    ? ExerciseLibraryData.muscleGroups.map((group) {
                        final formattedGroup = group.isNotEmpty
                            ? group[0].toUpperCase() + group.substring(1)
                            : group;
                        return _buildMuscleGroupChip(formattedGroup);
                      })
                    : _availableMuscleGroups.map((group) {
                        final formattedGroup = group.isNotEmpty
                            ? group[0].toUpperCase() + group.substring(1)
                            : group;
                        return _buildMuscleGroupChip(formattedGroup);
                      })
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error banner (dev only, for RLS/permission errors)
            if (kDebugMode && _isRlsError && _errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exercise table blocked by RLS. Add SELECT policy for authenticated/anon.',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Exercise count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_exercises.length} exercises',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Exercise List
            Expanded(
              child: _initialLoad
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.accentGreen,
                      ),
                    )
                  : _exercises.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                color: DesignTokens.textSecondary,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyStateMessage(),
                                style: const TextStyle(
                                  color: DesignTokens.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (kDebugMode && _errorMessage != null && !_isRlsError) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Error: $_errorMessage',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredExercises.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _filteredExercises.length) {
                              // Loading indicator at the bottom
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: DesignTokens.accentGreen,
                                  ),
                                ),
                              );
                            }
                            
                            final exerciseTemplate = _filteredExercises[index];
                            return _buildExerciseCard(exerciseTemplate);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseTemplate template) {
    return InkWell(
      onTap: () {
        final exercise = Exercise(
          id: null,
          dayId: '', // Will be set by the caller
          name: template.name,
          sets: template.defaultSets,
          reps: template.defaultReps,
          weight: null,
          rest: 60,
          notes: template.description,
          orderIndex: 0,
        );

        widget.onExerciseSelected(exercise);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          children: [
            // Icon based on equipment
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getEquipmentColor(template.equipment).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getEquipmentIcon(template.equipment),
                color: _getEquipmentColor(template.equipment),
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 15,
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (template.description != null && template.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(template.muscleGroup, DesignTokens.accentBlue),
                      _buildTag(template.equipment, DesignTokens.textSecondary),
                    ],
                  ),
                ],
              ),
            ),

            // Default values
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${template.defaultSets} sets',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                Text(
                  '${template.defaultReps} reps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Add icon
            const Icon(
              Icons.add_circle,
              color: DesignTokens.accentGreen,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case 'Barbell':
        return Icons.fitness_center;
      case 'Dumbbell':
        return Icons.fitness_center;
      case 'Cable':
        return Icons.settings_input_hdmi;
      case 'Machine':
        return Icons.settings;
      case 'Bodyweight':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getEquipmentColor(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return DesignTokens.accentOrange;
      case 'dumbbell':
      case 'dumbbells':
        return DesignTokens.accentGreen;
      case 'cable':
      case 'cables':
        return DesignTokens.accentPurple;
      case 'machine':
        return DesignTokens.accentBlue;
      case 'bodyweight':
        return const Color(0xFFFFD700); // Gold
      default:
        return DesignTokens.textSecondary;
    }
  }

  Widget _buildEquipmentChip(String equipment) {
    final isSelected = _selectedEquipment == equipment;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(equipment),
        selected: isSelected,
        onSelected: (selected) {
          _onEquipmentChanged(equipment);
        },
        backgroundColor: DesignTokens.primaryDark,
        selectedColor: DesignTokens.accentGreen.withValues(alpha: 0.3),
        labelStyle: TextStyle(
          color: isSelected ? DesignTokens.accentGreen : DesignTokens.textSecondary,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? DesignTokens.accentGreen : DesignTokens.glassBorder,
        ),
      ),
    );
  }

  Widget _buildMuscleGroupChip(String group) {
    final isSelected = _selectedMuscleGroup == group;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(group),
        selected: isSelected,
        onSelected: (selected) {
          _onMuscleGroupChanged(isSelected ? null : group);
        },
        backgroundColor: DesignTokens.primaryDark,
        selectedColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
        labelStyle: TextStyle(
          color: isSelected ? DesignTokens.accentBlue : DesignTokens.textSecondary,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? DesignTokens.accentBlue : DesignTokens.glassBorder,
        ),
      ),
    );
  }

  /// Get appropriate empty state message based on current filters
  String _getEmptyStateMessage() {
    // Check if any filters are applied
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final hasEquipmentFilter = _selectedEquipment != null && _selectedEquipment != 'All';
    final hasMuscleFilter = _selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty;
    final hasFilters = hasSearch || hasEquipmentFilter || hasMuscleFilter;
    
    // Check if error indicates table doesn't exist
    final isTableNotFound = _errorMessage != null && 
        (_errorMessage!.toLowerCase().contains('does not exist') ||
         _errorMessage!.toLowerCase().contains('relation') && 
         _errorMessage!.toLowerCase().contains('not found'));
    
    if (isTableNotFound) {
      return 'Exercise library table not found.\nPlease run migration:\n20251002000000_remove_mock_data_infrastructure.sql';
    }
    
    if (hasFilters) {
      return 'No matches found.\nClear filters to see all exercises.';
    } else {
      // No filters applied - likely empty database
      return 'No exercises found in database.\nSeed the exercises table.';
    }
  }
}
