import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/branding/vagus_appbar.dart';

class ModernLiveCallsScreen extends StatefulWidget {
  const ModernLiveCallsScreen({super.key});

  @override
  State<ModernLiveCallsScreen> createState() => _ModernLiveCallsScreenState();
}

class _ModernLiveCallsScreenState extends State<ModernLiveCallsScreen> {
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isSpeakerOn = false;

  // Real data from Supabase
  List<Map<String, dynamic>> _upcomingCalls = [];
  List<Map<String, dynamic>> _callHistory = [];
  bool _isLoading = true;
  String? _error;

  // Mock data as fallback
  final List<Map<String, dynamic>> _mockUpcomingCalls = [
    {
      'id': '1',
      'title': 'Weekly Check-in',
      'description': 'Progress review and plan adjustment',
      'time': DateTime.now().add(const Duration(hours: 2)),
      'duration': '30 min',
      'type': 'video',
      'coach': 'Coach Sarah',
    },
    {
      'id': '2',
      'title': 'Form Check Session',
      'description': 'Review squat and deadlift form',
      'time': DateTime.now().add(const Duration(days: 1, hours: 10)),
      'duration': '45 min',
      'type': 'video',
      'coach': 'Coach Sarah',
    },
    {
      'id': '3',
      'title': 'Nutrition Consultation',
      'description': 'Meal plan review and adjustments',
      'time': DateTime.now().add(const Duration(days: 3, hours: 14)),
      'duration': '20 min',
      'type': 'audio',
      'coach': 'Coach Sarah',
    },
  ];

