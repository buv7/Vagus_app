import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/workout/exercise_catalog_service.dart';
import '../../utils/tempo_parser.dart';
import '../../widgets/workout/tempo_cue_pill.dart';
import '../../components/workout/rest_timer_inline.dart';
import '../../services/haptics.dart';
import '../../utils/load_math.dart';
import '../../widgets/workout/LoadSuggestionBar.dart';
import '../../widgets/workout/WarmupPlanCard.dart';
import '../../services/workout/exercise_history_service.dart';
import '../../utils/progression_rules.dart';
import '../../widgets/workout/ExerciseHistoryCard.dart';
import '../../widgets/workout/AutoProgressionTip.dart';
import '../../services/workout/exercise_local_log_service.dart';
import 'package:flutter/services.dart';
import '../../widgets/workout/set_row_controls.dart';
import '../../widgets/workout/session_summary_footer.dart';
import '../../services/workout/exercise_session_draft_service.dart';
import '../../widgets/workout/finish_session_banner.dart';
import '../../services/messaging/thread_resolver_service.dart';
import '../../services/messages_service.dart';
import '../../utils/set_type_format.dart';
import '../../services/settings/user_prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ExerciseDetailSheet
/// Glassmorphism bottom sheet to preview exercise media, targeted muscles,
/// and switch between grouped exercises (superset/giant/drop/etc.).
///
/// Usage:
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => ExerciseDetailSheet(
///     exercises: groupExercises,        // List<Map<String, dynamic>>
///     initialIndex: initialIndex,       // int
///     roleContext: role,                // 'client' | 'coach'
///     onMarkDone: (ex) {},              // optional
///     onAddNote: (ex, note) {},         // optional
///     onAttachMedia: (ex) {},           // optional
///   ),
/// );
class ExerciseDetailSheet extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final int initialIndex;
  final String roleContext;
  final void Function(Map<String, dynamic>)? onMarkDone;
  final void Function(Map<String, dynamic>, String)? onAddNote;
  final void Function(Map<String, dynamic>)? onAttachMedia;

  const ExerciseDetailSheet({
    super.key,
    required this.exercises,
    this.initialIndex = 0,
    this.roleContext = 'client',
    this.onMarkDone,
    this.onAddNote,
    this.onAttachMedia,
  });

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet> with SingleTickerProviderStateMixin {
  late int _index;
  VideoPlayerController? _videoController;
  final _catalogService = ExerciseCatalogService();
  
  // Cached catalog data for current exercise
  List<String> _catalogPrimaryMuscles = [];
  List<String> _catalogSecondaryMuscles = [];
  List<String> _catalogMedia = [];
  bool _catalogLoaded = false;

  // Track inline rest timers per exercise -> per set index
  final Map<String, Map<int, bool>> _showInlineRestForSet = {}; // key: exerciseId/name, value: {setIndex: isVisible}
  bool _hapticsOn = true;
  
  // User preferences state
  late UserPrefsService _prefsService;
  bool _tempoCuesEnabled = true;
  String _unit = 'kg';
  bool _showQuickNoteCard = true;
  bool _showWorkingSetsFirst = true;

  // Load calculator state
  LoadUnit _loadUnit = LoadUnit.kg;
  double _barWeight = LoadMath.defaultKgBar;
  double? _targetLoad;

  // History and progression state
  List<ExerciseSetLog> _exerciseLogs = [];
  String? _clientId; // This would typically come from the current user context

  // Quick Log UI state
  late final TextEditingController _weightCtr;
  late final TextEditingController _repsCtr;
  double _rirVal = 2.0; // slider 0..5 in 0.5 steps
  String _unitLbl = 'kg'; // only a label; do not convert
  bool _loggingBusy = false;

  // Per-set tracking state
  final Map<int, ({double? w, int? r, double rir})> _setScratch = {}; // per-set temp values to compute tonnage and summary

  // Quick note state
  late final TextEditingController _quickNoteCtr;

  // Group tracking state
  final Map<String /*exerciseKey*/, int /*completed*/> _groupCompleted = {}; // Tracks per-exercise completed set count for the *current session* (local only)
  bool _autoAdvanceGroupTabs = true; // Auto-advance to next exercise in group
  int? _groupRestSecs; // null → hidden
  bool _groupRestRunning = false;
  DateTime? _groupRestStartedAt;

  Map<String, dynamic> get _exercise => widget.exercises[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.exercises.length - 1);
    _weightCtr = TextEditingController();
    _repsCtr = TextEditingController();
    _quickNoteCtr = TextEditingController();
    _prefsService = UserPrefsService.instance;
    _initializePrefs();
    _setupVideoIfAny();
    _loadCatalogData();
    _prefillFromLastLog();
  }

  Future<void> _initializePrefs() async {
    await _prefsService.init();
    
    // Load global preferences
    _hapticsOn = _prefsService.hapticsEnabled;
    _tempoCuesEnabled = _prefsService.tempoCuesEnabled;
    _autoAdvanceGroupTabs = _prefsService.autoAdvanceSupersets;
    _unit = _prefsService.defaultUnit;
    _showQuickNoteCard = _prefsService.showQuickNoteCard;
    _showWorkingSetsFirst = _prefsService.showWorkingSetsFirst;
    
    // Load sticky preferences for this exercise
    final exerciseKey = _exerciseKey(widget.exercises[_index]);
    final sticky = _prefsService.getStickyFor(exerciseKey);
    
    // Override global prefs with sticky if available
    if (sticky['unit'] != null) {
      _unit = sticky['unit'] as String;
    }
    
    // Update load unit based on preference
    _loadUnit = _unit == 'kg' ? LoadUnit.kg : LoadUnit.lb;
    _barWeight = _loadUnit == LoadUnit.kg ? LoadMath.defaultKgBar : LoadMath.defaultLbBar;
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _weightCtr.dispose();
    _repsCtr.dispose();
    _quickNoteCtr.dispose();
    // Save preferences when sheet is closed
    _saveGlobalPrefs();
    _saveStickyPrefs();
    super.dispose();
  }

  void _setupVideoIfAny() async {
    _videoController?.dispose();
    _videoController = null;

    final media = _pickBestMedia(_exercise);
    if (media == null) return;

    final url = media.$1;
    final type = media.$2;

    if (type == _MediaType.video) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (mounted) {
        setState(() {
          _videoController = controller;
        });
      } else {
        unawaited(controller.dispose());
      }
    }
  }

  /// Returns (url, type) or null.
  (String, _MediaType)? _pickBestMedia(Map<String, dynamic> ex) {
    // Accept either a rich `exerciseMedia: List<Map>` shape or a simple `mediaUrls: List<String>`.
    List<dynamic> mediaList = (ex['exerciseMedia'] as List?) ?? (ex['mediaUrls'] as List?) ?? const [];

    // If no media in exercise data, try catalog fallback
    if (mediaList.isEmpty && _catalogLoaded && _catalogMedia.isNotEmpty) {
      mediaList = _catalogMedia.map((url) => {'url': url}).toList();
    }

    String? video;
    String? gif;
    String? image;

    for (final m in mediaList) {
      if (m is Map<String, dynamic>) {
        final url = (m['url'] ?? m['path'] ?? '').toString();
        if (url.isEmpty) continue;
        final lower = url.toLowerCase();
        if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
          video ??= url;
        } else if (lower.endsWith('.gif')) {
          gif ??= url;
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
          image ??= url;
        }
      } else if (m is String) {
        final lower = m.toLowerCase();
        if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
          video ??= m;
        } else if (lower.endsWith('.gif')) {
          gif ??= m;
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
          image ??= m;
        }
      }
    }

    if (video != null) return (video, _MediaType.video);
    if (gif != null) return (gif, _MediaType.gif);
    if (image != null) return (image, _MediaType.image);
    return null;
  }

  Future<void> _loadCatalogData() async {
    final exerciseName = (_exercise['name'] ?? '').toString();
    if (exerciseName.isEmpty) return;

    try {
      final primary = await _catalogService.resolvePrimary(exerciseName);
      final secondary = await _catalogService.resolveSecondary(exerciseName);
      final media = await _catalogService.resolveMedia(exerciseName);

      if (mounted) {
        setState(() {
          _catalogPrimaryMuscles = primary;
          _catalogSecondaryMuscles = secondary;
          _catalogMedia = media;
          _catalogLoaded = true;
        });
      }
    } catch (e) {
      // Catalog loading failed, keep existing behavior
      if (mounted) {
        setState(() {
          _catalogLoaded = true;
        });
      }
    }
  }

  void _onTabChanged(int newIndex) {
    if (newIndex == _index) return;
    setState(() {
      _index = newIndex;
      _catalogLoaded = false; // Reset catalog data for new exercise
    });
    _setupVideoIfAny();
    _loadCatalogData();
  }

  int _resolveRestSeconds(Map<String, dynamic> exercise) {
    final raw = (exercise['rest'] ?? '').toString().trim();
    if (raw.isEmpty) return 60;
    // Accept "90s" or "1:30"
    final colon = RegExp(r'^(\d+)\:(\d{1,2})$');
    final sec = RegExp(r'^(\d+)\s*s$');
    if (colon.hasMatch(raw)) {
      final m = colon.firstMatch(raw)!;
      final mm = int.tryParse(m.group(1)!) ?? 0;
      final ss = int.tryParse(m.group(2)!) ?? 0;
      return mm * 60 + ss;
    }
    if (sec.hasMatch(raw)) {
      return int.tryParse(sec.firstMatch(raw)!.group(1)!) ?? 60;
    }
    final asInt = int.tryParse(raw);
    return (asInt != null && asInt > 0) ? asInt : 60;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(isDark),
                const SizedBox(height: 8),
                _buildHeader(context, isDark),
                const SizedBox(height: 12),
                _buildMedia(context, isDark),
                const SizedBox(height: 12),
                _buildTempoSection(context, isDark),
                const SizedBox(height: 12),
                _buildLoadCalculatorSection(context, isDark),
                const SizedBox(height: 12),
                _buildGroupHeader(context, isDark),
                _buildGroupRestTimer(context, isDark),
                const SizedBox(height: 12),
                _buildWorkingSetsSection(context, isDark),
                const SizedBox(height: 12),
                _buildQuickNoteCard(context, isDark),
                const SizedBox(height: 12),
                _buildQuickLogCard(_exercise),
                const SizedBox(height: 12),
                _buildHistorySection(context, isDark),
                const SizedBox(height: 12),
                _buildMuscles(isDark),
                const SizedBox(height: 12),
                _buildNotesAndActions(context, isDark),
                const SizedBox(height: 12),
                _buildGroupTabs(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final name = (_exercise['name'] ?? 'Exercise').toString();
    final groupType = (_exercise['groupType'] ?? '').toString();
    final gt = groupType.isEmpty ? null : groupType;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (gt != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              gt.replaceAll('_', ' ').toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMedia(BuildContext context, bool isDark) {
    final media = _pickBestMedia(_exercise);

    if (media == null) {
      return _glassBox(
        isDark: isDark,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Icon(Icons.hide_image_outlined, size: 40, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final url = media.$1;
    final type = media.$2;

    if (type == _MediaType.video) {
      final vc = _videoController;
      return _glassBox(
        isDark: isDark,
        child: AspectRatio(
          aspectRatio: vc?.value.aspectRatio == 0 ? 16 / 9 : (vc?.value.aspectRatio ?? (16 / 9)),
          child: vc == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    VideoPlayer(vc),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        tooltip: vc.value.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(vc.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 28, color: Colors.white),
                        onPressed: () {
                          if (vc.value.isPlaying) {
                            vc.pause();
                          } else {
                            vc.play();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    if (type == _MediaType.gif || type == _MediaType.image) {
      return _glassBox(
        isDark: isDark,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: () {
              // Fullscreen view
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        PhotoView(
                          imageProvider: NetworkImage(url),
                          heroAttributes: PhotoViewHeroAttributes(tag: url),
                          backgroundDecoration: const BoxDecoration(color: Colors.black),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }));
            },
            child: Hero(
              tag: url,
              child: Image.network(url, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _glassBox({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildMuscles(bool isDark) {
    List<dynamic> primary = (_exercise['primaryMuscles'] as List?) ?? const [];
    List<dynamic> secondary = (_exercise['secondaryMuscles'] as List?) ?? const [];

    // Use catalog data as fallback if exercise data is missing
    if (primary.isEmpty && _catalogLoaded && _catalogPrimaryMuscles.isNotEmpty) {
      primary = _catalogPrimaryMuscles;
    }
    if (secondary.isEmpty && _catalogLoaded && _catalogSecondaryMuscles.isNotEmpty) {
      secondary = _catalogSecondaryMuscles;
    }

    if (primary.isEmpty && secondary.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget chips(String label, List<dynamic> data, {required bool bold}) {
      if (data.isEmpty) return const SizedBox.shrink();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
          ),
          ...data.map((m) {
            final text = m.toString();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: bold ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary.isNotEmpty) chips('Primary:', primary, bold: true),
        if (primary.isNotEmpty && secondary.isNotEmpty) const SizedBox(height: 8),
        if (secondary.isNotEmpty) chips('Secondary:', secondary, bold: false),
      ],
    );
  }

  Widget _buildNotesAndActions(BuildContext context, bool isDark) {
    final ex = _exercise;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onAttachMedia == null ? null : () => widget.onAttachMedia!(ex),
                icon: const Icon(Icons.attachment_outlined),
                label: const Text('Attach'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onMarkDone == null ? null : () {
                  widget.onMarkDone!(ex);
                  if (_hapticsOn) Haptics.success();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark done'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (widget.onAddNote == null) return;
                  final note = await _askForNote(context, isDark);
                  if (note == null || note.trim().isEmpty) return;
                  widget.onAddNote!(ex, note.trim());
                },
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Add note'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRestTimerControls(context, isDark),
      ],
    );
  }

  Future<String?> _askForNote(BuildContext context, bool isDark) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          title: Text(
            'Add note',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Write a quick note…'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupTabs(bool isDark) {
    if (widget.exercises.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.exercises.length, (i) {
          final selected = i == _index;
          final ex = widget.exercises[i];
          final label = (ex['name'] ?? 'Exercise ${i + 1}').toString();

          return Padding(
            padding: EdgeInsets.only(right: i == widget.exercises.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => _onTabChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: selected ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: selected ? 0.24 : 0.12)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRestTimerControls(BuildContext context, bool isDark) {
    final exKey = (_exercise['id']?.toString() ?? _exercise['name']?.toString() ?? 'exercise_${_index}');
    _showInlineRestForSet.putIfAbsent(exKey, () => {});
    
    // For demonstration, we'll show a "Start rest" button that toggles the timer
    // In a real implementation, this would be triggered by set completion
    final showingTimer = _showInlineRestForSet[exKey]?[0] == true;
    
    if (!showingTimer) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          label: const Text('Start rest timer'),
          onPressed: () {
            setState(() {
              _showInlineRestForSet[exKey]![0] = true;
            });
            if (_hapticsOn) Haptics.selection();
          },
        ),
      );
    }
    
    return RestTimerInline(
      initialSeconds: _resolveRestSeconds(_exercise),
      onComplete: () {
        if (mounted) {
          setState(() {
            _showInlineRestForSet[exKey]![0] = false;
          });
        }
      },
    );
  }

  Widget _buildLoadCalculatorSection(BuildContext context, bool isDark) {
    // Detect barbell-eligible exercises heuristically (hide for dumbbell/machine)
    final name = (_exercise['name'] ?? '').toString().toLowerCase();
    final isBarbellish = !(name.contains('dumbbell') || 
                          name.contains('kettlebell') || 
                          name.contains('machine') || 
                          name.contains('cable') ||
                          name.contains('bodyweight') ||
                          name.contains('body weight'));

    if (!isBarbellish) {
      // For non-barbell exercises, show minimal load suggestion
      final percent1RM = _exercise['percent1RM'] as double?;
      final weight = _exercise['weight'] as double?;
      
      if (percent1RM == null && weight == null) {
        return const SizedBox.shrink();
      }
      
      final target = LoadMath.targetFromPercent(
        percent1RM: percent1RM,
        training1RM: null, // No training 1RM available
        fallbackWeight: weight,
      );
      
      if (target == null) return const SizedBox.shrink();
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.fitness_center,
              size: 16,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Suggested load: ${target.toStringAsFixed(0)} kg',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Load & Warm-Up',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        LoadSuggestionBar(
          exercise: _exercise,
          training1RM: null, // if you have it, pass the value; else null
          exerciseKey: _exerciseKey(_exercise),
          onApply: (load, unitStr) {
            // Optional: if your set row has an editable weight, forward via a callback you already own.
            // Keep additive: do not mutate exercise map here.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Suggested ${load.toStringAsFixed(0)} $unitStr'))
            );
            setState(() {
              _targetLoad = load;
              _loadUnit = unitStr == 'kg' ? LoadUnit.kg : LoadUnit.lb;
            });
          },
        ),
        if (_targetLoad != null) ...[
          const SizedBox(height: 8),
          WarmupPlanCard(
            topSet: _targetLoad!,
            unit: _loadUnit,
            barWeight: _barWeight,
          ),
        ],
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, bool isDark) {
    // For demonstration, use a mock client ID
    // In a real app, this would come from the current user context
    final clientId = _clientId ?? 'demo_client_id';
    final exerciseName = (_exercise['name'] ?? '').toString();
    final useKg = !exerciseName.toLowerCase().contains('lb');
    
    return Column(
      children: [
        ExerciseHistoryCard(
          clientId: clientId,
          exercise: _exercise,
          useKg: useKg,
          onLogsLoaded: (logs) {
            setState(() {
              _exerciseLogs = logs;
            });
          },
        ),
        const SizedBox(height: 8),
        AutoProgressionTip(
          exercise: _exercise,
          logs: _exerciseLogs,
          useKg: useKg,
          onApply: (load, unit) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Applied $load $unit'))
            );
          },
        ),
      ],
    );
  }

  String _exerciseKey(Map<String, dynamic> ex) =>
    (ex['id']?.toString() ?? ex['name']?.toString() ?? 'exercise').trim().toLowerCase();

  int _setsPlannedFor(Map<String, dynamic> ex) => (ex['sets'] as int?) ?? 0;

  double _computeTonnage() {
    double sum = 0;
    for (final e in _setScratch.entries) {
      final w = e.value.w ?? 0;
      final r = e.value.r ?? 0;
      sum += w * r;
    }
    return sum;
  }

  ({double? w, int? r, double rir})? _bestSet() {
    if (_setScratch.isEmpty) return null;
    ({double? w, int? r, double rir})? best;
    double bestScore = -1;
    _setScratch.forEach((i, v) {
      final score = (v.w ?? 0) * (v.r ?? 0);
      if (score > bestScore) { 
        bestScore = score; 
        best = v; 
      }
    });
    return best;
  }

  String _buildSummaryText(Map<String, dynamic> ex) {
    final name = (ex['name'] ?? '').toString();
    final done = _setScratch.length;
    final planned = _setsPlannedFor(ex);
    final ton = _computeTonnage().toStringAsFixed(0);
    final b = _bestSet();
    final bLine = b == null ? '' :
      'Best set: ${(b.w ?? 0).toStringAsFixed(0)} × ${b.r ?? 0} @ RIR ${b.rir.toStringAsFixed(1)}\n';
    final sb = StringBuffer()
      ..writeln('Workout summary — $name')
      ..writeln('Sets: $done/$planned')
      ..writeln('Tonnage: $ton')
      ..write(bLine);
    // Optional: list sets with advanced set type info
    _setScratch.entries.forEach((e) {
      final idx = e.key + 1;
      final w = e.value.w?.toStringAsFixed(0) ?? '-';
      final r = e.value.r?.toString() ?? '-';
      final rir = e.value.rir.toStringAsFixed(1);
      
      // Get set type info from local logs (simplified for now)
      final setTypeInfo = _getSetTypeInfoForSet(idx - 1);
      
      if (setTypeInfo.isNotEmpty) {
        sb.writeln('Set $idx — $setTypeInfo @ $w × $r @ RIR $rir');
      } else {
        sb.writeln('Set $idx — $w × $r @ RIR $rir');
      }
    });
    
    // Add quick note if present
    final note = _quickNoteCtr.text.trim();
    if (note.isNotEmpty) {
      sb.writeln('\n[Note]');
      sb.writeln(note);
    }
    
    return sb.toString().trimRight();
  }

  String _getSetTypeInfoForSet(int setIndex) {
    // This is a simplified version - in a real implementation, you'd store
    // set type info per set and retrieve it here
    // For now, return empty string to avoid breaking existing functionality
    // TODO: Implement proper set type info retrieval from stored logs
    return '';
  }

  /// Check if any micro flow is currently active (simplified check)
  bool _isMicroFlowActive() {
    // This is a simplified check - in a real implementation, you'd track
    // micro flow state per set and check if any are active
    // For now, return false to allow auto-advance
    return false;
  }

  /// Save current preferences to global settings
  Future<void> _saveGlobalPrefs() async {
    await _prefsService.setHapticsEnabled(_hapticsOn);
    await _prefsService.setTempoCuesEnabled(_tempoCuesEnabled);
    await _prefsService.setAutoAdvanceSupersets(_autoAdvanceGroupTabs);
    await _prefsService.setDefaultUnit(_unit);
  }

  /// Save sticky preferences for current exercise
  Future<void> _saveStickyPrefs() async {
    final exerciseKey = _exerciseKey(_exercise);
    final sticky = <String, dynamic>{
      'unit': _unit,
      'barWeight': _barWeight,
    };
    await _prefsService.setStickyFor(exerciseKey, sticky);
  }

  void _refreshHistoryFor(Map<String, dynamic> exercise) async {
    final clientId = _clientId ?? 'demo_client_id';
    final exerciseName = (exercise['name'] ?? '').toString();
    
    try {
      final logs = await ExerciseHistoryService.instance.lastLogs(
        clientId: clientId,
        exerciseName: exerciseName,
        limit: 3,
      );

      if (mounted) {
        setState(() {
          _exerciseLogs = logs;
        });
      }
    } catch (e) {
      // Graceful fallback - keep existing logs
    }
  }

  Future<void> _handleSendToCoach(Map<String, dynamic> ex) async {
    final text = _buildSummaryText(ex);

    // Try to reuse messaging send API if present; else clipboard fallback
    final sent = await _trySendMessageToCoachIfAvailable(text);
    if (sent) {
      Haptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to coach')));
      }
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      Haptics.selection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied summary — paste in chat to send')),
        );
      }
    }
  }

  Future<String?> _tryResolveCoachThreadId() async {
    try {
      // Get coachId from context (try to derive from client relationship)
      final coachId = await _getCoachIdForCurrentClient();
      if (coachId == null) return null;
      
      return await ThreadResolverService.instance.resolveOneToOne(
        coachId: coachId,
        clientId: _clientId ?? 'demo_client_id',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getCoachIdForCurrentClient() async {
    try {
      // Try to get coach ID for the current client
      return await ThreadResolverService.instance.getCoachForClient(
        _clientId ?? 'demo_client_id',
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _trySendMessageToCoachIfAvailable(String text) async {
    try {
      final threadId = await _tryResolveCoachThreadId();
      if (threadId == null) return false;
      
      await MessagesService().sendText(threadId: threadId, text: text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleSaveDraft(Map<String, dynamic> ex) async {
    final text = _buildSummaryText(ex);
    final exKey = _exerciseKey(ex);
    await ExerciseSessionDraftService.instance.save(
      clientId: _clientId ?? 'demo_client_id',
      exerciseKey: exKey,
      day: DateTime.now(),
      text: text,
    );
    Haptics.selection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved locally')));
    }
  }

  Future<void> _handleClearLocal(Map<String, dynamic> ex) async {
    setState(() {
      _setScratch.clear();
      // also hide any inline timers
      final key = _exerciseKey(ex);
      _showInlineRestForSet[key]?.clear();
    });
    Haptics.warning();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared current session (local)')));
    }
  }

  String _todayKey(Map<String, dynamic> ex) => _exerciseKey(ex);

  Future<String?> _peekTodayDraft(Map<String, dynamic> ex) async {
    return ExerciseSessionDraftService.instance.load(
      clientId: _clientId ?? 'demo_client_id',
      exerciseKey: _todayKey(ex),
      day: DateTime.now(),
    );
  }

  Future<void> _handleRestoreDraft(Map<String, dynamic> ex) async {
    final draft = await _peekTodayDraft(ex);
    if (draft != null && draft.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: draft));
      Haptics.selection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft copied — paste to edit/send')),
        );
      }
    }
  }

  // Exercise done flag helpers (local only, today only)
  Future<void> _markExerciseDoneLocal(Map<String, dynamic> ex) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'exdone::${_clientId ?? 'demo_client_id'}::${_exerciseKey(ex)}::$dateKey';
    await prefs.setString(key, '1');
  }

  Future<bool> _isExerciseDoneToday(Map<String, dynamic> ex) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'exdone::${_clientId ?? 'demo_client_id'}::${_exerciseKey(ex)}::$dateKey';
    return prefs.getString(key) == '1';
  }

  Future<void> _clearExerciseDoneLocal(Map<String, dynamic> ex) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'exdone::${_clientId ?? 'demo_client_id'}::${_exerciseKey(ex)}::$dateKey';
    await prefs.remove(key);
  }

  // Last-log prefill functionality
  Future<void> _prefillFromLastLog() async {
    try {
      final clientId = _clientId ?? 'demo_client_id';
      final exerciseName = (_exercise['name'] ?? '').toString();
      
      final logs = await ExerciseHistoryService.instance.lastLogs(
        clientId: clientId,
        exerciseName: exerciseName,
        limit: 1,
      );

      if (logs.isNotEmpty && mounted) {
        final lastLog = logs.first;
        // Only prefill if controllers are empty (don't override user input)
        if (_weightCtr.text.isEmpty && lastLog.weight != null) {
          _weightCtr.text = lastLog.weight!.toStringAsFixed(0);
        }
        if (_repsCtr.text.isEmpty && lastLog.reps != null) {
          _repsCtr.text = lastLog.reps.toString();
        }
        if (lastLog.rir != null) {
          _rirVal = lastLog.rir!;
        }
      }
    } catch (e) {
      // Graceful fallback - no prefill
    }
  }

  Future<void> _prefillSetFromLastLog() async {
    try {
      final clientId = _clientId ?? 'demo_client_id';
      final exerciseName = (_exercise['name'] ?? '').toString();
      
      final logs = await ExerciseHistoryService.instance.lastLogs(
        clientId: clientId,
        exerciseName: exerciseName,
        limit: 1,
      );

      if (logs.isNotEmpty && mounted) {
        final lastLog = logs.first;
        // Prefill Set 1 (index 0) if it's empty
        if (!_setScratch.containsKey(0)) {
          setState(() {
            _setScratch[0] = (
              w: lastLog.weight,
              r: lastLog.reps,
              rir: lastLog.rir ?? 2.0,
            );
          });
        }
      }
    } catch (e) {
      // Graceful fallback - no prefill
    }
  }

  // Group tracking helpers
  List<Map<String, dynamic>> get _currentGroup => widget.exercises;

  // Determine total planned sets per exercise safely
  int _plannedSetsFor(Map<String, dynamic> ex) => (ex['sets'] is int && ex['sets'] > 0) ? ex['sets'] as int : 0;

  // Compute current "round" index (1-based): the minimum completed across all exercises in the group + 1 (for in-progress)
  int _currentRound(List<Map<String, dynamic>> group) {
    if (group.isEmpty) return 0;
    var minDone = 1 << 30;
    for (final ex in group) {
      final key = _exerciseKey(ex);
      final done = _groupCompleted[key] ?? 0;
      if (done < minDone) minDone = done;
    }
    return (minDone + 1).clamp(1, 99999);
  }

  // Compute total rounds = min of planned sets across the group (so a "round" is one set of each exercise)
  // Edge case: uneven sets - total rounds = min across the group; after that, extra sets for exercises 
  // with higher 'sets' still appear individually (no group rest triggered for those extras)
  int _totalRounds(List<Map<String, dynamic>> group) {
    if (group.isEmpty) return 0;
    var m = 1 << 30;
    for (final ex in group) {
      m = (m < _plannedSetsFor(ex)) ? m : _plannedSetsFor(ex);
    }
    return m == (1 << 30) ? 0 : m;
  }

  // Next exercise index to perform in this round: pick the first exercise whose completed < planned for this round
  int _nextExerciseTabForRound(List<Map<String, dynamic>> group) {
    for (var i = 0; i < group.length; i++) {
      final ex = group[i];
      final key = _exerciseKey(ex);
      final planned = _plannedSetsFor(ex);
      final done = _groupCompleted[key] ?? 0;
      if (done < planned) return i;
    }
    return 0;
  }

  // Resolve rest seconds for group: use the max of member rests (to be safe), falling back to 60s if none
  int _resolveGroupRest(List<Map<String, dynamic>> group) {
    int maxRest = 0;
    for (final ex in group) {
      maxRest = math.max(maxRest, _resolveRestSeconds(ex));
    }
    return maxRest == 0 ? 60 : maxRest;
  }

  Widget _buildGroupHeader(BuildContext context, bool isDark) {
    final group = _currentGroup;
    if (group.length <= 1) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final currentRound = _currentRound(group);
    final totalRounds = _totalRounds(group);
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            'Round $currentRound/$totalRounds',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: -4,
              children: List.generate(group.length, (i) {
                final ex = group[i];
                final key = _exerciseKey(ex);
                final done = _groupCompleted[key] ?? 0;
                final planned = _plannedSetsFor(ex);
                final label = '${String.fromCharCode(65 + i)}: $done/$planned';
                return Chip(
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35)),
                  backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                );
              }),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Auto-advance',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: _autoAdvanceGroupTabs,
                onChanged: (v) => setState(() => _autoAdvanceGroupTabs = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRestTimer(BuildContext context, bool isDark) {
    if (_groupRestSecs == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RestTimerInline(
        initialSeconds: _groupRestSecs!,
        onComplete: () {
          Haptics.selection();
          setState(() {
            _groupRestSecs = null;
            _groupRestRunning = false;
          });
          // Optional: auto-advance to the next exercise in round start
          if (_autoAdvanceGroupTabs) {
            final group = _currentGroup;
            final idx = _nextExerciseTabForRound(group);
            if (idx != _index) _onTabChanged(idx);
          }
        },
      ),
    );
  }

  Widget _buildWorkingSetsSection(BuildContext context, bool isDark) {
    final exercise = _exercise;
    final setsPlanned = _setsPlannedFor(exercise);
    final exerciseName = (exercise['name'] ?? '').toString();
    final useKg = !exerciseName.toLowerCase().contains('lb');
    final unitLabel = useKg ? 'kg' : 'lb';
    
    if (setsPlanned <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Working Sets',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton(
              onPressed: _prefillSetFromLastLog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Prefill from last',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        // Exercise done chip (if done today)
        FutureBuilder<bool>(
          future: _isExerciseDoneToday(exercise),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Chip(
                      label: const Text('Exercise done (today)'),
                      avatar: const Icon(Icons.check_circle, size: 18),
                      backgroundColor: Colors.green.withValues(alpha: 0.18),
                      side: BorderSide(color: Colors.green.withValues(alpha: 0.35)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        await _clearExerciseDoneLocal(exercise);
                        setState(() {
                          _setScratch.clear();
                          final key = _exerciseKey(exercise);
                          _showInlineRestForSet[key]?.clear();
                        });
                        Haptics.warning();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reset exercise (local)')),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reset',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 8),
        
        // Per-set rows
        ...List.generate(setsPlanned, (index) {
          final setIndex = index + 1; // 1-based for display
          final exKey = _exerciseKey(exercise);
          final showRestTimer = _showInlineRestForSet[exKey]?[index] == true;
          
          return Column(
            children: [
              SetRowControls(
                setIndex: setIndex,
                initialWeight: _setScratch[index]?.w,
                initialReps: _setScratch[index]?.r,
                initialRir: _setScratch[index]?.rir ?? 2.0,
                unitLabel: unitLabel,
                onLog: ({required double? weight, required int? reps, required double rir, LocalSetLog? extras}) async {
                  // Update scratch data
                  _setScratch[index] = (w: weight, r: reps, rir: rir);
                  
                  // Log to local service
                  final clientId = _clientId ?? 'demo_client_id';
                  await ExerciseLocalLogService.instance.add(
                    clientId,
                    exKey,
                    LocalSetLog(
                      date: DateTime.now(),
                      weight: weight,
                      reps: reps,
                      rir: rir,
                      unit: unitLabel,
                      setType: extras?.setType,
                      dropWeights: extras?.dropWeights,
                      dropPercents: extras?.dropPercents,
                      rpBursts: extras?.rpBursts,
                      rpRestSec: extras?.rpRestSec,
                      clusterSize: extras?.clusterSize,
                      clusterRestSec: extras?.clusterRestSec,
                      clusterTotalReps: extras?.clusterTotalReps,
                      amrap: extras?.amrap,
                    ),
                  );
                  
                  // Refresh history
                  _refreshHistoryFor(exercise);
                  
                  // Group tracking: increment completed count for this exercise
                  // Edge case: drop sets (groupType == 'drop_set') - treat all drops inside that exercise as 
                  // one logical set for the purpose of round completion. When user completes any set for a 
                  // drop-set exercise, mark as done for this round (1 per round).
                  final group = _currentGroup;
                  _groupCompleted[exKey] = (_groupCompleted[exKey] ?? 0) + 1;
                  
                  // Debug assert: advanced set still increments by exactly 1
                  assert(() {
                    debugPrint('Set completed: $exKey, count: ${_groupCompleted[exKey]}');
                    return true;
                  }());
                  
                  // Check if round finished: a round is finished if every exercise in the group has completed >= currentRoundIndex
                  final round = _currentRound(group);
                  final roundFinished = group.every((ex) {
                    final key = _exerciseKey(ex);
                    final done = _groupCompleted[key] ?? 0;
                    return done >= round;
                  });
                  
                  if (roundFinished) {
                    // Start Group Rest Timer
                    _groupRestSecs = _resolveGroupRest(group);
                    _groupRestRunning = true;
                    _groupRestStartedAt = DateTime.now();
                    Haptics.success();
                  } else if (_autoAdvanceGroupTabs && !_isMicroFlowActive()) {
                    // Auto-advance tab: switch to the next exercise with remaining sets
                    // Block auto-advance if any micro flow is active
                    final nextIndex = _nextExerciseTabForRound(group);
                    if (nextIndex != _index) _onTabChanged(nextIndex);
                  }
                  
                  // Check for auto-finish trigger (individual exercise completion)
                  final done = _setScratch.length;
                  final planned = _setsPlannedFor(exercise);
                  if (done >= planned && planned > 0) {
                    final isAlreadyDone = await _isExerciseDoneToday(exercise);
                    if (!isAlreadyDone) {
                      Haptics.success();
                      await _markExerciseDoneLocal(exercise);
                    }
                  }
                  
                  // Update UI
                  if (mounted) {
                    setState(() {});
                  }
                },
                onAutoRestStart: () {
                  // Start rest timer for this set
                  _showInlineRestForSet.putIfAbsent(exKey, () => {});
                  _showInlineRestForSet[exKey]![index] = true;
                  if (mounted) {
                    setState(() {});
                  }
                },
                onApplyTarget: () {
                  // Apply target weight from load calculator
                  if (_targetLoad != null) {
                    _setScratch[index] = (w: _targetLoad, r: _setScratch[index]?.r, rir: _setScratch[index]?.rir ?? 2.0);
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                onSetTypeChanged: (extras) async {
                  // Save sticky preferences when set type changes
                  final sticky = <String, dynamic>{
                    'unit': _unit,
                    'barWeight': _barWeight,
                    ...extras,
                  };
                  await _prefsService.setStickyFor(exKey, sticky);
                },
              ),
              
              // Inline rest timer for this set
              if (showRestTimer) ...[
                const SizedBox(height: 8),
                RestTimerInline(
                  initialSeconds: _resolveRestSeconds(exercise),
                  onComplete: () {
                    setState(() {
                      _showInlineRestForSet[exKey]![index] = false;
                    });
                  },
                ),
              ],
            ],
          );
        }),
        
        // Session summary footer
        SessionSummaryFooter(
          done: _setScratch.length,
          planned: setsPlanned,
          tonnage: _computeTonnage(),
          onCopy: () async {
            final sb = StringBuffer()
              ..writeln('Exercise: ${exercise['name'] ?? ''}')
              ..writeln('Sets: ${_setScratch.length}/$setsPlanned')
              ..writeln('Tonnage: ${_computeTonnage().toStringAsFixed(0)}');
            for (final e in _setScratch.entries) {
              final idx = e.key + 1;
              final w = e.value.w?.toStringAsFixed(0) ?? '-';
              final r = e.value.r?.toString() ?? '-';
              final rir = e.value.rir.toStringAsFixed(1);
              sb.writeln('Set $idx — $w × $r @ RIR $rir');
            }
            await Clipboard.setData(ClipboardData(text: sb.toString()));
            Haptics.selection();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied')),
              );
            }
          },
        ),
        
        // Finish Session banner (only show when sets are logged)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _setScratch.isNotEmpty 
            ? FutureBuilder<String?>(
                future: _peekTodayDraft(exercise),
                builder: (context, snapshot) {
                  final draftText = snapshot.data;
                  return FinishSessionBanner(
                    key: const ValueKey('finish_banner'),
                    exerciseName: (exercise['name'] ?? '').toString(),
                    done: _setScratch.length,
                    planned: setsPlanned,
                    tonnage: _computeTonnage(),
                    bestSet: _bestSet(),
                    draftText: draftText,
                    onSendToCoach: () => _handleSendToCoach(exercise),
                    onSaveDraft: () => _handleSaveDraft(exercise),
                    onClearLocal: () => _handleClearLocal(exercise),
                    onRestoreDraft: () => _handleRestoreDraft(exercise),
                  );
                },
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }

  Widget _buildQuickNoteCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Note (optional)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quickNoteCtr,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note about this workout...',
              isDense: true,
              counterText: '', // Hide character count
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogCard(Map<String, dynamic> exercise) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Prefill from exercise data if available
    if (_weightCtr.text.isEmpty && (exercise['weight'] != null)) {
      _weightCtr.text = (exercise['weight'] as num).toString();
    }
    if (_repsCtr.text.isEmpty && (exercise['reps'] != null)) {
      _repsCtr.text = (exercise['reps'] as num).toString();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Log',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Weight
              Expanded(
                child: TextField(
                  controller: _weightCtr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
              ),
              const SizedBox(width: 8),
              // Unit (label only)
              DropdownButton<String>(
                value: _unitLbl,
                onChanged: (v) => setState(() => _unitLbl = (v == 'lb') ? 'lb' : 'kg'),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                ],
              ),
              const SizedBox(width: 8),
              // Reps
              Expanded(
                child: TextField(
                  controller: _repsCtr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('RIR', style: theme.textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: _rirVal,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _rirVal.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _rirVal = v),
                ),
              ),
              Text(_rirVal.toStringAsFixed(1), style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              FilledButton(
                onPressed: _loggingBusy ? null : () async {
                  final exKey = _exerciseKey(exercise);
                  final w = double.tryParse(_weightCtr.text.trim());
                  final r = int.tryParse(_repsCtr.text.trim());
                  setState(() => _loggingBusy = true);
                  
                  await ExerciseLocalLogService.instance.add(
                    _clientId ?? 'demo_client_id',
                    exKey,
                    LocalSetLog(
                      date: DateTime.now(),
                      weight: w,
                      reps: r,
                      rir: _rirVal,
                      unit: _unitLbl,
                    ),
                  );
                  
                  setState(() => _loggingBusy = false);
                  Haptics.success();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set logged (local)')),
                    );
                  }
                  
                  // Refresh history
                  _refreshHistoryFor(exercise);
                },
                child: _loggingBusy 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _loggingBusy ? null : () async {
                  final exKey = _exerciseKey(exercise);
                  await ExerciseLocalLogService.instance.deleteLast(
                    _clientId ?? 'demo_client_id',
                    exKey,
                  );
                  Haptics.selection();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Undid last (local)')),
                    );
                  }
                  
                  // Refresh history
                  _refreshHistoryFor(exercise);
                },
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo last'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempoSection(BuildContext context, bool isDark) {
    final tempo = Tempo.fromExercise(_exercise);
    if (tempo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tempo', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Switch(
                  value: _hapticsOn,
                  onChanged: (v) async {
                    setState(() => _hapticsOn = v);
                    await _prefsService.setHapticsEnabled(v);
                  },
                ),
                const SizedBox(width: 6),
                Text('Haptics', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tempoCuesEnabled)
          TempoCuePill(
            tempo: tempo,
            reps: (_exercise['reps'] is int && (_exercise['reps'] as int) > 0) ? _exercise['reps'] as int : 8,
            enableHaptics: _hapticsOn,
            tempoCuesEnabled: _tempoCuesEnabled,
          ),
      ],
    );
  }
}

enum _MediaType { video, gif, image }
