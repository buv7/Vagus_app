import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
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
  String _role = 'client';
  
  final ProgressService _progressService = ProgressService();

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

  final List<Map<String, dynamic>> _mockMeasurements = [
    {
      'metric': 'Weight',
      'current': 75.5,
      'previous': 76.2,
      'unit': 'kg',
      'trend': 'down',
      'change': -0.7,
    },
    {
      'metric': 'Body Fat',
      'current': 12.5,
      'previous': 13.1,
      'unit': '%',
      'trend': 'down',
      'change': -0.6,
    },
    {
      'metric': 'Muscle Mass',
      'current': 68.2,
      'previous': 67.8,
      'unit': 'kg',
      'trend': 'up',
      'change': 0.4,
    },
    {
      'metric': 'Chest',
      'current': 102.5,
      'previous': 101.8,
      'unit': 'cm',
      'trend': 'up',
      'change': 0.7,
    },
    {
      'metric': 'Waist',
      'current': 78.2,
      'previous': 79.1,
      'unit': 'cm',
      'trend': 'down',
      'change': -0.9,
    },
    {
      'metric': 'Arms',
      'current': 35.8,
      'previous': 35.2,
      'unit': 'cm',
      'trend': 'up',
      'change': 0.6,
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

      // Get user role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();

      // Load progress photos from progress_photos table
      final photosResponse = await Supabase.instance.client
          .from('progress_photos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Load measurements from measurements table
      final measurementsResponse = await Supabase.instance.client
          .from('measurements')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _progressPhotos = List<Map<String, dynamic>>.from(photosResponse);
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
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: SafeArea(
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.mintAqua,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading progress data',
                          style: DesignTokens.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadProgressData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mintAqua,
                            foregroundColor: AppTheme.primaryBlack,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header with hamburger menu
                      _buildHeader(),

                      // Tab Selector
            _buildTabSelector(),

            // Timeframe Selector
            _buildTimeframeSelector(),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Hamburger menu
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              'Progress',
              style: DesignTokens.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Add button
          IconButton(
            onPressed: () {
              _showAddProgressDialog();
            },
            icon: const Icon(Icons.add, color: AppTheme.mintAqua),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'photos',
                  label: Text('Photos'),
                  icon: Icon(Icons.camera_alt),
                ),
                ButtonSegment(
                  value: 'measurements',
                  label: Text('Measurements'),
                  icon: Icon(Icons.straighten),
                ),
                ButtonSegment(
                  value: 'goals',
                  label: Text('Goals'),
                  icon: Icon(Icons.flag),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTab = selection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.mintAqua;
                    }
                    return AppTheme.cardBackground;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryBlack;
                    }
                    return Colors.white;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Row(
        children: [
          Text(
            'Timeframe:',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'year', label: Text('Year')),
              ],
              selected: {_selectedTimeframe},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTimeframe = selection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.mintAqua.withOpacity(0.3);
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.mintAqua;
                    }
                    return Colors.white70;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 'photos':
        return _buildPhotosTab();
      case 'measurements':
        return _buildMeasurementsTab();
      case 'goals':
        return _buildGoalsTab();
      default:
        return _buildPhotosTab();
    }
  }

  Widget _buildPhotosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary
          _buildProgressSummary(),
          const SizedBox(height: DesignTokens.space24),

          // Photo Gallery
          Text(
            'Progress Photos',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._progressPhotos.map((photo) => _buildProgressPhotoCard(photo)),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final latestPhoto = _progressPhotos.first;
    final previousPhoto = _progressPhotos.length > 1 ? _progressPhotos[1] : null;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Summary',
            style: DesignTokens.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          Row(
            children: [
              // Latest Photo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.mintAqua,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: AppTheme.mintAqua,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space16),
              
              // Comparison Arrow
              if (previousPhoto != null) ...[
                const Icon(
                  Icons.arrow_forward,
                  color: AppTheme.mintAqua,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.space16),
                
                // Previous Photo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white70,
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
                  _buildStatItem('Weight', '${latestPhoto['weight']} kg', AppTheme.mintAqua),
                  _buildStatItem('Body Fat', '${latestPhoto['bodyFat']}%', AppTheme.softYellow),
                  _buildStatItem('Muscle', '${latestPhoto['muscle']} kg', const Color(0xFFD4A574)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotoCard(Map<String, dynamic> photo) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(photo['date']),
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mintAqua.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.mintAqua.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${photo['weight']} kg',
                  style: DesignTokens.bodySmall.copyWith(
                    color: AppTheme.mintAqua,
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
              color: AppTheme.primaryBlack.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                color: AppTheme.mintAqua,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          
          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Body Fat', '${photo['bodyFat']}%', AppTheme.softYellow),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: _buildMetricCard('Muscle', '${photo['muscle']} kg', const Color(0xFFD4A574)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space12),
          
          // Notes
          if (photo['notes'] != null) ...[
            Text(
              'Notes:',
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              photo['notes'],
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Measurements',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._measurements.map((measurement) => _buildMeasurementCard(measurement)),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Map<String, dynamic> measurement) {
    final isPositive = measurement['trend'] == 'up';
    final changeColor = isPositive ? AppTheme.mintAqua : AppTheme.softYellow;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Metric Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${measurement['current']} ${measurement['unit']}',
                      style: DesignTokens.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals & Targets',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space16),
          
          ..._goals.map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = goal['progress'] as double;
    final daysLeft = goal['deadline'].difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: daysLeft > 30 
                    ? AppTheme.mintAqua.withOpacity(0.2)
                    : daysLeft > 7
                      ? AppTheme.softYellow.withOpacity(0.2)
                      : const Color(0xFFD4A574).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: daysLeft > 30 
                      ? AppTheme.mintAqua.withOpacity(0.3)
                      : daysLeft > 7
                        ? AppTheme.softYellow.withOpacity(0.3)
                        : const Color(0xFFD4A574).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: DesignTokens.bodySmall.copyWith(
                    color: daysLeft > 30 
                      ? AppTheme.mintAqua
                      : daysLeft > 7
                        ? AppTheme.softYellow
                        : const Color(0xFFD4A574),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: AppTheme.mintAqua,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.mintAqua,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Add Progress Entry',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Progress entry functionality would be implemented here.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintAqua,
              foregroundColor: AppTheme.primaryBlack,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
