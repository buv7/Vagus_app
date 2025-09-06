// lib/widgets/workout/set_row_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/haptics.dart';
import '../../services/workout/exercise_local_log_service.dart';
import '../../widgets/workout/set_type_sheet.dart';
import '../../components/workout/rest_timer_inline.dart';
import '../../utils/set_type_format.dart';
import '../../services/settings/user_prefs_service.dart';

class SetRowControls extends StatefulWidget {
  final int setIndex;                         // 1-based for display
  final double? initialWeight;               // nullable
  final int? initialReps;                    // nullable
  final double initialRir;                   // 0..5, default 2
  final String unitLabel;                    // "kg" | "lb" (label only)
  final Future<void> Function({
    required double? weight,
    required int? reps,
    required double rir,
    LocalSetLog? extras,
  }) onLog;                                   // called on Complete+Log
  final VoidCallback onAutoRestStart;         // start inline rest timer for this set
  final VoidCallback? onApplyTarget;          // optional: prefill fields from target
  final bool dense;                           // compact spacing (default true)
  final Function(Map<String, dynamic> extras)? onSetTypeChanged; // optional: callback when set type changes

  const SetRowControls({
    super.key,
    required this.setIndex,
    required this.onLog,
    required this.onAutoRestStart,
    this.initialWeight,
    this.initialReps,
    this.initialRir = 2.0,
    this.unitLabel = 'kg',
    this.onApplyTarget,
    this.dense = true,
    this.onSetTypeChanged,
  });

  @override
  State<SetRowControls> createState() => _SetRowControlsState();
}

class _SetRowControlsState extends State<SetRowControls> {
  late final TextEditingController _wCtr;
  late final TextEditingController _rCtr;
  double _rir;
  bool _busy = false;
  
  // Advanced set type state
  LocalSetLog? _setExtras;
  bool _microTimerActive = false;
  int _currentBurstIndex = 0;
  int _currentClusterReps = 0;
  late UserPrefsService _prefsService;
  bool _hapticsEnabled = true;

  _SetRowControlsState() : _rir = 2.0;

  @override
  void initState() {
    super.initState();
    _wCtr = TextEditingController(
      text: widget.initialWeight != null ? widget.initialWeight!.toStringAsFixed(0) : '',
    );
    _rCtr = TextEditingController(
      text: widget.initialReps != null ? widget.initialReps!.toString() : '',
    );
    _rir = widget.initialRir;
    _prefsService = UserPrefsService.instance;
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    await _prefsService.init();
    _hapticsEnabled = _prefsService.hapticsEnabled;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _wCtr.dispose();
    _rCtr.dispose();
    super.dispose();
  }

  Future<void> _completeAndLog() async {
    if (_microTimerActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish current flow first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() => _busy = true);
    final w = double.tryParse(_wCtr.text.trim());
    final r = int.tryParse(_rCtr.text.trim());
    
    // Handle advanced set types
    if (_setExtras?.setType == SetType.restPause && _setExtras?.rpBursts != null) {
      await _handleRestPauseFlow(w, r);
    } else if (_setExtras?.setType == SetType.cluster && _setExtras?.clusterSize != null) {
      await _handleClusterFlow(w, r);
    } else {
      // Normal set or other types
      await widget.onLog(weight: w, reps: r, rir: _rir, extras: _setExtras);
      widget.onAutoRestStart();
      if (_hapticsEnabled) Haptics.success();
    }
    
    setState(() => _busy = false);
  }

  void _cancelMicroFlow() {
    setState(() {
      _microTimerActive = false;
      _currentBurstIndex = 0;
      _currentClusterReps = 0;
    });
    if (_hapticsEnabled) Haptics.selection();
  }

