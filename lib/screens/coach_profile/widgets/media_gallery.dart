import 'package:flutter/material.dart';
import '../../../services/coach_profile_service.dart';

class MediaGallery extends StatefulWidget {
  final String coachId;
  final bool isOwnProfile;
  final VoidCallback? onMediaUpdated;

  const MediaGallery({
    super.key,
    required this.coachId,
    this.isOwnProfile = false,
    this.onMediaUpdated,
  });

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  final _profileService = CoachProfileService();
  List<Map<String, dynamic>> _mediaItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _loading = true);

    try {
      final media = await _profileService.getCoachMedia(widget.coachId);
      setState(() {
        _mediaItems = media;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading media: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isOwnProfile
                  ? 'No media added yet'
                  : 'No media available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showAddMediaDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Media'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaItems.length + (widget.isOwnProfile ? 1 : 0),
      itemBuilder: (context, index) {
        // Add button at the end if own profile
        if (widget.isOwnProfile && index == _mediaItems.length) {
          return _buildAddMediaCard();
        }

        final media = _mediaItems[index];
        return _buildMediaCard(media);
      },
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> media) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewMedia(media),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    _getMediaIcon(media['type'] as String?),
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media['title'] as String? ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (media['type'] != null)
                      Chip(
                        label: Text(
                          media['type'] as String,
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
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

  Widget _buildAddMediaCard() {
    return Card(
      child: InkWell(
        onTap: _showAddMediaDialog,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Media',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMediaIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'course':
        return Icons.school_outlined;
      case 'article':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  void _viewMedia(Map<String, dynamic> media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(media['title'] as String? ?? 'Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media['description'] != null)
              Text(media['description'] as String),
            const SizedBox(height: 16),
            Text('Type: ${media['type'] ?? 'Unknown'}'),
            if (media['url'] != null)
              Text('URL: ${media['url']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddMediaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Media'),
        content: const Text('Media upload functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
