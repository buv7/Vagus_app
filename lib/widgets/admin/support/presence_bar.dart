import 'package:flutter/material.dart';

class SupportPresenceBar extends StatelessWidget {
  final List<Map<String, dynamic>> agents; // from AdminPresenceService.peers
  final String selfAgentId;
  final bool showCollisionBanner;

  const SupportPresenceBar({
    super.key,
    required this.agents,
    required this.selfAgentId,
    required this.showCollisionBanner,
  });

  @override
  Widget build(BuildContext context) {
    final others = agents.where((a) => a['agent_id'] != selfAgentId).toList();
    final typing = others.where((a) => (a['typing'] ?? false) == true).toList();
    final replying = others.where((a) => (a['replying'] ?? false) == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with avatars + live pill
        Row(
          children: [
            _livePill(),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: others.map((a) => _avatar(a)).toList(),
              ),
            ),
            if (typing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${typing.first['name']} is typing…',
                  style: TextStyle(color: Colors.black.withValues(alpha: .6)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (showCollisionBanner && replying.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${replying.first['name']} is actively replying. To avoid duplicate answers, coordinate before sending.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: .3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.green),
          SizedBox(width: 6),
          Text('Live'),
        ],
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> a) {
    final name = (a['name'] ?? '').toString();
    final avatar = (a['avatar'] ?? '').toString();

    return Tooltip(
      message: name.isEmpty ? 'Agent' : name,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.black.withValues(alpha: .1),
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty
            ? Text(
                _initials(name),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              )
            : null,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
