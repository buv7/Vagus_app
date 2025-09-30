import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class CheckinPhoto {
  final String id;
  final String url;
  final DateTime takenAt;
  final String? shotType;
  final String? storagePath;

  const CheckinPhoto({
    required this.id,
    required this.url,
    required this.takenAt,
    this.shotType,
    this.storagePath,
  });

  factory CheckinPhoto.fromMap(Map<String, dynamic> map) {
    return CheckinPhoto(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      takenAt: DateTime.tryParse(map['taken_at']?.toString() ?? '') ?? DateTime.now(),
      shotType: map['shot_type']?.toString(),
      storagePath: map['storage_path']?.toString(),
    );
  }
}

class CompareCheckinsModal extends StatefulWidget {
  final String clientId;
  final String? initialWeek1;
  final String? initialWeek2;

  const CompareCheckinsModal({
    super.key,
    required this.clientId,
    this.initialWeek1,
    this.initialWeek2,
  });

  @override
  State<CompareCheckinsModal> createState() => _CompareCheckinsModalState();
}

class _CompareCheckinsModalState extends State<CompareCheckinsModal> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<CheckinPhoto> _photos = [];
  List<String> _availableWeeks = [];
  String? _selectedWeek1;
  String? _selectedWeek2;
  String _selectedPose = 'front';
  bool _loading = true;
  String? _error;

  final List<String> _poses = ['front', 'side', 'back'];

  @override
  void initState() {
    super.initState();
    _selectedWeek1 = widget.initialWeek1;
    _selectedWeek2 = widget.initialWeek2;
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Get all photos for the client, grouped by week
      final response = await _supabase
          .from('progress_photos')
          .select('taken_at, shot_type')
          .eq('user_id', widget.clientId)
          .order('taken_at', ascending: false);

      final photos = (response as List<dynamic>)
          .map((photo) => CheckinPhoto.fromMap(photo as Map<String, dynamic>))
          .toList();

      // Group by week (Monday to Sunday)
      final weekGroups = <String, List<CheckinPhoto>>{};
      for (final photo in photos) {
        final weekStart = _getWeekStart(photo.takenAt);
        final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
        
        if (!weekGroups.containsKey(weekKey)) {
          weekGroups[weekKey] = [];
        }
        weekGroups[weekKey]!.add(photo);
      }

      setState(() {
        _availableWeeks = weekGroups.keys.toList()..sort((a, b) => b.compareTo(a));
        _loading = false;
      });

      // Load initial photos if weeks are selected
      if (_selectedWeek1 != null && _selectedWeek2 != null) {
        unawaited(_loadPhotosForComparison());
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPhotosForComparison() async {
    if (_selectedWeek1 == null || _selectedWeek2 == null) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final week1Start = _parseWeekKey(_selectedWeek1!);
      final week1End = week1Start.add(const Duration(days: 7));
      final week2Start = _parseWeekKey(_selectedWeek2!);
      final week2End = week2Start.add(const Duration(days: 7));

      // Get photos for both weeks
      final response = await _supabase
          .from('progress_photos')
          .select()
          .eq('user_id', widget.clientId)
          .or('and(taken_at.gte.${week1Start.toIso8601String()},taken_at.lt.${week1End.toIso8601String()}),and(taken_at.gte.${week2Start.toIso8601String()},taken_at.lt.${week2End.toIso8601String()})')
          .order('taken_at', ascending: false);

      final photos = (response as List<dynamic>)
          .map((photo) => CheckinPhoto.fromMap(photo as Map<String, dynamic>))
          .toList();

      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  DateTime _parseWeekKey(String weekKey) {
    final parts = weekKey.split('-W');
    final year = int.parse(parts[0]);
    final weekNumber = int.parse(parts[1]);
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToAdd = (weekNumber - 1) * 7;
    return firstDayOfYear.add(Duration(days: daysToAdd));
  }

  CheckinPhoto? _getPhotoForWeekAndPose(String weekKey, String pose) {
    final weekStart = _parseWeekKey(weekKey);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return _photos.where((photo) {
      final isInWeek = photo.takenAt.isAfter(weekStart) && photo.takenAt.isBefore(weekEnd);
      final matchesPose = photo.shotType == pose || (pose == 'front' && photo.shotType == null);
      return isInWeek && matchesPose;
    }).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Compare Check-ins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Week selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeekSelector('Week 1', _selectedWeek1, (value) {
                          setState(() {
                            _selectedWeek1 = value;
                          });
                          _loadPhotosForComparison();
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildWeekSelector('Week 2', _selectedWeek2, (value) {
                          setState(() {
                            _selectedWeek2 = value;
                          });
                          _loadPhotosForComparison();
                        }),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pose selector
                  _buildPoseSelector(),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
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
                                'Error loading photos',
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
                                onPressed: _loadPhotosForComparison,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _buildComparisonView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector(String label, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _availableWeeks.map((week) {
            final weekStart = _parseWeekKey(week);
            final weekEnd = weekStart.add(const Duration(days: 6));
            return DropdownMenuItem(
              value: week,
              child: Text('${_formatDate(weekStart)} - ${_formatDate(weekEnd)}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPoseSelector() {
    return Row(
      children: [
        const Text(
          'Pose: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(width: 8),
        ..._poses.map((pose) {
          final isSelected = _selectedPose == pose;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(pose.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPose = pose;
                  });
                }
              },
              selectedColor: AppTheme.primaryDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildComparisonView() {
    if (_selectedWeek1 == null || _selectedWeek2 == null) {
      return const Center(
        child: Text(
          'Select two weeks to compare',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final photo1 = _getPhotoForWeekAndPose(_selectedWeek1!, _selectedPose);
    final photo2 = _getPhotoForWeekAndPose(_selectedWeek2!, _selectedPose);

    return Column(
      children: [
        // Comparison header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatWeekLabel(_selectedWeek1!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Icon(
                Icons.compare_arrows,
                color: AppTheme.primaryDark,
              ),
              Expanded(
                child: Text(
                  _formatWeekLabel(_selectedWeek2!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Photos comparison
        Expanded(
          child: Row(
            children: [
              // Week 1 photo
              Expanded(
                child: _buildPhotoView(photo1, _selectedWeek1!),
              ),
              
              // Divider
              Container(
                width: 2,
                color: AppTheme.lightGrey,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              
              // Week 2 photo
              Expanded(
                child: _buildPhotoView(photo2, _selectedWeek2!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoView(CheckinPhoto? photo, String weekLabel) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Photo or placeholder
          Expanded(
            child: photo != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No photo available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // Photo info
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  _formatWeekLabel(weekLabel),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                if (photo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(photo.takenAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeekLabel(String weekKey) {
    final weekStart = _parseWeekKey(weekKey);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
