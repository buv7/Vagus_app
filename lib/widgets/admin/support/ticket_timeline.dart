import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';
import '../../../theme/design_tokens.dart';

class TicketTimeline extends StatefulWidget {
  final String ticketId;
  const TicketTimeline({super.key, required this.ticketId});

  @override
  State<TicketTimeline> createState() => _TicketTimelineState();
}

class _TicketTimelineState extends State<TicketTimeline> {
  final _svc = AdminSupportService.instance;
  List<Map<String, dynamic>> _events = const [];
  bool _loading = true;
  final _filters = <String>{'message','priority','claim','tag','system'}; // default all
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final r = await _svc.listTimelineEvents(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _events = r..sort((a,b)=> (a['ts']??'').toString().compareTo((b['ts']??'').toString()));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _events.where((e) => _filters.contains((e['kind'] ?? 'system').toString())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _tile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterBar() {
    Widget chip(String k, String label, IconData icon, Color c) {
      final on = _filters.contains(k);
      return FilterChip(
        avatar: Icon(icon, size: 18, color: on ? Colors.white : c),
        label: Text(label),
        selected: on,
        onSelected: (v) => setState(() { v ? _filters.add(k) : _filters.remove(k); }),
        selectedColor: c,
        showCheckmark: false,
        side: BorderSide(color: c.withValues(alpha: .6)),
        labelStyle: TextStyle(color: on ? Colors.white : Colors.black),
      );
    }

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        chip('message','Messages', Icons.chat_bubble_outline, Colors.blue),
        chip('priority','Priority', Icons.priority_high, Colors.orange),
        chip('claim','Claim', Icons.lock_outline, Colors.deepPurple),
        chip('tag','Tags', Icons.local_offer_outlined, Colors.teal),
        chip('system','System', Icons.settings, Colors.grey),
      ],
    );
  }

  Widget _tile(Map<String, dynamic> e) {
    final kind = (e['kind'] ?? 'system').toString();
    final ts = DateTime.tryParse((e['ts'] ?? '').toString());
    final when = ts == null ? '' : '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';
    late IconData icon;
    late Color tint;
    late String title;
    String? subtitle;

    switch (kind) {
      case 'message': icon = Icons.chat_bubble_outline; tint = Colors.blue; title = 'Message'; subtitle = (e['text'] ?? '').toString(); break;
      case 'priority': icon = Icons.priority_high; tint = Colors.orange; title = 'Priority set to ${(e['value'] ?? '').toString()}'; break;
      case 'claim': icon = Icons.lock_outline; tint = Colors.deepPurple; title = 'Claim ${(e['value'] ?? '').toString()}'; break;
      case 'tag': icon = Icons.local_offer_outlined; tint = Colors.teal; title = 'Tag: ${(e['value'] ?? '').toString()}'; break;
      default: icon = Icons.settings; tint = Colors.grey; title = (e['title'] ?? 'System event').toString(); subtitle = (e['details'] ?? '').toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: tint.withValues(alpha:.06),
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: tint.withValues(alpha:.2), child: Icon(icon, color: tint)),
              title: Text(title, style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
              trailing: Text(when, style: TextStyle(color: Colors.black.withValues(alpha:.6))),
            ),
          ),
        ),
      ),
    );
  }
}
