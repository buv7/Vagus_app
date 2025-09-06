import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/nutrition/preferences_service.dart';
import '../../services/ai/nutrition_ai.dart';
import '../../services/nutrition/pantry_service.dart';
import '../../services/nutrition/costing_service.dart';
import '../../services/nutrition/food_catalog_service.dart';
import '../../services/nutrition/calendar_bridge.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';

class NutritionDiagnosticsScreen extends StatefulWidget {
  const NutritionDiagnosticsScreen({super.key});

  @override
  State<NutritionDiagnosticsScreen> createState() => _NutritionDiagnosticsScreenState();
}

class _NutritionDiagnosticsScreenState extends State<NutritionDiagnosticsScreen> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic> _diagnostics = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final diagnostics = <String, dynamic>{};

      // Check tables and policies
      diagnostics['tables'] = await _checkTablesAndPolicies();
      
      // Cache stats
      diagnostics['cacheStats'] = await _getCacheStats();
      
      // Migration timestamps
      diagnostics['migrations'] = await _getMigrationTimestamps();

      setState(() {
        _diagnostics = diagnostics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _checkTablesAndPolicies() async {
    final tables = [
      'nutrition_plans',
      'nutrition_meals',
      'nutrition_food_items',
      'nutrition_recipes',
      'nutrition_grocery_lists',
      'nutrition_grocery_items',
      'nutrition_preferences',
      'nutrition_allergies',
      'nutrition_pantry_items',
      'nutrition_prices',
      'nutrition_hydration_logs',
      'nutrition_supplements',
    ];

    final results = <String, dynamic>{};
    
    for (final table in tables) {
      try {
        // Check if table exists
        final response = await supabase
            .from(table)
            .select('*')
            .limit(1);
        
        results[table] = {
          'exists': true,
          'accessible': true,
          'rowCount': response.length,
        };
      } catch (e) {
        results[table] = {
          'exists': false,
          'accessible': false,
          'error': e.toString(),
        };
      }
    }

    return results;
  }

  Future<Map<String, dynamic>> _getCacheStats() async {
    final stats = <String, dynamic>{};
    
    try {
      // Preferences Service cache
      final prefsService = PreferencesService();
      stats['preferences'] = {
        'cacheSize': prefsService.debugStats()['cacheSize'] ?? 0,
        'hitRate': prefsService.debugStats()['hitRate'] ?? 0.0,
      };
    } catch (e) {
      stats['preferences'] = {'error': e.toString()};
    }

    try {
      // AI Service cache
      final aiService = NutritionAI();
      stats['ai'] = {
        'cacheSize': aiService.debugStats()['cacheSize'] ?? 0,
        'hitRate': aiService.debugStats()['hitRate'] ?? 0.0,
        'rateLimit': aiService.debugStats()['rateLimit'] ?? 'unknown',
      };
    } catch (e) {
      stats['ai'] = {'error': e.toString()};
    }

    try {
      // Pantry Service cache
      final pantryService = PantryService();
      stats['pantry'] = {
        'cacheSize': pantryService.debugStats()['cacheSize'] ?? 0,
        'hitRate': pantryService.debugStats()['hitRate'] ?? 0.0,
      };
    } catch (e) {
      stats['pantry'] = {'error': e.toString()};
    }

    try {
      // Costing Service cache
      final costingService = CostingService();
      stats['costing'] = {
        'cacheSize': costingService.debugStats()['cacheSize'] ?? 0,
        'hitRate': costingService.debugStats()['hitRate'] ?? 0.0,
      };
    } catch (e) {
      stats['costing'] = {'error': e.toString()};
    }

    return stats;
  }

  Future<List<Map<String, dynamic>>> _getMigrationTimestamps() async {
    try {
      final response = await supabase
          .from('supabase_migrations')
          .select('version, executed_at')
          .order('executed_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [{'error': e.toString()}];
    }
  }

  Future<void> _recomputeDayCosts() async {
    try {
      // This would typically take a plan ID, but for diagnostics we'll just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day cost recomputation would require a specific plan ID'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recompute costs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rebuildMenaSeedCache() async {
    try {
      final foodCatalogService = FoodCatalogService();
      await foodCatalogService.seedMenaFoods();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MENA seed cache rebuilt successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rebuild MENA seed cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validatePlanToIcs() async {
    try {
      // This would typically validate a specific plan, but for diagnostics we'll just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan to ICS validation would require a specific plan ID'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to validate plan to ICS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final isRTL = LocaleHelper.isRTL(language);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleHelper.t('support_diagnostics', language)),
          actions: [
            IconButton(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh diagnostics',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _buildDiagnosticsContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Error running diagnostics',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _runDiagnostics,
              child: Text(LocaleHelper.t('retry', language)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tables and Policies Check
          _buildSection(
            'Tables & Policies',
            _buildTablesCheck(),
          ),
          
          const SizedBox(height: 24),
          
          // Cache Stats
          _buildSection(
            'Cache Statistics',
            _buildCacheStats(),
          ),
          
          const SizedBox(height: 24),
          
          // Migration Timestamps
          _buildSection(
            'Recent Migrations',
            _buildMigrationTimestamps(),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildSection(
            'Actions',
            _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTablesCheck() {
    final tables = _diagnostics['tables'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: tables.entries.map((entry) {
        final tableName = entry.key;
        final status = entry.value as Map<String, dynamic>;
        
        return ListTile(
          leading: Icon(
            status['exists'] == true 
                ? Icons.check_circle 
                : Icons.error,
            color: status['exists'] == true 
                ? Colors.green 
                : Colors.red,
          ),
          title: Text(tableName),
          subtitle: status['exists'] == true
              ? Text('${status['rowCount']} rows')
              : Text(status['error'] ?? 'Unknown error'),
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildCacheStats() {
    final cacheStats = _diagnostics['cacheStats'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: cacheStats.entries.map((entry) {
        final serviceName = entry.key;
        final stats = entry.value as Map<String, dynamic>;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(serviceName.toUpperCase()),
            subtitle: stats.containsKey('error')
                ? Text('Error: ${stats['error']}')
                : Text(
                    'Cache: ${stats['cacheSize']} items, '
                    'Hit Rate: ${(stats['hitRate'] * 100).toStringAsFixed(1)}%'
                  ),
            leading: Icon(
              stats.containsKey('error') ? Icons.error : Icons.storage,
              color: stats.containsKey('error') ? Colors.red : Colors.blue,
            ),
            dense: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMigrationTimestamps() {
    final migrations = _diagnostics['migrations'] as List<dynamic>? ?? [];
    
    if (migrations.isEmpty) {
      return const Text('No migration data available');
    }
    
    return Column(
      children: migrations.take(10).map((migration) {
        final data = migration as Map<String, dynamic>;
        
        return ListTile(
          leading: const Icon(Icons.update),
          title: Text(data['version'] ?? 'Unknown'),
          subtitle: Text(data['executed_at'] ?? 'Unknown date'),
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _recomputeDayCosts,
            icon: const Icon(Icons.calculate),
            label: const Text('Recompute Day Costs'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _rebuildMenaSeedCache,
            icon: const Icon(Icons.refresh),
            label: const Text('Rebuild MENA Seed Cache'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _validatePlanToIcs,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Validate Plan → ICS'),
          ),
        ),
      ],
    );
  }
}
