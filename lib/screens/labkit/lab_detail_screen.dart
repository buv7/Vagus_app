import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/labkit/lab_work.dart';
import '../../models/labkit/biomarker_result.dart';
import '../../services/labkit/lab_work_service.dart';
import '../../theme/design_tokens.dart';
import 'lab_trend_screen.dart';

/// Lab detail screen.
///
/// Safety guards:
///   - Disclaimer banner on every view (spec requirement).
///   - No diagnosis language anywhere in this file.
///   - Coach consent toggle calls grant/revoke RPCs (server-side audit).
///   - get_lab_detail RPC inserts audit row — we never call raw select here.
class LabDetailScreen extends StatefulWidget {
  const LabDetailScreen({
    super.key,
    required this.labWorkId,
    this.isCoachView = false,
  });

  final String labWorkId;
  final bool isCoachView;

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  final _service = LabWorkService();

  LabWork? _lab;
  bool _loading = true;
  String? _error;

  // coach consent
  List<Map<String, dynamic>> _grants = [];
  bool _grantsLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lab = widget.isCoachView
          ? await _service.getLabForCoach(widget.labWorkId)
          : await _service.getLabDetail(widget.labWorkId);
      List<Map<String, dynamic>> grants = [];
      if (!widget.isCoachView) {
        grants = await _service.getConsentGrants(widget.labWorkId);
      }
      if (mounted) {
        setState(() {
          _lab = lab;
          _grants = grants;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load lab results. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        title: Text(
          _lab != null
              ? 'Lab – ${DateFormat('MMM d, yyyy').format(_lab!.labDate)}'
              : 'Lab Results',
          style: const TextStyle(color: DesignTokens.textPrimary),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
        actions: [
          if (_lab != null && !widget.isCoachView)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: DesignTokens.accentPink),
              tooltip: 'Delete lab (permanent)',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: DesignTokens.accentGreen));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: const TextStyle(color: DesignTokens.textSecondary)),
      );
    }
    final lab = _lab!;
    return RefreshIndicator(
      onRefresh: _load,
      color: DesignTokens.accentGreen,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DisclaimerBanner(),
          const SizedBox(height: 16),
          _buildMetaCard(lab),
          const SizedBox(height: 20),
          _buildBiomarkerSection(lab),
          if (!widget.isCoachView) ...[
            const SizedBox(height: 24),
            _buildConsentSection(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetaCard(LabWork lab) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Biomarkers',
            value: '${lab.biomarkers.length}',
            color: DesignTokens.accentGreen,
          ),
          const SizedBox(width: 12),
          if (lab.flaggedCount > 0)
            _StatChip(
              label: 'Out of range',
              value: '${lab.flaggedCount}',
              color: DesignTokens.accentOrange,
            ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DesignTokens.accentBlue.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lab.sourceLabel,
              style: const TextStyle(
                  color: DesignTokens.accentGreen, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerSection(LabWork lab) {
    final grouped = <String, List<BiomarkerResult>>{};
    for (final b in lab.biomarkers) {
      grouped.putIfAbsent(b.dictionaryId != null ? 'Matched' : 'Review needed', () => []).add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biomarkers',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...lab.biomarkers.map((b) => _BiomarkerTile(
              result: b,
              onTrendTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabTrendScreen(biomarkerName: b.name),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildConsentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coach Access',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose which coaches can view this specific lab result.',
          style: TextStyle(
              color: DesignTokens.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_grantsLoading)
          const Center(
              child: CircularProgressIndicator(
                  color: DesignTokens.accentGreen)),
        ..._grants.map((g) => _ConsentGrantTile(
              coachUserId: g['coach_user_id'] as String,
              grantedAt: DateTime.parse(g['granted_at'] as String),
              onRevoke: () => _revokeConsent(g['coach_user_id'] as String),
            )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showAddCoachDialog,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Share with a coach'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.accentGreen,
            side: const BorderSide(color: DesignTokens.accentGreen),
          ),
        ),
      ],
    );
  }

  Future<void> _revokeConsent(String coachUserId) async {
    setState(() => _grantsLoading = true);
    try {
      await _service.revokeCoachConsent(widget.labWorkId, coachUserId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not revoke access.')),
        );
      }
    } finally {
      if (mounted) setState(() => _grantsLoading = false);
    }
  }

  Future<void> _showAddCoachDialog() async {
    final coachId = await showDialog<String>(
      context: context,
      builder: (ctx) => _AddCoachDialog(),
    );
    if (coachId == null || coachId.isEmpty) return;
    setState(() => _grantsLoading = true);
    try {
      await _service.grantCoachConsent(widget.labWorkId, coachId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share lab.')),
        );
      }
    } finally {
      if (mounted) setState(() => _grantsLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.secondaryDark,
        title: const Text('Delete lab?',
            style: TextStyle(color: DesignTokens.textPrimary)),
        content: const Text(
          'This permanently deletes all biomarker data for this lab '
          'and revokes all coach access. This cannot be undone.',
          style: TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: DesignTokens.accentPink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteLab(widget.labWorkId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete lab.')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Disclaimer banner — shown on every lab view (spec requirement)
// ---------------------------------------------------------------------------

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.accentBlue.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: DesignTokens.accentBlue.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: DesignTokens.accentGreen, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'For personal tracking only — not a diagnosis. '
              'Discuss all results with your healthcare provider.',
              style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 12,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Biomarker tile with range bar
// ---------------------------------------------------------------------------

class _BiomarkerTile extends StatelessWidget {
  const _BiomarkerTile({
    required this.result,
    required this.onTrendTap,
  });

  final BiomarkerResult result;
  final VoidCallback onTrendTap;

  @override
  Widget build(BuildContext context) {
    final flagColor = _flagColor(result.flag);

    return GestureDetector(
      onTap: onTrendTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: flagColor.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (result.needsReview)
                  const Tooltip(
                    message: 'Not matched to reference dictionary',
                    child: Icon(Icons.help_outline,
                        color: DesignTokens.accentOrange, size: 16),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTrendTap,
                  child: const Icon(Icons.show_chart,
                      color: DesignTokens.accentGreen, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  result.rawValueStr,
                  style: TextStyle(
                    color: flagColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  result.unit,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _FlagChip(flag: result.flag),
              ],
            ),
            if (result.referenceRange != null) ...[
              const SizedBox(height: 8),
              _RangeBar(
                  value: result.value,
                  rangeText: result.referenceRange!,
                  flag: result.flag),
              const SizedBox(height: 4),
              Text(
                'Ref: ${result.referenceRange}',
                style: const TextStyle(
                    color: DesignTokens.textTertiary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _flagColor(BiomarkerFlag flag) => switch (flag) {
        BiomarkerFlag.low => DesignTokens.accentBlue,
        BiomarkerFlag.normal => DesignTokens.accentGreen,
        BiomarkerFlag.high => DesignTokens.accentOrange,
        BiomarkerFlag.unknown => DesignTokens.textSecondary,
      };
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.flag});
  final BiomarkerFlag flag;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (flag) {
      BiomarkerFlag.low => ('Below range', DesignTokens.accentBlue),
      BiomarkerFlag.normal => ('In range', DesignTokens.accentGreen),
      BiomarkerFlag.high => ('Above range', DesignTokens.accentOrange),
      BiomarkerFlag.unknown => ('Unknown', DesignTokens.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

/// Simple horizontal range bar — shows where the value sits relative to range.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.value,
    required this.rangeText,
    required this.flag,
  });

  final double? value;
  final String rangeText;
  final BiomarkerFlag flag;

  @override
  Widget build(BuildContext context) {
    final bounds = _parseBounds(rangeText);
    if (bounds == null || value == null) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: DesignTokens.textTertiary.withAlpha(60),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final (lo, hi) = bounds;
    final span = hi - lo;
    final margin = span * 0.25;
    final displayMin = lo - margin;
    final displayMax = hi + margin;
    final displaySpan = displayMax - displayMin;

    final clampedValue = value!.clamp(displayMin, displayMax);
    final frac = ((clampedValue - displayMin) / displaySpan).clamp(0.0, 1.0);
    final normalLo = ((lo - displayMin) / displaySpan).clamp(0.0, 1.0);
    final normalHi = ((hi - displayMin) / displaySpan).clamp(0.0, 1.0);

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final normalColor = DesignTokens.accentGreen.withAlpha(60);
      final markerColor = switch (flag) {
        BiomarkerFlag.low => DesignTokens.accentBlue,
        BiomarkerFlag.normal => DesignTokens.accentGreen,
        BiomarkerFlag.high => DesignTokens.accentOrange,
        BiomarkerFlag.unknown => DesignTokens.textSecondary,
      };

      return SizedBox(
        height: 18,
        child: Stack(
          children: [
            // Track
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: DesignTokens.textTertiary.withAlpha(50),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Normal zone highlight
            Positioned(
              top: 6,
              left: normalLo * w,
              width: (normalHi - normalLo) * w,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: normalColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Value marker
            Positioned(
              top: 3,
              left: (frac * w - 6).clamp(0, w - 12),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: markerColor.withAlpha(120), blurRadius: 4)
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Parse "3.5-5.0", "<100", ">40" style range strings.
  (double, double)? _parseBounds(String range) {
    final dashMatch = RegExp(r'^([\d.]+)\s*[-–]\s*([\d.]+)$').firstMatch(range.trim());
    if (dashMatch != null) {
      final lo = double.tryParse(dashMatch.group(1)!);
      final hi = double.tryParse(dashMatch.group(2)!);
      if (lo != null && hi != null && hi > lo) return (lo, hi);
    }
    final ltMatch = RegExp(r'^[<≤]\s*([\d.]+)$').firstMatch(range.trim());
    if (ltMatch != null) {
      final hi = double.tryParse(ltMatch.group(1)!);
      if (hi != null) return (0.0, hi);
    }
    final gtMatch = RegExp(r'^[>≥]\s*([\d.]+)$').firstMatch(range.trim());
    if (gtMatch != null) {
      final lo = double.tryParse(gtMatch.group(1)!);
      if (lo != null) return (lo, lo * 2);
    }
    return null;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: DesignTokens.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ConsentGrantTile extends StatelessWidget {
  const _ConsentGrantTile({
    required this.coachUserId,
    required this.grantedAt,
    required this.onRevoke,
  });
  final String coachUserId;
  final DateTime grantedAt;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline,
          color: DesignTokens.accentGreen),
      title: Text(
        coachUserId,
        style: const TextStyle(
            color: DesignTokens.textPrimary, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Shared ${DateFormat('MMM d, yyyy').format(grantedAt)}',
        style: const TextStyle(
            color: DesignTokens.textSecondary, fontSize: 11),
      ),
      trailing: TextButton(
        onPressed: onRevoke,
        child: const Text('Revoke',
            style: TextStyle(color: DesignTokens.accentPink)),
      ),
    );
  }
}

class _AddCoachDialog extends StatefulWidget {
  @override
  State<_AddCoachDialog> createState() => _AddCoachDialogState();
}

class _AddCoachDialogState extends State<_AddCoachDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.secondaryDark,
      title: const Text('Share with coach',
          style: TextStyle(color: DesignTokens.textPrimary)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: DesignTokens.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Coach user ID',
          hintStyle: TextStyle(color: DesignTokens.textTertiary),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, _controller.text.trim()),
          child: const Text('Share'),
        ),
      ],
    );
  }
}
