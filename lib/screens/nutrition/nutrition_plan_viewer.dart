import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/nutrition/nutrition_plan.dart';
import '../../models/nutrition/money.dart';
import '../../models/nutrition/supplement.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../../services/nutrition/grocery_service.dart';
import '../../services/nutrition/costing_service.dart';
import '../../services/nutrition/supplements_service.dart';
import '../../services/nutrition/integrations/pantry_grocery_adapter.dart';
import '../../services/nutrition/pantry_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../services/nutrition/calendar_bridge.dart';
import '../../widgets/branding/vagus_appbar.dart';
import 'nutrition_plan_builder.dart';
import '../../widgets/nutrition/daily_summary_card.dart';
import '../../widgets/nutrition/nutrition_update_ring.dart';
import '../../widgets/nutrition/meal_tile_card.dart';
import '../../widgets/nutrition/meal_detail_sheet.dart';
import '../../components/nutrition/cost_summary.dart';
import '../../components/nutrition/supplement_chip.dart';
import '../../components/nutrition/supplement_editor_sheet.dart';
import '../../components/nutrition/insights/day_insights_panel.dart';
import '../../services/haptics.dart';
import '../../services/ui/snackbar_throttle.dart';
import '../supplements/supplement_list_screen.dart';
import 'grocery_list_screen.dart';


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
  final CostingService _costing = CostingService();
  final SupplementsService _supplementsService = SupplementsService();
  final PantryGroceryAdapter _pantryAdapter = PantryGroceryAdapter(PantryService(), GroceryService());
  final supabase = Supabase.instance.client;

  NutritionPlan? _currentPlan;
  List<NutritionPlan> _plans = [];
  String? _selectedPlanId;
  String _role = 'client';
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  
  // Cost tracking
  final Map<int, Money> _dayCost = {};
  final Map<int, List<CostBreakdownRow>> _dayRows = {};
  Money _weekCost = Money.zero('USD');
  
  // Supplements tracking
  final Map<int, List<Supplement>> _daySupplements = {};
  
  // PDF capture keys
  final Map<int, GlobalKey> _donutKeys = {};
  final Map<int, GlobalKey> _gaugeKeys = {};


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
          _calculateCosts();
          _loadSupplements();
          _initializePdfKeys();
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
    _calculateCosts();
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

  Future<void> _calculateCosts() async {
    if (_currentPlan == null) return;
    
    try {
      // Calculate daily costs
      for (int i = 0; i < _currentPlan!.meals.length; i++) {
        final meal = _currentPlan!.meals[i];
        final cost = await _costing.estimateMealCost(meal);
        _dayCost[i] = cost;
        
        // Create breakdown rows for each meal
        final rows = <CostBreakdownRow>[];
        for (final item in meal.items) {
          final itemCost = await _costing.estimateMealCost(Meal(
            label: item.name,
            items: [item],
            mealSummary: MealSummary(
              totalProtein: item.protein,
              totalCarbs: item.carbs,
              totalFat: item.fat,
              totalKcal: item.kcal,
              totalSodium: item.sodium,
              totalPotassium: item.potassium,
            ),
          ));
          rows.add(CostBreakdownRow(item.name, itemCost));
        }
        _dayRows[i] = rows;
      }
      
      // Calculate weekly cost (sum of all days)
      _weekCost = _dayCost.values.fold(Money.zero('USD'), (sum, cost) => sum + cost);
      
      if (mounted) setState(() {});
    } catch (e) {
      // Silently ignore cost calculation errors
    }
  }

  Future<void> _loadSupplements() async {
    if (_currentPlan == null) return;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load supplements for each day
      for (int i = 0; i < _currentPlan!.meals.length; i++) {
        final supplements = await _supplementsService.listForDay(_currentPlan!.id ?? '', i);
        _daySupplements[i] = supplements;
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      // Silently ignore supplement loading errors
    }
  }

  void _initializePdfKeys() {
    if (_currentPlan == null) return;
    
    // Initialize PDF capture keys for each day
    for (int i = 0; i < _currentPlan!.meals.length; i++) {
      _donutKeys[i] = GlobalKey();
      _gaugeKeys[i] = GlobalKey();
    }
  }

  Future<void> _showSupplementEditor(int dayIndex) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final result = await showSupplementEditorSheet(
      context,
      initialName: null,
      initialDosage: null,
      initialTiming: null,
      initialNotes: null,
    );
    
    if (result != null) {
      try {
        final supplement = Supplement(
          id: null,
          planId: _currentPlan!.id ?? '',
          dayIndex: dayIndex,
          name: result.name,
          dosage: result.dosage,
          timing: result.timing,
          notes: result.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _supplementsService.add(supplement);
        Haptics.success();
        if (!mounted) return;
        SnackbarThrottle.showSnack(
          context,
          LocaleHelper.t('supplement_added', Localizations.localeOf(context).languageCode),
          backgroundColor: Colors.green,
        );
        await _loadSupplements();
      } catch (e) {
        debugPrint('❌ Error adding supplement: $e');
      }
    }
  }

  Future<void> _editSupplement(Supplement supplement, int dayIndex) async {
    final result = await showSupplementEditorSheet(
      context,
      initialName: supplement.name,
      initialDosage: supplement.dosage,
      initialTiming: supplement.timing,
      initialNotes: supplement.notes,
    );
    
    if (result != null) {
      try {
        final updatedSupplement = supplement.copyWith(
          name: result.name,
          dosage: result.dosage,
          timing: result.timing,
          notes: result.notes,
        );
        await _supplementsService.update(updatedSupplement);
        Haptics.success();
        if (!mounted) return;
        SnackbarThrottle.showSnack(
          context,
          LocaleHelper.t('supplement_updated', Localizations.localeOf(context).languageCode),
          backgroundColor: Colors.green,
        );
        await _loadSupplements();
      } catch (e) {
        debugPrint('❌ Error updating supplement: $e');
      }
    }
  }




  Future<void> _exportToPDF() async {
    if (_currentPlan == null) return;

    try {
      setState(() {
        _saving = true;
      });

      Haptics.tap();

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
          build: (context) => _buildEnhancedPDFContent(),
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
        Haptics.success();
        SnackbarThrottle.showSnack(
          context,
          'PDF generated successfully! Opening...',
          backgroundColor: Colors.green,
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
        Haptics.warning();
        SnackbarThrottle.showSnack(
          context,
          'Failed to generate PDF: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  List<pw.Widget> _buildEnhancedPDFContent() {
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
        
        // Cost Summary
        if (_weekCost.amount > 0) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Cost Summary',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItemPDF('Daily Cost', _dayCost.values.fold(Money.zero('USD'), (sum, cost) => sum + cost).toStringDisplay(locale: language), PdfColors.blue),
                _buildSummaryItemPDF('Weekly Cost', _weekCost.toStringDisplay(locale: language), PdfColors.blue),
              ],
            ),
          ),
        ],
        
        // Supplements Summary
        if (_daySupplements.isNotEmpty && _daySupplements.values.any((supplements) => supplements.isNotEmpty)) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Supplements',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ..._buildSupplementsPDF(),
        ],
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

  List<pw.Widget> _buildSupplementsPDF() {
    final supplementsList = <pw.Widget>[];
    
    for (final entry in _daySupplements.entries) {
      final dayIndex = entry.key;
      final supplements = entry.value;
      
      if (supplements.isNotEmpty) {
        supplementsList.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Day ${dayIndex + 1}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...supplements.map((supplement) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('• '),
                      pw.Expanded(
                        child: pw.Text(supplement.name),
                      ),
                      if (supplement.dosage != null && supplement.dosage!.isNotEmpty)
                        pw.Text(' (${supplement.dosage})'),
                      if (supplement.timing != null && supplement.timing!.isNotEmpty)
                        pw.Text(' - ${supplement.timing}'),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      }
    }
    
    return supplementsList;
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
        appBar: VagusAppBar(
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
        appBar: VagusAppBar(
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
              
              const SizedBox(height: 16),
              
              // Day Insights Panel
              _buildDayInsightsPanel(),
              
              const SizedBox(height: 16),
              
              // Supplements Section
              _buildSupplementsSection(),
              
              const SizedBox(height: 48), // Breathing room for bottom gesture area
            ],
          ),
        ),
      );
    }

    // FALLBACK: If we somehow get here, show a basic UI
    debugPrint('🚨 NutritionPlanViewer: FALLBACK UI - something went wrong');
    return Scaffold(
      appBar: VagusAppBar(
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
              
              // Cost summary chips
              if (_dayCost.isNotEmpty || _weekCost.amount > 0) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_dayCost.isNotEmpty)
                      CostSummaryChip(
                        labelKey: 'daily_cost',
                        amount: _dayCost.values.fold(Money.zero('USD'), (sum, cost) => sum + cost),
                        onTap: () => showCostBreakdownSheet(
                          context,
                          titleKey: 'daily_cost',
                          rows: _dayRows.values.expand((rows) => rows).toList(),
                          total: _dayCost.values.fold(Money.zero('USD'), (sum, cost) => sum + cost),
                        ),
                      ),
                    if (_weekCost.amount > 0)
                      CostSummaryChip(
                        labelKey: 'weekly_cost',
                        amount: _weekCost,
                        onTap: () => showCostBreakdownSheet(
                          context,
                          titleKey: 'weekly_cost',
                          rows: _dayRows.values.expand((rows) => rows).toList(),
                          total: _weekCost,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(LocaleHelper.t('export_pdf', language)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateGroceryList,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(LocaleHelper.t('generate_grocery', language)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Calendar actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addDayToCalendar,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(LocaleHelper.t('add_day_to_calendar', language)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addPrepReminders,
                      icon: const Icon(Icons.alarm),
                      label: Text(LocaleHelper.t('add_prep_reminders', language)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
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
      // Render name-only boxes with animated frame
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final meal in _currentPlan!.meals)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 16*2 - 12) / 2, // 2 per row on phones
              child: MealTileCard(
                title: meal.label,
                onTap: () => _openMealDetails(context, meal),
              ),
            ),
        ],
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

  Widget _buildDayInsightsPanel() {
    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleHelper.t('insights', language),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DayInsightsPanel(
                proteinG: _currentPlan!.dailySummary.totalProtein,
                carbsG: _currentPlan!.dailySummary.totalCarbs,
                fatG: _currentPlan!.dailySummary.totalFat,
                sodiumMg: _currentPlan!.dailySummary.totalSodium.round(),
                potassiumMg: _currentPlan!.dailySummary.totalPotassium.round(),
                kcal: _currentPlan!.dailySummary.totalKcal.round(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error rendering insights panel: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading insights: $e'),
      );
    }
  }

  Widget _buildSupplementsSection() {
    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      // Get all supplements across all days
      final allSupplements = <Supplement>[];
      for (final supplements in _daySupplements.values) {
        allSupplements.addAll(supplements);
      }
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    LocaleHelper.t('supplements', language),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_role == 'coach')
                    FloatingActionButton.small(
                      onPressed: () => _showSupplementEditor(0),
                      tooltip: LocaleHelper.t('add_supplement', language),
                      child: const Icon(Icons.add),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (allSupplements.isEmpty)
                Text(
                  LocaleHelper.t('no_supplements', language),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allSupplements.map((supplement) => GestureDetector(
                    onTap: _role == 'coach' ? () => _editSupplement(supplement, 0) : null,
                    child: SupplementChip(
                      name: supplement.name,
                      timing: supplement.timing ?? '',
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error rendering supplements section: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Text('Error loading supplements: $e'),
      );
    }
  }



  Future<void> _openMealDetails(BuildContext context, Meal meal) async {
    // Build the sub-widgets using your existing components so logic stays the same.
    // Reuse current inline sections (coach notes widget, items list, summary, attachments, comment field).
    final coachNotes = _buildCoachNotes(meal);
    final foodItems = _buildFoodItems(meal);
    final summary = _buildMealSummary(meal);
    final attachList = _buildAttachments(meal);
    final comment = _buildClientCommentEditor(meal);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close meal details',
      barrierColor: Colors.transparent, // we do our own tint + blur in the sheet
      pageBuilder: (ctx, _, __) {
        return MealDetailSheet(
          meal: meal,
          coachNotes: coachNotes,
          foodItems: foodItems,
          onAddFood: () => _onAddFood(meal),
          mealSummary: summary,
          attachments: attachList,
          onAddFile: () => _onAddAttachment(meal),
          clientComment: comment,
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        // subtle slide-up
        final offset = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return Semantics(
          label: 'Meal details sheet',
          container: true,
          focused: true,
          child: SlideTransition(position: offset, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  Widget _buildCoachNotes(Meal meal) {
    // Simple text display for coach notes - can be enhanced later
    return Text(
      'No coach notes available',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildFoodItems(Meal meal) {
    if (meal.items.isEmpty) {
      return Text(
        'No food items added yet',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: meal.items.map((item) {
        // Show recipe items with special styling
        if (item.recipeId != null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                // Recipe icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Recipe info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        '${item.servings.toStringAsFixed(1)} servings • ${item.kcal.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // See steps button
                TextButton.icon(
                  onPressed: () => _showRecipeSteps(item),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Steps'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Show regular food items
        return ListTile(
          title: Text(item.name),
          subtitle: Text('${item.amount.toStringAsFixed(1)}g'),
          trailing: Text('${item.kcal.toStringAsFixed(0)} kcal'),
        );
      }).toList(),
    );
  }

  Widget _buildMealSummary(Meal meal) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            'Protein',
            '${meal.mealSummary.totalProtein.toStringAsFixed(1)}g',
            Colors.red.shade600,
          ),
        ),
        Expanded(
          child: _buildSummaryItem(
            'Carbs',
            '${meal.mealSummary.totalCarbs.toStringAsFixed(1)}g',
            Colors.orange.shade600,
          ),
        ),
        Expanded(
          child: _buildSummaryItem(
            'Fat',
            '${meal.mealSummary.totalFat.toStringAsFixed(1)}g',
            Colors.yellow.shade700,
          ),
        ),
        Expanded(
          child: _buildSummaryItem(
            'Calories',
            '${meal.mealSummary.totalKcal.toStringAsFixed(0)} kcal',
            Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(Meal meal) {
    if (meal.attachments.isEmpty) {
      return Text(
        'No attachments',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: meal.attachments.map((attachment) => ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text(attachment),
      )).toList(),
    );
  }

  Widget _buildClientCommentEditor(Meal meal) {
    return TextFormField(
      initialValue: meal.clientComment,
      decoration: const InputDecoration(
        hintText: 'Add your comment...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (value) {
        // This will be handled by the existing comment update logic
      },
    );
  }

  void _onAddFood(Meal meal) {
    // Placeholder for add food functionality
    // This should integrate with existing food addition logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add food functionality coming soon')),
    );
  }

  void _onAddAttachment(Meal meal) {
    // Placeholder for add attachment functionality
    // This should integrate with existing attachment logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add attachment functionality coming soon')),
    );
  }

  Future<void> _generateGroceryList() async {
    if (_currentPlan == null) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Show week selection dialog
      final weekIndex = await _showWeekSelectionDialog();
      if (weekIndex == null) return;

      if (!mounted) return;

      // Show loading dialog
      await showDialog(
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

      // Generate grocery list with pantry integration
      final (groceryList, pantrySummary) = await _pantryAdapter.generateWithPantry(
        planId: _currentPlan!.id!,
        weekIndex: weekIndex,
        ownerId: user.id,
        usePantry: true, // Always use pantry for now
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to grocery list screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroceryListScreen(
              groceryList: groceryList,
              pantrySummary: pantrySummary,
            ),
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
          SnackBar(content: Text('Failed to generate grocery list: $e')),
        );
      }
    }
  }

  Future<int?> _showWeekSelectionDialog() async {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleHelper.t('select_week', language)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleHelper.t('which_week_generate_grocery', language),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              final weekNumber = index + 1;
              return ListTile(
                title: Text('${LocaleHelper.t('week', language)} $weekNumber'),
                onTap: () => Navigator.pop(context, weekNumber),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleHelper.t('cancel', language)),
          ),
        ],
      ),
    );
  }

  Future<void> _addDayToCalendar() async {
    if (_currentPlan == null) return;

    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      // Show loading dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(LocaleHelper.t('generating_calendar', language)),
            ],
          ),
        ),
      );

      // Prepare meal data for calendar
      final meals = <String, List<Map<String, dynamic>>>{};
      for (final meal in _currentPlan!.meals) {
        final mealType = meal.label.toLowerCase();
        meals[mealType] = meal.items.map((item) => {
          'name': item.name,
          'prep_minutes': 0, // Default no prep time for regular items
        }).toList();
      }

      // Generate day title
      final dayTitle = '${LocaleHelper.t('meals_for_day', language)} ${_currentPlan!.name}';

      // Export to calendar
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: meals,
        language: language,
        dayTitle: dayTitle,
        includePrepReminders: false,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleHelper.t('calendar_exported_successfully', language)),
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
        final locale = Localizations.localeOf(context).languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocaleHelper.t('failed_to_export_calendar', locale)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addPrepReminders() async {
    if (_currentPlan == null) return;

    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      // Check if any recipes have prep time
      bool hasPrepTime = false;
      final meals = <String, List<Map<String, dynamic>>>{};
      
      for (final meal in _currentPlan!.meals) {
        final mealType = meal.label.toLowerCase();
        final mealItems = <Map<String, dynamic>>[];
        
        for (final item in meal.items) {
          int prepMinutes = 0;
          
          // Get prep time from recipe if it's a recipe item
          if (item.recipeId != null) {
            try {
              final recipe = await _nutritionService.getRecipeForFoodItem(item);
              prepMinutes = recipe?.prepMinutes ?? 0;
            } catch (e) {
              // Continue with 0 prep time if recipe fetch fails
            }
          }
          
          if (prepMinutes > 0) {
            hasPrepTime = true;
          }
          
          mealItems.add({
            'name': item.name,
            'prep_minutes': prepMinutes,
          });
        }
        
        meals[mealType] = mealItems;
      }

      if (!hasPrepTime) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleHelper.t('no_prep_time_recipes', language)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show loading dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(LocaleHelper.t('generating_prep_reminders', language)),
            ],
          ),
        ),
      );

      // Generate day title
      final dayTitle = '${LocaleHelper.t('prep_reminders_for', language)} ${_currentPlan!.name}';

      // Export to calendar with prep reminders
      await NutritionCalendarBridge.exportDayToCalendar(
        date: DateTime.now(),
        meals: meals,
        language: language,
        dayTitle: dayTitle,
        includePrepReminders: true,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleHelper.t('prep_reminders_exported_successfully', language)),
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
        final locale = Localizations.localeOf(context).languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocaleHelper.t('failed_to_export_prep_reminders', locale)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRecipeSteps(FoodItem item) async {
    if (item.recipeId == null) return;

    try {
      final recipe = await _nutritionService.getRecipeForFoodItem(item);
      if (recipe == null) return;
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Recipe info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.totalMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.servingSize} servings',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (recipe.halal) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Halal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const Divider(),
              
              // Steps
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recipe.steps.length,
                  itemBuilder: (context, index) {
                    final step = recipe.steps[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.instruction,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (step.photoUrl != null && step.photoUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey.shade200,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        step.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recipe steps: $e')),
        );
      }
    }
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
