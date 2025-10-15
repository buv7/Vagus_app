import 'package:flutter/material.dart';
import '../../services/coach_marketplace_service.dart';
import '../../models/coach_profile.dart';
import '../../theme/design_tokens.dart';
import 'coach_profile_view_screen.dart';

class ClientCoachMarketplace extends StatefulWidget {
  const ClientCoachMarketplace({super.key});

  @override
  State<ClientCoachMarketplace> createState() => _ClientCoachMarketplaceState();
}

class _ClientCoachMarketplaceState extends State<ClientCoachMarketplace> {
  final _marketplaceService = CoachMarketplaceService();
  final _searchController = TextEditingController();

  List<CoachProfile> _coaches = [];
  List<CoachProfile> _filteredCoaches = [];
  bool _loading = true;
  String _selectedSpecialty = 'All';

  final List<String> _specialties = [
    'All',
    'Weight Loss',
    'Muscle Building',
    'Strength Training',
    'Cardio Fitness',
    'HIIT',
    'Yoga',
    'Pilates',
    'Nutrition Coaching',
    'Sports Performance',
    'Rehabilitation',
  ];

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() => _loading = true);

    try {
      final coaches = await _marketplaceService.getActiveCoaches();
      setState(() {
        _coaches = coaches;
        _filteredCoaches = coaches;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading coaches: $e')),
        );
      }
    }
  }

  void _filterCoaches(String query) {
    setState(() {
      _filteredCoaches = _coaches.where((coach) {
        final matchesSearch = query.isEmpty ||
            coach.displayName?.toLowerCase().contains(query.toLowerCase()) == true ||
            coach.username?.toLowerCase().contains(query.toLowerCase()) == true ||
            coach.bio?.toLowerCase().contains(query.toLowerCase()) == true;

        final matchesSpecialty = _selectedSpecialty == 'All' ||
            coach.specialties?.contains(_selectedSpecialty) == true;

        return matchesSearch && matchesSpecialty;
      }).toList();
    });
  }

  void _selectSpecialty(String specialty) {
    setState(() {
      _selectedSpecialty = specialty;
      _filterCoaches(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: DesignTokens.textPrimary,
        title: const Text('Find a Coach'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCoaches,
                  style: const TextStyle(color: DesignTokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search coaches...',
                    hintStyle: const TextStyle(color: DesignTokens.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: DesignTokens.accentGreen),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: DesignTokens.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _filterCoaches('');
                            },
                          )
                        : null,
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
                      borderSide: const BorderSide(
                        color: DesignTokens.accentGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Specialty Filter Chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _specialties.length,
                  itemBuilder: (context, index) {
                    final specialty = _specialties[index];
                    final isSelected = specialty == _selectedSpecialty;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: (_) => _selectSpecialty(specialty),
                        backgroundColor: DesignTokens.cardBackground,
                        selectedColor: DesignTokens.accentGreen,
                        side: BorderSide(
                          color: isSelected
                              ? DesignTokens.accentGreen
                              : DesignTokens.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? DesignTokens.primaryDark
                              : DesignTokens.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DesignTokens.accentGreen))
          : _filteredCoaches.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCoaches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCoaches.length,
                    itemBuilder: (context, index) {
                      return _buildCoachCard(_filteredCoaches[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: DesignTokens.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No coaches found',
            style: TextStyle(
              fontSize: 18,
              color: DesignTokens.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(CoachProfile coach) {
    return FutureBuilder<String?>(
      future: _marketplaceService.getConnectionStatus(coach.coachId),
      builder: (context, snapshot) {
        final connectionStatus = snapshot.data;
        final isActive = connectionStatus == 'active';
        final isPending = connectionStatus == 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: DesignTokens.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            side: const BorderSide(
              color: DesignTokens.glassBorder,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoachProfileViewScreen(coachId: coach.coachId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header with avatar and basic info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: coach.avatarUrl != null
                        ? NetworkImage(coach.avatarUrl!)
                        : null,
                    child: coach.avatarUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.displayName ?? 'Coach',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.textPrimary,
                          ),
                        ),
                        if (coach.username != null)
                          Text(
                            '@${coach.username}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        // Rating placeholder
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            const Text('0.0', style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
                            const Text(' • ', style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
                            const Text('0 clients', style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Headline
              if (coach.headline != null) ...[
                const SizedBox(height: 12),
                Text(
                  coach.headline!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: DesignTokens.accentGreen,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Bio
              if (coach.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  coach.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: DesignTokens.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Specialties
              if (coach.specialties != null && coach.specialties!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: coach.specialties!.take(3).map((specialty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.accentGreen.withValues(alpha: 0.3),
                            DesignTokens.accentBlue.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DesignTokens.accentGreen,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.accentGreen.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Action Buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DesignTokens.accentGreen, DesignTokens.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoachProfileViewScreen(coachId: coach.coachId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: DesignTokens.primaryDark,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isActive
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                            label: const Text('Connected', style: TextStyle(color: Colors.green)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.green, width: 2),
                            ),
                          )
                        : isPending
                            ? OutlinedButton.icon(
                                onPressed: () async {
                                  final shouldCancel = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Request?'),
                                      content: const Text('Do you want to cancel your connection request to this coach?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('No'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Cancel Request'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldCancel == true) {
                                    try {
                                      await _marketplaceService.cancelConnectionRequest(coach.coachId);
                                      if (!context.mounted) return;
                                      setState(() {}); // Refresh to show connect button
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Connection request cancelled'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: DesignTokens.danger,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.schedule, size: 18, color: Colors.orange),
                                label: const Text('Pending (tap to cancel)', style: TextStyle(color: Colors.orange)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.orange, width: 2),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _marketplaceService.connectWithCoach(coach.coachId);
                                    if (!context.mounted) return;
                                    setState(() {}); // Refresh to show pending status
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Connection request sent!'),
                                        backgroundColor: DesignTokens.accentGreen,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: DesignTokens.danger,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.person_add, size: 18, color: DesignTokens.accentGreen),
                                label: const Text('Connect', style: TextStyle(color: DesignTokens.accentGreen)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: DesignTokens.accentGreen, width: 2),
                                ),
                              ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}
