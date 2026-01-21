import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/progress/progress_service.dart';

class ModernProgressTracker extends StatefulWidget {
  const ModernProgressTracker({super.key});

  @override
  State<ModernProgressTracker> createState() => _ModernProgressTrackerState();
}

class _ModernProgressTrackerState extends State<ModernProgressTracker> {
  String _selectedTab = 'photos';
  String _selectedTimeframe = 'week';

  // Real data from Supabase
  List<Map<String, dynamic>> _progressPhotos = [];
  List<Map<String, dynamic>> _measurements = [];
  bool _isLoading = true;
  String? _error;
  
  // Progress service instance
  final ProgressService _progressService = ProgressService();
  final ImagePicker _imagePicker = ImagePicker();

  // Mock data as fallback
  final List<Map<String, dynamic>> _mockProgressPhotos = [
    {
      'id': '1',
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'weight': 75.5,
      'bodyFat': 12.5,
      'muscle': 68.2,
      'notes': 'Feeling great after the new program!',
      'imageUrl': '/progress-photo-1.jpg',
    },
    {
      'id': '2',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'weight': 76.2,
      'bodyFat': 13.1,
      'muscle': 67.8,
      'notes': 'Good progress this week',
      'imageUrl': '/progress-photo-2.jpg',
    },
    {
      'id': '3',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'weight': 77.0,
      'bodyFat': 13.8,
      'muscle': 67.2,
      'notes': 'Starting to see definition',
      'imageUrl': '/progress-photo-3.jpg',
    },
    {
      'id': '4',
      'date': DateTime.now().subtract(const Duration(days: 21)),
      'weight': 77.8,
      'bodyFat': 14.2,
      'muscle': 66.9,
      'notes': 'Baseline measurements',
      'imageUrl': '/progress-photo-4.jpg',
    },
  ];


  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Weight Loss',
      'target': 72.0,
      'current': 75.5,
      'unit': 'kg',
      'progress': 0.7,
      'deadline': DateTime.now().add(const Duration(days: 60)),
    },
    {
      'title': 'Body Fat Reduction',
      'target': 10.0,
      'current': 12.5,
      'unit': '%',
      'progress': 0.6,
      'deadline': DateTime.now().add(const Duration(days: 90)),
    },
    {
      'title': 'Muscle Gain',
      'target': 70.0,
      'current': 68.2,
      'unit': 'kg',
      'progress': 0.3,
      'deadline': DateTime.now().add(const Duration(days: 120)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load progress photos from progress_photos table
      final photosResponse = await Supabase.instance.client
          .from('progress_photos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Load measurements from client_metrics table
      final measurementsResponse = await Supabase.instance.client
          .from('client_metrics')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          // Transform Supabase data to expected format
          _progressPhotos = (photosResponse as List).map((photo) {
            final createdAt = photo['created_at'];
            DateTime date;
            if (createdAt is DateTime) {
              date = createdAt;
            } else if (createdAt is String) {
              date = DateTime.tryParse(createdAt) ?? DateTime.now();
            } else {
              date = DateTime.now();
            }
            
            return {
              'id': photo['id']?.toString() ?? '',
              'date': date,
              'weight': photo['weight'] ?? 0.0,
              'bodyFat': photo['body_fat'] ?? photo['bodyFat'] ?? 0.0,
              'muscle': photo['muscle_mass'] ?? photo['muscle'] ?? 0.0,
              'notes': photo['notes'] ?? '',
              'imageUrl': photo['image_url'] ?? photo['imageUrl'] ?? '',
            };
          }).toList();
          _measurements = List<Map<String, dynamic>>.from(measurementsResponse);
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Use mock data as fallback
          _progressPhotos = _mockProgressPhotos;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBg(context),
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: SafeArea(
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.accentBlue,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: DesignTokens.accentPink,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading progress data',
                          style: DesignTokens.titleMedium.copyWith(
                            color: DesignTokens.textColor(context),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: DesignTokens.textColorSecondary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadProgressData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header with hamburger menu
                      _buildHeader(isDark),

                      // Tab Selector
                      _buildTabSelector(isDark),

                      // Timeframe Selector
                      _buildTimeframeSelector(isDark),

                      // Content
                      Expanded(
                        child: _buildContent(isDark),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0B1220);
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: isDark 
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.2),
                      DesignTokens.accentBlue.withValues(alpha: 0.05),
                    ]
                  : [
                      DesignTokens.accentBlue.withValues(alpha: 0.08),
                      DesignTokens.accentBlue.withValues(alpha: 0.02),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? DesignTokens.accentBlue.withValues(alpha: 0.15)
                      : DesignTokens.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: isDark 
                        ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                        : DesignTokens.accentBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: iconColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: DesignTokens.space12),

              // Title
              Expanded(
                child: Text(
                  'Progress',
                  style: DesignTokens.titleLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Add button
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                      : DesignTokens.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: isDark 
                        ? DesignTokens.accentBlue.withValues(alpha: 0.4)
                        : DesignTokens.accentBlue.withValues(alpha: 0.3),
                  ),
                  boxShadow: isDark ? [
                    BoxShadow(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
                child: IconButton(
                  onPressed: () {
                    _showAddProgressDialog();
                  },
                  icon: const Icon(Icons.add, color: DesignTokens.accentBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : DesignTokens.accentBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(
                color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.accentBlue.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabItem('photos', 'Photos', Icons.camera_alt, isDark),
                _buildTabItem('measurements', 'Measurements', Icons.straighten, isDark),
                _buildTabItem('goals', 'Goals', Icons.flag, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String value, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == value;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final inactiveColor = isDark 
        ? Colors.white.withValues(alpha: 0.6) 
        : const Color(0xFF6B7280);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space8,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: isSelected
                ? Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.5 : 0.3),
                  )
                : null,
            boxShadow: isSelected && isDark
                ? [
                    BoxShadow(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? DesignTokens.accentBlue
                    : inactiveColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: DesignTokens.bodySmall.copyWith(
                    color: isSelected
                        ? textColor
                        : inactiveColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space12,
              vertical: DesignTokens.space8,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                  : DesignTokens.accentBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(
                color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : DesignTokens.accentBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                _buildTimeframeChip('week', 'Week', isDark),
                const SizedBox(width: DesignTokens.space8),
                _buildTimeframeChip('month', 'Month', isDark),
                const SizedBox(width: DesignTokens.space8),
                _buildTimeframeChip('year', 'Year', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String value, String label, bool isDark) {
    final isSelected = _selectedTimeframe == value;
    final inactiveColor = isDark 
        ? Colors.white.withValues(alpha: 0.6) 
        : const Color(0xFF6B7280);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                  : DesignTokens.accentBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          border: isSelected
              ? Border.all(
                  color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.5 : 0.3),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: DesignTokens.accentBlue,
                ),
              ),
            Text(
              label,
              style: DesignTokens.bodySmall.copyWith(
                color: isSelected
                    ? DesignTokens.accentBlue
                    : inactiveColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_selectedTab) {
      case 'photos':
        return _buildPhotosTab(isDark);
      case 'measurements':
        return _buildMeasurementsTab(isDark);
      case 'goals':
        return _buildGoalsTab(isDark);
      default:
        return _buildPhotosTab(isDark);
    }
  }

  Widget _buildPhotosTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary
          _buildProgressSummary(isDark),
          const SizedBox(height: DesignTokens.space24),

          // Photo Gallery
          Text(
            'Progress Photos',
            style: DesignTokens.titleLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._progressPhotos.map((photo) => _buildProgressPhotoCard(photo, isDark)),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF6B7280);
    
    if (_progressPhotos.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        DesignTokens.accentBlue.withValues(alpha: 0.15),
                        DesignTokens.accentBlue.withValues(alpha: 0.05),
                      ]
                    : [
                        DesignTokens.accentBlue.withValues(alpha: 0.08),
                        DesignTokens.accentBlue.withValues(alpha: 0.02),
                      ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              border: Border.all(
                color: isDark 
                    ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                    : DesignTokens.accentBlue.withValues(alpha: 0.2),
              ),
              boxShadow: isDark ? [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: DesignTokens.accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Text(
                      'Progress Summary',
                      style: DesignTokens.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space16),
                Center(
                  child: Text(
                    'No progress photos yet.\nTake your first progress photo to see your journey!',
                    textAlign: TextAlign.center,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final latestPhoto = _progressPhotos.first;
    final previousPhoto = _progressPhotos.length > 1 ? _progressPhotos[1] : null;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.15),
                      DesignTokens.accentBlue.withValues(alpha: 0.05),
                    ]
                  : [
                      DesignTokens.accentBlue.withValues(alpha: 0.08),
                      DesignTokens.accentBlue.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                  : DesignTokens.accentBlue.withValues(alpha: 0.2),
            ),
            boxShadow: isDark ? [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: DesignTokens.accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Text(
                    'Progress Summary',
                    style: DesignTokens.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
              
              Row(
                children: [
                  // Latest Photo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(
                        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.5 : 0.3),
                        width: 2,
                      ),
                      boxShadow: isDark ? [
                        BoxShadow(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ] : null,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: DesignTokens.accentBlue,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space16),
                  
                  // Comparison Arrow
                  if (previousPhoto != null) ...[
                    const Icon(
                      Icons.arrow_forward,
                      color: DesignTokens.accentBlue,
                      size: 24,
                    ),
                    const SizedBox(width: DesignTokens.space16),
                    
                    // Previous Photo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: isDark ? Colors.white70 : const Color(0xFF9CA3AF),
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatItem('Weight', '${latestPhoto['weight']} kg', DesignTokens.accentBlue, isDark),
                      _buildStatItem('Body Fat', '${latestPhoto['bodyFat']}%', DesignTokens.accentTeal, isDark),
                      _buildStatItem('Muscle', '${latestPhoto['muscle']} kg', DesignTokens.accentPurple, isDark),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: DesignTokens.bodySmall.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotoCard(Map<String, dynamic> photo, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF6B7280);
    
    // Safely get the date with fallback
    DateTime photoDate;
    final dateValue = photo['date'];
    if (dateValue is DateTime) {
      photoDate = dateValue;
    } else if (dateValue is String) {
      photoDate = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      photoDate = DateTime.now();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.space16),
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.12),
                      DesignTokens.accentBlue.withValues(alpha: 0.04),
                    ]
                  : [
                      DesignTokens.accentBlue.withValues(alpha: 0.06),
                      DesignTokens.accentBlue.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.25)
                  : DesignTokens.accentBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(photoDate),
                    style: DesignTokens.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(
                        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                    ),
                    child: Text(
                      '${photo['weight']} kg',
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Photo
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.15),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: DesignTokens.accentBlue,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Body Fat', '${photo['bodyFat']}%', DesignTokens.accentTeal, isDark),
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Expanded(
                    child: _buildMetricCard('Muscle', '${photo['muscle']} kg', DesignTokens.accentPurple, isDark),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Notes
              if (photo['notes'] != null) ...[
                Text(
                  'Notes:',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  photo['notes'],
                  style: DesignTokens.bodyMedium.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: DesignTokens.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DesignTokens.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Measurements',
            style: DesignTokens.titleLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._measurements.map((measurement) => _buildMeasurementCard(measurement, isDark)),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Map<String, dynamic> measurement, bool isDark) {
    final isPositive = measurement['trend'] == 'up';
    final changeColor = isPositive ? DesignTokens.accentTeal : DesignTokens.accentOrange;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.6) 
        : const Color(0xFF6B7280);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.space12),
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.12),
                      DesignTokens.accentBlue.withValues(alpha: 0.04),
                    ]
                  : [
                      DesignTokens.accentBlue.withValues(alpha: 0.06),
                      DesignTokens.accentBlue.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.25)
                  : DesignTokens.accentBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Metric Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: changeColor.withValues(alpha: isDark ? 0.3 : 0.25),
                  ),
                  boxShadow: isDark ? [
                    BoxShadow(
                      color: changeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
                child: Icon(
                  changeIcon,
                  color: changeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              
              // Metric Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement['metric'],
                      style: DesignTokens.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${measurement['current']} ${measurement['unit']}',
                          style: DesignTokens.bodyLarge.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: changeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(DesignTokens.radius8),
                            border: Border.all(
                              color: changeColor.withValues(alpha: isDark ? 0.3 : 0.25),
                            ),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${measurement['change']} ${measurement['unit']}',
                            style: DesignTokens.bodySmall.copyWith(
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Previous Value
              Text(
                'Previous: ${measurement['previous']} ${measurement['unit']}',
                style: DesignTokens.bodySmall.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals & Targets',
            style: DesignTokens.titleLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._goals.map((goal) => _buildGoalCard(goal, isDark)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, bool isDark) {
    final progress = goal['progress'] as double;
    final daysLeft = goal['deadline'].difference(DateTime.now()).inDays;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    
    // Get status color based on days left
    Color statusColor = daysLeft > 30 
        ? DesignTokens.accentTeal
        : daysLeft > 7
            ? DesignTokens.accentOrange
            : DesignTokens.accentPink;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.space16),
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.12),
                      DesignTokens.accentBlue.withValues(alpha: 0.04),
                    ]
                  : [
                      DesignTokens.accentBlue.withValues(alpha: 0.06),
                      DesignTokens.accentBlue.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: isDark 
                  ? DesignTokens.accentBlue.withValues(alpha: 0.25)
                  : DesignTokens.accentBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    goal['title'],
                    style: DesignTokens.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                    ),
                    child: Text(
                      '$daysLeft days left',
                      style: DesignTokens.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${goal['current']} / ${goal['target']} ${goal['unit']}',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [DesignTokens.accentBlue, DesignTokens.accentTeal],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isDark ? [
                            BoxShadow(
                              color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddProgressDialog() {
    // Show different dialogs based on the currently selected tab
    switch (_selectedTab) {
      case 'photos':
        _showAddPhotoDialog();
        break;
      case 'measurements':
        _showAddMeasurementDialog();
        break;
      case 'goals':
        _showAddGoalDialog();
        break;
      default:
        _showAddPhotoDialog();
    }
  }

  void _showAddPhotoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF6B7280);
    final dialogBg = isDark 
        ? DesignTokens.cardBackground 
        : Colors.white;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          side: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Icon(
                Icons.add_a_photo,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Text(
              'Add Progress Photo',
              style: DesignTokens.titleLarge.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Choose how you would like to add your progress photo.',
          style: DesignTokens.bodyMedium.copyWith(
            color: secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: secondaryTextColor,
            ),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadPhoto(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.accentBlue,
              side: const BorderSide(color: DesignTokens.accentBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickAndUploadPhoto(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to upload photos'),
              backgroundColor: DesignTokens.accentPink,
            ),
          );
        }
        return;
      }
      
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: DesignTokens.accentBlue,
            ),
          ),
        );
      }
      
      // Upload the photo using progress service
      await _progressService.uploadProgressPhoto(
        userId: user.id,
        imageFile: image,
        shotType: 'front', // Default, can be made selectable
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Refresh data
      await _loadProgressData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress photo uploaded successfully!'),
            backgroundColor: DesignTokens.accentGreen,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
    }
  }

  void _showAddMeasurementDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF6B7280);
    final dialogBg = isDark 
        ? DesignTokens.cardBackground 
        : Colors.white;
    final inputBg = isDark 
        ? DesignTokens.accentBlue.withValues(alpha: 0.1)
        : Colors.grey.shade100;
    
    // Controllers for form fields
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    final waistController = TextEditingController();
    final chestController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          side: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Icon(
                Icons.straighten,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Text(
              'Add Measurement',
              style: DesignTokens.titleLarge.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Weight field
              _buildMeasurementField(
                controller: weightController,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_outlined,
                isDark: isDark,
                inputBg: inputBg,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Body Fat field
              _buildMeasurementField(
                controller: bodyFatController,
                label: 'Body Fat (%)',
                icon: Icons.pie_chart_outline,
                isDark: isDark,
                inputBg: inputBg,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Waist field
              _buildMeasurementField(
                controller: waistController,
                label: 'Waist (cm)',
                icon: Icons.accessibility_new,
                isDark: isDark,
                inputBg: inputBg,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Chest field
              _buildMeasurementField(
                controller: chestController,
                label: 'Chest (cm)',
                icon: Icons.accessibility,
                isDark: isDark,
                inputBg: inputBg,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(height: DesignTokens.space12),
              
              // Notes field
              TextField(
                controller: notesController,
                maxLines: 2,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(Icons.notes, color: secondaryTextColor),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: BorderSide(
                      color: isDark 
                          ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    borderSide: const BorderSide(
                      color: DesignTokens.accentBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: secondaryTextColor,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveMeasurement(
                weight: double.tryParse(weightController.text),
                bodyFat: double.tryParse(bodyFatController.text),
                waist: double.tryParse(waistController.text),
                chest: double.tryParse(chestController.text),
                notes: notesController.text.isNotEmpty ? notesController.text : null,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color inputBg,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryTextColor),
        prefixIcon: Icon(icon, color: secondaryTextColor),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(
            color: DesignTokens.accentBlue,
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurement({
    double? weight,
    double? bodyFat,
    double? waist,
    double? chest,
    String? notes,
  }) async {
    // Check if at least one measurement is provided
    if (weight == null && bodyFat == null && waist == null && chest == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one measurement'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to save measurements'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
      return;
    }

    try {
      await _progressService.addMetric(
        userId: user.id,
        date: DateTime.now(),
        weightKg: weight,
        bodyFatPercent: bodyFat,
        waistCm: waist,
        chestCm: chest,
        notes: notes,
      );

      // Refresh data
      await _loadProgressData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement saved successfully!'),
            backgroundColor: DesignTokens.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurement: $e'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
    }
  }

  void _showAddGoalDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);
    final secondaryTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF6B7280);
    final dialogBg = isDark 
        ? DesignTokens.cardBackground 
        : Colors.white;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          side: BorderSide(
            color: isDark 
                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Icon(
                Icons.flag,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Text(
                'Add Goal',
                style: DesignTokens.titleLarge.copyWith(
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: secondaryTextColor,
            ),
            const SizedBox(height: DesignTokens.space12),
            Text(
              'Goal creation is coming soon!',
              style: DesignTokens.bodyMedium.copyWith(
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'For now, goals are managed by your coach. Contact your coach to set up personalized goals.',
              style: DesignTokens.bodySmall.copyWith(
                color: secondaryTextColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