  Future<void> _handleRestPauseFlow(double? weight, int? reps) async {
    final bursts = _setExtras!.rpBursts!;
    final restSec = _setExtras!.rpRestSec ?? 20;
    
    if (_currentBurstIndex == 0) {
      // First burst - start the flow
      setState(() {
        _microTimerActive = true;
        _currentBurstIndex = 1;
      });
      
      // Log first burst (temporary, not final)
      await widget.onLog(weight: weight, reps: reps, rir: _rir, extras: null);
      
      if (_currentBurstIndex < bursts.length) {
        // Start micro timer for next burst
        _startMicroTimer(restSec, () => _promptNextBurst(weight));
      } else {
        // All bursts done - finalize
        await _finalizeRestPause(weight, bursts);
      }
    } else {
      // Subsequent burst
      if (_currentBurstIndex < bursts.length) {
        // Log this burst (temporary)
        await widget.onLog(weight: weight, reps: reps, rir: _rir, extras: null);
        
        setState(() => _currentBurstIndex++);
        
        if (_currentBurstIndex < bursts.length) {
          // Start micro timer for next burst
          _startMicroTimer(restSec, () => _promptNextBurst(weight));
        } else {
          // All bursts done - finalize
          await _finalizeRestPause(weight, bursts);
        }
      }
    }
  }

  Future<void> _handleClusterFlow(double? weight, int? reps) async {
    final clusterSize = _setExtras!.clusterSize!;
    final restSec = _setExtras!.clusterRestSec ?? 15;
    final totalReps = _setExtras!.clusterTotalReps ?? 12;
    
    if (_currentClusterReps == 0) {
      // First cluster - start the flow
      setState(() {
        _microTimerActive = true;
        _currentClusterReps = clusterSize;
      });
      
      // Log first cluster (temporary)
      await widget.onLog(weight: weight, reps: reps, rir: _rir, extras: null);
      
      if (_currentClusterReps < totalReps) {
        // Start micro timer for next cluster
        _startMicroTimer(restSec, () => _promptNextCluster(weight));
      } else {
        // All clusters done - finalize
        await _finalizeCluster(weight, totalReps);
      }
    } else {
      // Subsequent cluster
      _currentClusterReps += clusterSize;
      
      if (_currentClusterReps < totalReps) {
        // Log this cluster (temporary)
        await widget.onLog(weight: weight, reps: reps, rir: _rir, extras: null);
        
        // Start micro timer for next cluster
        _startMicroTimer(restSec, () => _promptNextCluster(weight));
      } else {
        // All clusters done - finalize
        await _finalizeCluster(weight, totalReps);
      }
    }
  }

