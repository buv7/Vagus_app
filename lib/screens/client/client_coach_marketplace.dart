import 'package:flutter/material.dart';
import '../../services/coach_marketplace_service.dart';
import '../../models/coach_profile.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
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
                  decoration: InputDecoration(
                    hintText: 'Search coaches...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterCoaches('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: isDarkMode
                          ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                          : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: isDarkMode
                          ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
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
                        backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.grey[200],
                        selectedColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : (isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.shade400),
                          width: isSelected ? 2 : 1,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white.withValues(alpha: 0.9) : null),
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
          ? const Center(child: CircularProgressIndicator())
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No coaches found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(CoachProfile coach) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
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
                          ),
                        ),
                        if (coach.username != null)
                          Text(
                            '@${coach.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        // Rating placeholder
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            const Text('0.0', style: TextStyle(fontSize: 14)),
                            const Text(' • ', style: TextStyle(fontSize: 14)),
                            const Text('0 clients', style: TextStyle(fontSize: 14)),
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
                  style: const TextStyle(fontSize: 14),
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
                          colors: isDarkMode
                              ? [
                                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                ]
                              : [
                                  Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 1.5,
                        ),
                        boxShadow: isDarkMode
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await _marketplaceService.connectWithCoach(coach.coachId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connection request sent!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Connect'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
  }
}
