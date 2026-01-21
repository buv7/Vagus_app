import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../widgets/navigation/vagus_side_menu.dart';
import '../../services/calendar/event_service.dart';
import '../../services/motion_service.dart';
import '../../services/supplements/supplement_service.dart';
import '../../models/supplements/supplement_models.dart';
import '../../widgets/supplements/pill_icon.dart';
import 'event_editor.dart';

// Feature flag for calendar supplement overlay
const bool kCalendarShowSupplements = true;

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
  final String? supplementId;

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
      capacity: event.capacity > 0 ? event.capacity : null,
      attendees: [],
      recurrenceRule: event.recurrenceRule,
      supplementId: null,
    );
  }
}

class ModernCalendarViewer extends StatefulWidget {
  const ModernCalendarViewer({super.key});

  @override
  State<ModernCalendarViewer> createState() => _ModernCalendarViewerState();
}

class _ModernCalendarViewerState extends State<ModernCalendarViewer> {
  final EventService _eventService = EventService();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String _viewMode = 'month'; // month, week, day
  
  // Real data from Supabase
  List<UiCalendarEvent> _events = [];
  List<Event> _originalEvents = [];
  bool _isLoading = true;
  String? _error;
  
  // Category filters
  final Set<String> _selectedCategories = {'workout', 'nutrition', 'session', 'other', 'supplement'};
  
  // Capacity tracking for live updates
  final Map<String, int?> _eventCapacities = {};
  final Map<String, int> _eventConfirmedCounts = {};
  final Map<String, StreamSubscription<int>> _capacitySubscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    // Cancel all capacity subscriptions
    for (final subscription in _capacitySubscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month + 2, 0);

      final events = await _eventService.listUpcomingForUser(
        userId: user.id,
        role: 'client',
        limit: 200,
      );

      // Load supplement events for overlay
      final supplementEvents = kCalendarShowSupplements
          ? await _eventService.getSupplementEvents(
              start: start,
              end: end,
            )
          : [];

      // Store original Event objects
      _originalEvents = events;
      final calendarEvents = events.map((event) => UiCalendarEvent.fromEvent(event)).toList();

