import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/locale_helper.dart';
import 'meal_editor.dart';
import 'nutrition_plan_builder.dart';
import '../../widgets/nutrition/daily_summary_card.dart';
import '../../widgets/nutrition/nutrition_update_ring.dart';
import '../supplements/supplement_list_screen.dart';


// Safe image handling helpers
bool _isValidHttpUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  return u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
}

Widget _imagePlaceholder({double? w, double? h}) {
  return Container(
    width: w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.image_not_supported),
  );
}

Widget safeNetImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (_isValidHttpUrl(url)) {
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(w: width, h: height),
    );
  }
  return _imagePlaceholder(w: width, h: height);
}

class NutritionPlanViewer extends StatefulWidget {
  final NutritionPlan? planOverride;

  const NutritionPlanViewer({
    super.key,
    this.planOverride,
  });

  @override
  State<NutritionPlanViewer> createState() => _NutritionPlanViewerState();
}

class _NutritionPlanViewerState extends State<NutritionPlanViewer> {
  final NutritionService _nutritionService = NutritionService();
  final supabase = Supabase.instance.client;

  NutritionPlan? _currentPlan;
  List<NutritionPlan> _plans = [];
  String? _selectedPlanId;
  String _role = 'client';
  bool _loading = true;
  bool _saving = false;
  String _error = '';


  @override
  void initState() {
    super.initState();
    if (widget.planOverride != null) {
      _currentPlan = widget.planOverride!;
      _selectedPlanId = _currentPlan!.id;
      _loading = false;
      _markPlanSeen();
      _populatePlansForContext();
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    debugPrint('🔍 NutritionPlanViewer: Starting _init()');
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ NutritionPlanViewer: No user found');
      setState(() {
        _error = 'No user.';
        _loading = false;
      });
      return;
    }

    debugPrint('👤 NutritionPlanViewer: User ID: ${user.id}');

    try {
      // Get role and profile
      debugPrint('🔍 NutritionPlanViewer: Loading profile...');
      final profile = await supabase
          .from('profiles')
          .select('role, name')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();
      debugPrint('👤 NutritionPlanViewer: Role: $_role, Name: ${profile['name']}');

      // Load plans
      debugPrint('🔍 NutritionPlanViewer: Loading nutrition plans...');
      final plans = await _nutritionService.fetchPlansForClient(user.id);
      debugPrint('📋 NutritionPlanViewer: Found ${plans.length} plans');

      setState(() {
        _plans = plans;
        if (_plans.isNotEmpty) {
          _currentPlan = _plans.first;
          _selectedPlanId = _currentPlan!.id;
          debugPrint('✅ NutritionPlanViewer: Set current plan: ${_currentPlan!.name}');
          _markPlanSeen();
          _loadCoachProfile();
        } else {
          _currentPlan = null;
          _selectedPlanId = null;
          _error = 'No nutrition plans found.';
          debugPrint('⚠️ NutritionPlanViewer: No plans found');
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ NutritionPlanViewer: Error in _init: $e');
      setState(() {
        _error = '❌ Failed to load data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _populatePlansForContext() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Ensure role is known
      if (_role.isEmpty) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        _role = (profile['role'] ?? 'client').toString();
      }

      final plans = await _nutritionService.fetchPlansForClient(user.id);

      setState(() {
        _plans = plans;
        // Ensure the current plan is present in the list for the dropdown
        if (_currentPlan != null &&
            _plans.every((p) => p.id != _currentPlan!.id)) {
          _plans = [_currentPlan!, ..._plans];
        }
      });
    } catch (e) {
      // Silently ignore to avoid blocking UI; dropdown will just be empty
    }
  }

  Future<void> _markPlanSeen() async {
    if (_currentPlan?.id != null && _currentPlan!.unseenUpdate) {
      try {
        await _nutritionService.markPlanSeen(_currentPlan!.id!);
        setState(() {
          _currentPlan = _currentPlan!.copyWith(unseenUpdate: false);
        });
      } catch (e) {
        // Silently ignore
      }
    }
  }

  void _onSelectPlan(String? id) {
    if (id == null) return;
    final found = _plans.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Plan not found'),
    );

    setState(() {
      _selectedPlanId = id;
      _currentPlan = found;
    });
    _markPlanSeen();
    _loadCoachProfile();
  }

  Future<void> _loadCoachProfile() async {
    if (_currentPlan == null) return;
    
    try {
      await supabase
          .from('profiles')
          .select('name')
          .eq('id', _currentPlan!.createdBy)
          .single();

      // Coach profile loaded successfully
    } catch (e) {
      // Silently ignore
    }
  }

  Future<void> _updateMealComment(int index, String? comment) async {
    if (_currentPlan == null) return;
    
    try {
      setState(() {
        _saving = true;
      });
      
      final updatedMeals = List<Meal>.from(_currentPlan!.meals);
      updatedMeals[index] = updatedMeals[index].copyWith(clientComment: comment);

      final updatedPlan = _currentPlan!.copyWith(meals: updatedMeals);
      
      await _nutritionService.updatePlan(updatedPlan);
      
      if (!mounted) return;
      setState(() {
        _currentPlan = updatedPlan;
        _saving = false;
      });
      
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment saved!')),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save comment: $e')),
      );
    }
  }

