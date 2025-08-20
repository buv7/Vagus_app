import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Upload Photos Screen for VAGUS app
/// Simple grid gallery of user's uploaded files with upload functionality
class UploadPhotosScreen extends StatefulWidget {
  const UploadPhotosScreen({super.key});

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _loading = true;
  List<Map<String, dynamic>> _files = [];
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;

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

      // Query files for the current user (images and videos for gallery view)
      final response = await supabase
          .from('user_files')
          .select('*')
          .eq('user_id', user.id)
          .inFilter('category', ['images', 'videos'])
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

  Future<void> _pickAndUploadFiles() async {
    try {
      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Show picker options
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Files'),
          content: const Text('Choose how you want to upload files:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'camera'),
              child: const Text('📷 Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Text('🖼️ Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'file_picker'),
              child: const Text('📁 File Picker'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result == null) {
        setState(() => _uploading = false);
        return;
      }

      List<File> filesToUpload = [];

      switch (result) {
        case 'camera':
          final image = await _imagePicker.pickImage(source: ImageSource.camera);
          if (image != null) {
            filesToUpload.add(File(image.path));
          }
          break;
        case 'gallery':
          final images = await _imagePicker.pickMultiImage();
          filesToUpload.addAll(images.map((img) => File(img.path)));
          break;
        case 'file_picker':
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
          );
          if (result != null) {
            filesToUpload.addAll(
              result.files
                  .where((file) => file.path != null)
                  .map((file) => File(file.path!))
            );
          }
          break;
      }

      if (filesToUpload.isEmpty) {
        setState(() => _uploading = false);
        return;
      }

      // Upload files with progress
      for (int i = 0; i < filesToUpload.length; i++) {
        final file = filesToUpload[i];
        final fileName = file.path.split('/').last;
        final fileSize = file.lengthSync();
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
        
        await supabase.storage.from('vagus-media').upload(filePath, file);
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

        // Update progress
        setState(() {
          _uploadProgress = (i + 1) / filesToUpload.length;
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
      setState(() => _uploadError = e.toString());
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

  Widget _buildFileThumbnail(Map<String, dynamic> file) {
    final category = file['category'];
    final fileUrl = file['file_url'];
    final fileName = file['file_name'];

    if (category == 'images' && fileUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fileUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      );
    } else {
      // Video or other file type
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              category == 'videos' ? Icons.videocam : Icons.insert_drive_file,
              size: 32,
              color: Colors.grey.shade600,
            ),
            if (category == 'videos')
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Upload Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh gallery',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _files.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(),

          // Upload progress overlay
          if (_uploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Uploading files...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text('${(_uploadProgress * 100).toInt()}%'),
                        if (_uploadError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: $_uploadError',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _pickAndUploadFiles,
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
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No photos or videos yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to upload your first file',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return GestureDetector(
          onTap: () {
            // TODO: Navigate to file previewer
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening ${file['file_name']}')),
            );
          },
          onLongPress: () => _showFileOptions(file),
          child: Stack(
            children: [
              _buildFileThumbnail(file),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatFileSize(file['file_size'] ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFileOptions(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to file previewer
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(file);
              },
            ),
          ],
        ),
      ),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
