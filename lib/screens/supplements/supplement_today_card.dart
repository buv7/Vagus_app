import 'package:flutter/material.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';
import '../../services/billing/plan_access_manager.dart';

/// Card showing supplements due today with progress tracking
class SupplementTodayCard extends StatefulWidget {
  final String? userId;
  final VoidCallback? onViewAll;

  const SupplementTodayCard({
    super.key,
    this.userId,
    this.onViewAll,
  });

  @override
  State<SupplementTodayCard> createState() => _SupplementTodayCardState();
}

class _SupplementTodayCardState extends State<SupplementTodayCard> {
  final SupplementService _supplementService = SupplementService.instance;
  final PlanAccessManager _planAccessManager = PlanAccessManager.instance;
  
  List<SupplementDueToday> _supplements = [];
  bool _loading = true;
  String? _error;
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _loadSupplements();
    _checkProStatus();
  }

  Future<void> _loadSupplements() async {
    try {
      setState(() => _loading = true);
      
      final supplements = await _supplementService.getSupplementsDueToday(
        userId: widget.userId,
      );
      
      setState(() {
        _supplements = supplements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _checkProStatus() async {
    try {
      final isPro = await _planAccessManager.isProUser();
      setState(() => _isProUser = isPro);
    } catch (e) {
      // Ignore pro status errors
    }
  }

  Future<void> _markTaken(SupplementDueToday supplement) async {
    try {
      await _supplementService.createLog(
        SupplementLog.create(
          supplementId: supplement.supplementId,
          userId: widget.userId ?? '',
          status: 'taken',
        ),
      );
      
      // Reload supplements to update progress
      await _loadSupplements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${supplement.supplementName} marked as taken'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark taken: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _markSkipped(SupplementDueToday supplement) async {
    try {
      await _supplementService.createLog(
        SupplementLog.create(
          supplementId: supplement.supplementId,
          userId: widget.userId ?? '',
          status: 'skipped',
        ),
      );
      
      // Reload supplements to update progress
      await _loadSupplements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${supplement.supplementName} marked as skipped'),
            backgroundColor: DesignTokens.warn,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark skipped: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(DesignTokens.space16),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medication,
                  color: DesignTokens.blue600,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Text(
                    'Supplements Today',
                    style: DesignTokens.titleMedium.copyWith(
                      color: DesignTokens.ink900,
                    ),
                  ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text(
                      'View All',
                      style: TextStyle(color: DesignTokens.blue600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.space16),
            
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_supplements.isEmpty)
              _buildEmptyState()
            else
              _buildSupplementsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.danger,
            size: 48,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Failed to load supplements',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink700,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          TextButton(
            onPressed: _loadSupplements,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          const Icon(
            Icons.medication_outlined,
            color: DesignTokens.ink500,
            size: 48,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'No supplements scheduled for today',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Add supplements to your routine to see them here',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementsList() {
    return Column(
      children: [
        // Progress summary
        Container(
          padding: const EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: DesignTokens.blue50,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: DesignTokens.blue600,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  '${_supplements.where((s) => s.isCompletedToday).length} of ${_supplements.length} completed',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: DesignTokens.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space16),
        
        // Supplements list
        ..._supplements.map((supplement) => _buildSupplementItem(supplement)),
      ],
    );
  }

  Widget _buildSupplementItem(SupplementDueToday supplement) {
    final isCompleted = supplement.isCompletedToday;
    final isOverdue = supplement.isOverdue;
    final isDueSoon = supplement.isDueSoon;
    
    Color statusColor = DesignTokens.ink500;
    if (isCompleted) {
      statusColor = DesignTokens.success;
    } else if (isOverdue) {
      statusColor = DesignTokens.danger;
    } else if (isDueSoon) {
      statusColor = DesignTokens.warn;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        color: statusColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(int.parse(supplement.color.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplement.supplementName,
                      style: DesignTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: DesignTokens.ink900,
                      ),
                    ),
                    Text(
                      supplement.dosage,
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: DesignTokens.success,
                  size: 20,
                )
              else if (isOverdue)
                const Icon(
                  Icons.warning,
                  color: DesignTokens.danger,
                  size: 20,
                ),
            ],
          ),
          
          if (supplement.instructions != null) ...[
            const SizedBox(height: DesignTokens.space8),
            Text(
              supplement.instructions!,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space8),
          
          // Progress bar
          LinearProgressIndicator(
            value: supplement.progressPercentage,
            backgroundColor: DesignTokens.ink100,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
          
          const SizedBox(height: DesignTokens.space8),
          
          // Progress text
          Text(
            '${supplement.takenCount}/${supplement.timesPerDay} taken today',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
          
          if (!isCompleted) ...[
            const SizedBox(height: DesignTokens.space12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markTaken(supplement),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markSkipped(supplement),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.ink500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Pro feature indicator
          if (supplement.specificTimes != null && 
              supplement.specificTimes!.length > 2 && 
              !_isProUser) ...[
            const SizedBox(height: DesignTokens.space8),
            Container(
              padding: const EdgeInsets.all(DesignTokens.space8),
              decoration: BoxDecoration(
                color: DesignTokens.purple50,
                borderRadius: BorderRadius.circular(DesignTokens.radius4),
                border: Border.all(
                  color: DesignTokens.purple500.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: DesignTokens.purple500,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: Text(
                      'Upgrade to Pro for advanced scheduling',
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.purple500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
