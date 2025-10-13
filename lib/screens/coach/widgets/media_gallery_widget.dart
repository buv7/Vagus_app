import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';
import '../../../theme/design_tokens.dart';

class MediaGalleryWidget extends StatefulWidget {
  final List<CoachMedia> media;
  final bool isEditMode;
  final bool isOwner;
  final String coachId;
  final VoidCallback onMediaUpdated;

  const MediaGalleryWidget({
    super.key,
    required this.media,
    required this.isEditMode,
    required this.isOwner,
    required this.coachId,
    required this.onMediaUpdated,
  });

  @override
  State<MediaGalleryWidget> createState() => _MediaGalleryWidgetState();
}

class _MediaGalleryWidgetState extends State<MediaGalleryWidget>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  bool _isGridView = true;

  late AnimationController _filterController;
  late AnimationController _itemsController;

  final List<String> _filters = ['all', 'videos', 'courses', 'public', 'clients_only'];

  @override
  void initState() {
    super.initState();

    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _itemsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _filterController.forward();
    _itemsController.forward();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  List<CoachMedia> get _filteredMedia {
    switch (_selectedFilter) {
      case 'videos':
        return widget.media.where((m) => m.mediaType == 'video').toList();
      case 'courses':
        return widget.media.where((m) => m.mediaType == 'course').toList();
      case 'public':
        return widget.media.where((m) => m.visibility == 'public').toList();
      case 'clients_only':
        return widget.media.where((m) => m.visibility == 'clients_only').toList();
      default:
        return widget.media;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      padding: const EdgeInsets.all(DesignTokens.space20),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: DesignTokens.cardShadow,
        border: Border.all(color: DesignTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),

          if (widget.media.isNotEmpty || widget.isEditMode) ...[
            const SizedBox(height: DesignTokens.space16),
            _buildFiltersAndControls(),
            const SizedBox(height: DesignTokens.space16),
            _buildMediaContent(),
          ] else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space8),
          decoration: BoxDecoration(
            color: DesignTokens.accentPink.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: const Icon(
            Icons.video_library,
            size: 20,
            color: DesignTokens.accentPink,
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Text(
          'Portfolio',
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.neutralWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (widget.media.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space8,
              vertical: DesignTokens.space4,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.accentGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Text(
              '${_filteredMedia.length} ${_filteredMedia.length == 1 ? 'item' : 'items'}',
              style: DesignTokens.labelSmall.copyWith(
                color: DesignTokens.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersAndControls() {
    return Column(
      children: [
        // Filters
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _filterController,
            curve: Curves.easeOut,
          )),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.space12),

        // Controls
        Row(
          children: [
            if (widget.isEditMode) ...[
              _buildAddMediaButton(),
              const SizedBox(width: DesignTokens.space8),
            ],

            const Spacer(),

            // View toggle
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.primaryDark,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggleButton(
                    icon: Icons.grid_view,
                    isSelected: _isGridView,
                    onTap: () => setState(() => _isGridView = true),
                  ),
                  _buildViewToggleButton(
                    icon: Icons.view_list,
                    isSelected: !_isGridView,
                    onTap: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final displayName = _getFilterDisplayName(filter);

    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.space8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = filter),
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space12,
              vertical: DesignTokens.space6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                  : DesignTokens.primaryDark,
              borderRadius: BorderRadius.circular(DesignTokens.radius20),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.accentBlue
                    : DesignTokens.glassBorder,
              ),
            ),
            child: Text(
              displayName,
              style: DesignTokens.labelSmall.copyWith(
                color: isSelected
                    ? DesignTokens.accentBlue
                    : DesignTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all': return 'All';
      case 'videos': return 'Videos';
      case 'courses': return 'Courses';
      case 'public': return 'Public';
      case 'clients_only': return 'Clients Only';
      default: return filter;
    }
  }

  Widget _buildAddMediaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddMediaDialog,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space12,
            vertical: DesignTokens.space8,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.accentGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            border: Border.all(color: DesignTokens.accentGreen),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: DesignTokens.accentGreen),
              const SizedBox(width: DesignTokens.space4),
              Text(
                'Add Media',
                style: DesignTokens.labelSmall.copyWith(
                  color: DesignTokens.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius4),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space6),
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radius4),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? DesignTokens.accentBlue
                : DesignTokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_filteredMedia.isEmpty) {
      return _buildFilteredEmptyState();
    }

    return AnimatedBuilder(
      animation: _itemsController,
      builder: (context, child) {
        return _isGridView
            ? _buildGridView()
            : _buildListView();
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.space12,
        mainAxisSpacing: DesignTokens.space12,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredMedia.length,
      itemBuilder: (context, index) {
        final media = _filteredMedia[index];
        return _buildMediaGridCard(media, index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredMedia.length,
      separatorBuilder: (context, index) => const SizedBox(height: DesignTokens.space12),
      itemBuilder: (context, index) {
        final media = _filteredMedia[index];
        return _buildMediaListCard(media, index);
      },
    );
  }

  Widget _buildMediaGridCard(CoachMedia media, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.5 + (index * 0.1)),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _itemsController,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.easeOut,
        ),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Stack(
          children: [
            // Media thumbnail/preview
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                child: Container(
                  color: DesignTokens.primaryDark,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        media.mediaType == 'video' ? Icons.play_circle_outline : Icons.school,
                        size: 32,
                        color: DesignTokens.accentGreen,
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8),
                        child: Text(
                          media.title,
                          style: DesignTokens.labelMedium.copyWith(color: DesignTokens.neutralWhite),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Status badges
            Positioned(
              top: DesignTokens.space8,
              left: DesignTokens.space8,
              child: Row(
                children: [
                  _buildMediaBadge(media),
                ],
              ),
            ),

            // Edit actions (edit mode only)
            if (widget.isEditMode)
              Positioned(
                top: DesignTokens.space8,
                right: DesignTokens.space8,
                child: _buildMediaActions(media),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaListCard(CoachMedia media, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _itemsController,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.easeOut,
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryDark,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: DesignTokens.glassBorder),
        ),
        child: Row(
          children: [
            // Media icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(
                media.mediaType == 'video' ? Icons.play_circle_outline : Icons.school,
                color: DesignTokens.accentGreen,
              ),
            ),

            const SizedBox(width: DesignTokens.space12),

            // Media info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.neutralWhite,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (media.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      media.description!,
                      style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.space8),
                  Row(
                    children: [
                      _buildMediaBadge(media),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (widget.isEditMode)
              _buildMediaActions(media),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBadge(CoachMedia media) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (!media.isApproved) {
      badgeColor = DesignTokens.accentOrange;
      badgeText = 'Pending';
      badgeIcon = Icons.schedule;
    } else if (media.visibility == 'public') {
      badgeColor = DesignTokens.accentGreen;
      badgeText = 'Public';
      badgeIcon = Icons.public;
    } else {
      badgeColor = DesignTokens.accentBlue;
      badgeText = 'Clients Only';
      badgeIcon = Icons.lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: DesignTokens.space2),
          Text(
            badgeText,
            style: DesignTokens.labelSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaActions(CoachMedia media) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radius4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _editMedia(media),
            child: const Icon(Icons.edit, size: 16, color: Colors.white),
          ),
          const SizedBox(width: DesignTokens.space4),
          GestureDetector(
            onTap: () => _deleteMedia(media),
            child: const Icon(Icons.delete, size: 16, color: DesignTokens.accentPink),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space32),
      child: Column(
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 48,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            widget.isOwner ? 'Build Your Portfolio' : 'No Portfolio Yet',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.neutralWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            widget.isOwner
                ? 'Add videos and courses to showcase your expertise'
                : 'This coach hasn\'t added any portfolio content yet',
            style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (widget.isEditMode) ...[
            const SizedBox(height: DesignTokens.space20),
            ElevatedButton(
              onPressed: _showAddMediaDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accentGreen,
                foregroundColor: DesignTokens.primaryDark,
              ),
              child: const Text('Add First Media'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off,
            size: 32,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(height: DesignTokens.space12),
          Text(
            'No ${_getFilterDisplayName(_selectedFilter).toLowerCase()} found',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 'all'),
            child: Text(
              'Show all media',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.accentBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMediaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        title: Text(
          'Add Media',
          style: DesignTokens.titleMedium.copyWith(color: DesignTokens.neutralWhite),
        ),
        content: const Text(
          'Media upload functionality will be implemented here',
          style: TextStyle(color: DesignTokens.textSecondary),
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

  void _editMedia(CoachMedia media) {
    // Implement edit media functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${media.title}'),
        backgroundColor: DesignTokens.accentBlue,
      ),
    );
  }

  void _deleteMedia(CoachMedia media) {
    // Implement delete media functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.cardBackground,
        title: const Text('Delete Media', style: TextStyle(color: DesignTokens.neutralWhite)),
        content: Text(
          'Are you sure you want to delete "${media.title}"?',
          style: const TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual deletion
              widget.onMediaUpdated();
            },
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.accentPink),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}