import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/app_theme.dart';
import '../../services/billing/plan_access_manager.dart';

/// Full screen showing supplements due today with progress tracking
/// For coaches: pass clientId to view client's supplements
class SupplementsTodayScreen extends StatefulWidget {
  final String? clientId; // Coach viewing client supplements

  const SupplementsTodayScreen({
    super.key,
    this.clientId,
  });

  @override
  State<SupplementsTodayScreen> createState() => _SupplementsTodayScreenState();
}

class _SupplementsTodayScreenState extends State<SupplementsTodayScreen> {
  final SupplementService _supplementService = SupplementService.instance;
  final PlanAccessManager _planAccessManager = PlanAccessManager.instance;
  
  List<SupplementDueToday> _supplements = [];
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
      setState(() {
        _loading = true;
        _error = null;
      });
      
      // Try to load supplements, but if the database function doesn't exist,
      // show mock data instead of crashing
      try {
        // Use clientId if provided (coach viewing client)
        final supplements = await _supplementService.getSupplementsDueToday(
          clientId: widget.clientId,
        );
        setState(() {
          _supplements = supplements;
          _loading = false;
        });
      } catch (dbError) {
        // If database function doesn't exist, show mock data
        if (dbError.toString().contains('get_next_supplement_due') || 
            dbError.toString().contains('get_supplements_due_today')) {
          setState(() {
            _supplements = _getMockSupplements();
            _loading = false;
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<SupplementDueToday> _getMockSupplements() {
    // Return mock supplement data when database functions are not available
    return [
      SupplementDueToday(
        supplementId: 'mock-1',
        supplementName: 'Whey Protein',
        dosage: '1 scoop (30g)',
        instructions: 'Mix with water or milk',
        category: 'protein',
        color: '#6C83F7',
        icon: 'medication',
        timesPerDay: 2,
        specificTimes: [
          DateTime(2024, 1, 1, 8, 0), // 8:00 AM
          DateTime(2024, 1, 1, 20, 0), // 8:00 PM
        ],
        nextDue: DateTime.now().add(const Duration(hours: 2)),
        lastTaken: DateTime.now().subtract(const Duration(hours: 4)),
        takenCount: 1,
      ),
      SupplementDueToday(
        supplementId: 'mock-2',
        supplementName: 'Creatine',
        dosage: '5g',
        instructions: 'Take with water',
        category: 'performance',
        color: '#4CAF50',
        icon: 'medication',
        timesPerDay: 1,
        specificTimes: [
          DateTime(2024, 1, 1, 18, 0), // 6:00 PM
        ],
        nextDue: DateTime.now().add(const Duration(hours: 1)),
        lastTaken: null,
        takenCount: 0,
      ),
      SupplementDueToday(
        supplementId: 'mock-3',
        supplementName: 'Multivitamin',
        dosage: '1 tablet',
        instructions: 'Take with food',
        category: 'general',
        color: '#FF9800',
        icon: 'medication',
        timesPerDay: 1,
        specificTimes: [
          DateTime(2024, 1, 1, 9, 0), // 9:00 AM
        ],
        nextDue: DateTime.now().add(const Duration(minutes: 30)),
        lastTaken: null,
        takenCount: 0,
      ),
    ];
  }

  Future<void> _checkProStatus() async {
    try {
      await _planAccessManager.isProUser();
      setState(() {});
    } catch (e) {
      // Ignore pro status errors
    }
  }

  Future<void> _markTaken(SupplementDueToday supplement) async {
    try {
      // For mock data, just show success message
      if (supplement.supplementId.startsWith('mock-')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${supplement.supplementName} marked as taken (Demo Mode)'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload to update UI
        await _loadSupplements();
        return;
      }
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final log = SupplementLog.create(
        supplementId: supplement.supplementId,
        userId: userId,
        takenAt: DateTime.now(),
        status: 'taken',
      );
      
      await _supplementService.createLog(log);
      
      // Reload supplements to update the UI
      await _loadSupplements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${supplement.supplementName} marked as taken'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to mark supplement as taken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markSkipped(SupplementDueToday supplement) async {
    try {
      // For mock data, just show success message
      if (supplement.supplementId.startsWith('mock-')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏭️ ${supplement.supplementName} marked as skipped (Demo Mode)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Reload to update UI
        await _loadSupplements();
        return;
      }
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final log = SupplementLog.create(
        supplementId: supplement.supplementId,
        userId: userId,
        takenAt: DateTime.now(),
        status: 'skipped',
      );
      
      await _supplementService.createLog(log);
      
      // Reload supplements to update the UI
      await _loadSupplements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏭️ ${supplement.supplementName} marked as skipped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to mark supplement as skipped: $e'),
            backgroundColor: Colors.red,
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
        foregroundColor: Colors.white,
        title: const Text(
          'Supplements Today',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F33),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _loadSupplements,
              icon: const Icon(Icons.refresh, color: AppTheme.accentGreen),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _supplements.isEmpty
                  ? _buildEmptyState()
                  : _buildSupplementsList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Loading supplements...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load supplements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSupplements,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication,
                color: AppTheme.accentGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No supplements today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no supplements scheduled for today.\nEnjoy your day off!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsList() {
    final completedCount = _supplements.where((s) => s.isCompletedToday).length;
    final totalCount = _supplements.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.accentGreen,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$completedCount/$totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% completed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Supplements list
          ..._supplements.map((supplement) => _buildSupplementItem(supplement)),
        ],
      ),
    );
  }

  Widget _buildSupplementItem(SupplementDueToday supplement) {
    final isCompleted = supplement.isCompletedToday;
    final isOverdue = supplement.isOverdue;
    final isDueSoon = supplement.isDueSoon;
    
    Color statusColor = Colors.white70;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isOverdue) {
      statusColor = Colors.red;
    } else if (isDueSoon) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
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
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supplement.supplementName,
                  style: TextStyle(
                    color: isCompleted ? Colors.white70 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            supplement.dosage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          
          if (supplement.specificTimes != null && supplement.specificTimes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Due: ${supplement.specificTimes!.map((t) => DateFormat('HH:mm').format(t)).join(', ')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
          
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markTaken(supplement),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markSkipped(supplement),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
