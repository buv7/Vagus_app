import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/digestion_models.dart';
import '../../services/nutrition/digestion_tracking_service.dart';
import '../../widgets/common/save_icon.dart';

class DigestionTrackingScreen extends StatefulWidget {
  const DigestionTrackingScreen({super.key});

  @override
  State<DigestionTrackingScreen> createState() => _DigestionTrackingScreenState();
}

class _DigestionTrackingScreenState extends State<DigestionTrackingScreen> {
  int? _digestionQuality = 3;
  int _bloatLevel = 5;
  final Set<BloatFactor> _selectedFactors = {};
  int _complianceScore = 75;
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Digestion & Bloat Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDigestionQualitySelector(),
          const SizedBox(height: 16),
          _buildBloatSlider(),
          const SizedBox(height: 16),
          _buildBloatFactors(),
          const SizedBox(height: 16),
          _buildComplianceSlider(),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Any observations about your digestion...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loading ? null : () => _saveLog(user.id),
            icon: SaveIcon(),
            label: const Text('Save Log'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestionQualitySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digestion Quality (1-5)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final value = index + 1;
                return ChoiceChip(
                  label: Text('$value'),
                  selected: _digestionQuality == value,
                  onSelected: (selected) {
                    setState(() => _digestionQuality = selected ? value : null);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloatSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bloat Level: $_bloatLevel / 10',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: _bloatLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_bloatLevel',
              onChanged: (value) {
                setState(() => _bloatLevel = value.round());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloatFactors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bloating Factors (select all that apply)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BloatFactor.values.map((factor) {
                final isSelected = _selectedFactors.contains(factor);
                return FilterChip(
                  label: Text(factor.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFactors.add(factor);
                      } else {
                        _selectedFactors.remove(factor);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Score: $_complianceScore%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: _complianceScore.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_complianceScore%',
              onChanged: (value) {
                setState(() => _complianceScore = value.round());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLog(String userId) async {
    setState(() => _loading = true);
    try {
      final log = DigestionLog(
        id: 'temp',
        userId: userId,
        date: DateTime.now(),
        digestionQuality: _digestionQuality,
        bloatLevel: _bloatLevel,
        bloatingFactors: _selectedFactors.toList(),
        complianceScore: _complianceScore,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await DigestionTrackingService.I.logDigestion(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