  final List<Map<String, dynamic>> _mockCallHistory = [
    {
      'id': '1',
      'title': 'Training Session',
      'description': 'Strength training guidance',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'duration': '45 min',
      'type': 'video',
      'coach': 'Coach Sarah',
      'status': 'completed',
    },
    {
      'id': '2',
      'title': 'Quick Check-in',
      'description': 'Daily motivation and tips',
      'time': DateTime.now().subtract(const Duration(days: 3)),
      'duration': '15 min',
      'type': 'audio',
      'coach': 'Coach Sarah',
      'status': 'completed',
    },
    {
      'id': '3',
      'title': 'Emergency Call',
      'description': 'Injury consultation',
      'time': DateTime.now().subtract(const Duration(days: 7)),
      'duration': '25 min',
      'type': 'video',
      'coach': 'Coach Sarah',
      'status': 'completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCallsData();
  }

  Future<void> _loadCallsData() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;



      // Load upcoming calls from calls table
      final upcomingResponse = await Supabase.instance.client
          .from('calls')
          .select()
          .or('client_id.eq.${user.id},coach_id.eq.${user.id}')
          .gte('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time', ascending: true);

      // Load call history
      final historyResponse = await Supabase.instance.client
          .from('calls')
          .select()
          .or('client_id.eq.${user.id},coach_id.eq.${user.id}')
          .lt('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _upcomingCalls = List<Map<String, dynamic>>.from(upcomingResponse);
          _callHistory = List<Map<String, dynamic>>.from(historyResponse);
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Use mock data as fallback
          _upcomingCalls = _mockUpcomingCalls;
          _callHistory = _mockCallHistory;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: VagusAppBar(
        title: const Text('Calls'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showScheduleCallDialog();
            },
            icon: const Icon(Icons.add_call),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentGreen,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: DesignTokens.space16),
                      Text(
                        'Error loading calls data',
                        style: DesignTokens.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      Text(
                        _error!,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.space16),
                      ElevatedButton(
                        onPressed: _loadCallsData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: AppTheme.primaryDark,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _isInCall ? _buildCallInterface() : _buildCallsList(),
    );
  }

  Widget _buildCallsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: DesignTokens.space24),

          // Upcoming Calls
          _buildSectionHeader('Upcoming Calls'),
          const SizedBox(height: DesignTokens.space16),
          ..._upcomingCalls.map((call) => _buildCallCard(call, isUpcoming: true)),
          const SizedBox(height: DesignTokens.space24),

          // Call History
          _buildSectionHeader('Call History'),
          const SizedBox(height: DesignTokens.space16),
          ..._callHistory.map((call) => _buildCallCard(call, isUpcoming: false)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.videocam,
            title: 'Video Call',
            subtitle: 'Start video call',
            color: AppTheme.accentGreen,
            onTap: () {
              setState(() {
                _isInCall = true;
              });
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.phone,
            title: 'Audio Call',
            subtitle: 'Start audio call',
            color: Colors.blue,
            onTap: () {
              setState(() {
                _isInCall = true;
                _isVideoOn = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: DesignTokens.space12),
            Text(
              title,
              style: DesignTokens.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: DesignTokens.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: DesignTokens.titleLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCallCard(Map<String, dynamic> call, {required bool isUpcoming}) {
    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          children: [
            // Call Type Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCallTypeColor(call['type']).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getCallTypeIcon(call['type']),
                color: _getCallTypeColor(call['type']),
                size: 24,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            
            // Call Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call['title'],
                    style: DesignTokens.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    call['description'],
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        call['coach'],
                        style: DesignTokens.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space16),
                      Icon(
                        Icons.access_time,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUpcoming 
                          ? _formatUpcomingTime(call['time'])
                          : '${call['duration']} • ${_formatPastTime(call['time'])}',
                        style: DesignTokens.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            if (isUpcoming) ...[
              IconButton(
                onPressed: () {
                  setState(() {
                    _isInCall = true;
                    _isVideoOn = call['type'] == 'video';
                  });
                },
                icon: Icon(
                  call['type'] == 'video' ? Icons.videocam : Icons.phone,
                  color: AppTheme.accentGreen,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showRescheduleDialog(call);
                },
                icon: const Icon(
                  Icons.schedule,
                  color: Colors.white70,
                ),
              ),
            ] else ...[
              IconButton(
                onPressed: () {
                  // View call details
                },
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryDark.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Call Header
            Container(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isInCall = false;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Column(
                    children: [
                      Text(
                        'Coach Sarah',
                        style: DesignTokens.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '00:05:23',
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // More options
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Video/Audio Display
            Expanded(
              child: _isVideoOn ? _buildVideoDisplay() : _buildAudioDisplay(),
            ),
            
            // Call Controls
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDisplay() {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Main video (coach)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primaryDark.withValues(alpha: 0.3),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.accentGreen,
                    child: Text(
                      'CS',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space16),
                  Text(
                    'Coach Sarah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Self video (user) - Picture in Picture
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 120,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentGreen,
                  width: 2,
                ),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioDisplay() {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio visualization
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentGreen,
                width: 3,
              ),
            ),
            child: const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.accentGreen,
                child: Text(
                  'CS',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space24),
          Text(
            'Coach Sarah',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            'Audio Call',
            style: DesignTokens.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: _isMuted,
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
              });
            },
          ),
          
          // Video Toggle
          _buildControlButton(
            icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
            isActive: _isVideoOn,
            onPressed: () {
              setState(() {
                _isVideoOn = !_isVideoOn;
              });
            },
          ),
          
          // Speaker
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            isActive: _isSpeakerOn,
            onPressed: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
              });
            },
          ),
          
          // End Call
          _buildControlButton(
            icon: Icons.call_end,
            isActive: false,
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _isInCall = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isActive ? AppTheme.accentGreen : AppTheme.cardBackground),
        shape: BoxShape.circle,
        border: Border.all(
          color: backgroundColor ?? (isActive ? AppTheme.accentGreen : Colors.white.withValues(alpha: 0.3)),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: backgroundColor != null 
            ? Colors.white 
            : (isActive ? AppTheme.primaryDark : Colors.white),
          size: 24,
        ),
      ),
    );
  }

  Color _getCallTypeColor(String type) {
    switch (type) {
      case 'video':
        return AppTheme.accentGreen;
      case 'audio':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.phone;
      default:
        return Icons.call;
    }
  }

  String _formatUpcomingTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _formatPastTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _showScheduleCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Schedule Call',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Call scheduling functionality would be implemented here.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.primaryDark,
            ),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Reschedule Call',
          style: DesignTokens.titleLarge.copyWith(
            color: Colors.white,
          ),
        ),
        content: Text(
          'Reschedule "${call['title']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.primaryDark,
            ),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }
}
