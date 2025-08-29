import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/progress/progress_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        actions: [
          if (_photos.isNotEmpty) ...[
            IconButton(
              icon: Icon(_compareMode ? Icons.compare_arrows : Icons.compare),
              onPressed: _toggleCompareMode,
            ),
            if (_compareMode && _selectedPhoto1 != null && _selectedPhoto2 != null)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: _showCompareView,
              ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadPhotos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    if (_photos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedFilter == null,
                              onSelected: (_) => _applyFilter(null),
                            ),
                            ..._filters.map((filter) => FilterChip(
                              label: Text(filter.toUpperCase()),
                              selected: _selectedFilter == filter,
                              onSelected: (_) => _applyFilter(filter),
                            )),
                          ],
                        ),
                      ),
                    
                    // Compare mode indicator
                    if (_compareMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Row(
                          children: [
                            const Icon(Icons.compare, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Compare Mode: Select 2 photos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (_selectedPhoto1 != null)
                              const Chip(label: Text('1 selected')),
                            if (_selectedPhoto2 != null)
                              const Chip(label: Text('2 selected')),
                          ],
                        ),
                      ),
                    
                    // Photos grid
                    Expanded(
                      child: _filteredPhotos.isEmpty
                          ? const Center(
                              child: Text(
                                'No photos found',
                                style: TextStyle(color: Colors.grey),
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
                                          ? Border.all(color: Colors.blue, width: 3)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            photo['url'] ?? '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
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
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
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
