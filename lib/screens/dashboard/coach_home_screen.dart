import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../auth/login_screen.dart';
import '../workout/workout_plan_viewer_screen.dart';
import '../workout/coach_plan_builder_screen.dart';
import '../nutrition/nutrition_plan_builder.dart';
import '../coach/coach_notes_screen.dart';
import '../calendar/event_editor.dart';
import '../calendar/availability_publisher.dart';
import '../messaging/coach_threads_screen.dart';
import '../messaging/coach_messenger_screen.dart';
import '../coach/intake/coach_forms_screen.dart';
import 'edit_profile_screen.dart';
import '../../components/rank/neon_rank_chip.dart';
import '../rank/rank_hub_screen.dart';
import '../../services/calendar/event_service.dart';
import '../../theme/design_tokens.dart';

// Feature flags
const bool kCoachShowRecentCheckins = true;

// Safe image handling helpers
bool _isValidHttpUrl(String? url) {
  if (url == null) return false;
  final u = url.trim();
  return u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));
}

Widget _imagePlaceholder({double? w, double? h}) {
  return Container(
    width: w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: DesignTokens.ink100,
      borderRadius: BorderRadius.circular(DesignTokens.radius8),
    ),
    child: const Icon(
      Icons.image_not_supported,
      color: DesignTokens.ink500,
    ),
  );
}

