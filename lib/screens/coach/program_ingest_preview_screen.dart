import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/coach/program_ingest_service.dart';
import '../../services/coach/program_apply_service.dart';
import '../../models/program_ingest/program_ingest_job.dart';

class ProgramIngestPreviewScreen extends StatefulWidget {
  final String jobId;

  const ProgramIngestPreviewScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ProgramIngestPreviewScreen> createState() => _ProgramIngestPreviewScreenState();
}

class _ProgramIngestPreviewScreenState extends State<ProgramIngestPreviewScreen> {
  final ProgramIngestService _ingestService = ProgramIngestService();
  final ProgramApplyService _applyService = ProgramApplyService();
  
  ProgramIngestJob? _job;
  ProgramIngestResult? _result;
  bool _loading = true;
  bool _applying = false;
  StreamSubscription<ProgramIngestJob>? _jobSubscription;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _startJobSubscription();
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final job = await _ingestService.getJob(widget.jobId);
      setState(() {
        _job = job;
        _loading = false;
      });

      if (job.status == 'succeeded') {
        await _loadResult();
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadResult() async {
    try {
      final result = await _ingestService.getResult(widget.jobId);
      setState(() {
        _result = result;
      });
    } catch (e) {
      debugPrint('Error loading result: $e');
    }
  }

  void _startJobSubscription() {
    _jobSubscription = _ingestService.streamJob(widget.jobId).listen((job) {
      setState(() {
        _job = job;
      });

      if (job.status == 'succeeded' && _result == null) {
        _loadResult();
      }
    });
  }

  Future<void> _applyProgram() async {
    if (_result == null) return;

    setState(() {
      _applying = true;
    });

    try {
      final counts = await _applyService.apply(_result!, _job!.clientId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Program applied successfully!\n'
              'Notes: ${counts['notes']}, '
              'Supplements: ${counts['supplements']}, '
              'Nutrition Plans: ${counts['nutrition_plans']}, '
              'Workout Plans: ${counts['workout_plans']}',
            ),
            backgroundColor: DesignTokens.success,
            duration: const Duration(seconds: 4),
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _applying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying program: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text(
          'Program Preview',
          style: TextStyle(color: AppTheme.neutralWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            )
          : _job == null
              ? const Center(
                  child: Text(
                    'Job not found',
                    style: TextStyle(color: AppTheme.lightGrey),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_job!.hasError) {
      return _buildErrorState();
    }

    if (_job!.isProcessing || _job!.isQueued) {
      return _buildProcessingState();
    }

    if (_job!.status == 'succeeded' && _result != null) {
      return _buildPreviewContent();
    }

    return const Center(
      child: Text(
        'Unknown state',
        style: TextStyle(color: AppTheme.lightGrey),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: DesignTokens.danger,
              size: 64,
            ),
            const SizedBox(height: DesignTokens.space16),
            const Text(
              'Processing Failed',
              style: TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              _job?.error ?? 'Unknown error occurred',
              style: const TextStyle(color: AppTheme.lightGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(color: AppTheme.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              strokeWidth: 3,
            ),
            const SizedBox(height: DesignTokens.space24),
            const Text(
              'Processing Program',
              style: TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              _job!.status == 'queued' 
                  ? 'Your program is in the queue...'
                  : 'AI is analyzing your program...',
              style: const TextStyle(color: AppTheme.lightGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space16),
            const Text(
              'This may take a few moments',
              style: TextStyle(
                color: AppTheme.lightGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success Header
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  decoration: BoxDecoration(
                    color: DesignTokens.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    border: Border.all(
                      color: DesignTokens.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: DesignTokens.success,
                        size: 24,
                      ),
                      SizedBox(width: DesignTokens.space12),
                      Expanded(
                        child: Text(
                          'Program parsed successfully!',
                          style: TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: DesignTokens.space24),
                
                // Notes Section
                if (_result!.notes != null && _result!.notes!.isNotEmpty) ...[
                  _buildSection(
                    title: 'Notes',
                    icon: Icons.note,
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: Text(
                        _result!.notes!,
                        style: const TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
                
                // Supplements Section
                if (_result!.supplements.isNotEmpty) ...[
                  _buildSection(
                    title: 'Supplements (${_result!.supplements.length})',
                    icon: Icons.medication,
                    child: Column(
                      children: _result!.supplements.map((supp) => Container(
                        margin: const EdgeInsets.only(bottom: DesignTokens.space8),
                        padding: const EdgeInsets.all(DesignTokens.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supp['name'] ?? 'Unknown Supplement',
                              style: const TextStyle(
                                color: AppTheme.neutralWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (supp['dosage'] != null) ...[
                              const SizedBox(height: DesignTokens.space4),
                              Text(
                                'Dosage: ${supp['dosage']}',
                                style: const TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (supp['timing'] != null) ...[
                              const SizedBox(height: DesignTokens.space4),
                              Text(
                                'Timing: ${supp['timing']}',
                                style: const TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (supp['notes'] != null) ...[
                              const SizedBox(height: DesignTokens.space4),
                              Text(
                                'Notes: ${supp['notes']}',
                                style: const TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
                
                // Nutrition Plan Section
                if (_result!.nutritionPlan != null) ...[
                  _buildSection(
                    title: 'Nutrition Plan',
                    icon: Icons.restaurant,
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: const Text(
                        'Nutrition plan data detected and will be applied to the client.',
                        style: TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
                
                // Workout Plan Section
                if (_result!.workoutPlan != null) ...[
                  _buildSection(
                    title: 'Workout Plan',
                    icon: Icons.fitness_center,
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: const Text(
                        'Workout plan data detected and will be applied to the client.',
                        style: TextStyle(
                          color: AppTheme.neutralWhite,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
              ],
            ),
          ),
        ),
        
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: const BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border(
              top: BorderSide(color: AppTheme.mediumGrey),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.lightGrey),
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.lightGrey),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applying ? null : _applyProgram,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                  ),
                  child: _applying
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                        )
                      : const Text(
                          'Apply to Client',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.accentGreen,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.space8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.neutralWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space12),
        child,
      ],
    );
  }
}
