import 'package:flutter/material.dart';
import '../../models/knowledge/knowledge_models.dart';
import '../../services/ai/knowledge_action_service.dart';

class KnowledgeActionsPanel extends StatelessWidget {
  final String noteId;
  final List<KnowledgeAction> actions;

  const KnowledgeActionsPanel({
    super.key,
    required this.noteId,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text(
                  'Knowledge Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...actions.map((action) => _buildActionTile(context, action)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, KnowledgeAction action) {
    return ListTile(
      leading: Icon(
        _getActionIcon(action.actionType),
        color: _getActionColor(action.actionType),
      ),
      title: Text(action.actionType.label),
      subtitle: Text(
        action.actionData['extracted_text']?.toString() ?? 'No details',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: action.isCompleted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : action.isTriggered
              ? const Icon(Icons.schedule, color: Colors.orange)
              : IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () async {
                    await KnowledgeActionService.I.triggerAction(action.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action triggered')),
                      );
                    }
                  },
                ),
      onTap: action.isCompleted
          ? null
          : () async {
              await KnowledgeActionService.I.completeAction(action.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Action completed')),
                );
              }
            },
    );
  }

  IconData _getActionIcon(KnowledgeActionType type) {
    switch (type) {
      case KnowledgeActionType.reminder:
        return Icons.notifications;
      case KnowledgeActionType.task:
        return Icons.checklist;
      case KnowledgeActionType.followUp:
        return Icons.follow_the_signs;
      case KnowledgeActionType.alert:
        return Icons.warning;
    }
  }

  Color _getActionColor(KnowledgeActionType type) {
    switch (type) {
      case KnowledgeActionType.reminder:
        return Colors.blue;
      case KnowledgeActionType.task:
        return Colors.green;
      case KnowledgeActionType.followUp:
        return Colors.orange;
      case KnowledgeActionType.alert:
        return Colors.red;
    }
  }
}
