// lib/widgets/workout/set_type_sheet.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/workout/exercise_local_log_service.dart';

class SetTypeSheet extends StatefulWidget {
  final double? currentWeight;
  final String unitLabel;
  final LocalSetLog? existingExtras; // for editing existing set type
  final Function(LocalSetLog extras) onApply;

  const SetTypeSheet({
    super.key,
    this.currentWeight,
    required this.unitLabel,
    this.existingExtras,
    required this.onApply,
  });

  @override
  State<SetTypeSheet> createState() => _SetTypeSheetState();
}

class _SetTypeSheetState extends State<SetTypeSheet> {
  SetType _selectedType = SetType.normal;
  
  // Drop-set state
  List<double> _dropPercents = [];
  List<double> _dropWeights = [];
  bool _useAbsoluteWeights = false;
  
  // Rest-pause state
  int _rpRestSec = 20;
  List<int> _rpBursts = [8];
  
  // Cluster state
  int _clusterSize = 3;
  int _clusterRestSec = 15;
  int _clusterTotalReps = 12;
  
  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  void _initializeFromExisting() {
    if (widget.existingExtras != null) {
      final extras = widget.existingExtras!;
      _selectedType = extras.setType ?? SetType.normal;
      
      if (extras.dropPercents != null) {
        _dropPercents = List.from(extras.dropPercents!);
        _useAbsoluteWeights = false;
      } else if (extras.dropWeights != null) {
        _dropWeights = List.from(extras.dropWeights!);
        _useAbsoluteWeights = true;
      }
      
      if (extras.rpBursts != null) {
        _rpBursts = List.from(extras.rpBursts!);
      }
      if (extras.rpRestSec != null) {
        _rpRestSec = extras.rpRestSec!;
      }
      
      if (extras.clusterSize != null) {
        _clusterSize = extras.clusterSize!;
      }
      if (extras.clusterRestSec != null) {
        _clusterRestSec = extras.clusterRestSec!;
      }
      if (extras.clusterTotalReps != null) {
        _clusterTotalReps = extras.clusterTotalReps!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Set Type Configuration',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyConfiguration,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSetTypeSelector(theme, isDark),
                  const SizedBox(height: 24),
                  _buildConfigurationContent(theme, isDark),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetTypeSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Type',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SetType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _getSetTypeLabel(type),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfigurationContent(ThemeData theme, bool isDark) {
    switch (_selectedType) {
      case SetType.drop:
        return _buildDropSetConfiguration(theme, isDark);
      case SetType.restPause:
        return _buildRestPauseConfiguration(theme, isDark);
      case SetType.cluster:
        return _buildClusterConfiguration(theme, isDark);
      case SetType.amrap:
        return _buildAmrapConfiguration(theme, isDark);
      default:
        return _buildNormalConfiguration(theme, isDark);
    }
  }

  Widget _buildDropSetConfiguration(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drop-Set Configuration',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Weight mode toggle
        Row(
          children: [
            Text('Mode:', style: theme.textTheme.labelLarge),
            const SizedBox(width: 16),
            Switch(
              value: _useAbsoluteWeights,
              onChanged: (value) => setState(() {
                _useAbsoluteWeights = value;
                if (value) {
                  _dropPercents.clear();
                  _calculateDropWeights();
                } else {
                  _dropWeights.clear();
                }
              }),
            ),
            const SizedBox(width: 8),
            Text(_useAbsoluteWeights ? 'Absolute Weights' : 'Percent Drops'),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_useAbsoluteWeights) ...[
          // Absolute weights input
          Text('Weights (${widget.unitLabel}):', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'e.g., 80, 70, 60',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final weights = value.split(',').map((s) => double.tryParse(s.trim())).where((w) => w != null).cast<double>().toList();
              setState(() => _dropWeights = weights);
            },
          ),
        ] else ...[
          // Percent drops with quick chips
          Text('Percent Drops:', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickChip('-10%', () => _addDropPercent(-10)),
              _buildQuickChip('-15%', () => _addDropPercent(-15)),
              _buildQuickChip('-20%', () => _addDropPercent(-20)),
            ],
          ),
          const SizedBox(height: 8),
          if (_dropPercents.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: _dropPercents.asMap().entries.map((entry) {
                final index = entry.key;
                final percent = entry.value;
                return Chip(
                  label: Text('${percent.toInt()}%'),
                  onDeleted: () => _removeDropPercent(index),
                );
              }).toList(),
            ),
          ],
        ],
        
        const SizedBox(height: 16),
        _buildDropSetPreview(theme, isDark),
      ],
    );
  }

  Widget _buildRestPauseConfiguration(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rest-Pause Configuration',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Rest seconds slider
        Text('Rest Between Bursts: ${_rpRestSec}s', style: theme.textTheme.labelLarge),
        Slider(
          value: _rpRestSec.toDouble(),
          min: 10,
          max: 40,
          divisions: 30,
          onChanged: (value) => setState(() => _rpRestSec = value.round()),
        ),
        
        const SizedBox(height: 16),
        
        // Burst sequence
        Text('Burst Sequence:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickChip('+1', () => _addBurst(1)),
            _buildQuickChip('+2', () => _addBurst(2)),
            _buildQuickChip('+3', () => _addBurst(3)),
          ],
        ),
        const SizedBox(height: 8),
        if (_rpBursts.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: _rpBursts.asMap().entries.map((entry) {
              final index = entry.key;
              final reps = entry.value;
              return Chip(
                label: Text('$reps'),
                onDeleted: () => _removeBurst(index),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildClusterConfiguration(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cluster Configuration',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Cluster size
        Row(
          children: [
            Text('Cluster Size:', style: theme.textTheme.labelLarge),
            const Spacer(),
            IconButton(
              onPressed: _clusterSize > 2 ? () => setState(() => _clusterSize--) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$_clusterSize', style: theme.textTheme.titleMedium),
            IconButton(
              onPressed: _clusterSize < 5 ? () => setState(() => _clusterSize++) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Rest seconds
        Text('Rest Between Clusters: ${_clusterRestSec}s', style: theme.textTheme.labelLarge),
        Slider(
          value: _clusterRestSec.toDouble(),
          min: 10,
          max: 40,
          divisions: 30,
          onChanged: (value) => setState(() => _clusterRestSec = value.round()),
        ),
        
        const SizedBox(height: 16),
        
        // Total reps
        Row(
          children: [
            Text('Total Reps:', style: theme.textTheme.labelLarge),
            const Spacer(),
            IconButton(
              onPressed: _clusterTotalReps > 6 ? () => setState(() => _clusterTotalReps -= 3) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$_clusterTotalReps', style: theme.textTheme.titleMedium),
            IconButton(
              onPressed: _clusterTotalReps < 30 ? () => setState(() => _clusterTotalReps += 3) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmrapConfiguration(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AMRAP Configuration',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AMRAP (As Many Reps As Possible)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Log the achieved reps in the main input. Progression rules will use AMRAP signals to suggest load adjustments.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNormalConfiguration(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Normal Set',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            'Standard set with weight, reps, and RIR. No special configuration needed.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDropSetPreview(ThemeData theme, bool isDark) {
    if (widget.currentWeight == null) return const SizedBox.shrink();
    
    List<double> weights = [];
    if (_useAbsoluteWeights) {
      weights = _dropWeights;
    } else {
      weights = _calculateDropWeights();
    }
    
    if (weights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: weights.map((weight) {
            return Chip(
              label: Text('${weight.toStringAsFixed(0)} ${widget.unitLabel}'),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addDropPercent(double percent) {
    if (_dropPercents.length < 4) {
      setState(() => _dropPercents.add(percent));
    }
  }

  void _removeDropPercent(int index) {
    setState(() => _dropPercents.removeAt(index));
  }

  void _addBurst(int reps) {
    if (_rpBursts.length < 5) {
      setState(() => _rpBursts.add(reps));
    }
  }

  void _removeBurst(int index) {
    setState(() => _rpBursts.removeAt(index));
  }

  List<double> _calculateDropWeights() {
    if (widget.currentWeight == null || _dropPercents.isEmpty) return [];
    
    final weights = <double>[widget.currentWeight!];
    var currentWeight = widget.currentWeight!;
    
    for (final percent in _dropPercents) {
      currentWeight = currentWeight * (1 + percent / 100);
      weights.add(currentWeight);
    }
    
    return weights;
  }

  void _applyConfiguration() {
    LocalSetLog extras;
    
    switch (_selectedType) {
      case SetType.drop:
        extras = LocalSetLog(
          date: DateTime.now(),
          unit: widget.unitLabel,
          setType: SetType.drop,
          dropWeights: _useAbsoluteWeights ? _dropWeights : null,
          dropPercents: _useAbsoluteWeights ? null : _dropPercents,
        );
        break;
      case SetType.restPause:
        extras = LocalSetLog(
          date: DateTime.now(),
          unit: widget.unitLabel,
          setType: SetType.restPause,
          rpBursts: _rpBursts,
          rpRestSec: _rpRestSec,
        );
        break;
      case SetType.cluster:
        extras = LocalSetLog(
          date: DateTime.now(),
          unit: widget.unitLabel,
          setType: SetType.cluster,
          clusterSize: _clusterSize,
          clusterRestSec: _clusterRestSec,
          clusterTotalReps: _clusterTotalReps,
        );
        break;
      case SetType.amrap:
        extras = LocalSetLog(
          date: DateTime.now(),
          unit: widget.unitLabel,
          setType: SetType.amrap,
          amrap: true,
        );
        break;
      default:
        extras = LocalSetLog(
          date: DateTime.now(),
          unit: widget.unitLabel,
          setType: SetType.normal,
        );
    }
    
    widget.onApply(extras);
    Navigator.of(context).pop();
  }

  String _getSetTypeLabel(SetType type) {
    switch (type) {
      case SetType.normal:
        return 'Normal';
      case SetType.drop:
        return 'Drop-Set';
      case SetType.restPause:
        return 'Rest-Pause';
      case SetType.cluster:
        return 'Cluster';
      case SetType.amrap:
        return 'AMRAP';
    }
  }
}
