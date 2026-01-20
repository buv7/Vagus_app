import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/calendar/event_service.dart';
import '../../services/motion_service.dart';
import '../../theme/design_tokens.dart';
import '../../services/supplements/supplement_service.dart';
import '../../models/supplements/supplement_models.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../widgets/supplements/pill_icon.dart';
import 'event_editor.dart';
import 'dart:async';

// Feature flag for calendar supplement overlay
const bool kCalendarShowSupplements = true;



enum CalendarView { month, week, day }

// UI-specific event wrapper for display purposes
class UiCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final String? clientId;
  final List<String> tags;
  final int? capacity;
  final List<String>? attendees;
  final String? recurrenceRule;
  final String? supplementId; // For supplement events

  UiCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    required this.endAt,
    this.clientId,
    this.tags = const [],
    this.capacity,
    this.attendees,
    this.recurrenceRule,
    this.supplementId,
  });

  /// Factory constructor to create UiCalendarEvent from Event
  factory UiCalendarEvent.fromEvent(Event event) {
    return UiCalendarEvent(
      id: event.id,
      title: event.title,
      description: event.notes,
      location: event.location,
      startAt: event.startAt,
      endAt: event.endAt,
      clientId: event.clientId,
      tags: event.tags,
      capacity: event.capacity > 0 ? event.capacity : null, // Nullable-safe
      attendees: [], // Event class doesn't have attendees
      recurrenceRule: event.recurrenceRule,
      supplementId: null, // Regular events don't have supplement ID
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final EventService _eventService = EventService();
  
  late TabController _tabController;
  CalendarView _currentView = CalendarView.month;
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<UiCalendarEvent> _events = [];
  List<Event> _originalEvents = []; // Store original Event objects
  bool _loading = false;
  String? _error;
  
  // Calendar Polish v1.1: Category filters
  final Set<String> _selectedCategories = {'workout', 'nutrition', 'session', 'other', 'supplement'};

  // Capacity tracking for live updates
  final Map<String, int?> _eventCapacities = {};
  final Map<String, int> _eventConfirmedCounts = {};
  final Map<String, StreamSubscription<int>> _capacitySubscriptions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    unawaited(_loadEvents());
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Cancel all capacity subscriptions
    for (final subscription in _capacitySubscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      
      final events = await _eventService.listUpcomingForUser(
        userId: supabase.auth.currentUser?.id ?? '',
        role: 'client',
        limit: 100,
      );
      
      // Load supplement events for overlay
      final supplementEvents = kCalendarShowSupplements 
          ? await _eventService.getSupplementEvents(
              start: start,
              end: end,
            )
          : [];
      
      // Store original Event objects and convert to UiCalendarEvent for UI
      _originalEvents = events;
      final calendarEvents = events.map((event) => UiCalendarEvent.fromEvent(event)).toList();
      
      // Convert supplement events to UiCalendarEvent format
      final supplementCalendarEvents = supplementEvents.map((event) => UiCalendarEvent(
        id: event['id'],
        title: event['title'],
        description: event['description'],
        location: null,
        startAt: event['startAt'],
        endAt: event['endAt'],
        clientId: null,
        tags: [event['type'] ?? 'supplement'],
        capacity: null,
        attendees: null,
        recurrenceRule: null,
        supplementId: event['supplement_id'], // Store the supplement ID
      )).toList();
      
      // Combine regular events with supplement events
      final allEvents = [...calendarEvents, ...supplementCalendarEvents];
      
      // Filter events by selected categories and date range
      final filteredEvents = allEvents.where((event) {
        // Check date range
        if (event.startAt.isBefore(start) || event.startAt.isAfter(end)) {
          return false;
        }
        
        // Check category filter
        final category = event.tags.contains('workout') ? 'workout' :
                        event.tags.contains('nutrition') ? 'nutrition' :
                        event.tags.contains('session') ? 'session' :
                        event.tags.contains('supplement') ? 'supplement' : 'other';
        
        if (!_selectedCategories.contains(category)) return false;
        
        return true;
      }).toList();
      
      // Load capacity data for all events
      await _loadCapacityData(events);
      
      setState(() {
        _events = filteredEvents;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Load capacity data for events and set up live subscriptions
  Future<void> _loadCapacityData(List<Event> events) async {
    // Cancel existing subscriptions
    for (final subscription in _capacitySubscriptions.values) {
      await subscription.cancel();
    }
    _capacitySubscriptions.clear();
    
    for (final event in events) {
      try {
        // Get initial capacity
        final capacity = await _eventService.getCapacity(event.id);
        _eventCapacities[event.id] = capacity;
        
        // Get initial confirmed count
        final confirmedCount = await _eventService.getConfirmedCount(event.id);
        _eventConfirmedCounts[event.id] = confirmedCount;
        
        // Set up live subscription for confirmed count
        final subscription = _eventService.streamConfirmedCount(event.id).listen(
          (count) {
            if (mounted) {
              setState(() {
                _eventConfirmedCounts[event.id] = count;
              });
            }
          },
          onError: (e) {
            debugPrint('Error in capacity stream for event ${event.id}: $e');
          },
        );
        
        _capacitySubscriptions[event.id] = subscription;
      } catch (e) {
        debugPrint('Error loading capacity data for event ${event.id}: $e');
      }
    }
  }

  void _onViewChanged(CalendarView view) {
    setState(() => _currentView = view);
  }

  Future<void> _onDateChanged(DateTime date) async {
    setState(() {
      _focusedDate = date;
      _selectedDate = date;
    });
    await _loadEvents();
  }

  Future<void> _onEventTap(UiCalendarEvent event) async {
    if (event.tags.contains('supplement')) {
      _showSupplementQuickSheet(event);
    } else {
      // Find the original Event object for the EventEditor
      final originalEvent = _originalEvents.firstWhere(
        (e) => e.id == event.id,
        orElse: () => throw Exception('Original event not found'),
      );
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventEditor(event: originalEvent),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEvents();
      });
    }
  }

  void _showSupplementQuickSheet(UiCalendarEvent event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PillIcon(size: 24),
              title: Text(event.title),
              subtitle: const Text('Supplement reminder'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markSupplementTaken(event.id);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Taken'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnoozeOptions(event.id);
                    },
                    icon: const Icon(Icons.snooze),
                    label: const Text('Snooze'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _skipSupplement(event.id);
              },
              icon: const Icon(Icons.close),
              label: const Text('Skip'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markSupplementTaken(String eventId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Find the supplement ID from the event
      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      // Extract supplement ID from event
      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

      // Create supplement log
      final log = SupplementLog.create(
        supplementId: supplementId,
        userId: currentUser.id,
        status: 'taken',
        notes: 'Marked taken from calendar',
      );

      await SupplementService.instance.createLog(log);
      
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplement marked as taken')),
      );

      unawaited(_loadEvents()); // Refresh calendar
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark supplement: $e')),
      );
    }
  }

  Future<void> _snoozeSupplement(String eventId, int minutes) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Find the supplement ID from the event
      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

      // Create supplement log
      final log = SupplementLog.create(
        supplementId: supplementId,
        userId: currentUser.id,
        status: 'snoozed',
        notes: 'Snoozed for $minutes minutes from calendar',
      );

      await SupplementService.instance.createLog(log);
      
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplement snoozed for $minutes minutes')),
      );

      unawaited(_loadEvents()); // Refresh calendar
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to snooze supplement: $e')),
      );
    }
  }

  Future<void> _skipSupplement(String eventId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Find the supplement ID from the event
      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

      // Create supplement log
      final log = SupplementLog.create(
        supplementId: supplementId,
        userId: currentUser.id,
        status: 'skipped',
        notes: 'Skipped from calendar',
      );

      await SupplementService.instance.createLog(log);
      
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplement skipped')),
      );

      unawaited(_loadEvents()); // Refresh calendar
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to skip supplement: $e')),
      );
    }
  }

  void _showSnoozeOptions(String eventId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Snooze for how long?',
              style: DesignTokens.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _snoozeSupplement(eventId, 5);
                    },
                    child: const Text('5 min'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _snoozeSupplement(eventId, 15);
                    },
                    child: const Text('15 min'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _snoozeSupplement(eventId, 30);
                    },
                    child: const Text('30 min'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tap on time slot to add new event
  void _onTimeSlotTapped(int hour) {
    MotionService.hapticFeedback();
    final selectedDateTime = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      _focusedDate.day,
      hour,
    );
    
    // Navigate to EventEditor with the selected time
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: selectedDateTime),
      ),
    ).then((_) => unawaited(_loadEvents()));
  }

  /// Handle tap on time slot in week view
  void _onWeekTimeSlotTapped(DateTime date, int hour) {
    MotionService.hapticFeedback();
    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: selectedDateTime),
      ),
    ).then((_) => unawaited(_loadEvents()));
  }

  /// Handle tap on month view day
  void _onMonthDayTapped(DateTime date) {
    MotionService.hapticFeedback();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: date),
      ),
    ).then((_) => unawaited(_loadEvents()));
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case CalendarView.week:
        final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case CalendarView.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(_focusedDate);
    }
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: DesignTokens.ink700,
            ),
            onPressed: () {
              switch (_currentView) {
                case CalendarView.month:
                  _onDateChanged(DateTime(_focusedDate.year, _focusedDate.month - 1));
                  break;
                case CalendarView.week:
                  _onDateChanged(_focusedDate.subtract(const Duration(days: 7)));
                  break;
                case CalendarView.day:
                  _onDateChanged(_focusedDate.subtract(const Duration(days: 1)));
                  break;
              }
            },
          ),
          Expanded(
            child: Text(
              _getHeaderTitle(),
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.ink900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: DesignTokens.ink700,
            ),
            onPressed: () {
              switch (_currentView) {
                case CalendarView.month:
                  _onDateChanged(DateTime(_focusedDate.year, _focusedDate.month + 1));
                  break;
                case CalendarView.week:
                  _onDateChanged(_focusedDate.add(const Duration(days: 7)));
                  break;
                case CalendarView.day:
                  _onDateChanged(_focusedDate.add(const Duration(days: 1)));
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    switch (_currentView) {
      case CalendarView.month:
        return _buildMonthView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.day:
        return _buildDayView();
    }
  }

  Widget _buildMonthView() {
    final days = <DateTime>[];
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    
    // Add days from previous month to fill first week
    final firstWeekday = firstDay.weekday;
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    
    // Add all days of current month
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month, i));
    }
    
    // Add days from next month to fill last week
    final lastWeekday = lastDay.weekday;
    for (int i = 1; i <= 7 - lastWeekday; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }
    
    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )).toList(),
        ),
        
        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final dayEvents = _events.where((event) =>
                event.startAt.year == date.year &&
                event.startAt.month == date.month &&
                event.startAt.day == date.day,
              ).toList();
              
              return GestureDetector(
                onTap: () => _onMonthDayTapped(date),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: DesignTokens.ink100),
                  ),
                  child: Column(
                    children: [
                      // Date header
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: date.isAtSameMomentAs(
                              DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                            ) ? DesignTokens.blue600 : DesignTokens.ink900,
                          ),
                        ),
                      ),
                      // Events for this day
                      if (dayEvents.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: dayEvents.length,
                            itemBuilder: (context, eventIndex) {
                              final event = dayEvents[eventIndex];
                              return _buildEventTile(event);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }





  Widget _buildEventTile(UiCalendarEvent event) {
    final category = _getEventCategory(event);
    final categoryColor = _getCategoryColor(category);
    final categoryBgColor = _getCategoryBgColor(category);
    
    return GestureDetector(
      onTap: () => _onEventTap(event),
      child: Container(
        margin: const EdgeInsets.all(DesignTokens.space2),
        padding: const EdgeInsets.all(DesignTokens.space8),
        decoration: BoxDecoration(
          color: categoryBgColor,
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Text(
                    event.title,
                    style: DesignTokens.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.ink900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_eventCapacities[event.id] != null && _eventCapacities[event.id]! > 0) ...[
              const SizedBox(height: DesignTokens.space4),
              _buildCapacityBar(event.id, _getCategoryColor(category)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityBar(String eventId, Color color) {
    final capacity = _eventCapacities[eventId] ?? 0;
    final attendees = _eventConfirmedCounts[eventId] ?? 0;
    final percentage = capacity > 0 ? attendees / capacity : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$attendees/$capacity',
              style: DesignTokens.labelSmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: DesignTokens.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space2),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  String _getEventCategory(UiCalendarEvent event) {
    if (event.tags.contains('workout')) return 'workout';
    if (event.tags.contains('nutrition')) return 'nutrition';
    if (event.tags.contains('session')) return 'session';
    return 'other';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'workout':
        return DesignTokens.success;
      case 'nutrition':
        return DesignTokens.warn;
      case 'session':
        return DesignTokens.blue600;
      default:
        return DesignTokens.ink500;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'workout':
        return DesignTokens.successBg;
      case 'nutrition':
        return DesignTokens.warnBg;
      case 'session':
        return DesignTokens.blue50;
      default:
        return DesignTokens.ink50;
    }
  }

  Widget _buildWeekView() {
    final days = <DateTime>[];
    final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    
    for (int i = 0; i < 7; i++) {
      days.add(weekStart.add(Duration(days: i)));
    }
    
    return Column(
      children: [
        // Weekday headers
        Row(
          children: days.map((date) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('E').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )).toList(),
        ),
        
        // Week grid with time slots
        Expanded(
          child: Row(
            children: days.map((date) => Expanded(
              child: _buildWeekDayColumn(date),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayColumn(DateTime date) {
    final dayEvents = _events.where((event) =>
      event.startAt.year == date.year &&
      event.startAt.month == date.month &&
      event.startAt.day == date.day,
    ).toList();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: DesignTokens.ink100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DesignTokens.ink100),
              ),
            ),
            child: Text(
              '${date.day}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Time slots
          Expanded(
            child: ListView.builder(
              itemCount: 24, // 24 hours
              itemBuilder: (context, hour) {
                final hourEvents = dayEvents.where((event) =>
                  event.startAt.hour == hour,
                ).toList();

                return GestureDetector(
                  onTap: () => _onWeekTimeSlotTapped(date, hour),
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: DesignTokens.ink100.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: hourEvents.isNotEmpty
                        ? _buildEventTile(hourEvents.first)
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final dayEvents = _events.where((event) =>
      event.startAt.year == _focusedDate.year &&
      event.startAt.month == _focusedDate.month &&
      event.startAt.day == _focusedDate.day,
    ).toList();

    return ListView.builder(
      itemCount: 24, // 24 hours
      itemBuilder: (context, hour) {
        final hourEvents = dayEvents.where((event) =>
          event.startAt.hour == hour,
        ).toList();

        return GestureDetector(
          onTap: () => _onTimeSlotTapped(hour),
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DesignTokens.ink100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: DesignTokens.labelSmall.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                ),
                Expanded(
                  child: hourEvents.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          itemCount: hourEvents.length,
                          itemBuilder: (context, index) {
                            final event = hourEvents[index];
                            return _buildEventTile(event);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Event'),
        content: const Text('Quick add functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            final views = [CalendarView.month, CalendarView.week, CalendarView.day];
            _onViewChanged(views[index]);
          },
          tabs: const [
            Tab(text: 'Month'),
            Tab(text: 'Week'),
            Tab(text: 'Day'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Calendar header
          _buildCalendarHeader(),
          
          // Calendar view
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading calendar: $_error',
                              style: const TextStyle(color: DesignTokens.danger),
                            ),
                            const SizedBox(height: DesignTokens.space16),
                            ElevatedButton(
                              onPressed: _loadEvents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildCalendarView(),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _showQuickAddDialog,
        child: FloatingActionButton(
          onPressed: () {
            MotionService.hapticFeedback();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventEditor(initialDate: _selectedDate),
              ),
            ).then((_) => unawaited(_loadEvents()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
