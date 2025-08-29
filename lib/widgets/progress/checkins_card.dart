import 'package:flutter/material.dart';
import '../../components/common/section_header_bar.dart';
import '../../services/progress/progress_service.dart';
import 'package:intl/intl.dart';

class CheckinsCard extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> checkins;
  final List<Map<String, dynamic>> coaches;
  final VoidCallback onRefresh;

  const CheckinsCard({
    super.key,
    required this.userId,
    required this.checkins,
    required this.coaches,
    required this.onRefresh,
  });

  @override
  State<CheckinsCard> createState() => _CheckinsCardState();
}

class _CheckinsCardState extends State<CheckinsCard> {
  final ProgressService _progressService = ProgressService();
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isCreatingCheckin = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showCreateCheckinDialog() {
    if (widget.coaches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No coach connected. Please connect with a coach first.'),
        ),
      );
      return;
    }

    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Weekly Check-in'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share your progress, challenges, and goals with your coach.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(),
                  hintText: 'How was your week? Any challenges or achievements?',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
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
            onPressed: _isCreatingCheckin ? null : _createCheckin,
            child: _isCreatingCheckin
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCheckin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreatingCheckin = true);

    try {
      // Use the first coach (assuming one coach per client for now)
      final coachId = widget.coaches.first['coach_id'] ?? widget.coaches.first['id'];
      
      await _progressService.createCheckin(
        clientId: widget.userId,
        coachId: coachId,
        checkinDate: DateTime.now(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Check-in sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to send check-in: $e')),
        );
      }
    } finally {
      setState(() => _isCreatingCheckin = false);
    }
  }

  Widget _buildCheckinsList() {
    if (widget.checkins.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No check-ins yet.\nTap "New Check-in" to start!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.checkins.length,
      itemBuilder: (context, index) {
        final checkin = widget.checkins[index];
        final date = DateTime.parse(checkin['checkin_date']);
        final status = checkin['status'] ?? 'open';
        final hasCoachReply = checkin['coach_reply'] != null && 
                             checkin['coach_reply'].toString().isNotEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            title: Row(
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasCoachReply) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.reply, size: 16, color: Colors.green),
                ],
              ],
            ),
            subtitle: Text(
              checkin['message'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Message:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(checkin['message'] ?? ''),
                    if (hasCoachReply) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Coach Reply:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(checkin['coach_reply'] ?? ''),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Waiting for coach reply...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'replied':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeaderBar(
              title: 'Weekly Check-ins',
              leadingIcon: const Icon(Icons.chat_bubble_outline, color: Colors.purple),
              actionLabel: 'New Check-in',
              onAction: _showCreateCheckinDialog,
              actionIcon: Icons.add,
            ),
            const SizedBox(height: 16),
            _buildCheckinsList(),
          ],
        ),
      ),
    );
  }
}