  Future<void> _exportToPDF() async {
    if (_currentPlan == null) return;

    try {
      setState(() {
        _saving = true;
      });

      // Show a loading dialog
      await showDialog(
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

      // Generate PDF
      final pdf = pw.Document();
      
      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildPDFContent(),
        ),
      );

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'nutrition_plan_${_currentPlan!.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Save PDF to file
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message and open PDF
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully! Opening...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Open PDF for viewing
        unawaited(Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Nutrition Plan - ${_currentPlan!.name}',
        ));
      }

      setState(() {
        _saving = false;
      });
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<pw.Widget> _buildPDFContent() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    return [
      // Header
      pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Nutrition Plan',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      
      pw.SizedBox(height: 20),
      
      // Plan Information
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Plan: ${_currentPlan!.name}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Type: ${_getLengthTypeDisplayName(_currentPlan!.lengthType)}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Created: ${_currentPlan!.createdAt.toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      
      pw.SizedBox(height: 20),
      
      // Meals Section
      if (_currentPlan!.meals.isNotEmpty) ...[
        pw.Text(
          'Meals',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        
        ..._currentPlan!.meals.map((meal) => _buildMealPDFSection(meal, language)),
        
        pw.SizedBox(height: 20),
        
        // Daily Summary
        pw.Text(
          'Daily Summary',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItemPDF('Protein', '${_currentPlan!.dailySummary.totalProtein.toStringAsFixed(1)}g', PdfColors.red),
              _buildSummaryItemPDF('Carbs', '${_currentPlan!.dailySummary.totalCarbs.toStringAsFixed(1)}g', PdfColors.orange),
              _buildSummaryItemPDF('Fat', '${_currentPlan!.dailySummary.totalFat.toStringAsFixed(1)}g', PdfColors.yellow),
              _buildSummaryItemPDF('Calories', '${_currentPlan!.dailySummary.totalKcal.toStringAsFixed(0)} kcal', PdfColors.green),
            ],
          ),
        ),
      ] else ...[
        pw.Text(
          'No meals in plan',
          style: pw.TextStyle(
            fontSize: 16,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey,
          ),
        ),
      ],
    ];
  }

  pw.Widget _buildMealPDFSection(Meal meal, String language) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            meal.label,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          
          if (meal.items.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            
            // Food items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Food Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Protein', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Carbs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Fat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Calories', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                
                // Data rows
                ...meal.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.name),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.amount.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.protein.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.carbs.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${item.fat.toStringAsFixed(1)}g'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.kcal.toStringAsFixed(0)),
                    ),
                  ],
                )),
              ],
            ),
            
            // Meal summary
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
              child: pw.Text(
                'Meal Total: ${meal.mealSummary.totalProtein.toStringAsFixed(1)}g protein, '
                '${meal.mealSummary.totalCarbs.toStringAsFixed(1)}g carbs, '
                '${meal.mealSummary.totalFat.toStringAsFixed(1)}g fat, '
                '${meal.mealSummary.totalKcal.toStringAsFixed(0)} calories',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
          
          // Client comment if exists
          if (meal.clientComment.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
              child: pw.Text(
                'Note: ${meal.clientComment}',
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItemPDF(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get global language from context
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    debugPrint('🔍 NutritionPlanViewer: build() called - loading: $_loading, error: $_error, currentPlan: ${_currentPlan?.name ?? "null"}');

    if (_loading) {
      debugPrint('⏳ NutritionPlanViewer: Showing loading state');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentPlan == null) {
      debugPrint('⚠️ NutritionPlanViewer: Showing no plan state - error: $_error');
      return Scaffold(
        appBar: AppBar(
          title: Text(LocaleHelper.t('nutrition', language)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            // Supplements Button
            IconButton(
              icon: const Icon(Icons.medication_outlined),
              tooltip: 'Supplements',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupplementListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              LocaleHelper.t('nutrition', language),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                        _error.isEmpty 
                            ? LocaleHelper.t('no_nutrition_plan', language)
                            : _error,
                        style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _role == 'client' 
                            ? LocaleHelper.t('coach_will_create_plan', language)
                            : LocaleHelper.t('no_plans_found', language),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick actions for coaches
              if (_role == 'coach') ...[
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NutritionPlanBuilder(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Nutrition Plan'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
              
              // Nutrition tips card
              const SizedBox(height: 24),
              Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                        'Nutrition Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        Icons.water_drop,
                        'Stay hydrated throughout the day',
                        'Drink at least 8 glasses of water daily',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        Icons.eco,
                        'Eat a balanced diet',
                        'Include protein, carbs, and healthy fats in each meal',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        Icons.schedule,
                        'Eat regularly',
                        'Try to eat every 3-4 hours to maintain energy levels',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the actual nutrition plan
    if (_currentPlan != null) {
      debugPrint('✅ NutritionPlanViewer: Showing plan: ${_currentPlan!.name}');
      return Scaffold(
        appBar: AppBar(
          title: Text(LocaleHelper.t('nutrition', language)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            // Supplements Button
            IconButton(
              icon: const Icon(Icons.medication_outlined),
              tooltip: 'Supplements',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupplementListScreen(),
                  ),
                );
              },
            ),
            // PDF Export Button
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export as PDF',
              onPressed: _exportToPDF,
            ),
            if (_role == 'client' && _saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              // IMMEDIATE FALLBACK - Always show this first
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                          'Plan Loaded Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan: ${_currentPlan!.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('Role: $_role'),
                    Text('Plans count: ${_plans.length}'),
                    Text('Loading: $_loading'),
                    Text('Error: $_error'),
                  ],
                ),
              ),
              
              // Plan selector (only show if multiple plans exist)
              if (_plans.length > 1) ...[
                _buildPlanSelector(),
                const SizedBox(height: 16),
              ],
              
              // Plan info
              _buildPlanInfo(),
              
              const SizedBox(height: 16),
              
              // Meals
              if (_currentPlan!.meals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      LocaleHelper.t('no_meals_in_plan', language),
                            style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                _buildMealsList(),
              
              const SizedBox(height: 24),
              
              // Daily summary
              _buildDailySummary(),
              
              const SizedBox(height: 48), // Breathing room for bottom gesture area
            ],
          ),
        ),
      );
    }

    // FALLBACK: If we somehow get here, show a basic UI
    debugPrint('🚨 NutritionPlanViewer: FALLBACK UI - something went wrong');
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleHelper.t('nutrition', language)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Supplements Button
          IconButton(
            icon: const Icon(Icons.medication_outlined),
            tooltip: 'Supplements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupplementListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Loading: $_loading\nError: $_error\nRole: $_role\nPlans: ${_plans.length}\nCurrent: ${_currentPlan?.name ?? "null"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
    );
  }

  Color _getLengthTypeColor(String lengthType) {
    switch (lengthType) {
      case 'daily':
        return Colors.green;
      case 'weekly':
        return Colors.blue;
      case 'program':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getLengthTypeDisplayName(String lengthType) {
    // Get global language from context
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    switch (lengthType) {
      case 'daily':
        return LocaleHelper.t('daily', language);
      case 'weekly':
        return LocaleHelper.t('weekly', language);
      case 'program':
        return LocaleHelper.t('program', language);
      default:
        return LocaleHelper.t('unknown', language);
    }
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelector() {
    try {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPlanId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _plans.map((plan) {
                      return DropdownMenuItem<String>(
                  value: plan.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                        child: Text(
                          plan.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (plan.unseenUpdate)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: NutritionUpdateRing(
                                hasUnseenUpdate: true,
                                size: 16,
                          ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _onSelectPlan,
                  ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error rendering plan selector: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading plan selector: $e'),
      );
    }
  }

  Widget _buildPlanInfo() {
    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentPlan!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
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
                                  color: _getLengthTypeColor(_currentPlan!.lengthType),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getLengthTypeDisplayName(_currentPlan!.lengthType),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                '${LocaleHelper.t('created', language)}: ${_currentPlan!.createdAt.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
              const SizedBox(height: 16),
              // PDF Export Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export Nutrition Plan as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error rendering plan info: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading plan info: $e'),
      );
    }
  }

  Widget _buildMealsList() {
    try {
      return Column(
        children: _currentPlan!.meals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final meal = entry.value;
          try {
                      return MealEditor(
                        meal: meal,
                        onMealChanged: (updatedMeal) {
                          // For clients, allow comment updates
                          if (_role == 'client' && updatedMeal.clientComment != meal.clientComment) {
                            _updateMealComment(index, updatedMeal.clientComment);
                          }
                        },
                        isReadOnly: _role != 'client', // Allow editing for clients
                        isClientView: _role == 'client',
                        onCommentSave: _role == 'client' ? () => _updateMealComment(index, meal.clientComment) : null,
            );
          } catch (e) {
            debugPrint('❌ Error rendering meal $index: $e');
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.red.shade50,
              child: Text('Error loading meal $index: $e'),
            );
          }
                    }).toList(),
      );
    } catch (e) {
      debugPrint('❌ Error rendering meals list: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading meals: $e'),
      );
    }
  }

  Widget _buildDailySummary() {
    try {
      return DailySummaryCard(
        summary: _currentPlan!.dailySummary,
      );
    } catch (e) {
      debugPrint('❌ Error rendering daily summary: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading daily summary: $e'),
      );
    }
  }
}
