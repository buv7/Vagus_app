import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/navigation/vagus_side_menu.dart';

class ModernCalendarViewer extends StatefulWidget {
  const ModernCalendarViewer({super.key});

  @override
  State<ModernCalendarViewer> createState() => _ModernCalendarViewerState();
}

class _ModernCalendarViewerState extends State<ModernCalendarViewer> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'month'; // month, week, day
  
  // Real data from Supabase
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  
  // Current month for display
  // DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;



      // Load events from calendar_events table
      final response = await Supabase.instance.client
          .from('calendar_events')
          .select()
          .or('client_id.eq.${user.id},coach_id.eq.${user.id}')
          .order('start_at', ascending: true);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      body: SafeArea(
        child: _isLoading 
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
                        const Text(
                          'Error loading calendar events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadEvents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header with hamburger menu
                      _buildHeader(),
                      
                      // View Mode Selector
                      _buildViewModeSelector(),
                      
                      // Calendar Header with navigation
                      _buildCalendarHeader(),
                      
                      // Calendar Content
                      Expanded(
                        child: _buildCalendarContent(),
                      ),
                      
                      // Legend
                      _buildLegend(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          // Title (centered without menu icon) // Menu Icon Removed
          Expanded(
            child: Text(
              'Calendar',
              style: DesignTokens.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildViewModeButton('Month', 'month', Icons.calendar_month),
          ),
          Expanded(
            child: _buildViewModeButton('Week', 'week', Icons.calendar_view_week),
          ),
          Expanded(
            child: _buildViewModeButton('Day', 'day', Icons.calendar_view_day),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String label, String mode, IconData icon) {
    final isSelected = _viewMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryDark : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: DesignTokens.bodySmall.copyWith(
                color: isSelected ? AppTheme.primaryDark : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                } else if (_viewMode == 'week') {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                } else {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                }
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            _getHeaderText(),
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                } else if (_viewMode == 'week') {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                } else {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                }
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    switch (_viewMode) {
      case 'month':
        return '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case 'week':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
      case 'day':
        return '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildCalendarContent() {
    switch (_viewMode) {
      case 'month':
        return _buildMonthView();
      case 'week':
        return _buildWeekView();
      case 'day':
        return _buildDayView();
      default:
        return _buildMonthView();
    }
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstDayOfWeek; i++) {
      days.add(Container());
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final dayEvents = _getEventsForDate(date);
      
      days.add(_buildDayCell(day, dayEvents, date));
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: DesignTokens.bodyMedium.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: DesignTokens.space8),
          
          // Calendar grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: days,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final dayEvents = _getEventsForDate(date);
              
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _getWeekdayName(date.weekday),
                      style: DesignTokens.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Text(
                      '${date.day}',
                      style: DesignTokens.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final event = dayEvents[index];
                          return _buildEventChip(event, isCompact: true);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final dayEvents = _getEventsForDate(_selectedDate);
    
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getWeekdayName(_selectedDate.weekday)}, ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}',
            style: DesignTokens.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space24),
          
          if (dayEvents.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 64,
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  Text(
                    'No events scheduled',
                    style: DesignTokens.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  return _buildEventCard(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, List<Map<String, dynamic>> events, DateTime date) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGreen
              : isToday
                  ? AppTheme.accentGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '$day',
                style: DesignTokens.bodyMedium.copyWith(
                  color: isSelected
                      ? AppTheme.primaryDark
                      : isToday
                          ? AppTheme.accentGreen
                          : Colors.white,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: events.length > 3 ? 3 : events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: event['color'],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            if (events.length > 3)
              Text(
                '+${events.length - 3}',
                style: DesignTokens.bodySmall.copyWith(
                  color: isSelected ? AppTheme.primaryDark : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventChip(Map<String, dynamic> event, {bool isCompact = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: event['color'].withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: event['color'].withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        event['title'],
        style: DesignTokens.bodySmall.copyWith(
          color: event['color'],
          fontWeight: FontWeight.w600,
        ),
        maxLines: isCompact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: event['color'],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: DesignTokens.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'],
                    style: DesignTokens.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: event['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(event['startTime'])} - ${_formatTime(event['endTime'])}',
                        style: DesignTokens.bodySmall.copyWith(
                          color: event['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Event type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event['color'].withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getEventIcon(event['type']),
                color: event['color'],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: DesignTokens.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          Row(
            children: [
              _buildLegendItem('Workout', AppTheme.accentGreen),
              const SizedBox(width: DesignTokens.space16),
              _buildLegendItem('Nutrition', Colors.orange),
              const SizedBox(width: DesignTokens.space16),
              _buildLegendItem('Progress', Colors.blue),
              const SizedBox(width: DesignTokens.space16),
              _buildLegendItem('Call', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    // Mock events for the design (currently unused)
    /*
    final mockEvents = [
      {
        'id': '1',
        'title': 'Training Session',
        'description': 'Strength training with Coach Sarah',
        'startTime': DateTime(2025, 9, 7, 10, 0),
        'endTime': DateTime(2025, 9, 7, 11, 0),
        'type': 'workout',
        'color': AppTheme.accentGreen,
      },
      {
        'id': '2',
        'title': 'Nutrition Check-in',
        'description': 'Weekly nutrition review',
        'startTime': DateTime(2025, 9, 8, 14, 0),
        'endTime': DateTime(2025, 9, 8, 15, 0),
        'type': 'nutrition',
        'color': Colors.orange,
      },
      {
        'id': '3',
        'title': 'Progress Photo Session',
        'description': 'Monthly progress photos',
        'startTime': DateTime(2025, 9, 10, 16, 0),
        'endTime': DateTime(2025, 9, 10, 17, 0),
        'type': 'progress',
        'color': Colors.blue,
      },
      {
        'id': '4',
        'title': 'Video Call with Coach',
        'description': 'Weekly check-in call',
        'startTime': DateTime(2025, 9, 12, 18, 0),
        'endTime': DateTime(2025, 9, 12, 19, 0),
        'type': 'call',
        'color': Colors.purple,
      },
    ];
    */

    // Filter real events for the specific date
    return _events.where((event) {
      final startTime = DateTime.tryParse(event['start_at']?.toString() ?? '');
      if (startTime == null) return false;
      
      return startTime.year == date.year &&
             startTime.month == date.month &&
             startTime.day == date.day;
    }).map((event) {
      final startTime = DateTime.tryParse(event['start_at']?.toString() ?? '') ?? DateTime.now();
      final endTime = DateTime.tryParse(event['end_at']?.toString() ?? '') ?? startTime.add(const Duration(hours: 1));
      
      return {
        'id': event['id']?.toString() ?? '',
        'title': event['title']?.toString() ?? 'Event',
        'description': event['description']?.toString() ?? '',
        'startTime': startTime,
        'endTime': endTime,
        'type': event['type']?.toString() ?? 'general',
        'color': _getEventColor(event['type']?.toString() ?? 'general'),
      };
    }).toList();
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'workout':
      case 'training':
        return AppTheme.accentGreen;
      case 'nutrition':
        return Colors.orange;
      case 'progress':
        return Colors.blue;
      case 'call':
      case 'video':
        return Colors.purple;
      default:
        return AppTheme.accentOrange;
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'workout':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'progress':
        return Icons.camera_alt;
      case 'call':
        return Icons.videocam;
      default:
        return Icons.event;
    }
  }
}
