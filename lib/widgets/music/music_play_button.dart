import 'package:flutter/material.dart';
import '../../models/music/music_models.dart';
import '../../services/music/music_service.dart';

class MusicPlayButton extends StatefulWidget {
  final List<MusicLink> musicLinks;
  final String? defaultProvider;
  final bool autoOpen;
  final VoidCallback? onAutoOpenTriggered;

  const MusicPlayButton({
    super.key,
    required this.musicLinks,
    this.defaultProvider,
    this.autoOpen = true,
    this.onAutoOpenTriggered,
  });

  @override
  State<MusicPlayButton> createState() => MusicPlayButtonState();
}

class MusicPlayButtonState extends State<MusicPlayButton> {
  final MusicService _musicService = MusicService();
  bool _hasAutoOpened = false;

  @override
  Widget build(BuildContext context) {
    if (widget.musicLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Select which link to show based on default provider preference
    final selectedLink = _selectPreferredLink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main play button
        ElevatedButton.icon(
          onPressed: () => _playMusic(selectedLink),
          icon: _getProviderIcon(selectedLink.kind),
          label: Text(
            'Play ${selectedLink.title}',
            style: const TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getProviderColor(selectedLink.kind),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 32),
          ),
        ),
        
        // Show dropdown if multiple links
        if (widget.musicLinks.length > 1) ...[
          const SizedBox(width: 4),
          PopupMenuButton<MusicLink>(
            icon: const Icon(Icons.more_vert, size: 16),
            itemBuilder: (context) => widget.musicLinks.map((link) {
              return PopupMenuItem(
                value: link,
                child: Row(
                  children: [
                    _getProviderIcon(link.kind),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onSelected: _playMusic,
          ),
        ],
      ],
    );
  }

  MusicLink _selectPreferredLink() {
    if (widget.musicLinks.length == 1) {
      return widget.musicLinks.first;
    }

    // If user has a default provider preference, try to find a matching link
    if (widget.defaultProvider != null) {
      final preferredLink = widget.musicLinks.firstWhere(
        (link) => link.kind.name == widget.defaultProvider,
        orElse: () => widget.musicLinks.first,
      );
      return preferredLink;
    }

    // Default to first link
    return widget.musicLinks.first;
  }

  Widget _getProviderIcon(MusicKind kind) {
    switch (kind) {
      case MusicKind.spotify:
        return const Icon(Icons.music_note, color: Colors.white, size: 16);
      case MusicKind.soundcloud:
        return const Icon(Icons.music_note, color: Colors.white, size: 16);
    }
  }

  Color _getProviderColor(MusicKind kind) {
    switch (kind) {
      case MusicKind.spotify:
        return Colors.green;
      case MusicKind.soundcloud:
        return Colors.orange;
    }
  }

  Future<void> _playMusic(MusicLink link) async {
    try {
      final success = await _musicService.openDeepLink(link);
      
      if (success) {
        _musicService.logMusicOpen(link.id, link.kind.name);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎵 Opening ${link.title}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Could not open music app. Please check if it\'s installed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening music: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Auto-open functionality - call this when workout starts
  Future<void> triggerAutoOpen() async {
    if (!widget.autoOpen || _hasAutoOpened || widget.musicLinks.isEmpty) {
      return;
    }

    final selectedLink = _selectPreferredLink();
    final success = await _musicService.openDeepLink(selectedLink);
    
    if (success) {
      _hasAutoOpened = true;
      _musicService.logMusicAutoOpen(selectedLink.id);
      widget.onAutoOpenTriggered?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Auto-opened ${selectedLink.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Reset auto-open state (call when workout ends)
  void resetAutoOpen() {
    _hasAutoOpened = false;
  }
}
