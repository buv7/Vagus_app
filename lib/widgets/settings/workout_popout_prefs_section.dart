// lib/widgets/settings/WorkoutPopoutPrefsSection.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/settings/user_prefs_service.dart';
import '../../theme/design_tokens.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Workout Popout Defaults',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
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
            const Text(
              'Coach UI Features',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default unit',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 14,
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
    final isSelected = _defaultUnit == unit;
    
    return GestureDetector(
      onTap: () async {
        await _prefsService.setDefaultUnit(unit);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
              : DesignTokens.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? DesignTokens.accentBlue.withValues(alpha: 0.6)
                : DesignTokens.accentBlue.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
