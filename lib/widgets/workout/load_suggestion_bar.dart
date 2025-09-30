// lib/widgets/workout/LoadSuggestionBar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../utils/load_math.dart';
import '../../services/settings/user_prefs_service.dart';

class LoadSuggestionBar extends StatefulWidget {
  final Map<String, dynamic> exercise;      // current exercise map
  final double? training1RM;                // if unknown, pass null
  final Function(double load, String unit)? onApply; // called if coach taps "Apply"
  final String? exerciseKey;                // for sticky preferences
  
  const LoadSuggestionBar({
    super.key, 
    required this.exercise, 
    this.training1RM, 
    this.onApply,
    this.exerciseKey,
  });

  @override
  State<LoadSuggestionBar> createState() => _LoadSuggestionBarState();
}

class _LoadSuggestionBarState extends State<LoadSuggestionBar> {
  LoadUnit _unit = LoadUnit.kg;
  double _barWeight = LoadMath.defaultKgBar;
  double? _targetLoad;
  List<double> _plates = [];
  late UserPrefsService _prefsService;

  @override
  void initState() {
    super.initState();
    _prefsService = UserPrefsService.instance;
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    await _prefsService.init();
    
    // Load sticky preferences for this exercise
    if (widget.exerciseKey != null) {
      final sticky = _prefsService.getStickyFor(widget.exerciseKey!);
      
      // Override with sticky preferences if available
      if (sticky['unit'] != null) {
        _unit = sticky['unit'] == 'kg' ? LoadUnit.kg : LoadUnit.lb;
      }
      if (sticky['barWeight'] != null) {
        _barWeight = (sticky['barWeight'] as num).toDouble();
      }
    } else {
      // Use global default unit
      _unit = _prefsService.defaultUnit == 'kg' ? LoadUnit.kg : LoadUnit.lb;
      _barWeight = _unit == LoadUnit.kg ? LoadMath.defaultKgBar : LoadMath.defaultLbBar;
    }
    
    _detectUnit();
    _calculateTarget();
    
    if (mounted) {
      setState(() {});
    }
  }

  void _detectUnit() {
    final name = (widget.exercise['name'] ?? '').toString().toLowerCase();
    final notes = (widget.exercise['notes'] ?? '').toString().toLowerCase();
    
    if (name.contains('lb') || notes.contains('lb') || name.contains('pound')) {
      _unit = LoadUnit.lb;
      _barWeight = LoadMath.defaultLbBar;
    } else if (name.contains('kg') || notes.contains('kg') || name.contains('kilo')) {
      _unit = LoadUnit.kg;
      _barWeight = LoadMath.defaultKgBar;
    }
  }

  void _calculateTarget() {
    final percent1RM = widget.exercise['percent1RM'] as double?;
    final weight = widget.exercise['weight'] as double?;
    
    final target = LoadMath.targetFromPercent(
      percent1RM: percent1RM,
      training1RM: widget.training1RM,
      fallbackWeight: weight,
    );
    
    if (target != null) {
      _targetLoad = LoadMath.roundToGym(target, _unit);
      _calculatePlates();
    }
  }

  void _calculatePlates() {
    if (_targetLoad == null) return;
    
    _plates = LoadMath.platesPerSide(
      total: _targetLoad!,
      unit: _unit,
      barWeight: _barWeight,
    );
  }

  void _onUnitChanged(LoadUnit unit) {
    setState(() {
      _unit = unit;
      _barWeight = unit == LoadUnit.kg ? LoadMath.defaultKgBar : LoadMath.defaultLbBar;
    });
    _calculateTarget();
    _saveStickyPrefs();
  }

  void _onBarWeightChanged(double weight) {
    setState(() {
      _barWeight = weight;
    });
    _calculateTarget();
    _calculatePlates();
    _saveStickyPrefs();
  }

  Future<void> _saveStickyPrefs() async {
    if (widget.exerciseKey != null) {
      final sticky = <String, dynamic>{
        'unit': _unit.name,
        'barWeight': _barWeight,
      };
      await _prefsService.setStickyFor(widget.exerciseKey!, sticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_targetLoad == null) {
      return Container(
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No load data available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Header with unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Load Calculator',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  _buildUnitChip(LoadUnit.kg, 'kg'),
                  const SizedBox(width: 8),
                  _buildUnitChip(LoadUnit.lb, 'lb'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Target load display
          Row(
            children: [
              Text(
                'Target: ',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${_targetLoad!.toStringAsFixed(0)} ${_unit.name}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (widget.onApply != null)
                FilledButton(
                  onPressed: () => widget.onApply!(_targetLoad!, _unit.name),
                  child: const Text('Apply'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bar weight selector
          _buildBarWeightSelector(theme, isDark),
          const SizedBox(height: 12),
          
          // Plate breakdown
          if (_plates.isNotEmpty) ...[
            Text(
              'Plates per side:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _plates.map((plate) => _buildPlateChip(plate, theme, isDark)).toList(),
            ),
          ] else if (_targetLoad! > _barWeight) ...[
            Text(
              'No plates needed (${_targetLoad!.toStringAsFixed(0)} ${_unit.name} = bar only)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitChip(LoadUnit unit, String label) {
    final isSelected = _unit == unit;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _onUnitChanged(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected 
              ? theme.colorScheme.primary
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBarWeightSelector(ThemeData theme, bool isDark) {
    final commonBars = _unit == LoadUnit.kg 
      ? [15.0, 20.0, 25.0]
      : [35.0, 45.0, 55.0];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bar weight:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...commonBars.map((weight) => _buildBarChip(weight, theme, isDark)),
            _buildCustomBarChip(theme, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChip(double weight, ThemeData theme, bool isDark) {
    final isSelected = (_barWeight - weight).abs() < 0.1;
    
    return GestureDetector(
      onTap: () => _onBarWeightChanged(weight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          '${weight.toStringAsFixed(0)} ${_unit.name}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected 
              ? theme.colorScheme.primary
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBarChip(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _showCustomBarDialog(theme, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Custom',
              style: theme.textTheme.labelSmall?.copyWith(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 12,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateChip(double plate, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${plate.toStringAsFixed(plate < 1 ? 1 : 0)} ${_unit.name}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCustomBarDialog(ThemeData theme, bool isDark) {
    final controller = TextEditingController(text: _barWeight.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        title: Text(
          'Custom Bar Weight',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Weight (${_unit.name})',
            suffixText: _unit.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                _onBarWeightChanged(weight);
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}
