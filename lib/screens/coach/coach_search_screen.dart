import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';

class CoachSearchScreen extends StatefulWidget {
  const CoachSearchScreen({super.key});

  @override
  State<CoachSearchScreen> createState() => _CoachSearchScreenState();
}

class _CoachSearchScreenState extends State<CoachSearchScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSuggestedCoaches(); // show default coaches
  }

  Future<void> _loadSuggestedCoaches() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('role', 'coach');

      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      unawaited(_loadSuggestedCoaches());
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _results = [];
    });

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('role', 'coach')
          .or('name.ilike.%$query%,email.ilike.%$query%');

      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _sendRequest(String coachId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('coach_requests').insert({
        'coach_id': coachId,
        'client_id': user.id,
        'status': 'pending',
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Request sent!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to send: $e')),
        );
      }
    }
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: DesignTokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        side: const BorderSide(color: DesignTokens.glassBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: coach['avatar_url'] != null
              ? NetworkImage(coach['avatar_url'])
              : null,
          child: coach['avatar_url'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(coach['name'] ?? 'No name'),
        subtitle: Text(
          coach['email'] ?? '',
          style: const TextStyle(color: DesignTokens.textSecondary),
        ),
        trailing: ElevatedButton(
          onPressed: () => _sendRequest(coach['id']),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.accentGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        title: const Text('Find a Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: QR code scanner navigation
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                filled: true,
                fillColor: DesignTokens.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: const BorderSide(color: DesignTokens.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: const BorderSide(color: DesignTokens.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: const BorderSide(color: DesignTokens.accentGreen),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: DesignTokens.accentGreen),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: DesignTokens.accentGreen))
          else if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error, style: const TextStyle(color: DesignTokens.accentGreen)),
            )
          else if (_results.isEmpty)
              const Expanded(
                child: Center(child: Text('No coaches found.', style: TextStyle(color: DesignTokens.textSecondary))),
              )
            else
              Expanded(
                child: ListView(
                  children: _results.map(_buildCoachCard).toList(),
                ),
              ),
        ],
      ),
    );
  }
}