      // Convert supplement events
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
        supplementId: event['supplement_id'],
      )).toList();

      // Combine all events
      final allEvents = [...calendarEvents, ...supplementCalendarEvents];

      // Filter events by selected categories
      final filteredEvents = allEvents.where((event) {
        final category = _getEventCategory(event);
        return _selectedCategories.contains(category);
      }).toList();

      // Load capacity data
      await _loadCapacityData(events);

      if (mounted) {
        setState(() {
          _events = filteredEvents;
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

  Future<void> _loadCapacityData(List<Event> events) async {
    // Cancel existing subscriptions
    for (final subscription in _capacitySubscriptions.values) {
      await subscription.cancel();
    }
    _capacitySubscriptions.clear();

    for (final event in events) {
      try {
        final capacity = await _eventService.getCapacity(event.id);
        _eventCapacities[event.id] = capacity;

        final confirmedCount = await _eventService.getConfirmedCount(event.id);
        _eventConfirmedCounts[event.id] = confirmedCount;

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

  String _getEventCategory(UiCalendarEvent event) {
    if (event.tags.contains('workout')) return 'workout';
    if (event.tags.contains('nutrition')) return 'nutrition';
    if (event.tags.contains('session')) return 'session';
    if (event.tags.contains('supplement')) return 'supplement';
    return 'other';
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    _loadEvents();
  }

  Future<void> _onEventTap(UiCalendarEvent event) async {
    if (event.tags.contains('supplement')) {
      _showSupplementQuickSheet(event);
    } else {
      final originalEvent = _originalEvents.firstWhere(
        (e) => e.id == event.id,
        orElse: () => throw Exception('Original event not found'),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventEditor(event: originalEvent),
        ),
      );
      
      if (result == true) {
        _loadEvents();
      }
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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

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

      unawaited(_loadEvents());
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark supplement: $e')),
      );
    }
  }

  Future<void> _snoozeSupplement(String eventId, int minutes) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

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

      unawaited(_loadEvents());
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to snooze supplement: $e')),
      );
    }
  }

  Future<void> _skipSupplement(String eventId) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final event = _events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final supplementId = event.supplementId;
      if (supplementId == null) {
        throw Exception('Supplement ID not found in event');
      }

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

      unawaited(_loadEvents());
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

  void _onTimeSlotTapped(int hour) {
    MotionService.hapticFeedback();
    final selectedDateTime = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      _focusedDate.day,
      hour,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: selectedDateTime),
      ),
    ).then((result) {
      if (result == true) {
        _loadEvents();
      }
    });
  }

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
    ).then((result) {
      if (result == true) {
        _loadEvents();
      }
    });
  }

  void _onMonthDayTapped(DateTime date) {
    MotionService.hapticFeedback();
    setState(() {
      _selectedDate = date;
      _focusedDate = date;
    });
  }

  void _onMonthDayDoubleTapped(DateTime date) {
    MotionService.hapticFeedback();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: date),
      ),
    ).then((result) {
      if (result == true) {
        _loadEvents();
      }
    });
  }

  void _createNewEvent() {
    MotionService.hapticFeedback();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(initialDate: _selectedDate),
      ),
    ).then((result) {
      if (result == true) {
        _loadEvents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = context.tc;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawerEdgeDragWidth: 24,
      drawer: const VagusSideMenu(isClient: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewEvent,
        backgroundColor: tc.accent,
        child: Icon(Icons.add, color: tc.textOnDark),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: tc.accent,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: tc.danger,
                          size: 48,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        Text(
                          'Error loading calendar events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: tc.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: tc.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.space16),
                        ElevatedButton(
                          onPressed: _loadEvents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tc.accent,
                            foregroundColor: tc.textOnDark,
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

                      // Category Filter Chips
                      _buildCategoryFilters(),

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
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Calendar',
              style: DesignTokens.titleLarge.copyWith(
                color: tc.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final tc = context.tc;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Row(
        children: [
          _buildFilterChip('Workout', 'workout', DesignTokens.success),
          const SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Nutrition', 'nutrition', DesignTokens.warn),
          const SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Session', 'session', DesignTokens.blue600),
          const SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Supplement', 'supplement', Colors.purple),
          const SizedBox(width: DesignTokens.space8),
          _buildFilterChip('Other', 'other', tc.textSecondary),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String category, Color color) {
    final isSelected = _selectedCategories.contains(category);
    final tc = context.tc;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleCategory(category),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : tc.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : tc.border,
      ),
    );
  }

  Widget _buildViewModeSelector() {
    final tc = context.tc;
    return Container(
      margin: const EdgeInsets.all(DesignTokens.space16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tc.border),
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
    final tc = context.tc;

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
          color: isSelected ? tc.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? tc.textOnDark : tc.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: DesignTokens.bodySmall.copyWith(
                color: isSelected ? tc.textOnDark : tc.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                  _selectedDate = _focusedDate;
                } else if (_viewMode == 'week') {
                  _focusedDate = _focusedDate.subtract(const Duration(days: 7));
                  _selectedDate = _focusedDate;
                } else {
                  _focusedDate = _focusedDate.subtract(const Duration(days: 1));
                  _selectedDate = _focusedDate;
                }
              });
            },
            icon: Icon(Icons.chevron_left, color: tc.icon),
          ),
          Text(
            _getHeaderText(),
            style: DesignTokens.titleLarge.copyWith(
              color: tc.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                  _selectedDate = _focusedDate;
                } else if (_viewMode == 'week') {
                  _focusedDate = _focusedDate.add(const Duration(days: 7));
                  _selectedDate = _focusedDate;
                } else {
                  _focusedDate = _focusedDate.add(const Duration(days: 1));
                  _selectedDate = _focusedDate;
                }
              });
            },
            icon: Icon(Icons.chevron_right, color: tc.icon),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    switch (_viewMode) {
      case 'month':
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case 'week':
        final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';
      case 'day':
        return DateFormat('EEEE, MMM d, yyyy').format(_focusedDate);
      default:
        return '';
    }
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
    final tc = context.tc;
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
                            color: tc.textSecondary,
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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final dayEvents = _getEventsForDate(date);
                return _buildDayCell(date, dayEvents);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date, List<UiCalendarEvent> events) {
    final tc = context.tc;
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    final isCurrentMonth = date.month == _focusedDate.month;

    return GestureDetector(
      onTap: () => _onMonthDayTapped(date),
      onDoubleTap: () => _onMonthDayDoubleTapped(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? tc.accent
              : isToday
                  ? tc.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: tc.accent, width: 1)
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '${date.day}',
                style: DesignTokens.bodyMedium.copyWith(
                  color: isSelected
                      ? tc.textOnDark
                      : !isCurrentMonth
                          ? tc.textDisabled
                          : isToday
                              ? tc.accent
                              : tc.textPrimary,
                  fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 3 ? 3 : events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final color = _getCategoryColor(_getEventCategory(event));
                    return Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            if (events.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '+${events.length - 3}',
                  style: DesignTokens.labelSmall.copyWith(
                    color: isSelected ? tc.textOnDark : tc.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final tc = context.tc;
    final days = <DateTime>[];
    final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));

    for (int i = 0; i < 7; i++) {
      days.add(weekStart.add(Duration(days: i)));
    }

    return Column(
      children: [
        // Weekday headers with dates
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space8),
          child: Row(
            children: [
              const SizedBox(width: 50), // Space for time labels
              ...days.map((date) {
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday ? tc.accent.withValues(alpha: 0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday ? tc.accent : tc.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isToday ? tc.accent : null,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isToday ? tc.textOnDark : tc.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Time slots grid
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time labels
                SizedBox(
                  width: 50,
                  child: Column(
                    children: List.generate(24, (hour) {
                      return SizedBox(
                        height: 60,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: DesignTokens.labelSmall.copyWith(
                              color: tc.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Day columns
                ...days.map((date) => Expanded(
                      child: _buildWeekDayColumn(date),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayColumn(DateTime date) {
    final tc = context.tc;
    final dayEvents = _getEventsForDate(date);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: tc.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: List.generate(24, (hour) {
          final hourEvents = dayEvents.where((event) => event.startAt.hour == hour).toList();

          return GestureDetector(
            onTap: () => _onWeekTimeSlotTapped(date, hour),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tc.border.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: hourEvents.isNotEmpty
                  ? ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hourEvents.length,
                      itemBuilder: (context, index) {
                        final event = hourEvents[index];
                        return _buildCompactEventTile(event);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayView() {
    final tc = context.tc;
    final dayEvents = _getEventsForDate(_focusedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
          child: Text(
            DateFormat('EEEE, MMMM d').format(_focusedDate),
            style: DesignTokens.titleMedium.copyWith(
              color: tc.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space8),

        // Day's events summary
        if (dayEvents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space16),
            child: Text(
              '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''} scheduled',
              style: DesignTokens.bodySmall.copyWith(
                color: tc.textSecondary,
              ),
            ),
          ),

        const SizedBox(height: DesignTokens.space8),

        // Time slots with events
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final hourEvents = dayEvents.where((event) => event.startAt.hour == hour).toList();

              return GestureDetector(
                onTap: () => _onTimeSlotTapped(hour),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tc.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: DesignTokens.labelSmall.copyWith(
                            color: tc.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: hourEvents.isEmpty
                            ? const SizedBox.shrink()
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
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
          ),
        ),
      ],
    );
  }

  Widget _buildCompactEventTile(UiCalendarEvent event) {
    final category = _getEventCategory(event);
    final color = _getCategoryColor(category);

    return GestureDetector(
      onTap: () => _onEventTap(event),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Text(
          event.title,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEventTile(UiCalendarEvent event) {
    final tc = context.tc;
    final category = _getEventCategory(event);
    final categoryColor = _getCategoryColor(category);
    final categoryBgColor = _getCategoryBgColor(category);

    return GestureDetector(
      onTap: () => _onEventTap(event),
      child: Container(
        margin: const EdgeInsets.all(DesignTokens.space4),
        padding: const EdgeInsets.all(DesignTokens.space8),
        constraints: const BoxConstraints(minWidth: 120),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  child: Text(
                    event.title,
                    style: DesignTokens.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tc.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_eventCapacities[event.id] != null && _eventCapacities[event.id]! > 0) ...[
              const SizedBox(height: DesignTokens.space4),
              _buildCapacityBar(event.id, categoryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityBar(String eventId, Color color) {
    final tc = context.tc;
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
                color: tc.textSecondary,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'workout':
        return DesignTokens.success;
      case 'nutrition':
        return DesignTokens.warn;
      case 'session':
        return DesignTokens.blue600;
      case 'supplement':
        return Colors.purple;
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
      case 'supplement':
        return Colors.purple.withValues(alpha: 0.1);
      default:
        return DesignTokens.ink50;
    }
  }

  Widget _buildLegend() {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(
          top: BorderSide(
            color: tc.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: DesignTokens.titleMedium.copyWith(
              color: tc.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem('Workout', DesignTokens.success),
                const SizedBox(width: DesignTokens.space16),
                _buildLegendItem('Nutrition', DesignTokens.warn),
                const SizedBox(width: DesignTokens.space16),
                _buildLegendItem('Session', DesignTokens.blue600),
                const SizedBox(width: DesignTokens.space16),
                _buildLegendItem('Supplement', Colors.purple),
                const SizedBox(width: DesignTokens.space16),
                _buildLegendItem('Other', DesignTokens.ink500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final tc = context.tc;
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
            color: tc.textSecondary,
          ),
        ),
      ],
    );
  }

  List<UiCalendarEvent> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.startAt.year == date.year &&
          event.startAt.month == date.month &&
          event.startAt.day == date.day;
    }).toList();
  }
}
