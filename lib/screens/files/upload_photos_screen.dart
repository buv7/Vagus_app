import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/design_tokens.dart';

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

      final List<File> filesToUpload = [];

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
                    color: Colors.black.withValues(alpha: 0.7),
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
                Icons.camera_alt,
                color: DesignTokens.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Upload Photos',
              style: TextStyle(
                color: isDark ? Colors.white : DesignTokens.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context)),
            onPressed: _loadFiles,
            tooltip: 'Refresh gallery',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _loading
              ? Center(child: CircularProgressIndicator(color: DesignTokens.accentBlue))
              : _files.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(),

          // Upload progress overlay with glassmorphism
          if (_uploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? DesignTokens.darkBackground.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Uploading files...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : DesignTokens.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: isDark 
                              ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                              : Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentBlue),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                          ),
                          if (_uploadError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Error: $_uploadError',
                              style: TextStyle(color: DesignTokens.accentPink),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              DesignTokens.accentBlue.withValues(alpha: 0.3),
              DesignTokens.accentBlue.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _uploading ? null : _pickAndUploadFiles,
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: _uploading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
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
                Icons.photo_library,
                size: 48,
                color: DesignTokens.accentBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No photos or videos yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to upload your first file',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                    color: Colors.black.withValues(alpha: 0.7),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: DesignTokens.accentBlue.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.visibility, color: DesignTokens.accentBlue),
                ),
                title: Text('View', style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context), fontWeight: FontWeight.w600)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                hoverColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to file previewer
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentPurple.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.share, color: DesignTokens.accentPurple),
                ),
                title: Text('Share', style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context), fontWeight: FontWeight.w600)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                hoverColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.accentPink.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.delete, color: DesignTokens.accentPink),
                ),
                title: Text('Delete', style: TextStyle(color: DesignTokens.accentPink, fontWeight: FontWeight.w600)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                hoverColor: DesignTokens.accentPink.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(file);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
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
