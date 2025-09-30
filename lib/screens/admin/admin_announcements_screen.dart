import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/announcements/announcement.dart';
import '../../services/announcements_service.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final AnnouncementsService _announcementsService = AnnouncementsService();
  
  List<Announcement> _announcements = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final announcements = await _announcementsService.fetchAllForAdmin();
      setState(() {
        _announcements = announcements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementEditorScreen(),
      ),
    );

    if (result == true) {
      unawaited(_loadAnnouncements());
    }
  }

  Future<void> _editAnnouncement(Announcement announcement) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementEditorScreen(announcement: announcement),
      ),
    );

    if (result == true) {
      unawaited(_loadAnnouncements());
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _announcementsService.deleteAnnouncement(announcement.id);
        unawaited(_loadAnnouncements());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete announcement: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewAnalytics(Announcement announcement) async {
    try {
      final analytics = await _announcementsService.fetchAnalytics(announcement.id);
      if (mounted) {
        unawaited(showDialog(
          context: context,
          builder: (context) => AnnouncementAnalyticsDialog(
            announcement: announcement,
            analytics: analytics,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VagusAppBar(title: Text('Announcements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnnouncements,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No announcements yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first announcement to engage users',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _createAnnouncement,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Announcement'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnnouncements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return _buildAnnouncementCard(announcement);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAnnouncement,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final isActive = announcement.isCurrentlyActive;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(announcement.createdAt)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            if (announcement.body != null && announcement.body!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                announcement.body!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (announcement.hasCta) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CTA: ${_getCtaDescription(announcement)}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewAnalytics(announcement),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analytics'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editAnnouncement(announcement),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _deleteAnnouncement(announcement),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getCtaDescription(Announcement announcement) {
    switch (announcement.ctaType) {
      case 'url':
        return 'External Link';
      case 'coach':
        return 'Coach Profile';
      default:
        return 'None';
    }
  }
}

// Placeholder for announcement editor screen
class AnnouncementEditorScreen extends StatefulWidget {
  final Announcement? announcement;

  const AnnouncementEditorScreen({super.key, this.announcement});

  @override
  State<AnnouncementEditorScreen> createState() => _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState extends State<AnnouncementEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ctaValueController = TextEditingController();
  
  String _ctaType = 'none';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _bodyController.text = widget.announcement!.body ?? '';
      _imageUrlController.text = widget.announcement!.imageUrl ?? '';
      _ctaType = widget.announcement!.ctaType;
      _ctaValueController.text = widget.announcement!.ctaValue ?? '';
      _startDate = widget.announcement!.startAt;
      _endDate = widget.announcement!.endAt;
      _isActive = widget.announcement!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _ctaValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.announcement == null ? 'Create Announcement' : 'Edit Announcement'),
        actions: [
          TextButton(
            onPressed: _saveAnnouncement,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                hintText: 'Optional description text',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                hintText: 'Optional image URL',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _ctaType,
              decoration: const InputDecoration(
                labelText: 'Call-to-Action Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'url', child: Text('External URL')),
                DropdownMenuItem(value: 'coach', child: Text('Coach Profile')),
              ],
              onChanged: (value) {
                setState(() {
                  _ctaType = value ?? 'none';
                });
              },
            ),
            if (_ctaType != 'none') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctaValueController,
                decoration: InputDecoration(
                  labelText: _ctaType == 'url' ? 'URL' : 'Coach ID',
                  border: const OutlineInputBorder(),
                  hintText: _ctaType == 'url' ? 'https://example.com' : 'coach-user-id',
                ),
                validator: (value) {
                  if (_ctaType != 'none' && (value == null || value.trim().isEmpty)) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show this announcement to users'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_startDate != null ? _formatDate(_startDate!) : 'No start date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectStartDate,
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'No end date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectEndDate,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final announcement = Announcement(
        id: widget.announcement?.id ?? '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        ctaType: _ctaType,
        ctaValue: _ctaValueController.text.trim().isEmpty ? null : _ctaValueController.text.trim(),
        startAt: _startDate,
        endAt: _endDate,
        isActive: _isActive,
        createdBy: widget.announcement?.createdBy,
        createdAt: widget.announcement?.createdAt ?? DateTime.now(),
      );

      final announcementsService = AnnouncementsService();
      
      if (widget.announcement == null) {
        await announcementsService.createOrUpdateAnnouncement(announcement);
      } else {
        await announcementsService.updateAnnouncement(announcement);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.announcement == null 
                ? 'Announcement created successfully' 
                : 'Announcement updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save announcement: $e')),
        );
      }
    }
  }
}

// Placeholder for analytics dialog
class AnnouncementAnalyticsDialog extends StatelessWidget {
  final Announcement announcement;
  final AnnouncementAnalytics analytics;

  const AnnouncementAnalyticsDialog({
    super.key,
    required this.announcement,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Analytics: ${announcement.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow('Impressions', analytics.impressions.toString()),
          _buildMetricRow('Unique Users', analytics.uniqueUsers.toString()),
          _buildMetricRow('Clicks', analytics.clicks.toString()),
          _buildMetricRow('CTR', '${analytics.ctr.toStringAsFixed(2)}%'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
