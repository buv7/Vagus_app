import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../auth/modern_login_screen.dart';
import '../workout/workout_plan_viewer_screen.dart';
import '../workout/coach_plan_builder_screen.dart';
import '../nutrition/nutrition_plan_builder.dart';
import '../coach/coach_notes_screen.dart';
import '../calendar/event_editor.dart';
import '../calendar/availability_publisher.dart';
import '../messaging/coach_threads_screen.dart';
import '../messaging/coach_messenger_screen.dart';
import '../coach/intake/coach_forms_screen.dart';
import '../../services/coach/calendar_quick_book_service.dart';
import '../supplements/supplement_editor_sheet.dart';
import '../../widgets/supplements/supplement_templates.dart';
import 'edit_profile_screen.dart';
import '../coach/ClientWeeklyReviewScreen.dart';
import '../../components/rank/neon_rank_chip.dart';
import '../rank/rank_hub_screen.dart';
import '../../services/calendar/event_service.dart';
import '../../services/coach/coach_inbox_service.dart';
import '../../services/coach/coach_analytics_service.dart';
import '../../services/coach/coach_quick_actions_service.dart';
import '../../services/messaging/saved_replies_service.dart';
import '../../widgets/coach/CoachInboxCard.dart';
import '../../widgets/coach/CoachInboxActionsBar.dart';
import '../../widgets/coach/QuickBookSheet.dart';
import '../../widgets/coach/analytics/AnalyticsHeader.dart';
import '../../utils/natural_time_parser.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../widgets/navigation/vagus_side_menu.dart';

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
  final CoachInboxService _inboxService = CoachInboxService();
  final CoachAnalyticsService _analyticsService = CoachAnalyticsService();
  final CoachQuickActionsService _qa = CoachQuickActionsService();
  final SavedRepliesService _saved = SavedRepliesService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _recentCheckins = [];
  List<Event> _upcomingSessions = [];
  List<ClientFlag> _inboxFlags = [];
  CoachAnalyticsSummary? _analytics;
  int _analyticsDays = 7;
  bool _analyticsBusy = false;
  bool _inboxBulk = false;
  final Set<String> _selectedInboxClients = {};
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
          .select('client_id')
          .eq('coach_id', user.id);

      List<String> clientIds = [];
      if (links.isNotEmpty) {
        clientIds = links.map((row) => row['client_id'] as String).toList();
        
        final clients = await supabase
            .from('profiles')
            .select('id, name, email')
            .inFilter('id', clientIds);

        setState(() {
          _clients = List<Map<String, dynamic>>.from(clients);
        });
      } else {
        setState(() {
          _clients = [];
        });
      }

      // Load pending requests
      try {
        final requestLinks = await supabase
            .from('coach_requests')
            .select('id, client_id, status, created_at, message')
            .eq('coach_id', user.id)
            .eq('status', 'pending')
            .not('client_id', 'in', clientIds);

        List<Map<String, dynamic>> requests = [];
        if (requestLinks.isNotEmpty) {
          final requestClientIds = requestLinks.map((row) => row['client_id'] as String).toList();
          
          final requestClients = await supabase
              .from('profiles')
              .select('id, name, email')
              .inFilter('id', requestClientIds);

          // Combine request data with client data
          for (final request in requestLinks) {
            final clientId = request['client_id'] as String;
            final client = requestClients.firstWhere(
              (c) => c['id'] == clientId,
              orElse: () => {'id': clientId, 'name': 'Unknown', 'email': ''},
            );
            
            requests.add({
              ...request,
              'client': client,
            });
          }
        }

        setState(() {
          _requests = requests;
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

      // Load inbox flags
      await _loadInboxFlags(user.id);

      // Load analytics
      await _loadAnalytics(user.id);
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
    // Use the correct table name from migrations
    try {
      final checkinsLinks = await supabase
          .from('checkins')
          .select('id, client_id, created_at, notes, mood, energy_level')
          .inFilter('client_id', clientIds)
          .order('created_at', ascending: false)
          .limit(5);

      List<Map<String, dynamic>> checkinsData = [];
      if (checkinsLinks.isNotEmpty) {
        final checkinClientIds = checkinsLinks.map((row) => row['client_id'] as String).toList();
        
        final checkinClients = await supabase
            .from('profiles')
            .select('id, name')
            .inFilter('id', checkinClientIds);

        // Combine checkin data with client data
        for (final checkin in checkinsLinks) {
          final clientId = checkin['client_id'] as String;
          final client = checkinClients.firstWhere(
            (c) => c['id'] == clientId,
            orElse: () => {'id': clientId, 'name': 'Unknown'},
          );
          
          checkinsData.add({
            ...checkin,
            'profiles': client,
          });
        }
      }
      
      setState(() {
        _recentCheckins = List<Map<String, dynamic>>.from(checkinsData);
      });
      
      debugPrint('✅ Successfully loaded check-ins from checkins table');
    } catch (e) {
      debugPrint('❌ Failed to load check-ins: $e');
      setState(() {
        _recentCheckins = [];
      });
    }
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

  Future<void> _loadInboxFlags(String coachId) async {
    try {
      final flags = await _inboxService.getFlagsForCoach(coachId);
      setState(() {
        _inboxFlags = flags;
      });
    } catch (e) {
      debugPrint('❌ Failed to load inbox flags: $e');
      setState(() {
        _inboxFlags = [];
      });
    }
  }

  Future<void> _loadAnalytics(String coachId) async {
    setState(() => _analyticsBusy = true);
    try {
      final analytics = await _analyticsService.getSummary(
        coachId: coachId,
        days: _analyticsDays,
      );
      if (mounted) {
        setState(() {
          _analytics = analytics;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load analytics: $e');
      if (mounted) {
        setState(() {
          _analytics = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _analyticsBusy = false;
        });
      }
    }
  }


  // Quick Actions Methods
  void _toggleInboxBulk() {
    setState(() {
      _inboxBulk = !_inboxBulk;
      if (!_inboxBulk) _selectedInboxClients.clear();
    });
  }

  void _onInboxSelect(String clientId, bool selected) {
    setState(() {
      if (selected) {
        _selectedInboxClients.add(clientId);
      } else {
        _selectedInboxClients.remove(clientId);
      }
    });
  }

  Future<void> _actInboxNudge([String? reason]) async {
    final ids = _inboxBulk ? _selectedInboxClients.toList() : _inboxFlags.map((f) => f.clientId).toList();
    if (ids.isEmpty) return;
    
    try {
      if (_inboxBulk) {
        final results = await _qa.bulkSendNudge(
          clientIds: ids,
          reason: reason ?? 'missed_session',
        );
        
        final successCount = results.values.where((r) => r.ok).length;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nudge sent to $successCount/${ids.length} clients')),
          );
        }
      } else {
        final result = await _qa.sendNudgeMessage(
          clientId: ids.first,
          reason: reason ?? 'missed_session',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send nudge: $e')),
        );
      }
    }
  }

  Future<void> _actInboxQuickCall() async {
    final ids = _inboxBulk ? _selectedInboxClients.toList() : _inboxFlags.map((f) => f.clientId).toList();
    if (ids.isEmpty) return;
    
    if (_inboxBulk) {
      // For bulk mode, use the old method for now
      try {
        final results = await _qa.bulkProposeQuickCall(clientIds: ids);
        final successCount = results.values.where((r) => r.ok).length;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quick call proposed to $successCount/${ids.length} clients')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to propose call: $e')),
          );
        }
      }
    } else {
      // For single mode, open the QuickBookSheet
      _openQuickBookSheet(ids.first);
    }
  }

  void _actInboxReviewed() {
    final ids = _inboxBulk ? _selectedInboxClients.toList() : _inboxFlags.map((f) => f.clientId).toList();
    for (final id in ids) {
      _qa.markReviewed(id);
    }
    _selectedInboxClients.clear();
    setState(() {
      // Filter out reviewed clients from the inbox
      _inboxFlags = _inboxFlags.where((f) => !_qa.isReviewed(f.clientId)).toList();
    });
  }

  Future<void> _openSavedReplies() async {
    try {
      final replies = await _saved.list();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved Replies'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final reply = replies[index];
                return ListTile(
                  title: Text(reply.title),
                  subtitle: Text(
                    reply.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // For now, just show a message - in a real implementation,
                    // this would open the message compose with the reply content
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reply: ${reply.title}')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load saved replies: $e')),
        );
      }
    }
  }

  void _openQuickBookSheet(String clientId, {String? mode, QuickBookSlot? prefillSlot}) {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickBookSheet(
        coachId: user.id,
        clientId: clientId,
        conversationId: null, // No conversation context from inbox
        mode: mode,
        prefillSlot: prefillSlot,
        onProposed: (slot) {
          // Optional: analytics/log
          print('Quick book proposed: ${slot.start}');
        },
        onBooked: (slot) {
          // Optional: refresh calendar
          print('Quick book confirmed: ${slot.start}');
        },
      ),
    );
  }

  void _parseLastReply(String clientId) {
    // This is a simplified implementation - in a real app, you would
    // fetch the last message from the conversation with this client
    // For now, we'll show a dialog asking for the message text
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parse Last Reply'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the client\'s last message to parse for time:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g., "tmrw 6pm" or "الخميس 7"',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                Navigator.pop(context);
                _handleParseLastReply(clientId, text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // This would get the actual last message in a real implementation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature requires conversation access')),
              );
            },
            child: const Text('Parse'),
          ),
        ],
      ),
    );
  }

  void _handleParseLastReply(String clientId, String message) {
    final parsed = NaturalTimeParser.parse(message, anchor: DateTime.now());
    if (parsed != null) {
      final slot = QuickBookSlot(parsed.start, parsed.duration);
      _openQuickBookSheet(clientId, prefillSlot: slot);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No time found in message')),
      );
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
      MaterialPageRoute(builder: (_) => const ModernLoginScreen()),
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

  void _goToWeeklyReview(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientWeeklyReviewScreen(
          clientId: client['id'] ?? '',
          clientName: client['name'] ?? 'Client',
        ),
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

  Future<void> _openSupplementQuickAdd(BuildContext context) async {
    // 1) Resolve client
    final currentContext = context;
    final client = await _pickClientIfNeeded(currentContext);
    if (client == null) return;

    if (!currentContext.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: SupplementEditorSheet(
            clientId: client['id'],
            onSaved: (supplement) => Navigator.of(ctx).pop(true),
          ),
        );
      },
    );

    if (created == true && currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Supplement created')),
      );
      // If you maintain quick stats on dashboard, refresh them (fire-and-forget):
      unawaited(_refreshDashboardSummaries());
    }
  }

  Future<Map<String, dynamic>?> _pickClientIfNeeded(BuildContext context) async {
    // If you already have a selected client context on the dashboard, return it here.
    // For now, we'll always show the client picker since this is a general dashboard action.
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select client'),
        content: SizedBox(
          width: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.value(_clients), // Use existing loaded clients
            builder: (c, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No clients available'),
                  ),
                );
              }
              final clients = snap.data!;
              return ListView.separated(
                shrinkWrap: true,
                itemCount: clients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = clients[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _isValidHttpUrl(item['avatar_url'])
                          ? NetworkImage(item['avatar_url']!.trim())
                          : null,
                      child: !_isValidHttpUrl(item['avatar_url']) 
                          ? const Icon(Icons.person) 
                          : null,
                    ),
                    title: Text(item['name'] ?? 'No name'),
                    subtitle: Text(item['email'] ?? ''),
                    onTap: () => Navigator.of(ctx).pop(item),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), 
            child: const Text('Cancel')
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDashboardSummaries() async {
    // Refresh any dashboard counters or summaries that might be affected
    // This is a fire-and-forget operation to keep the UI responsive
    try {
      // Could refresh supplement counts, client stats, etc.
      // For now, just reload the main data
      unawaited(_loadData());
    } catch (e) {
      // Silently ignore errors in background refresh
      debugPrint('Background refresh failed: $e');
    }
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
              icon: const Icon(Icons.assessment_outlined),
              tooltip: 'Weekly Review',
              onPressed: () => _goToWeeklyReview(client),
            ),
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

  Widget _buildInboxSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actions Bar
            CoachInboxActionsBar(
              bulkMode: _inboxBulk,
              selectedCount: _selectedInboxClients.length,
              onToggleBulk: _toggleInboxBulk,
              onNudge: () => _actInboxNudge(),
              onQuickCall: _actInboxQuickCall,
              onMarkReviewed: _actInboxReviewed,
              onSavedReplies: _openSavedReplies,
            ),
            const SizedBox(height: 12),
            
            // Inbox Cards
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _inboxFlags.length,
                itemBuilder: (context, index) {
                  final flag = _inboxFlags[index];
                  return CoachInboxCard(
                    flag: flag,
                    onTap: () => _goToWeeklyReview({
                      'id': flag.clientId,
                      'name': flag.clientName,
                    }),
                    selectable: _inboxBulk,
                    selected: _selectedInboxClients.contains(flag.clientId),
                    onSelected: (selected) => _onInboxSelect(flag.clientId, selected),
                    onNudge: () => _actInboxNudge(),
                    onQuickCall: () => _openQuickBookSheet(flag.clientId),
                    onReschedule: () => _openQuickBookSheet(flag.clientId, mode: 'reschedule'),
                    onParseLastReply: () => _parseLastReply(flag.clientId),
                    onMarkReviewed: () => _actInboxReviewed(),
                    onSavedReplies: _openSavedReplies,
                  );
                },
              ),
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
                ActionChip(
                  avatar: const Icon(Icons.local_pharmacy, size: 18),
                  label: const Text('Add Supplement'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openSupplementQuickAdd(context);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Templates'),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final currentContext = context;
                    final client = await _pickClientIfNeeded(currentContext);
                    if (client == null) return;
                    if (!currentContext.mounted) return;

                    await showModalBottomSheet(
                      context: currentContext,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _TemplatesSheet(
                        onTemplateTap: (tpl) async {
                          if (!currentContext.mounted) return;
                          Navigator.of(currentContext).pop(); // close sheet before opening editor

                          if (!currentContext.mounted) return;
                          await showModalBottomSheet(
                            context: currentContext,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SupplementEditorSheet(
                              clientId: client['id'],
                              onSaved: (supplement) {
                                if (!currentContext.mounted) return;
                                ScaffoldMessenger.of(currentContext).showSnackBar(
                                  const SnackBar(content: Text('Supplement created')),
                                );
                                unawaited(_refreshDashboardSummaries());
                              },
                            ),
                          );
                        },
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
      drawerEdgeDragWidth: 24,
              drawer: VagusSideMenu(
          isClient: false, // hides "Apply to become a coach"
          onLogout: _logout,
        ),
      appBar: VagusAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Inbox notification badge
          if (_inboxFlags.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.inbox_outlined),
                  tooltip: 'Client Alerts',
                  onPressed: () {
                    // Scroll to inbox section or show full inbox
                    // For now, just scroll to the top
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_inboxFlags.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
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
              
              // 2. Analytics Header
              if (_analytics != null) ...[
                AnalyticsHeader(
                  data: _analytics!,
                  days: _analyticsDays,
                  onRangeChange: (int days) {
                    setState(() => _analyticsDays = days);
                    _loadAnalytics(supabase.auth.currentUser!.id);
                  },
                ),
                const SizedBox(height: 16),
              ] else if (_analyticsBusy) ...[
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 3. Coach Inbox (if any flags)
              if (_inboxFlags.isNotEmpty) ...[
                _buildInboxSection(),
                const SizedBox(height: 16),
              ],
              
              // 3. Clients Overview
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

class _TemplatesSheet extends StatelessWidget {
  final void Function(SupplementTemplate) onTemplateTap;
  const _TemplatesSheet({required this.onTemplateTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.radius12);
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.ink50.withValues(alpha: 230),
        borderRadius: radius,
      ),
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pick a template',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DesignTokens.space12),
            ...kSupplementTemplates.map((tpl) => Card(
              shape: RoundedRectangleBorder(borderRadius: radius),
              child: ListTile(
                leading: const Icon(Icons.local_pharmacy_outlined),
                title: Text(tpl.name),
                subtitle: Text(tpl.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => onTemplateTap(tpl),
              ),
            )),
            const SizedBox(height: DesignTokens.space8),
          ],
        ),
      ),
    );
  }
}
