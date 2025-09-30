import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';
import '../../../theme/design_tokens.dart';

class DraftHandoffSheet extends StatefulWidget {
  final String ticketId;
  final String agentId;             // current agent
  final List<Map<String, String>> teammates; // [{id,name,avatar?}]
  final String? initialDraft;

  const DraftHandoffSheet({
    super.key,
    required this.ticketId,
    required this.agentId,
    required this.teammates,
    this.initialDraft,
  });

  @override
  State<DraftHandoffSheet> createState() => _DraftHandoffSheetState();
}

class _DraftHandoffSheetState extends State<DraftHandoffSheet> {
  final _svc = AdminSupportService.instance;
  final _draft = TextEditingController();
  String? _handoffTo;
  final _handoffNote = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft.text = widget.initialDraft ?? '';
  }

  @override
  void dispose() {
    _draft.dispose();
    _handoffNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0;
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(pad, pad, pad, pad + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha:.2), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            const Text('Draft & Handoff', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),

            // Draft editor
            Align(alignment: Alignment.centerLeft, child: Text('Draft reply', style: TextStyle(color: Colors.black.withValues(alpha:.7), fontWeight: FontWeight.w700))),
            const SizedBox(height: 6),
            TextField(
              controller: _draft,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write a draft reply for the user…',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _saveDraftDebounced(),
            ),
            const SizedBox(height: 12),

            // Handoff
            Align(alignment: Alignment.centerLeft, child: Text('Handoff (optional)', style: TextStyle(color: Colors.black.withValues(alpha:.7), fontWeight: FontWeight.w700))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _handoffTo,
              items: [
                const DropdownMenuItem(value: null, enabled: false, child: Text('Select teammate')),
                ...widget.teammates.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'] ?? 'Agent'))),
              ],
              onChanged: (v) => setState(() => _handoffTo = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _handoffNote,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Context for teammate (steps taken, logs, hypothesis)…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save draft'),
                    onPressed: _saving ? null : _saveDraftNow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.redo),
                    label: const Text('Handoff'),
                    onPressed: (_saving || _handoffTo == null) ? null : _handoffNow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
        ),
    );
  }

  Timer? _debounce;
  void _saveDraftDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _saveDraftSilently);
  }

  Future<void> _saveDraftSilently() async {
    final ok = await _svc.saveDraftReply(widget.ticketId, widget.agentId, _draft.text.trim());
    if (!ok || !mounted) return;
    // silent save; no snackbar to avoid noise while typing
  }

  Future<void> _saveDraftNow() async {
    setState(() => _saving = true);
    final ok = await _svc.saveDraftReply(widget.ticketId, widget.agentId, _draft.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Draft saved' : 'Save failed')));
  }

  Future<void> _handoffNow() async {
    setState(() => _saving = true);
    final ok = await _svc.handoffTicket(
      ticketId: widget.ticketId,
      fromAgentId: widget.agentId,
      toAgentId: _handoffTo!,
      note: _handoffNote.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Handed off' : 'Handoff failed')));
    if (ok) Navigator.of(context).pop(true);
  }
}
