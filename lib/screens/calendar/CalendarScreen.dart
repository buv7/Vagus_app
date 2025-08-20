import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/calendar/calendar_service.dart';
import 'EventEditor.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  final CalendarService _calendarService = CalendarService();
  late TabController _tabController;
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  CalendarView _currentView = CalendarView.month;
  
  List<CalendarEvent> _events = [];
  List<CalendarEventInstance> _eventInstances = [];
  bool _loading = true;
  String? _error;

  // Filters
  bool _showMyEvents = false;
  bool _showWithCoach = false;
  bool _showWithClients = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _focusedDate = DateTime.now();
    _selectedDate = DateTime.now();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _loading = true);

      final start = _getViewStartDate();
      final end = _getViewEndDate();

      final events = await _calendarService.fetchEvents(
        start: start,
        end: end,
      );

      // Expand recurrence for all events
      final instances = <CalendarEventInstance>[];
      for (final event in events) {
        instances.addAll(
          _calendarService.expandRecurrence(event, start, end),
        );
      }

      setState(() {
        _events = events;
        _eventInstances = instances;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        final msg = e.toString();
        if (msg.contains('42P01') || (msg.contains('relation') && msg.contains('calendar_events'))) {
          _error = 'Calendar tables are missing. Run migrations (supabase/migrations/0003_calendar_booking.sql) or deploy via CI.';
        } else {
          _error = msg;
        }
        _loading = false;
      });
    }
  }

  DateTime _getViewStartDate() {
    switch (_currentView) {
      case CalendarView.month:
        return DateTime(_focusedDate.year, _focusedDate.month, 1);
      case CalendarView.week:
        final weekStart = _focusedDate.subtract(
          Duration(days: _focusedDate.weekday - 1),
        );
        return DateTime(weekStart.year, weekStart.month, weekStart.day);
      case CalendarView.day:
        return DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);
    }
  }

  DateTime _getViewEndDate() {
    switch (_currentView) {
      case CalendarView.month:
        return DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
      case CalendarView.week:
        final weekStart = _focusedDate.subtract(
          Duration(days: _focusedDate.weekday - 1),
        );
        return weekStart.add(const Duration(days: 6));
      case CalendarView.day:
        return DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day, 23, 59, 59);
    }
  }

  void _onViewChanged(CalendarView view) {
    setState(() => _currentView = view);
    _loadEvents();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _focusedDate = date;
      _selectedDate = date;
    });
    _loadEvents();
  }

  void _onEventTap(CalendarEventInstance instance) {
    final event = _events.firstWhere((e) => e.id == instance.eventId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditor(event: event),
      ),
    ).then((_) => _loadEvents());
  }

  void _onSlotTap(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditor(
          initialDate: date,
        ),
      ),
    ).then((_) => _loadEvents());
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('My Events'),
              value: _showMyEvents,
              onChanged: (value) {
                setState(() => _showMyEvents = value ?? false);
                Navigator.pop(context);
                _loadEvents();
              },
            ),
            CheckboxListTile(
              title: const Text('With My Coach'),
              value: _showWithCoach,
              onChanged: (value) {
                setState(() => _showWithCoach = value ?? false);
                Navigator.pop(context);
                _loadEvents();
              },
            ),
            CheckboxListTile(
              title: const Text('With My Clients'),
              value: _showWithClients,
              onChanged: (value) {
                setState(() => _showWithClients = value ?? false);
                Navigator.pop(context);
                _loadEvents();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventEditor(),
            ),
          ).then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
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
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => _onDateChanged(DateTime.now()),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case CalendarView.week:
        final weekStart = _focusedDate.subtract(
          Duration(days: _focusedDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case CalendarView.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(_focusedDate);
    }
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
    final startDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final endDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayOfWeek = startDate.weekday;
    final daysInMonth = endDate.day;
    
    final days = <DateTime>[];
    
    // Add days from previous month
    final prevMonth = DateTime(_focusedDate.year, _focusedDate.month - 1);
    final daysInPrevMonth = DateTime(_focusedDate.year, _focusedDate.month, 0).day;
    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i + 1));
    }
    
    // Add days from current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month, i));
    }
    
    // Add days from next month
    final remainingDays = 42 - days.length; // 6 weeks * 7 days
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month + 1, i));
    }

    return Column(
      children: [
        // Day headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ))
              .toList(),
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
              final isCurrentMonth = date.month == _focusedDate.month;
              final isToday = date.isAtSameMomentAs(
                DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
              );
              final isSelected = date.isAtSameMomentAs(
                DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
              );
              
              final dayEvents = _eventInstances.where((event) =>
                event.startAt.isAtSameMomentAs(
                  DateTime(date.year, date.month, date.day),
                ),
              ).toList();

              return GestureDetector(
                onTap: () => _onSlotTap(date),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade100
                        : isToday
                            ? Colors.orange.shade50
                            : null,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : isToday
                              ? Colors.orange
                              : Colors.grey.shade300,
                      width: isSelected || isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isCurrentMonth ? Colors.black : Colors.grey,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
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

  Widget _buildWeekView() {
    final weekStart = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - 1),
    );
    final days = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Column(
      children: [
        // Day headers
        Row(
          children: days.map((date) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: date.isAtSameMomentAs(
                        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                      ) ? Colors.blue : null,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
        
        // Week grid
        Expanded(
          child: Row(
            children: days.map((date) => Expanded(
              child: _buildDayColumn(date),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayColumn(DateTime date) {
    final dayEvents = _eventInstances.where((event) =>
      event.startAt.isAtSameMomentAs(
        DateTime(date.year, date.month, date.day),
      ),
    ).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dayEvents.length,
              itemBuilder: (context, index) {
                final event = dayEvents[index];
                return GestureDetector(
                  onTap: () => _onEventTap(event),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
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
    final dayEvents = _eventInstances.where((event) =>
      event.startAt.isAtSameMomentAs(
        DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day),
      ),
    ).toList();

    return ListView.builder(
      itemCount: 24, // 24 hours
      itemBuilder: (context, hour) {
        final hourEvents = dayEvents.where((event) =>
          event.startAt.hour == hour,
        ).toList();

        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: hourEvents.isEmpty
                    ? const SizedBox()
                    : ListView.builder(
                        itemCount: hourEvents.length,
                        itemBuilder: (context, index) {
                          final event = hourEvents[index];
                          return GestureDetector(
                            onTap: () => _onEventTap(event),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                event.title,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
