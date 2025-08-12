import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/nutrition_plan.dart';
import '../../services/nutrition/nutrition_service.dart';
import 'MealEditor.dart';
import '../../widgets/nutrition/DailySummaryCard.dart';
import '../../widgets/nutrition/NutritionUpdateRing.dart';
import '../../widgets/ai/ai_usage_meter.dart';

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
  Map<String, dynamic>? _coachProfile;
  Map<String, dynamic>? _clientProfile;

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
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'No user.';
        _loading = false;
      });
      return;
    }

    try {
      // Get role and profile
      final profile = await supabase
          .from('profiles')
          .select('role, name')
          .eq('id', user.id)
          .single();

      _role = (profile['role'] ?? 'client').toString();
      _clientProfile = profile;

      // Load plans
      final plans = await _nutritionService.fetchPlansForClient(user.id);

      setState(() {
        _plans = plans;
        if (_plans.isNotEmpty) {
          _currentPlan = _plans.first;
          _selectedPlanId = _currentPlan!.id;
          _markPlanSeen();
          _loadCoachProfile();
        } else {
          _currentPlan = null;
          _selectedPlanId = null;
          _error = 'No nutrition plans found.';
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '❌ Failed to load data.';
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
      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', _currentPlan!.createdBy)
          .single();

      setState(() {
        _coachProfile = response as Map<String, dynamic>;
      });
    } catch (e) {
      print('Failed to load coach profile: $e');
    }
  }

  Future<void> _updateMealComment(int mealIndex, String comment) async {
    if (_currentPlan?.id == null) return;
    
    try {
      await _nutritionService.updateMealComment(_currentPlan!.id!, mealIndex, comment);
      
      // Update the local plan data
      final updatedMeals = List<Meal>.from(_currentPlan!.meals);
      updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(clientComment: comment);
      
      setState(() {
        _currentPlan = _currentPlan!.copyWith(meals: updatedMeals);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Comment saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save comment: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (_currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No plan selected for export')),
      );
      return;
    }

    try {
      final plan = _currentPlan!;
      final coachName = _coachProfile?['name'] ?? 'Unknown Coach';
      final clientName = _clientProfile?['name'] ?? 'Unknown Client';

      await _nutritionService.exportNutritionPlanToPdf(plan, coachName, clientName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍎 Nutrition Plan'),
        actions: [
          if (_currentPlan != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export to PDF',
              onPressed: _exportToPdf,
            ),
            if (_currentPlan!.unseenUpdate)
              const NutritionUpdateRing(
                hasUnseenUpdate: true,
                size: 20,
              ),
          ],
        ],
      ),
      body: _currentPlan == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error.isEmpty ? 'No nutrition plan yet' : _error,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _role == 'client' 
                          ? 'Your coach will create a nutrition plan for you soon.'
                          : 'No nutrition plans found for this client.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Usage Meter at the top
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AIUsageMeter(
                      isCompact: true,
                      onRefresh: () {
                        // Refresh any necessary data
                      },
                    ),
                  ),
                  
                  // Plan selector
                  DropdownButtonFormField<String>(
                    value: _selectedPlanId,
                    decoration: const InputDecoration(
                      labelText: 'Select Plan',
                      border: OutlineInputBorder(),
                    ),
                    items: _plans.map((p) {
                      final displayName = p.name.isEmpty ? 'Unnamed Plan' : p.name;
                      final date = p.createdAt.toString().split(' ')[0];
                      final label = '$displayName — $date';
                      
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(label, overflow: TextOverflow.ellipsis),
                            ),
                            if (p.unseenUpdate)
                              const NutritionUpdateRing(
                                hasUnseenUpdate: true,
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _onSelectPlan,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Plan info
                  Card(
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
                            'Created: ${_currentPlan!.createdAt.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Meals
                  if (_currentPlan!.meals.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No meals in this plan',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._currentPlan!.meals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final meal = entry.value;
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
                    }).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Daily summary
                  DailySummaryCard(summary: _currentPlan!.dailySummary),
                  
                  const SizedBox(height: 48), // Breathing room for bottom gesture area
                ],
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
    switch (lengthType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'program':
        return 'Program';
      default:
        return 'Unknown';
    }
  }
}
