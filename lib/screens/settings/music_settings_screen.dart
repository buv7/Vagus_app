import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/music/music_service.dart';
import '../../models/music/music_models.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-open toggle
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Auto-open on workout start',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Automatically open music when starting a workout',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable auto-open'),
                            value: _prefs?.autoOpen ?? true,
                            onChanged: (value) {
                              _updatePrefs((prefs) => prefs.copyWith(autoOpen: value));
                              _musicService.logMusicPrefUpdate(_prefs!.userId, 'auto_open');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Default provider picker
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Default Music Provider',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose which music app to open by default',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _prefs?.defaultProvider,
                            decoration: const InputDecoration(
                              labelText: 'Default Provider',
                              border: OutlineInputBorder(),
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
                  ),
                  const SizedBox(height: 16),

                  // Genres
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Preferred Genres',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select your favorite workout music genres',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGenreChips(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BPM Range
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'BPM Range',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preferred tempo range for workout music',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBpmRangeSlider(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pro upgrade CTA
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upgrade to Pro',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pro users can attach unlimited music links to workouts and events',
                            style: Theme.of(context).textTheme.bodySmall,
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
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
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
