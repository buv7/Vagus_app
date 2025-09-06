// lib/widgets/settings/WorkoutPopoutPrefsSection.dart
import 'package:flutter/material.dart';
import '../../services/settings/user_prefs_service.dart';

class WorkoutPopoutPrefsSection extends StatefulWidget {
  const WorkoutPopoutPrefsSection({super.key});

  @override
  State<WorkoutPopoutPrefsSection> createState() => _WorkoutPopoutPrefsSectionState();
}

class _WorkoutPopoutPrefsSectionState extends State<WorkoutPopoutPrefsSection> {
  late UserPrefsService _prefsService;
  bool _hapticsEnabled = true;
  bool _tempoCuesEnabled = true;
  bool _autoAdvanceSupersets = true;
  String _defaultUnit = 'kg';
  bool _showQuickNoteCard = true;
  bool _showWorkingSetsFirst = true;
  bool _showAIInsights = true;
  bool _showMiniDayCards = true;

  @override
  void initState() {
    super.initState();
    _prefsService = UserPrefsService.instance;
    _loadPrefs();
    
    // Listen for preference changes
    _prefsService.prefsVersion.addListener(_loadPrefs);
  }

  @override
  void dispose() {
    _prefsService.prefsVersion.removeListener(_loadPrefs);
    super.dispose();
  }

  void _loadPrefs() {
    if (mounted) {
      setState(() {
        _hapticsEnabled = _prefsService.hapticsEnabled;
        _tempoCuesEnabled = _prefsService.tempoCuesEnabled;
        _autoAdvanceSupersets = _prefsService.autoAdvanceSupersets;
        _defaultUnit = _prefsService.defaultUnit;
        _showQuickNoteCard = _prefsService.showQuickNoteCard;
        _showWorkingSetsFirst = _prefsService.showWorkingSetsFirst;
        _showAIInsights = _prefsService.showAIInsights;
        _showMiniDayCards = _prefsService.showMiniDayCards;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.blue, // Use const color instead of theme-dependent
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Workout Popout Defaults',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Haptics toggle
            _buildToggleTile(
              title: 'Haptics',
              subtitle: 'Vibration feedback for timers and actions',
              value: _hapticsEnabled,
              onChanged: (value) async {
                await _prefsService.setHapticsEnabled(value);
              },
            ),
            
            // Tempo cues toggle
            _buildToggleTile(
              title: 'Tempo cues',
              subtitle: 'Visual and haptic tempo guidance',
              value: _tempoCuesEnabled,
              onChanged: (value) async {
                await _prefsService.setTempoCuesEnabled(value);
              },
            ),
            
            // Auto-advance supersets toggle
            _buildToggleTile(
              title: 'Auto-advance in supersets/giant sets',
              subtitle: 'Automatically switch between exercises in groups',
              value: _autoAdvanceSupersets,
              onChanged: (value) async {
                await _prefsService.setAutoAdvanceSupersets(value);
              },
            ),
            
            // Default unit selector
            _buildUnitSelector(),
            
            // Show Quick Note card toggle
            _buildToggleTile(
              title: 'Show Quick Note card',
              subtitle: 'Display quick note input in workout popout',
              value: _showQuickNoteCard,
              onChanged: (value) async {
                await _prefsService.setShowQuickNoteCard(value);
              },
            ),
            
            // Show Working Sets first toggle
            _buildToggleTile(
              title: 'Show Working Sets before Quick Log',
              subtitle: 'Order of sections in workout popout',
              value: _showWorkingSetsFirst,
              onChanged: (value) async {
                await _prefsService.setShowWorkingSetsFirst(value);
              },
            ),
            
            // Feature flags section
            const SizedBox(height: 16),
            Text(
              'Coach UI Features',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Show AI Insights toggle
            _buildToggleTile(
              title: 'Show AI Insights',
              subtitle: 'Display AI-generated weekly insights',
              value: _showAIInsights,
              onChanged: (value) async {
                await _prefsService.setShowAIInsights(value);
              },
            ),
            
            // Show Mini Day Cards toggle
            _buildToggleTile(
              title: 'Show Mini Day Cards',
              subtitle: 'Display compact daily progress cards',
              value: _showMiniDayCards,
              onChanged: (value) async {
                await _prefsService.setShowMiniDayCards(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default unit',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildUnitChip('kg', 'Kilograms'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitChip('lb', 'Pounds'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitChip(String unit, String label) {
    final theme = Theme.of(context);
    final isSelected = _defaultUnit == unit;
    
    return GestureDetector(
      onTap: () async {
        await _prefsService.setDefaultUnit(unit);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