  void _startMicroTimer(int seconds, VoidCallback onComplete) {
    setState(() => _microTimerActive = true);
    
    // Show micro timer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Micro Rest: ${seconds}s'),
            const SizedBox(height: 16),
            RestTimerInline(
              initialSeconds: seconds,
              onComplete: () {
                Navigator.of(context).pop();
                setState(() => _microTimerActive = false);
                if (_hapticsEnabled) Haptics.selection();
                onComplete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptNextBurst(double? weight) {
    final bursts = _setExtras!.rpBursts!;
    final nextBurst = bursts[_currentBurstIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Burst ${_currentBurstIndex + 1}/${bursts.length}'),
        content: Text('Target: $nextBurst reps'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _promptNextCluster(double? weight) {
    final clusterSize = _setExtras!.clusterSize!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Next Cluster'),
        content: Text('Target: $clusterSize reps'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeRestPause(double? weight, List<int> bursts) async {
    // Calculate total reps
    final totalReps = bursts.reduce((a, b) => a + b);
    
    // Create final log with extras
    final finalExtras = LocalSetLog(
      date: DateTime.now(),
      unit: widget.unitLabel,
      setType: SetType.restPause,
      rpBursts: bursts,
      rpRestSec: _setExtras!.rpRestSec,
    );
    
    await widget.onLog(weight: weight, reps: totalReps, rir: _rir, extras: finalExtras);
    widget.onAutoRestStart();
    Haptics.success();
    
    setState(() {
      _microTimerActive = false;
      _currentBurstIndex = 0;
    });
  }

  Future<void> _finalizeCluster(double? weight, int totalReps) async {
    // Create final log with extras
    final finalExtras = LocalSetLog(
      date: DateTime.now(),
      unit: widget.unitLabel,
      setType: SetType.cluster,
      clusterSize: _setExtras!.clusterSize,
      clusterRestSec: _setExtras!.clusterRestSec,
      clusterTotalReps: totalReps,
    );
    
    await widget.onLog(weight: weight, reps: totalReps, rir: _rir, extras: finalExtras);
    widget.onAutoRestStart();
    Haptics.success();
    
    setState(() {
      _microTimerActive = false;
      _currentClusterReps = 0;
    });
  }

  void _openSetTypeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetTypeSheet(
        currentWeight: double.tryParse(_wCtr.text.trim()),
        unitLabel: widget.unitLabel,
        existingExtras: _setExtras,
        onApply: (extras) {
          setState(() => _setExtras = extras);
          // Notify parent of set type change for sticky preferences
          if (widget.onSetTypeChanged != null && extras != null) {
            final stickyData = <String, dynamic>{
              'setType': extras.setType?.name,
              'dropWeights': extras.dropWeights,
              'dropPercents': extras.dropPercents,
              'rpBursts': extras.rpBursts,
              'rpRestSec': extras.rpRestSec,
              'clusterSize': extras.clusterSize,
              'clusterRestSec': extras.clusterRestSec,
              'clusterTotalReps': extras.clusterTotalReps,
            };
            widget.onSetTypeChanged!(stickyData);
          }
        },
      ),
    );
  }

  Widget _buildSetTypeIndicator(ThemeData theme, bool isDark) {
    if (_setExtras?.setType == null) return const SizedBox.shrink();
    
    final descriptor = SetTypeFormat.descriptor(
      weight: double.tryParse(_wCtr.text.trim()) ?? 0,
      unit: widget.unitLabel,
      reps: int.tryParse(_rCtr.text.trim()) ?? 0,
      setType: _setExtras!.setType,
      dropWeights: _setExtras!.dropWeights,
      dropPercents: _setExtras!.dropPercents,
      rpBursts: _setExtras!.rpBursts,
      rpRestSec: _setExtras!.rpRestSec,
      clusterSize: _setExtras!.clusterSize,
      clusterRestSec: _setExtras!.clusterRestSec,
      clusterTotalReps: _setExtras!.clusterTotalReps,
      amrap: _setExtras!.amrap,
    );
    
    if (descriptor.isEmpty) return const SizedBox.shrink();
    
    // Trim to ~28 chars with ellipsis
    final displayText = descriptor.length > 28 
        ? '${descriptor.substring(0, 25)}...' 
        : descriptor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gap = widget.dense ? 8.0 : 12.0;

    return Container(
      margin: EdgeInsets.only(top: gap),
      padding: EdgeInsets.all(widget.dense ? 10 : 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Set ${widget.setIndex}',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Set type button
              IconButton(
                onPressed: _openSetTypeSheet,
                icon: const Icon(Icons.tune_rounded, size: 18),
                tooltip: 'Set Type',
              ),
              if (widget.onApplyTarget != null)
                TextButton.icon(
                  onPressed: _microTimerActive ? null : widget.onApplyTarget,
                  icon: const Icon(Icons.speed_rounded, size: 18),
                  label: const Text('Apply target'),
                ),
            ],
          ),
          // Set type indicator
          if (_setExtras?.setType != null && _setExtras!.setType != SetType.normal)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildSetTypeIndicator(theme, isDark),
            ),
          // In-progress state
          if (_microTimerActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'In progress...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelMicroFlow,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Reset flow',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: gap),
          // Inputs row
          Row(
            children: [
              // Weight
              Expanded(
                child: TextField(
                  controller: _wCtr,
                  enabled: !_microTimerActive,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight (${widget.unitLabel})',
                    isDense: widget.dense,
                  ),
                ),
              ),
              SizedBox(width: gap),
              // Reps
              SizedBox(
                width: 92,
                child: TextField(
                  controller: _rCtr,
                  enabled: !_microTimerActive,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Reps',
                    isDense: widget.dense,
                  ),
                ),
              ),
              SizedBox(width: gap),
              // Complete + Log
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _completeAndLog,
                icon: _busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded),
                label: const Text('Complete + Log'),
              ),
            ],
          ),
          SizedBox(height: widget.dense ? 2 : 6),
          // RIR slider
          Row(
            children: [
              Text('RIR', style: theme.textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: _rir,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _rir.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _rir = v),
                ),
              ),
              Text(_rir.toStringAsFixed(1), style: theme.textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
