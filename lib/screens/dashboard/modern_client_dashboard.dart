import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/progress/progress_service.dart';
import '../../services/nutrition/grocery_service.dart';
import '../../services/nutrition/calendar_bridge.dart';
import '../../models/nutrition/nutrition_plan.dart';

class ModernClientDashboard extends StatefulWidget {
  const ModernClientDashboard({super.key});

  @override
  State<ModernClientDashboard> createState() => _ModernClientDashboardState();
}

class _ModernClientDashboardState extends State<ModernClientDashboard> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  List<NutritionPlan> _nutritionPlans = [];
  Map<String, dynamic>? _dailyProgress;
  
  final NutritionService _nutritionService = NutritionService();
  final ProgressService _progressService = ProgressService();
  final GroceryService _groceryService = GroceryService();
  final NutritionCalendarBridge _calendarBridge = NutritionCalendarBridge();
  String? _error;
  bool _showProfileDropdown = false;
  
  // Mock data for the design
  final String _selectedNutritionPlan = 'Muscle Gain Protocol';
  final int _currentCalories = 2340;
  final int _targetCalories = 2800;
  final int _currentProtein = 163;
  final int _targetProtein = 180;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Load profile data
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      // Load nutrition plans for the user
      final nutritionPlans = await _nutritionService.fetchPlansForClient(user.id);

      // Load daily progress (today's metrics)
      final today = DateTime.now().toIso8601String().split('T')[0];
      final progressData = await _progressService.fetchMetrics(user.id);
      final todayProgress = progressData.isNotEmpty 
          ? progressData.firstWhere(
              (metric) => metric['date'] == today,
              orElse: () => {},
            )
          : {};

      if (mounted) {
        setState(() {
          _profile = profileResponse;
          _nutritionPlans = nutritionPlans;
          _dailyProgress = Map<String, dynamic>.from(todayProgress);
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.mintAqua),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      drawerEdgeDragWidth: 24,
      drawer: VagusSideMenu(
        isClient: true,
        onLogout: _logout,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with hamburger menu, welcome message, and profile dropdown
              _buildHeader(),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Nutrition Plans Section
              _buildNutritionPlansSection(),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Daily Summary Section
              _buildDailySummarySection(),
              
              const SizedBox(height: DesignTokens.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Hamburger menu
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        
        // Welcome message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${_profile?['full_name'] ?? _profile?['name'] ?? 'User'}!',
                style: DesignTokens.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to crush your fitness goals today?',
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        
        // Profile dropdown
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showProfileDropdown = !_showProfileDropdown;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.mintAqua,
                    backgroundImage: _profile?['avatar_url'] != null 
                      ? NetworkImage(_profile!['avatar_url']) 
                      : null,
                    child: _profile?['avatar_url'] == null 
                      ? Text(
                          (_profile?['first_name'] ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
            
            // Dropdown menu
            if (_showProfileDropdown)
              Positioned(
                top: 40,
                right: 0,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.white, size: 16),
                        title: Text(
                          'Edit Profile',
                          style: DesignTokens.bodySmall.copyWith(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() => _showProfileDropdown = false);
                          _goToEditProfile();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red, size: 16),
                        title: Text(
                          'Logout',
                          style: DesignTokens.bodySmall.copyWith(color: Colors.red),
                        ),
                        onTap: () {
                          setState(() => _showProfileDropdown = false);
                          _logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Nutrition Plans',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space12),
        
        // Dropdown selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _nutritionPlans.isNotEmpty 
                      ? _nutritionPlans.first.name 
                      : 'No nutrition plans',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Nutrition plan card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and tag
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _nutritionPlans.isNotEmpty 
                          ? _nutritionPlans.first.name 
                          : 'No nutrition plan',
                      style: DesignTokens.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mintAqua,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bulking',
                      style: DesignTokens.bodySmall.copyWith(
                        color: AppTheme.primaryBlack,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Created info
              Text(
                'Created March 1, 2024 • By Coach Sarah',
                style: DesignTokens.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: DesignTokens.space16),
              
              // Metrics
              Row(
                children: [
                  _buildMetricTag('\$45/week'),
                  const SizedBox(width: 8),
                  _buildMetricTag('2,800 calories/day'),
                  const SizedBox(width: 8),
                  _buildMetricTag('180g protein'),
                ],
              ),
              
              const SizedBox(height: DesignTokens.space16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Export PDF',
                      Icons.description,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Grocery List',
                      Icons.shopping_cart,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Add to Calendar',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Prep Reminders',
                      Icons.notifications,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummarySection() {
    // Get real progress data or use defaults
    final currentCalories = _dailyProgress?['calories_consumed'] ?? _currentCalories;
    final targetCalories = _dailyProgress?['calorie_target'] ?? _targetCalories;
    final currentProtein = _dailyProgress?['protein_consumed'] ?? _currentProtein;
    final targetProtein = _dailyProgress?['protein_target'] ?? _targetProtein;
    
    final calorieProgress = targetCalories > 0 ? currentCalories / targetCalories : 0.0;
    final proteinProgress = targetProtein > 0 ? currentProtein / targetProtein : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Daily Summary',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Daily summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Circular progress indicator
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    // Background circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 8,
                        ),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: calorieProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintAqua),
                      ),
                    ),
                    // Center text
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$currentCalories',
                            style: DesignTokens.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            '/$targetCalories',
                            style: DesignTokens.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DesignTokens.space24),
              
              // Progress bars
              _buildProgressBar(
                'Calories',
                currentCalories,
                targetCalories,
                AppTheme.mintAqua,
              ),
              
              const SizedBox(height: DesignTokens.space12),
              
              _buildProgressBar(
                'Protein',
                currentProtein,
                targetProtein,
                AppTheme.softYellow,
                showPercentage: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: DesignTokens.bodySmall.copyWith(
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    return GestureDetector(
      onTap: () => _handleActionButton(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.mintAqua.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.mintAqua,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int current, int target, Color color, {bool showPercentage = false}) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: DesignTokens.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            if (showPercentage)
              Text(
                '$percentage%',
                style: DesignTokens.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                '$current/$target',
                style: DesignTokens.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action button handler
  void _handleActionButton(String action) {
    switch (action) {
      case 'Export PDF':
        _exportNutritionPlanToPDF();
        break;
      case 'Grocery List':
        _generateGroceryList();
        break;
      case 'Add to Calendar':
        _addToCalendar();
        break;
      case 'Prep Reminders':
        _addPrepReminders();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action feature coming soon!'),
            backgroundColor: AppTheme.mintAqua,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  // Export nutrition plan to PDF
  Future<void> _exportNutritionPlanToPDF() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Generate PDF using the existing service
      await _nutritionService.exportNutritionPlanToPdf(
        plan,
        'Your Coach',
        _profile?['name'] ?? 'Client',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate grocery list
  Future<void> _generateGroceryList() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available for grocery list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final plan = _nutritionPlans.first;
      
      // Show week selection dialog
      final weekIndex = await _showWeekSelectionDialog();
      if (weekIndex == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating grocery list...'),
            ],
          ),
        ),
      );

      // Generate grocery list
      final groceryList = await _groceryService.generateForPlanWeek(
        planId: plan.id!,
        weekIndex: weekIndex,
        ownerId: user.id,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to grocery list screen
      if (mounted) {
        Navigator.pushNamed(context, '/grocery-list', arguments: groceryList);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate grocery list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add nutrition plan to calendar
  Future<void> _addToCalendar() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available to add to calendar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding to calendar...'),
            ],
          ),
        ),
      );

      // Export to calendar
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: _convertPlanToMeals(plan),
        language: 'en',
        dayTitle: 'Nutrition Plan - ${plan.name}',
        includePrepReminders: false,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to calendar successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add prep reminders
  Future<void> _addPrepReminders() async {
    if (_nutritionPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No nutrition plan available for prep reminders'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final plan = _nutritionPlans.first;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Setting up prep reminders...'),
            ],
          ),
        ),
      );

      // Export to calendar with prep reminders
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: _convertPlanToMeals(plan),
        language: 'en',
        dayTitle: 'Prep Reminders - ${plan.name}',
        includePrepReminders: true,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prep reminders added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add prep reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to show week selection dialog
  Future<int?> _showWeekSelectionDialog() async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Week'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) => ListTile(
            title: Text('Week ${index + 1}'),
            onTap: () => Navigator.of(context).pop(index),
          )),
        ),
      ),
    );
  }

  // Helper method to convert nutrition plan to meals format
  Map<String, List<Map<String, dynamic>>> _convertPlanToMeals(NutritionPlan plan) {
    final meals = <String, List<Map<String, dynamic>>>{};
    
    for (final meal in plan.meals) {
      final mealType = meal.label.toLowerCase();
      final mealItems = <Map<String, dynamic>>[];
      
      for (final item in meal.items) {
        mealItems.add({
          'name': item.name,
          'prep_minutes': 0, // Default prep time
        });
      }
      
      meals[mealType] = mealItems;
    }
    
    return meals;
  }
}
