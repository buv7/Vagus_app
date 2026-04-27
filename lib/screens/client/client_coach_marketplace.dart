import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/coach_marketplace_service.dart';
import '../../models/coach_profile.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';
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
    final theme = Theme.of(context);
    final tc = context.tc;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: tc.textPrimary,
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
                  style: TextStyle(color: tc.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search coaches...',
                    hintStyle: TextStyle(color: tc.textSecondary),
                    prefixIcon: Icon(Icons.search, color: tc.accent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: tc.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _filterCoaches('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      borderSide: BorderSide(color: tc.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      borderSide: BorderSide(color: tc.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      borderSide: BorderSide(
                        color: tc.accent,
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
                        backgroundColor: tc.chipBg,
                        selectedColor: tc.chipSelectedBg,
                        side: BorderSide(
                          color: isSelected
                              ? tc.accent
                              : tc.border,
                          width: isSelected ? 2 : 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? tc.chipTextOnSelected
                              : tc.textPrimary,
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
          ? Center(child: CircularProgressIndicator(color: tc.accent))
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
    final tc = context.tc;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: tc.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No coaches found',
            style: TextStyle(
              fontSize: 18,
              color: tc.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: tc.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(CoachProfile coach) {
    final tc = context.tc;
    return FutureBuilder<String?>(
      future: _marketplaceService.getConnectionStatus(coach.coachId),
      builder: (context, snapshot) {
        final connectionStatus = snapshot.data;
        final isActive = connectionStatus == 'active';
        final isPending = connectionStatus == 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: tc.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            side: BorderSide(
              color: tc.border,
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
                    backgroundColor: tc.avatarBg,
                    backgroundImage: coach.avatarUrl != null
                        ? NetworkImage(coach.avatarUrl!)
                        : null,
                    child: coach.avatarUrl == null
                        ? Icon(Icons.person, size: 30, color: tc.avatarIcon)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.displayName ?? 'Coach',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tc.textPrimary,
                          ),
                        ),
                        if (coach.username != null)
                          Text(
                            '@${coach.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: tc.textSecondary,
                            ),
                          ),
                        // Rating placeholder
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text('0.0', style: TextStyle(fontSize: 14, color: tc.textSecondary)),
                            Text(' • ', style: TextStyle(fontSize: 14, color: tc.textSecondary)),
                            Text('0 clients', style: TextStyle(fontSize: 14, color: tc.textSecondary)),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: tc.accent,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: tc.textSecondary,
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
                            tc.accent.withValues(alpha: 0.3),
                            tc.accentSecondary.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tc.accent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tc.accent.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Action Buttons - Glassmorphic style matching FAB/nav
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 2.0,
                              colors: [
                                DesignTokens.accentBlue.withValues(alpha: 0.3),
                                DesignTokens.accentBlue.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            border: Border.all(
                              color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.accentBlue.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CoachProfileViewScreen(coachId: coach.coachId),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isActive
                        ? _buildGlassmorphicButton(
                            icon: Icons.check_circle,
                            label: 'Connected',
                            isSuccess: true,
                            onTap: null,
                          )
                        : isPending
                            ? _buildGlassmorphicButton(
                                icon: Icons.schedule,
                                label: 'Pending',
                                isWarning: true,
                                onTap: () => _showCancelDialog(coach, tc),
                              )
                            : _buildGlassmorphicButton(
                                icon: Icons.person_add,
                                label: 'Connect',
                                onTap: () => _connectWithCoach(coach, tc),
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

  Widget _buildGlassmorphicButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color baseColor;
    if (isSuccess) {
      baseColor = const Color(0xFF00D4AA); // Green
    } else if (isWarning) {
      baseColor = const Color(0xFFFFB800); // Amber
    } else {
      baseColor = DesignTokens.accentBlue;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                baseColor.withValues(alpha: 0.25),
                baseColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: baseColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(CoachProfile coach, ThemeColors tc) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tc.surface,
        title: Text('Cancel Request?', style: TextStyle(color: tc.textPrimary)),
        content: Text(
          'Do you want to cancel your connection request to this coach?',
          style: TextStyle(color: tc.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: tc.danger),
            child: Text('Cancel Request', style: TextStyle(color: tc.textOnDark)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        await _marketplaceService.cancelConnectionRequest(coach.coachId);
        if (!mounted) return;
        setState(() {}); // Refresh to show connect button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection request cancelled'),
            backgroundColor: tc.warning,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: tc.danger,
          ),
        );
      }
    }
  }

  Future<void> _connectWithCoach(CoachProfile coach, ThemeColors tc) async {
    try {
      await _marketplaceService.connectWithCoach(coach.coachId);
      if (!mounted) return;
      setState(() {}); // Refresh to show pending status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection request sent!'),
          backgroundColor: tc.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: tc.danger,
        ),
      );
    }
  }
}
