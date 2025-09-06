import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_incident_service.dart';
import '../../models/admin/incident_models.dart';
import '../../models/admin/ticket_models.dart';

class AdminTicketBoardScreen extends StatefulWidget {
  const AdminTicketBoardScreen({super.key});
  @override State<AdminTicketBoardScreen> createState() => _AdminTicketBoardScreenState();
}

class _AdminTicketBoardScreenState extends State<AdminTicketBoardScreen> {
  final _svc = AdminIncidentService.instance;
  final Map<String, List<TicketSummary>> _columns = {
    'New': [], 'Investigating': [], 'Blocked': [], 'Resolved': [],
  };
  final Map<String, bool> _collapsed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=> _loading = true);
    // Use demo tickets from the incident service for now
    final all = _svc.tickets; // Access demo tickets
    // naive bucketing by status
    _columns.forEach((k,_)=> _columns[k]=[]);
    for (final t in all) {
      final key = t.status.name; // Use the actual status enum
      if (_columns.containsKey(key)) {
        _columns[key]!.add(t);
      } else {
        _columns['New']!.add(t); // Default to New column
      }
    }
    if (!mounted) return;
    setState(()=> _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminStats>(
      future: _svc.computeStats(),
      builder: (c,snap){
        final stat = snap.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Admin • Board')),
          body: Column(
            children: [
              if (stat != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(spacing: 8, children: [
                    _chip('Total', stat.total),
                    _chip('New', stat.newCnt),
                    _chip('Investigating', stat.investigatingCnt),
                    _chip('Blocked', stat.blockedCnt),
                    _chip('Resolved', stat.resolvedCnt),
                  ]),
                ),
              Expanded(child: _buildColumns()),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        );
      },
    );
  }

  Widget _buildColumns() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final keys = _columns.keys.toList();
    return Row(
      children: keys.map((k){
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$k (${_columns[k]!.length})', 
                        style: Theme.of(context).textTheme.titleMedium
                      )
                    ),
                    IconButton(
                      tooltip: 'Collapse/Expand',
                      icon: Icon(_collapsed[k]==true ? Icons.unfold_more : Icons.unfold_less),
                      onPressed: ()=> setState(()=> _collapsed[k] = !(_collapsed[k]??false)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_collapsed[k] != true)
                  Expanded(
                    child: DragTarget<TicketSummary>(
                    onWillAccept: (t) => true,
                    onAccept: (ticket) async {
                      // remove from old column
                      for (final e in _columns.entries) { 
                        e.value.removeWhere((x)=> x.id==ticket.id); 
                      }
                      // add to new column
                      _columns[k]!.add(ticket);
                      setState((){});
                      await _svc.setTicketStatus(ticket.id, k);
                      // tiny feedback
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ticket #${ticket.id} → $k'))
                      );
                    },
                    builder: (c,_,__){
                      final items = _columns[k]!;
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (c,i){
                          final t = items[i];
                          return LongPressDraggable<TicketSummary>(
                            data: t,
                            feedback: Material(
                              elevation: 6,
                              child: _TicketChipMini(title: t.subject),
                            ),
                            childWhenDragging: Opacity(opacity: .3, child: _TicketTile(t)),
                            child: _TicketTile(t),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, int n) => Chip(label: Text('$label: $n'));
}

class _TicketChipMini extends StatelessWidget {
  final String title;
  const _TicketChipMini({required this.title});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _TicketTile extends StatefulWidget {
  final TicketSummary t;
  const _TicketTile(this.t);
  @override State<_TicketTile> createState() => _TicketTileState();
}

class _TicketTileState extends State<_TicketTile> {
  final _svc = AdminIncidentService.instance;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final pinned = await _svc.getPinned(widget.t.id);
    if (mounted) {
      setState(() => _pinned = pinned);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(widget.t.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('#${widget.t.id} • ${widget.t.createdAt}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            _AgeChip(createdAt: widget.t.createdAt),
            IconButton(
              tooltip: _pinned ? 'Unpin' : 'Pin',
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () async {
                final newPinned = !_pinned;
                await _svc.setPinned(widget.t.id, newPinned);
                if (mounted) {
                  setState(() => _pinned = newPinned);
                }
              },
            ),
            const Icon(Icons.drag_indicator),
          ],
        ),
        onTap: ()=> Navigator.of(context).maybePop(widget.t),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  final DateTime createdAt;
  const _AgeChip({required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(createdAt);
    final days = age.inDays;
    final hours = age.inHours;
    
    String label;
    Color color;
    
    if (days > 0) {
      label = '+${days}d';
      color = days > 3 ? Colors.red : days > 1 ? Colors.orange : Colors.blue;
    } else if (hours > 0) {
      label = '+${hours}h';
      color = hours > 12 ? Colors.orange : Colors.blue;
    } else {
      label = '<1h';
      color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
