import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../widgets/ai/ai_usage_meter.dart';
// AI Usage Test Widget archived - no longer in use
// import '../../widgets/ai/ai_usage_test_widget.dart';
import 'upload_photos_screen.dart';
import 'coach_file_feedback_screen.dart';
import '../../theme/design_tokens.dart';


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

            // AI Usage Test Panel archived - no longer displayed
            // const AIUsageTestWidget(),

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadPhotosScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Photo Gallery'),
            ),
                         ElevatedButton.icon(
               onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const CoachFileFeedbackScreen(),
                   ),
                 );
               },
               icon: const Icon(Icons.feedback),
               label: const Text('Coach Feedback'),
             ),
          ],
        ),
      ],
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
            color: DesignTokens.ink500.withValues(alpha: 0.5),
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'No files found',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink700,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Upload your first file to get started',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final category = file['category'] ?? 'other';
        final categoryColor = _getCategoryColor(category);
        final categoryBgColor = _getCategoryBgColor(category);
        
        return Card(
          margin: const EdgeInsets.only(bottom: DesignTokens.space8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            side: const BorderSide(
              color: DesignTokens.ink100,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(DesignTokens.space12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryBgColor,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(
                _getFileIcon(category),
                color: categoryColor,
                size: 24,
              ),
            ),
            title: Text(
              file['file_name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.ink900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DesignTokens.space4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space6,
                        vertical: DesignTokens.space2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radius4),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: DesignTokens.labelSmall.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space8),
                    Text(
                      _formatFileSize(file['file_size'] ?? 0),
                      style: DesignTokens.labelSmall.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  _formatDate(DateTime.parse(file['created_at'])),
                  style: DesignTokens.labelSmall.copyWith(
                    color: DesignTokens.ink500.withValues(alpha: 0.7),
                  ),
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
                if (value == 'download') {
                  _downloadFile(file);
                } else if (value == 'delete') {
                  _deleteFile(file['id']);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'images':
        return DesignTokens.success;
      case 'videos':
        return DesignTokens.info;
      case 'documents':
        return DesignTokens.warn;
      case 'audio':
        return DesignTokens.purple500;
      default:
        return DesignTokens.ink500;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'images':
        return DesignTokens.successBg;
      case 'videos':
        return DesignTokens.infoBg;
      case 'documents':
        return DesignTokens.warnBg;
      case 'audio':
        return DesignTokens.purple50;
      default:
        return DesignTokens.ink50;
    }
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




  Future<void> _downloadFile(Map<String, dynamic> file) async {
    try {
      final fileName = file['name'] as String;
      final fileUrl = file['url'] as String?;
      
      if (fileUrl == null || fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File URL not available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show download progress dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(
          fileName: fileName,
          onDownload: () => unawaited(_performDownload(fileUrl, fileName)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performDownload(String fileUrl, String fileName) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadPath = '${directory.path}/$fileName';
      
      // Download the file
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode == 200) {
        // Save the file
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Downloaded to: $downloadPath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Open file with appropriate app
                  debugPrint('Would open file: $downloadPath');
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Download failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }




}

/// Dialog showing download progress
class DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final VoidCallback onDownload;

  const DownloadProgressDialog({
    super.key,
    required this.fileName,
    required this.onDownload,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  final bool _downloading = false;
  final double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Start download automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDownload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.fileName,
            style: DesignTokens.labelMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_downloading) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: DesignTokens.ink100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                DesignTokens.blue600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading... ${(_progress * 100).toInt()}%',
              style: DesignTokens.labelSmall,
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Preparing download...'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
