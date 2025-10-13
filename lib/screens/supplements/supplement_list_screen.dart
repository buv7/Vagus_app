import 'package:flutter/material.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';
import '../../services/billing/plan_access_manager.dart';
import 'supplement_history_screen.dart';

/// Screen showing all supplements with management options
/// For coaches: pass clientId to view client's supplements
class SupplementListScreen extends StatefulWidget {
  final String? userId;
  final String? clientId; // Coach viewing client supplements

  const SupplementListScreen({
    super.key,
    this.userId,
    this.clientId,
  });

  @override
  State<SupplementListScreen> createState() => _SupplementListScreenState();
}

class _SupplementListScreenState extends State<SupplementListScreen> {
  final SupplementService _supplementService = SupplementService.instance;
  final PlanAccessManager _planAccessManager = PlanAccessManager.instance;
  
  List<Supplement> _supplements = [];
  Map<String, List<SupplementSchedule>> _schedules = {};
  bool _loading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    _loadSupplements();
    _checkProStatus();
  }

  Future<void> _loadSupplements() async {
    try {
      setState(() => _loading = true);
      
      // Use clientId if provided (coach viewing client)
      final supplements = await _supplementService.listSupplements(
        userId: widget.userId,
        clientId: widget.clientId,
        isActive: true,
      );
      
      // Load schedules for each supplement
      final schedulesMap = <String, List<SupplementSchedule>>{};
      for (final supplement in supplements) {
        final schedules = await _supplementService.getSchedulesForSupplement(supplement.id);
        schedulesMap[supplement.id] = schedules;
      }
      
      setState(() {
        _supplements = supplements;
        _schedules = schedulesMap;
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
      await _planAccessManager.isProUser();
    } catch (e) {
      // Ignore pro status errors
    }
  }

  Future<void> _toggleSupplementActive(Supplement supplement) async {
    try {
      final updatedSupplement = supplement.copyWith(
        isActive: !supplement.isActive,
      );
      
      await _supplementService.updateSupplement(updatedSupplement);
      
      // Reload supplements
      await _loadSupplements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${supplement.name} ${updatedSupplement.isActive ? 'activated' : 'deactivated'}',
            ),
            backgroundColor: updatedSupplement.isActive 
                ? DesignTokens.success 
                : DesignTokens.warn,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update supplement: $e'),
            backgroundColor: DesignTokens.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteSupplement(Supplement supplement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplement'),
        content: Text(
          'Are you sure you want to delete "${supplement.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supplementService.deleteSupplement(supplement.id);
        
        // Reload supplements
        await _loadSupplements();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${supplement.name} deleted'),
              backgroundColor: DesignTokens.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete supplement: $e'),
              backgroundColor: DesignTokens.danger,
            ),
          );
        }
      }
    }
  }

  void _showSupplementDetails(Supplement supplement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSupplementDetailsSheet(supplement),
    );
  }

  Widget _buildSupplementDetailsSheet(Supplement supplement) {
    final schedules = _schedules[supplement.id] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(int.parse(supplement.color.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: Text(
                  supplement.name,
                  style: DesignTokens.titleLarge.copyWith(
                    color: DesignTokens.ink900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Supplement details
          _buildDetailRow('Dosage', supplement.dosage),
          if (supplement.instructions != null)
            _buildDetailRow('Instructions', supplement.instructions!),
          _buildDetailRow('Category', supplement.categoryDisplayName),
          _buildDetailRow('Status', supplement.isActive ? 'Active' : 'Inactive'),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Schedules section
          Text(
            'Schedules',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          
          if (schedules.isEmpty)
            Text(
              'No schedules configured',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...schedules.map((schedule) => _buildScheduleItem(schedule)),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to edit supplement
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: DesignTokens.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplementHistoryScreen(
                          supplementId: supplement.id,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(SupplementSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.ink50,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(
          color: DesignTokens.ink100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: DesignTokens.blue600,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                schedule.frequency,
                style: DesignTokens.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.ink900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: schedule.isActive 
                      ? DesignTokens.successBg 
                      : DesignTokens.ink100,
                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                ),
                child: Text(
                  schedule.isActive ? 'Active' : 'Inactive',
                  style: DesignTokens.bodySmall.copyWith(
                    color: schedule.isActive 
                        ? DesignTokens.success 
                        : DesignTokens.ink500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (schedule.specificTimes != null) ...[
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Times: ${schedule.specificTimes!.map((time) => 
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
              ).join(', ')}',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
          ],
          
          if (schedule.intervalHours != null) ...[
            const SizedBox(height: DesignTokens.space8),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: DesignTokens.purple500,
                  size: 16,
                ),
                const SizedBox(width: DesignTokens.space4),
                Text(
                  'Every ${schedule.intervalHours} hours (Pro feature)',
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.purple500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Supplements'),
        backgroundColor: DesignTokens.blue600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _supplements.isEmpty
                  ? _buildEmptyState()
                  : _buildSupplementsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add supplement screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add supplement functionality coming soon'),
            ),
          );
        },
        backgroundColor: DesignTokens.blue600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.danger,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'Failed to load supplements',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            _error!,
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space16),
          ElevatedButton(
            onPressed: _loadSupplements,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            color: DesignTokens.ink500,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.space16),
          Text(
            'No supplements yet',
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.ink900,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Add your first supplement to start tracking your routine',
            style: DesignTokens.bodyMedium.copyWith(
              color: DesignTokens.ink500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add supplement screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add supplement functionality coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Supplement'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space16),
      itemCount: _supplements.length,
      itemBuilder: (context, index) {
        final supplement = _supplements[index];
        final schedules = _schedules[supplement.id] ?? [];
        final activeSchedules = schedules.where((s) => s.isActive).length;
        
        return Card(
          margin: const EdgeInsets.only(bottom: DesignTokens.space12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(int.parse(supplement.color.replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: const Icon(
                Icons.medication,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              supplement.name,
              style: DesignTokens.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: DesignTokens.ink900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplement.dosage,
                  style: DesignTokens.bodySmall.copyWith(
                    color: DesignTokens.ink500,
                  ),
                ),
                if (schedules.isNotEmpty)
                  Text(
                    '$activeSchedules active schedule${activeSchedules != 1 ? 's' : ''}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: supplement.isActive 
                        ? DesignTokens.success 
                        : DesignTokens.ink500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                // More options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        _showSupplementDetails(supplement);
                        break;
                      case 'toggle':
                        _toggleSupplementActive(supplement);
                        break;
                      case 'delete':
                        _deleteSupplement(supplement);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            supplement.isActive 
                                ? Icons.pause 
                                : Icons.play_arrow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            supplement.isActive ? 'Pause' : 'Activate',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            onTap: () => _showSupplementDetails(supplement),
          ),
        );
      },
    );
  }
}
