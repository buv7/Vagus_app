import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coach File Feedback Screen for VAGUS app
/// Coaches can view client uploads and add comments + tags
class CoachFileFeedbackScreen extends StatefulWidget {
  final String? clientId;
  final String? clientName;

  const CoachFileFeedbackScreen({
    super.key,
    this.clientId,
    this.clientName,
  });

  @override
  State<CoachFileFeedbackScreen> createState() => _CoachFileFeedbackScreenState();
}

class _CoachFileFeedbackScreenState extends State<CoachFileFeedbackScreen> {
  final supabase = Supabase.instance.client;
  
  bool _loading = true;
  List<Map<String, dynamic>> _clientFiles = [];
  List<Map<String, dynamic>> _feedbackList = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';

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
    _loadClientFiles();
    _loadFeedback();
  }

  Future<void> _loadClientFiles() async {
    try {
      setState(() => _loading = true);

      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Query files for the specific client
      final response = await supabase
          .from('user_files')
          .select('*')
          .eq('user_id', widget.clientId ?? user.id)
          .order('created_at', ascending: false);

      setState(() {
        _clientFiles = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load client files: $e')),
        );
      }
    }
  }

  Future<void> _loadFeedback() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Query feedback for files of this client
      final response = await supabase
          .from('file_feedback')
          .select('*, user_files(*)')
          .eq('coach_id', user.id)
          .eq('user_files.user_id', widget.clientId ?? user.id)
          .order('created_at', ascending: false);

      setState(() {
        _feedbackList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load feedback: $e')),
        );
      }
    }
  }

  Future<void> _addFeedback(Map<String, dynamic> file) async {
    final TextEditingController commentController = TextEditingController();
    final List<String> selectedTags = [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Feedback for ${file['file_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(file['category']),
                        color: _getFileColor(file['category']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file['file_name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _formatFileSize(file['file_size'] ?? 0),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Comment field
                const Text(
                  'Comment:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add your feedback here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tags selection
                const Text(
                  'Tags:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'progress',
                    'form',
                    'technique',
                    'nutrition',
                    'motivation',
                    'question',
                    'concern',
                    'achievement',
                  ].map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'comment': commentController.text.trim(),
                    'tags': selectedTags,
                  });
                }
              },
              child: const Text('Save Feedback'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _saveFeedback(file, result['comment'], result['tags']);
    }
  }

  Future<void> _saveFeedback(
    Map<String, dynamic> file,
    String comment,
    List<String> tags,
  ) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Save feedback to database
      await supabase.from('file_feedback').insert({
        'file_id': file['id'],
        'coach_id': user.id,
        'comment': comment,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload feedback
      await _loadFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save feedback: $e')),
        );
      }
    }
  }

  Future<void> _editFeedback(Map<String, dynamic> feedback) async {
    final TextEditingController commentController = TextEditingController(
      text: feedback['comment'],
    );
    final List<String> selectedTags = List<String>.from(feedback['tags'] ?? []);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comment:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add your feedback here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Tags:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'progress',
                    'form',
                    'technique',
                    'nutrition',
                    'motivation',
                    'question',
                    'concern',
                    'achievement',
                  ].map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'comment': commentController.text.trim(),
                    'tags': selectedTags,
                  });
                }
              },
              child: const Text('Update Feedback'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _updateFeedback(feedback['id'], result['comment'], result['tags']);
    }
  }

  Future<void> _updateFeedback(
    String feedbackId,
    String comment,
    List<String> tags,
  ) async {
    try {
      await supabase.from('file_feedback').update({
        'comment': comment,
        'tags': tags,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', feedbackId);

      // Reload feedback
      await _loadFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to update feedback: $e')),
        );
      }
    }
  }

  Future<void> _deleteFeedback(String feedbackId) async {
    try {
      await supabase.from('file_feedback').delete().eq('id', feedbackId);
      
      // Reload feedback
      await _loadFeedback();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete feedback: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFiles {
    return _clientFiles.where((file) {
      final matchesSearch = file['file_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || file['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Map<String, dynamic>? _getFeedbackForFile(String fileId) {
    try {
      return _feedbackList.firstWhere((feedback) => feedback['file_id'] == fileId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('📁 ${widget.clientName ?? 'Client'} Files'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Files', icon: Icon(Icons.folder)),
              Tab(text: 'Feedback', icon: Icon(Icons.comment)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadClientFiles();
                _loadFeedback();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Files Tab
            _buildFilesTab(),
            // Feedback Tab
            _buildFeedbackTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab() {
    return Column(
      children: [
        // Search and filters
        Padding(
          padding: const EdgeInsets.all(16),
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
        
        // Files list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredFiles.isEmpty
                  ? _buildEmptyState()
                  : _buildFilesList(),
        ),
      ],
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final feedback = _getFeedbackForFile(file['id']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getFileColor(file['category']).withOpacity(0.1),
              child: Icon(
                _getFileIcon(file['category']),
                color: _getFileColor(file['category']),
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
                if (feedback != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Has feedback',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'feedback',
                  child: Row(
                    children: [
                      Icon(feedback != null ? Icons.edit : Icons.comment),
                      const SizedBox(width: 8),
                      Text(feedback != null ? 'Edit Feedback' : 'Add Feedback'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View File'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'feedback':
                    if (feedback != null) {
                      _editFeedback(feedback);
                    } else {
                      _addFeedback(file);
                    }
                    break;
                  case 'view':
                    // TODO: Navigate to file previewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${file['file_name']}')),
                    );
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTab() {
    return _feedbackList.isEmpty
        ? _buildEmptyFeedbackState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = _feedbackList[index];
              final file = feedback['user_files'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File info
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(file['category']),
                            color: _getFileColor(file['category']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file['file_name'],
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _formatDate(DateTime.parse(feedback['created_at'])),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
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
                                case 'edit':
                                  _editFeedback(feedback);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(feedback);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Comment
                      Text(
                        feedback['comment'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      
                      // Tags
                      if (feedback['tags'] != null && (feedback['tags'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: (feedback['tags'] as List).map<Widget>((tag) {
                            return Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
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
            'Client hasn\'t uploaded any files yet',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedbackState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No feedback yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add feedback to client files to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFeedback(feedback['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  Color _getFileColor(String category) {
    switch (category) {
      case 'images':
        return Colors.green;
      case 'documents':
        return Colors.blue;
      case 'videos':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
