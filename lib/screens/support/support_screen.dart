import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _priority = 'normal';

  bool _submitting = false;
  bool _loadingHistory = true;
  String? _error;
  List<Map<String, dynamic>> _tickets = [];

  static const List<String> _priorities = ['low', 'normal', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loadingHistory = false;
        _error = 'Please sign in to view your support requests.';
      });
      return;
    }

    try {
      final rows = await _supabase
          .from('support_requests')
          .select('id, title, status, priority, created_at')
          .eq('requester_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;
      setState(() {
        _tickets = List<Map<String, dynamic>>.from(
          (rows as List).map((r) => Map<String, dynamic>.from(r as Map)),
        );
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingHistory = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      final inserted = await _supabase
          .from('support_requests')
          .insert({
            'requester_id': user.id,
            'requester_email': user.email ?? '',
            'title': _titleController.text.trim(),
            'body': _bodyController.text.trim(),
            'priority': _priority,
            'status': 'open',
          })
          .select('id, title')
          .single();

      // Best-effort notify via existing edge function; don't fail on error.
      try {
        await _supabase.functions.invoke('send-support-email', body: {
          'type': 'new_request',
          'to': user.email ?? '',
          'ticketId': inserted['id'],
          'subject': inserted['title'] ?? '',
          'body': _bodyController.text.trim(),
        });
      } catch (_) {
        // Edge function is optional per docs; silently skip on failure.
      }

      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      setState(() => _priority = 'normal');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support request sent'),
          backgroundColor: DesignTokens.success,
        ),
      );
      await _loadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'closed':
        return DesignTokens.mediumGrey;
      case 'assigned':
      case 'waiting':
        return DesignTokens.accentBlue;
      case 'open':
      default:
        return DesignTokens.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Contact support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingHistory ? null : _loadTickets,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildForm(),
              const SizedBox(height: 24),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How can we help?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe your issue and our team will get back to you.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Please add at least 10 characters'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: _priorities
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p[0].toUpperCase() + p.substring(1)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_submitting ? 'Sending…' : 'Send request'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'My requests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (_loadingHistory)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!,
                style: const TextStyle(color: DesignTokens.danger)),
          )
        else if (_tickets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: DesignTokens.mediumGrey),
                  SizedBox(height: 8),
                  Text(
                    'No support requests yet',
                    style: TextStyle(color: DesignTokens.mediumGrey),
                  ),
                ],
              ),
            ),
          )
        else
          ..._tickets.map((t) {
            final status = (t['status'] ?? 'open').toString();
            final priority = (t['priority'] ?? 'normal').toString();
            return Card(
              child: ListTile(
                leading: Icon(Icons.circle,
                    size: 12, color: _statusColor(status)),
                title: Text(
                  (t['title'] ?? 'Untitled').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('$status • $priority'),
                trailing: Text(
                  _formatDate(t['created_at']?.toString() ?? ''),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
