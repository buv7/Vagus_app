import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supplements/supplement_service.dart';
import '../../../models/supplements/supplement_models.dart';
import '../../../theme/design_tokens.dart';
import '../../supplements/supplement_editor_sheet.dart';
import '../../supplements/supplement_occurrence_preview.dart';

class CoachClientProfileScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CoachClientProfileScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CoachClientProfileScreen> createState() => _CoachClientProfileScreenState();
}

class _CoachClientProfileScreenState extends State<CoachClientProfileScreen> {
  final supabase = Supabase.instance.client;
  final SupplementService _supplementService = SupplementService.instance;
  
  Map<String, dynamic>? _clientProfile;
  List<Supplement> _supplements = [];
  bool _loading = true;
  String _error = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      // Load client profile
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.clientId)
          .single();

      // Load client supplements
      final supplements = await _supplementService.listSupplements(
        clientId: widget.clientId,
      );

      setState(() {
        _clientProfile = profile;
        _supplements = supplements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load client data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    await _loadClientData();
  }

  void _showAddSupplement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SupplementEditorSheet(
        clientId: widget.clientId,
        onSaved: (supplement) {
          _refreshData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditSupplement(Supplement supplement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SupplementEditorSheet(
        supplement: supplement,
        clientId: widget.clientId,
        onSaved: (updatedSupplement) {
          _refreshData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showOccurrencePreview(Supplement supplement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SupplementOccurrencePreview(
        supplement: supplement,
      ),
    );
  }

  Future<void> _toggleSupplementActive(Supplement supplement) async {
    try {
      final updatedSupplement = supplement.copyWith(
        isActive: !supplement.isActive,
      );
      await _supplementService.updateSupplement(updatedSupplement);
      unawaited(_refreshData());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update supplement: $e')),
        );
      }
    }
  }

  List<Supplement> get _filteredSupplements {
    if (_searchQuery.isEmpty) return _supplements;
    return _supplements.where((supplement) =>
      supplement.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      supplement.dosage.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Supplement> get _activeSupplements => 
    _filteredSupplements.where((s) => s.isActive).toList();

  List<Supplement> get _pausedSupplements => 
    _filteredSupplements.where((s) => !s.isActive).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.clientName}\'s Profile'),
          backgroundColor: DesignTokens.ink50,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.clientName}\'s Profile'),
          backgroundColor: DesignTokens.ink50,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error, style: const TextStyle(color: DesignTokens.danger)),
              const SizedBox(height: DesignTokens.space16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName}\'s Profile'),
        backgroundColor: DesignTokens.ink50,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Info Card
              _buildClientInfoCard(),
              const SizedBox(height: DesignTokens.space24),
              
              // Supplements Section
              _buildSupplementsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    final email = _clientProfile?['email'] ?? 'No email';
    final avatar = _clientProfile?['avatar_url'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: DesignTokens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientName,
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    email,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Supplements',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _supplements.length >= 2 ? null : _showAddSupplement,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.blue600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        
        if (_supplements.length >= 2)
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.space8),
            padding: const EdgeInsets.all(DesignTokens.space12),
            decoration: BoxDecoration(
              color: DesignTokens.warn.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(color: DesignTokens.warn.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: DesignTokens.warn, size: 20),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: Text(
                    'Client has reached the maximum number of supplements. Upgrade to Pro for unlimited supplements.',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.warn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Search Bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search supplements...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
            ),
            filled: true,
            fillColor: DesignTokens.ink50,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Active Supplements
        if (_activeSupplements.isNotEmpty) ...[
          _buildSupplementGroup('Active', _activeSupplements, true),
          const SizedBox(height: DesignTokens.space16),
        ],
        
        // Paused Supplements
        if (_pausedSupplements.isNotEmpty) ...[
          _buildSupplementGroup('Paused', _pausedSupplements, false),
        ],
        
        // Empty State
        if (_filteredSupplements.isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space32),
              child: Column(
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: DesignTokens.ink500,
                  ),
                  const SizedBox(height: DesignTokens.space16),
                                     Text(
                     _searchQuery.isEmpty 
                         ? 'No supplements yet'
                         : 'No supplements match your search',
                     style: DesignTokens.titleMedium.copyWith(
                       color: DesignTokens.ink500,
                     ),
                   ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: DesignTokens.space8),
                    Text(
                      'Add supplements to help your client stay on track',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: DesignTokens.ink500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSupplementGroup(String title, List<Supplement> supplements, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTokens.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? DesignTokens.success : DesignTokens.ink500,
          ),
        ),
        const SizedBox(height: DesignTokens.space12),
        ...supplements.map((supplement) => _buildSupplementCard(supplement)),
      ],
    );
  }

  Widget _buildSupplementCard(Supplement supplement) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplement.name,
                        style: DesignTokens.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      Text(
                        supplement.dosage,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: DesignTokens.ink500,
                        ),
                      ),
                                             if (supplement.instructions != null) ...[
                         const SizedBox(height: DesignTokens.space4),
                         Text(
                           supplement.instructions!,
                           style: DesignTokens.bodySmall.copyWith(
                             color: DesignTokens.ink500,
                           ),
                         ),
                       ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditSupplement(supplement);
                        break;
                      case 'preview':
                        _showOccurrencePreview(supplement);
                        break;
                      case 'toggle':
                        _toggleSupplementActive(supplement);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: DesignTokens.space8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20),
                          SizedBox(width: DesignTokens.space8),
                          Text('Preview Schedule'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            supplement.isActive ? Icons.pause : Icons.play_arrow,
                            size: 20,
                          ),
                          const SizedBox(width: DesignTokens.space8),
                          Text(supplement.isActive ? 'Pause' : 'Activate'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: DesignTokens.space12),
            
            // Schedule Info
            FutureBuilder<List<SupplementSchedule>>(
              future: _supplementService.getSchedulesForSupplement(supplement.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                
                final schedules = snapshot.data ?? [];
                if (schedules.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(DesignTokens.space8),
                    decoration: BoxDecoration(
                      color: DesignTokens.ink100,
                      borderRadius: BorderRadius.circular(DesignTokens.radius4),
                    ),
                    child: Text(
                      'No schedule configured',
                      style: DesignTokens.bodySmall.copyWith(
                        color: DesignTokens.ink500,
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: schedules.map((schedule) => _buildScheduleChip(schedule)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleChip(SupplementSchedule schedule) {
    final isProSchedule = schedule.intervalHours != null;
    
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space8,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: isProSchedule 
            ? DesignTokens.blue50 
            : DesignTokens.ink100,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
                 border: Border.all(
           color: isProSchedule 
               ? DesignTokens.blue50 
               : DesignTokens.ink100,
         ),
      ),
               child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(
               schedule.scheduleType == 'fixed_times' 
                   ? Icons.schedule 
                   : Icons.timer,
               size: 16,
               color: isProSchedule 
                   ? DesignTokens.blue600 
                   : DesignTokens.ink500,
             ),
          const SizedBox(width: DesignTokens.space4),
                       Text(
               _getScheduleDisplayText(schedule),
               style: DesignTokens.bodySmall.copyWith(
                 color: isProSchedule 
                     ? DesignTokens.blue600 
                     : DesignTokens.ink500,
               ),
             ),
          if (isProSchedule) ...[
            const SizedBox(width: DesignTokens.space4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.blue600,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Text(
                'PRO',
                style: DesignTokens.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getScheduleDisplayText(SupplementSchedule schedule) {
    switch (schedule.scheduleType) {
      case 'fixed_times':
        if (schedule.specificTimes != null && schedule.specificTimes!.isNotEmpty) {
          final timeStrings = schedule.specificTimes!.map((time) {
            return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          }).toList();
          return timeStrings.join(', ');
        }
        return 'Fixed times';
      case 'interval':
        if (schedule.intervalHours != null) {
          return 'Every ${schedule.intervalHours} hours';
        }
        return 'Interval schedule';
      default:
        return schedule.frequency;
    }
  }
}
