import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/music/music_service.dart';
import '../../models/music/music_models.dart';
import '../../theme/app_theme.dart';

class MusicSettingsScreen extends StatefulWidget {
  const MusicSettingsScreen({super.key});

  @override
  State<MusicSettingsScreen> createState() => _MusicSettingsScreenState();
}

class _MusicSettingsScreenState extends State<MusicSettingsScreen> {
  final MusicService _musicService = MusicService();
  final supabase = Supabase.instance.client;
  
  UserMusicPrefs? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final prefs = await _musicService.getPrefs(user.id);
      setState(() {
        _prefs = prefs ?? UserMusicPrefs(userId: user.id);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePrefs() async {
    if (_prefs == null) return;

    try {
      final updatedPrefs = await _musicService.setPrefs(_prefs!);
      setState(() {
        _prefs = updatedPrefs;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Music preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }

  void _updatePrefs(UserMusicPrefs Function(UserMusicPrefs) update) {
    if (_prefs == null) return;
    setState(() {
      _prefs = update(_prefs!);
    });
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🎵 Music Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-open toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Auto-open on workout start',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Automatically open music when starting a workout',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Enable auto-open',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _prefs?.autoOpen ?? true,
                          activeColor: AppTheme.accentGreen,
                          onChanged: (value) {
                            _updatePrefs((prefs) => prefs.copyWith(autoOpen: value));
                            _musicService.logMusicPrefUpdate(_prefs!.userId, 'auto_open');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Default provider picker
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Default Music Provider',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose which music app to open by default',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _prefs?.defaultProvider,
                          dropdownColor: const Color(0xFF2C2F33),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Default Provider',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.accentGreen),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1C1E),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('No preference'),
                            ),
                            DropdownMenuItem(
                              value: 'spotify',
                              child: Row(
                                children: [
                                  Icon(Icons.music_note, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Spotify'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'soundcloud',
                              child: Row(
                                children: [
                                  Icon(Icons.music_note, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('SoundCloud'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            _updatePrefs((prefs) => prefs.copyWith(defaultProvider: value));
                            _musicService.logMusicPrefUpdate(_prefs!.userId, 'default_provider');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Genres
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Preferred Genres',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your favorite workout music genres',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGenreChips(),
                      ],
                    ),
                  ),

                  // BPM Range
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2F33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.speed,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'BPM Range',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preferred tempo range for workout music',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBpmRangeSlider(),
                      ],
                    ),
                  ),

                  // Pro upgrade CTA
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upgrade to Pro',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pro users can attach unlimited music links to workouts and events',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to billing screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pro upgrade coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.upgrade),
                            label: const Text('Upgrade to Pro'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildGenreChips() {
    final allGenres = [
      'Rock', 'Pop', 'Hip Hop', 'Electronic', 'Country', 'Jazz',
      'Classical', 'R&B', 'Reggae', 'Metal', 'Folk', 'Blues',
      'Punk', 'Indie', 'Alternative', 'Dance', 'House', 'Techno'
    ];

    final selectedGenres = _prefs?.genres ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allGenres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (selected) {
            final newGenres = List<String>.from(selectedGenres);
            if (selected) {
              newGenres.add(genre);
            } else {
              newGenres.remove(genre);
            }
            _updatePrefs((prefs) => prefs.copyWith(genres: newGenres));
            _musicService.logMusicPrefUpdate(_prefs!.userId, 'genres');
          },
        );
      }).toList(),
    );
  }

  Widget _buildBpmRangeSlider() {
    final minBpm = _prefs?.bpmMin ?? 60;
    final maxBpm = _prefs?.bpmMax ?? 180;
    RangeValues rangeValues = RangeValues(minBpm.toDouble(), maxBpm.toDouble());

    return Column(
      children: [
        RangeSlider(
          values: rangeValues,
          min: 60,
          max: 200,
          divisions: 28, // (200-60)/5 = 28 divisions
          labels: RangeLabels(
            '${rangeValues.start.round()} BPM',
            '${rangeValues.end.round()} BPM',
          ),
          onChanged: (values) {
            setState(() {
              rangeValues = values;
            });
          },
          onChangeEnd: (values) {
            _updatePrefs((prefs) => prefs.copyWith(
              bpmMin: values.start.round(),
              bpmMax: values.end.round(),
            ));
            _musicService.logMusicPrefUpdate(_prefs!.userId, 'bpm_range');
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${rangeValues.start.round()} BPM'),
            Text('${rangeValues.end.round()} BPM'),
          ],
        ),
      ],
    );
  }
}
