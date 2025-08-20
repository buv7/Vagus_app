import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = note['title']?.toString() ?? '';
    final body = note['body']?.toString() ?? note['note_text']?.toString() ?? '';
    final createdAt = note['created_at'] != null 
        ? DateTime.tryParse(note['created_at'].toString())
        : null;
    final tags = (note['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString())
        .toList();
    final attachments = (note['attachments'] as List<dynamic>? ?? []);
    final reminderAt = note['reminder_at'] != null 
        ? DateTime.tryParse(note['reminder_at'].toString())
        : null;
    final linkedPlans = note['linked_plan_ids'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (title.isNotEmpty)
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            // Version badge
                            if ((note['version'] ?? 1) > 1)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'v${note['version']}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (createdAt != null)
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete note',
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Body preview
              if (body.isNotEmpty)
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              
              const SizedBox(height: 8),
              
              // Tags
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.blue[50],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              
              const SizedBox(height: 8),
              
              // Footer with metadata
              Row(
                children: [
                  // Attachments count
                  if (attachments.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${attachments.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  
                  // Linked plans
                  if (linkedPlans.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (attachments.isNotEmpty) const SizedBox(width: 12),
                        Icon(Icons.link, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${linkedPlans.length} plans',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  
                  const Spacer(),
                  
                  // Reminder indicator
                  if (reminderAt != null && reminderAt.isAfter(DateTime.now()))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm, size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            '⏰ due in ${_formatTimeUntil(reminderAt)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeUntil(DateTime reminderAt) {
    final now = DateTime.now();
    final difference = reminderAt.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
