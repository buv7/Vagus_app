import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/progress/progress_service.dart';
import '../../theme/design_tokens.dart';

class ProgressGallery extends StatefulWidget {
  final String userId;

  const ProgressGallery({
    super.key,
    required this.userId,
  });

  @override
  State<ProgressGallery> createState() => _ProgressGalleryState();
}

class _ProgressGalleryState extends State<ProgressGallery> {
  final ProgressService _progressService = ProgressService();
  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _filteredPhotos = [];
  bool _loading = true;
  String? _error;
  
  // Filter states
  String? _selectedFilter;
  final List<String> _filters = ['front', 'side', 'back', 'other'];
  
  // Compare mode
  bool _compareMode = false;
  Map<String, dynamic>? _selectedPhoto1;
  Map<String, dynamic>? _selectedPhoto2;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() => _loading = true);
      final photos = await _progressService.fetchProgressPhotos(widget.userId);
      setState(() {
        _photos = photos;
        _filteredPhotos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == null) {
        _filteredPhotos = _photos;
      } else {
        _filteredPhotos = _photos.where((photo) => photo['shot_type'] == filter).toList();
      }
    });
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      if (!_compareMode) {
        _selectedPhoto1 = null;
        _selectedPhoto2 = null;
      }
    });
  }

  void _selectPhotoForCompare(Map<String, dynamic> photo) {
    if (!_compareMode) return;
    
    setState(() {
      if (_selectedPhoto1 == null) {
        _selectedPhoto1 = photo;
      } else if (_selectedPhoto2 == null && _selectedPhoto1 != photo) {
        _selectedPhoto2 = photo;
      } else {
        // Reset selection
        _selectedPhoto1 = photo;
        _selectedPhoto2 = null;
      }
    });
  }

  void _showCompareView() {
    if (_selectedPhoto1 == null || _selectedPhoto2 == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoCompareView(
          photo1: _selectedPhoto1!,
          photo2: _selectedPhoto2!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
        foregroundColor: isDark ? Colors.white : DesignTokens.textColor(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.photo_library,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Progress Photos',
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (_photos.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                _compareMode ? Icons.compare_arrows : Icons.compare,
                color: _compareMode ? DesignTokens.accentBlue : (isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context)),
              ),
              onPressed: _toggleCompareMode,
            ),
            if (_compareMode && _selectedPhoto1 != null && _selectedPhoto2 != null)
              IconButton(
                icon: Icon(Icons.visibility, color: DesignTokens.accentBlue),
                onPressed: _showCompareView,
              ),
          ],
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DesignTokens.accentBlue))
          : _error != null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? DesignTokens.accentPink.withValues(alpha: 0.1)
                        : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark 
                          ? DesignTokens.accentPink.withValues(alpha: 0.3)
                          : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DesignTokens.accentPink.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: DesignTokens.accentPink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: DesignTokens.accentBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _loadPhotos,
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Filter chips with glassmorphism styling
                    if (_photos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text(
                                'All',
                                style: TextStyle(
                                  color: _selectedFilter == null 
                                    ? Colors.white 
                                    : (isDark ? Colors.white : DesignTokens.textColor(context)),
                                ),
                              ),
                              selected: _selectedFilter == null,
                              selectedColor: DesignTokens.accentBlue,
                              backgroundColor: isDark 
                                ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                              side: BorderSide(
                                color: _selectedFilter == null
                                  ? DesignTokens.accentBlue
                                  : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context)),
                              ),
                              onSelected: (_) => _applyFilter(null),
                            ),
                            ..._filters.map((filter) => FilterChip(
                              label: Text(
                                filter.toUpperCase(),
                                style: TextStyle(
                                  color: _selectedFilter == filter 
                                    ? Colors.white 
                                    : (isDark ? Colors.white : DesignTokens.textColor(context)),
                                ),
                              ),
                              selected: _selectedFilter == filter,
                              selectedColor: DesignTokens.accentBlue,
                              backgroundColor: isDark 
                                ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                              side: BorderSide(
                                color: _selectedFilter == filter
                                  ? DesignTokens.accentBlue
                                  : (isDark ? DesignTokens.accentBlue.withValues(alpha: 0.3) : DesignTokens.borderColor(context)),
                              ),
                              onSelected: (_) => _applyFilter(filter),
                            )),
                          ],
                        ),
                      ),
                    
                    // Compare mode indicator with glassmorphism
                    if (_compareMode)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                            : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                              : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.compare, color: DesignTokens.accentBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Compare Mode: Select 2 photos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : DesignTokens.textColor(context),
                              ),
                            ),
                            const Spacer(),
                            if (_selectedPhoto1 != null)
                              Chip(
                                label: Text(
                                  '1 selected',
                                  style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                                ),
                                backgroundColor: isDark 
                                  ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                                  : Colors.blue.shade100,
                                side: BorderSide(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
                              ),
                            if (_selectedPhoto2 != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  '2 selected',
                                  style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                                ),
                                backgroundColor: isDark 
                                  ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                                  : Colors.blue.shade100,
                                side: BorderSide(color: DesignTokens.accentBlue.withValues(alpha: 0.3)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    
                    // Photos grid
                    Expanded(
                      child: _filteredPhotos.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(32),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: isDark 
                                    ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                                    : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark 
                                      ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                      : DesignTokens.borderColor(context),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.photo,
                                        size: 48,
                                        color: DesignTokens.accentBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No photos found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : DesignTokens.textColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _filteredPhotos.length,
                              itemBuilder: (context, index) {
                                final photo = _filteredPhotos[index];
                                final isSelected = _compareMode && 
                                    (_selectedPhoto1 == photo || _selectedPhoto2 == photo);
                                
                                return GestureDetector(
                                  onTap: () {
                                    if (_compareMode) {
                                      _selectPhotoForCompare(photo);
                                    } else {
                                      _showFullScreenPhoto(photo);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelected
                                          ? Border.all(color: DesignTokens.accentBlue, width: 3)
                                          : Border.all(
                                              color: isDark 
                                                ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                                : DesignTokens.borderColor(context),
                                              width: 1,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          spreadRadius: 0,
                                        ),
                                      ] : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            photo['url'] ?? '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: isDark 
                                                  ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                                                  : Colors.grey[300],
                                                child: Icon(Icons.error, color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withValues(alpha: 0.7),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                DateFormat('MMM dd, yyyy').format(
                                                  DateTime.parse(photo['taken_at']),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: DesignTokens.accentBlue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                                                      blurRadius: 8,
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showFullScreenPhoto(Map<String, dynamic> photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(DateFormat('MMM dd, yyyy').format(
              DateTime.parse(photo['taken_at']),
            )),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePhoto(photo['id']),
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: NetworkImage(photo['url'] ?? ''),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _progressService.deleteProgressPhoto(photoId);
      unawaited(_loadPhotos());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Photo deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete photo: $e')),
        );
      }
    }
  }
}

class PhotoCompareView extends StatefulWidget {
  final Map<String, dynamic> photo1;
  final Map<String, dynamic> photo2;

  const PhotoCompareView({
    super.key,
    required this.photo1,
    required this.photo2,
  });

  @override
  State<PhotoCompareView> createState() => _PhotoCompareViewState();
}

class _PhotoCompareViewState extends State<PhotoCompareView> {
  final PhotoViewScaleStateController _controller1 = PhotoViewScaleStateController();
  final PhotoViewScaleStateController _controller2 = PhotoViewScaleStateController();

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              // Synchronize zoom levels
              final scale1 = _controller1.scaleState;
              final scale2 = _controller2.scaleState;
              if (scale1 != scale2) {
                _controller2.scaleState = scale1;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(widget.photo1['taken_at']),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(widget.photo2['taken_at']),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Photos side by side
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PhotoView(
                    imageProvider: NetworkImage(widget.photo1['url'] ?? ''),
                    scaleStateController: _controller1,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  ),
                ),
                Container(width: 1, color: Colors.grey),
                Expanded(
                  child: PhotoView(
                    imageProvider: NetworkImage(widget.photo2['url'] ?? ''),
                    scaleStateController: _controller2,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
