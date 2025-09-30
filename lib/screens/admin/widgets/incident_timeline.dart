import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_incident_service.dart';
import '../../../models/admin/incident_models.dart';

class IncidentTimeline extends StatefulWidget {
  final String ticketId;
  const IncidentTimeline({super.key, required this.ticketId});

  @override
  State<IncidentTimeline> createState() => _IncidentTimelineState();
}

class _IncidentTimelineState extends State<IncidentTimeline> {
  final _svc = AdminIncidentService.instance;
  StreamSubscription<List<IncidentEvent>>? _sub;
  List<IncidentEvent> _events = const [];
  bool _showSystem = true, _showNotes = true, _showNetwork = true;

  @override
  void initState() {
    super.initState();
    _sub = _svc.streamEvents(widget.ticketId).listen((ev) {
      setState(() => _events = ev);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _events.where((e) {
      if (e.kind == IncidentKind.system && !_showSystem) return false;
      if (e.kind == IncidentKind.note && !_showNotes) return false;
      if (e.kind == IncidentKind.network && !_showNetwork) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterChip(
              label: const Text('System'),
              selected: _showSystem,
              onSelected: (v) => setState(() => _showSystem = v),
            ),
            FilterChip(
              label: const Text('Notes'),
              selected: _showNotes,
              onSelected: (v) => setState(() => _showNotes = v),
            ),
            FilterChip(
              label: const Text('Network'),
              selected: _showNetwork,
              onSelected: (v) => setState(() => _showNetwork = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...filtered.map(_tile),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_comment),
            label: const Text('Add internal note'),
            onPressed: _onAddNote,
          ),
        ),
      ],
    );
  }

  Widget _tile(IncidentEvent e) {
    final icon = switch (e.kind) {
      IncidentKind.system => Icons.auto_awesome,
      IncidentKind.push => Icons.notifications_active,
      IncidentKind.deeplink => Icons.link,
      IncidentKind.banner => Icons.campaign,
      IncidentKind.auth => Icons.verified_user,
      IncidentKind.network => Icons.network_check,
      IncidentKind.note => Icons.note_alt,
    };
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${e.details}\n${e.at.toLocal()} • ${e.by}'),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _onAddNote() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add internal note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'What did you change or observe?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    await _svc.addEvent(IncidentEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      ticketId: widget.ticketId,
      kind: IncidentKind.note,
      title: 'Internal note',
      details: text,
      at: DateTime.now(),
      by: 'admin',
    ));
  }
}
