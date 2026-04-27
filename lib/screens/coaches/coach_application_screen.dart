import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

class CoachApplicationScreen extends StatefulWidget {
  const CoachApplicationScreen({super.key});

  @override
  State<CoachApplicationScreen> createState() => _CoachApplicationScreenState();
}

class _CoachApplicationScreenState extends State<CoachApplicationScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _bioController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationsController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to apply.';
      });
      return;
    }

    try {
      final rows = await _supabase
          .from('coach_applications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      setState(() {
        _existing = rows.isNotEmpty
            ? Map<String, dynamic>.from(rows.first as Map)
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await _supabase.from('coach_applications').insert({
        'user_id': user.id,
        'bio': _bioController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'years_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'certifications': _certificationsController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted'),
          backgroundColor: DesignTokens.success,
        ),
      );
      await _loadExisting();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Apply to be a Coach'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _existing == null) {
      return _buildErrorState(_error!);
    }
    if (_existing != null) {
      return _buildStatusView(_existing!);
    }
    return _buildForm();
  }

  Widget _buildStatusView(Map<String, dynamic> app) {
    final status = (app['status'] ?? 'pending').toString();
    final theme = Theme.of(context);
    Color color;
    IconData icon;
    String message;
    switch (status) {
      case 'approved':
        color = DesignTokens.success;
        icon = Icons.check_circle;
        message = 'Your application has been approved!';
        break;
      case 'rejected':
        color = DesignTokens.danger;
        icon = Icons.cancel;
        message = 'Your application was not approved at this time.';
        break;
      default:
        color = AppTheme.accentOrange;
        icon = Icons.hourglass_top;
        message = 'Your application is under review.';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          _infoRow('Specialization', app['specialization']?.toString() ?? '—'),
          _infoRow('Years of experience', app['years_experience']?.toString() ?? '0'),
          _infoRow('Certifications', app['certifications']?.toString() ?? '—'),
          const SizedBox(height: 16),
          if (app['review_notes'] != null && app['review_notes'].toString().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reviewer notes', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(app['review_notes'].toString()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: DesignTokens.danger, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadExisting,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about yourself',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your application will be reviewed by our team. We usually respond within 3–5 business days.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Short bio',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Please write at least 20 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                hintText: 'e.g. Strength training, Nutrition, Mobility',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years of experience',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Enter a whole number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _certificationsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Certifications',
                hintText: 'List your relevant certifications',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}
