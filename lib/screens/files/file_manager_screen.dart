import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/ai/ai_usage_meter.dart';
import '../../widgets/ai/ai_usage_test_widget.dart';

/// File Manager Screen for VAGUS app
/// Allows users to upload, view, and manage files
class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _files = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _uploading = false;

  final List<String> _categories = [
    'all',
    'images',
    'documents',
    'videos',
    'audio',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() => _loading = true);

      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Query files for the current user
      final response = await supabase
          .from('user_files')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _files = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load files: $e')),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);

      final user = supabase.auth.currentUser;
      if (user == null) return;

      for (final file in result.files) {
        if (file.path == null) continue;

        final fileObj = File(file.path!);
        final fileName = file.name;
        final fileSize = fileObj.lengthSync();
        final fileExt = fileName.split('.').last.toLowerCase();
        
        // Determine category based on file extension
        String category = 'other';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
          category = 'images';
        } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileExt)) {
          category = 'documents';
        } else if (['mp4', 'avi', 'mov', 'wmv'].contains(fileExt)) {
          category = 'videos';
        } else if (['mp3', 'wav', 'm4a', 'aac'].contains(fileExt)) {
          category = 'audio';
        }

        // Upload to Supabase Storage
        final filePath = 'user_files/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        
        await supabase.storage.from('vagus-media').upload(filePath, fileObj);
        final publicUrl = supabase.storage.from('vagus-media').getPublicUrl(filePath);

        // Save file metadata to database
        await supabase.from('user_files').insert({
          'user_id': user.id,
          'file_name': fileName,
          'file_path': filePath,
          'file_url': publicUrl,
          'file_size': fileSize,
          'file_type': fileExt,
          'category': category,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Reload files
      await _loadFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Files uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Upload failed: $e')),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteFile(String fileId) async {
    try {
      // Get file info before deletion
      final fileInfo = _files.firstWhere((f) => f['id'] == fileId);
      
      // Delete from storage
      await supabase.storage.from('vagus-media').remove([fileInfo['file_path']]);
      
      // Delete from database
      await supabase.from('user_files').delete().eq('id', fileId);
      
      // Reload files
      await _loadFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ File deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Delete failed: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFiles {
    return _files.where((file) {
      final matchesSearch = file['file_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || file['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String category) {
    switch (category) {
      case 'images':
        return Icons.image;
      case 'documents':
        return Icons.description;
      case 'videos':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh files',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AI Usage Meter at the top
            Padding(
              padding: const EdgeInsets.all(16),
              child: AIUsageMeter(
                isCompact: true,
                onRefresh: _loadFiles,
              ),
            ),
            
            // AI Usage Test Panel (for testing purposes)
            const AIUsageTestWidget(),
    
            // Search and filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search files...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : 'all';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Files list
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? _buildEmptyState()
                    : _buildFilesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _uploadFile,
        tooltip: 'Upload files',
        child: _uploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.upload),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No files found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first file to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                _getFileIcon(file['category']),
                color: Colors.grey.shade600,
              ),
            ),
            title: Text(
              file['file_name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFileSize(file['file_size'] ?? 0),
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '${file['category']} • ${_formatDate(DateTime.parse(file['created_at']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'download':
                    // TODO: Implement download functionality
                    break;
                  case 'share':
                    // TODO: Implement share functionality
                    break;
                  case 'delete':
                    _showDeleteConfirmation(file);
                    break;
                }
              },
            ),
            onTap: () {
              // TODO: Implement file preview/opening
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file['file_name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