Widget safeNetImage(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (_isValidHttpUrl(url)) {
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imagePlaceholder(w: width, h: height),
    );
  }
  return _imagePlaceholder(w: width, h: height);
}

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final supabase = Supabase.instance.client;
  final EventService _eventService = EventService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _recentCheckins = [];
  List<Event> _upcomingSessions = [];
  bool _loading = true;
  final String _error = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Load profile data
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _profile = profileData;
      });
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
      // Continue loading other data even if profile fails
    }

    try {
      // Load connected clients
      final links = await supabase
          .from('coach_clients')
          .select('client_id, profiles:client_id (id, name, email, avatar_url)')
          .eq('coach_id', user.id);

      final clientIds = links.map((row) => row['client_id'] as String).toList();

      setState(() {
        _clients = List<Map<String, dynamic>>.from(
            links.map((row) => row['profiles']));
      });

      // Load pending requests
      try {
        final requests = await supabase
            .from('coach_requests')
            .select('*, client:client_id (id, name, email, avatar_url)')
            .eq('coach_id', user.id)
            .eq('status', 'pending')
            .not('client_id', 'in', clientIds);

        setState(() {
          _requests = List<Map<String, dynamic>>.from(requests);
        });
      } catch (e) {
        debugPrint('❌ Failed to load pending requests: $e');
        setState(() {
          _requests = [];
        });
      }

      // Load recent client check-ins (with auto-detection)
      if (kCoachShowRecentCheckins && clientIds.isNotEmpty) {
        await _loadRecentCheckins(clientIds);
      }

      // Load upcoming sessions
      await _loadUpcomingSessions();
    } catch (e) {
      debugPrint('❌ Failed to load clients: $e');
      setState(() {
        _clients = [];
        _requests = [];
      });
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadRecentCheckins(List<String> clientIds) async {
    // Try different table names in order (first that works wins)
    final tableNames = ['progress_checkins', 'checkins', 'client_checkins'];
    
    for (final tableName in tableNames) {
      try {
        final checkinsData = await supabase
            .from(tableName)
            .select('*, profiles:user_id (id, name, avatar_url)')
            .inFilter('user_id', clientIds)
            .order('created_at', ascending: false)
            .limit(5);
        
        setState(() {
          _recentCheckins = List<Map<String, dynamic>>.from(checkinsData);
        });
        
        debugPrint('✅ Successfully loaded check-ins from $tableName');
        return; // Exit on success
      } catch (e) {
        debugPrint('❌ Failed to load from $tableName: $e');
        continue; // Try next table
      }
    }
    
    // If all tables fail, set empty state
    debugPrint('❌ All check-in tables failed, showing empty state');
    setState(() {
      _recentCheckins = [];
    });
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final sessions = await _eventService.listUpcomingForUser(
        userId: user.id,
        role: 'coach',
        limit: 3,
      );

      setState(() {
        _upcomingSessions = sessions
            .where((event) => event.isBookingSlot || event.tags.contains('session'))
            .take(3)
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Failed to load upcoming sessions: $e');
      setState(() {
        _upcomingSessions = [];
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    try {
      final existing = await supabase
          .from('coach_clients')
          .select()
          .eq('coach_id', request['coach_id'])
          .eq('client_id', request['client_id']);

      if (existing.isEmpty) {
        await supabase.from('coach_clients').insert({
          'coach_id': request['coach_id'],
          'client_id': request['client_id'],
        });
      }

      await supabase
          .from('coach_requests')
          .delete()
          .eq('id', request['id']);

      unawaited(_loadData());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await supabase
          .from('coach_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);

      unawaited(_loadData());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _goToWorkoutViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutPlanViewerScreen()),
    );
  }

  void _goToPlanBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoachPlanBuilderScreen()),
    );
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  void _goToNutritionBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NutritionPlanBuilder()),
    );
  }

  void _goToNotes(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachNotesScreen(client: client),
      ),
    );
  }

  void _goToMessaging(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachMessengerScreen(client: client),
      ),
    );
  }

  void _goToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CoachThreadsScreen(),
      ),
    );
  }



  Widget _buildClientCard(Map<String, dynamic> client) {
    final String? imgUrl = client['avatar_url'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(client['name'] ?? 'No name'),
        subtitle: Text(client['email'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Message Client',
              onPressed: () => _goToMessaging(client),
            ),
            IconButton(
              icon: const Icon(Icons.note),
              tooltip: 'View Notes',
              onPressed: () => _goToNotes(client),
            ),
          ],
        ),
        onTap: () => _goToWorkoutViewer(), // Open client overview
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final client = request['client'] ?? {};
    final String? imgUrl = client['avatar_url'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
              color: DesignTokens.warnBg,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _isValidHttpUrl(imgUrl)
              ? NetworkImage(imgUrl!.trim())
              : null,
          child: !_isValidHttpUrl(imgUrl) ? const Icon(Icons.person) : null,
        ),
        title: Text(client['name'] ?? 'No name'),
        subtitle: Text('${client['email'] ?? ''}\n${request['message'] ?? ''}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                              icon: const Icon(Icons.check, color: DesignTokens.success),
              tooltip: 'Approve',
              onPressed: () => _approveRequest(request),
            ),
            IconButton(
                              icon: const Icon(Icons.close, color: DesignTokens.danger),
              tooltip: 'Reject',
              onPressed: () => _rejectRequest(request['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Clients Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_clients.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_clients.isEmpty)
              const Text(
                'No clients connected yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: _clients.take(3).map(_buildClientCard).toList(),
              ),
            if (_clients.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'And ${_clients.length - 3} more...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsCard() {
    if (_requests.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Pending Requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_requests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._requests.map(_buildRequestCard),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCheckinsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Recent Check-ins',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentCheckins.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No check-ins yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect progress tracking to enable',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              ..._recentCheckins.map((checkin) {
                final client = checkin['profiles'] ?? {};
                final message = checkin['notes'] ?? checkin['message'] ?? '';
                final weight = checkin['weight'];
                final createdAt = checkin['created_at'] != null
                    ? DateTime.parse(checkin['created_at'])
                    : null;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _isValidHttpUrl(client['avatar_url'])
                        ? NetworkImage(client['avatar_url']!.trim())
                        : null,
                    child: !_isValidHttpUrl(client['avatar_url'])
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(client['name'] ?? 'Unknown Client'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isNotEmpty)
                        Text(
                          message.length > 50
                              ? '${message.substring(0, 50)}...'
                              : message,
                        ),
                      if (weight != null)
                        Text(
                          'Weight: ${weight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM d, y').format(createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      // TODO: Navigate to detailed check-in view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Check-in details coming soon!')),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_upcomingSessions.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_upcomingSessions.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No upcoming sessions',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create booking slots to get started',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              ..._upcomingSessions.map((session) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      session.isBookingSlot ? Icons.schedule : Icons.event,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(session.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, y • HH:mm').format(session.startAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (session.location != null)
                        Text(
                          '📍 ${session.location}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      if (session.isBookingSlot)
                        Text(
                          'Booking slot • ${session.capacity} spots',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventEditor(event: session),
                        ),
                      );
                    },
                  ),
                );
              }),
            if (_upcomingSessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/calendar');
                  },
                  child: const Text('View All Sessions'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.fitness_center, size: 18),
                  label: const Text('New Workout Plan'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _goToPlanBuilder();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('New Nutrition Plan'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _goToNutritionBuilder();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.note_add, size: 18),
                  label: const Text('Add Coach Note'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to general coach notes
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coach notes coming soon!')),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.assignment, size: 18),
                  label: const Text('Intake Forms'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoachFormsScreen(),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.chat, size: 18),
                  label: const Text('Open Messages'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _goToMessages();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.publish, size: 18),
                  label: const Text('Publish Availability'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AvailabilityPublisher(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsStrip() {
    // Simple notifications banner
    final hasNewActivity = _requests.isNotEmpty; // Only check requests for now
    
    if (!hasNewActivity) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have pending coach requests to review!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] ?? 'Unknown';
    final email = _profile?['email'] ?? '';
    final role = _profile?['role'] ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏋️ Coach Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Edit Profile',
            onPressed: _goToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header row
              Row(
                children: [
                  if (_isValidHttpUrl(avatarUrl))
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(avatarUrl!.trim()),
                    )
                  else
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(role.toUpperCase()),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                  ),
                  // Neon Rank Chip
                  NeonRankChip(
                    streak: 12, // TODO: Get from actual coach streak data
                    rank: 'Silver', // TODO: Get from actual coach rank
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RankHubScreen()),
                      );
                    },
                    isPro: true, // TODO: Get from actual Pro status
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 2. Clients Overview
              _buildClientsOverviewCard(),
              const SizedBox(height: 16),
              
              // 3. Pending Requests
              _buildPendingRequestsCard(),
              const SizedBox(height: 16),
              
              // 4. Recent Check-ins
              _buildRecentCheckinsCard(),
              const SizedBox(height: 16),
              
              // 5. Upcoming Sessions
              _buildUpcomingSessionsCard(),
              const SizedBox(height: 16),
              
              // 6. Quick Actions
              _buildQuickActionsCard(),
              const SizedBox(height: 16),
              
              // 7. Notifications Strip
              _buildNotificationsStrip(),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
