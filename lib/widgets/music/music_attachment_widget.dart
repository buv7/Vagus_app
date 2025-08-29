import 'package:flutter/material.dart';
import '../../models/music/music_models.dart';
import '../../services/music/music_service.dart';

class MusicAttachmentWidget extends StatefulWidget {
  final String? planId;
  final int? weekIdx;
  final int? dayIdx;
  final String? eventId;
  final List<MusicLink> attachedLinks;
  final Function(List<MusicLink>) onLinksChanged;
  final bool isReadOnly;

  const MusicAttachmentWidget({
    super.key,
    this.planId,
    this.weekIdx,
    this.dayIdx,
    this.eventId,
    required this.attachedLinks,
    required this.onLinksChanged,
    this.isReadOnly = false,
  });

  @override
  State<MusicAttachmentWidget> createState() => _MusicAttachmentWidgetState();
}

class _MusicAttachmentWidgetState extends State<MusicAttachmentWidget> {
  final MusicService _musicService = MusicService();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.music_note,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Session Playlist',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!widget.isReadOnly)
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: _showMusicPicker,
                tooltip: 'Attach music',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.attachedLinks.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.music_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'No music attached',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.attachedLinks.map((link) => _buildMusicChip(link)).toList(),
          ),
      ],
    );
  }

  Widget _buildMusicChip(MusicLink link) {
    return Chip(
      avatar: _getProviderIcon(link.kind),
      label: Text(
        link.title,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      deleteIcon: widget.isReadOnly ? null : const Icon(Icons.close, size: 16),
      onDeleted: widget.isReadOnly ? null : () => _removeLink(link),
      backgroundColor: _getProviderColor(link.kind).withValues(alpha: 0.1),
      side: BorderSide(color: _getProviderColor(link.kind)),
    );
  }

  Widget _getProviderIcon(MusicKind kind) {
    switch (kind) {
      case MusicKind.spotify:
        return const Icon(Icons.music_note, color: Colors.green, size: 16);
      case MusicKind.soundcloud:
        return const Icon(Icons.music_note, color: Colors.orange, size: 16);
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

  Future<void> _showMusicPicker() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final myLinks = await _musicService.listMyLinks();
      setState(() => _loading = false);

      if (!mounted) return;

      final selected = await showModalBottomSheet<MusicLink>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _MusicPickerSheet(
          existingLinks: myLinks,
          attachedLinks: widget.attachedLinks,
        ),
      );

      if (selected != null) {
        await _attachLink(selected);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading music links: $e')),
        );
      }
    }
  }

  Future<void> _attachLink(MusicLink link) async {
    try {
      if (widget.planId != null) {
        await _musicService.attachToPlanDay(
          planId: widget.planId!,
          weekIdx: widget.weekIdx,
          dayIdx: widget.dayIdx,
          musicLinkId: link.id,
        );
      } else if (widget.eventId != null) {
        await _musicService.attachToEvent(
          eventId: widget.eventId!,
          musicLinkId: link.id,
        );
      }

      final updatedLinks = [...widget.attachedLinks, link];
      widget.onLinksChanged(updatedLinks);
      _musicService.logMusicAttach(
        widget.planId != null ? 'plan_day' : 'event',
        link.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${link.title} attached')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error attaching music: $e')),
        );
      }
    }
  }

  Future<void> _removeLink(MusicLink link) async {
    try {
      if (widget.planId != null) {
        await _musicService.detachFromPlanDay(
          planId: widget.planId!,
          weekIdx: widget.weekIdx,
          dayIdx: widget.dayIdx,
          musicLinkId: link.id,
        );
      } else if (widget.eventId != null) {
        await _musicService.detachFromEvent(
          eventId: widget.eventId!,
          musicLinkId: link.id,
        );
      }

      final updatedLinks = widget.attachedLinks.where((l) => l.id != link.id).toList();
      widget.onLinksChanged(updatedLinks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${link.title} removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing music: $e')),
        );
      }
    }
  }
}

class _MusicPickerSheet extends StatefulWidget {
  final List<MusicLink> existingLinks;
  final List<MusicLink> attachedLinks;

  const _MusicPickerSheet({
    required this.existingLinks,
    required this.attachedLinks,
  });

  @override
  State<_MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<_MusicPickerSheet> {
  final MusicService _musicService = MusicService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _uriController = TextEditingController();
  MusicKind _selectedKind = MusicKind.spotify;
  bool _showAddForm = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attach Music',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!_showAddForm) ...[
            // Existing links
            if (widget.existingLinks.isNotEmpty) ...[
              Text(
                'Your Music Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.existingLinks.length,
                  itemBuilder: (context, index) {
                    final link = widget.existingLinks[index];
                    final isAttached = widget.attachedLinks.any((l) => l.id == link.id);
                    
                    return ListTile(
                      leading: _getProviderIcon(link.kind),
                      title: Text(link.title),
                      subtitle: Text(link.uri),
                      trailing: isAttached
                          ? const Icon(Icons.check, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => Navigator.pop(context, link),
                            ),
                      onTap: isAttached ? null : () => Navigator.pop(context, link),
                    );
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No music links yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first music link to get started',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = true),
                icon: const Icon(Icons.add),
                label: const Text('Add New Music Link'),
              ),
            ),
          ] else ...[
            // Add new link form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Music Link',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Provider selection
                    Text(
                      'Music Provider',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<MusicKind>(
                      segments: const [
                        ButtonSegment(
                          value: MusicKind.spotify,
                          label: Text('Spotify'),
                          icon: Icon(Icons.music_note, color: Colors.green),
                        ),
                        ButtonSegment(
                          value: MusicKind.soundcloud,
                          label: Text('SoundCloud'),
                          icon: Icon(Icons.music_note, color: Colors.orange),
                        ),
                      ],
                      selected: {_selectedKind},
                      onSelectionChanged: (Set<MusicKind> selection) {
                        setState(() => _selectedKind = selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Workout Mix 2024',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // URI field
                    TextField(
                      controller: _uriController,
                      decoration: InputDecoration(
                        labelText: 'Music Link',
                        hintText: _selectedKind == MusicKind.spotify
                            ? 'e.g., spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'
                            : 'e.g., https://soundcloud.com/artist/track',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Help text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to get music links:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedKind == MusicKind.spotify) ...[
                            const Text('• Open Spotify app'),
                            const Text('• Find your playlist/track'),
                            const Text('• Tap Share → Copy link'),
                            const Text('• Or use spotify: URI format'),
                          ] else ...[
                            const Text('• Open SoundCloud app'),
                            const Text('• Find your track/playlist'),
                            const Text('• Tap Share → Copy link'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showAddForm = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveNewLink,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _getProviderIcon(MusicKind kind) {
    switch (kind) {
      case MusicKind.spotify:
        return const Icon(Icons.music_note, color: Colors.green);
      case MusicKind.soundcloud:
        return const Icon(Icons.music_note, color: Colors.orange);
    }
  }

  Future<void> _saveNewLink() async {
    final title = _titleController.text.trim();
    final uri = _uriController.text.trim();
    
    if (title.isEmpty || uri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final newLink = await _musicService.createLink(
        title: title,
        kind: _selectedKind,
        uri: uri,
      );
      
      if (!mounted) return;
      setState(() => _saving = false);
      if (!mounted || !context.mounted) return;
      Navigator.pop(context, newLink);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating music link: $e')),
      );
    }
  }
}
