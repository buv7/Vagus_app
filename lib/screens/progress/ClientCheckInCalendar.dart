import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/progress/progress_service.dart';

class ClientCheckInCalendar extends StatefulWidget {
  const ClientCheckInCalendar({super.key});

  @override
  State<ClientCheckInCalendar> createState() => _ClientCheckInCalendarState();
}

class _ClientCheckInCalendarState extends State<ClientCheckInCalendar> {
  final ProgressService _progressService = ProgressService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _monthCheckins = [];
  Set<DateTime> _checkinDates = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    try {
      setState(() => _loading = true);
      
      final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final checkins = await _progressService.getCheckinsForMonth(
        monthStart: monthStart,
        monthEnd: monthEnd,
      );
      
      setState(() {
        _monthCheckins = checkins;
        _checkinDates = checkins
            .map((c) => DateTime.parse(c['checkin_date']))
            .toSet();
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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _selectedDate = null;
    });
    _loadMonthData();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  List<Map<String, dynamic>> _getCheckinsForDate(DateTime date) {
    return _monthCheckins
        .where((c) => 
            DateTime.parse(c['checkin_date']).day == date.day &&
            DateTime.parse(c['checkin_date']).month == date.month &&
            DateTime.parse(c['checkin_date']).year == date.year)
        .toList();
  }

  void _showAddCheckInDialog(DateTime date) {
    final messageController = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Check-In for ${DateFormat('MMM dd, yyyy').format(date)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  hintText: 'How are you feeling today? Any updates...',
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a message')),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        
                        try {
                          await _progressService.addCheckIn(
                            checkinDate: date,
                            message: messageController.text.trim(),
                          );
                          
                          Navigator.pop(context);
                          _loadMonthData();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Check-in added successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Failed to add check-in: $e')),
                            );
                          }
                        } finally {
                          setDialogState(() => saving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save'),
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

  Widget _buildCalendarGrid() {
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstDayOfWeek = monthStart.weekday % 7; // Sunday = 0
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    
    // Calculate total cells needed (6 weeks max)
    final totalCells = 42;
    
    return Column(
      children: [
        // Weekday headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - firstDayOfWeek + 1;
            
            if (dayNumber <= 0 || dayNumber > daysInMonth) {
              return const SizedBox(); // Empty cell
            }
            
            final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
            final hasCheckin = _checkinDates.any((d) => 
                d.day == date.day && d.month == date.month && d.year == date.year);
            final isSelected = _selectedDate != null &&
                _selectedDate!.day == date.day &&
                _selectedDate!.month == date.month &&
                _selectedDate!.year == date.year;
            final isToday = DateTime.now().day == date.day &&
                DateTime.now().month == date.month &&
                DateTime.now().year == date.year;
            
            return GestureDetector(
              onTap: () => _selectDate(date),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : isToday
                          ? Colors.blue[50]
                          : null,
                  border: hasCheckin
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Colors.blue[700]
                                  : Colors.black,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasCheckin)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDateDetails() {
    if (_selectedDate == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Select a date to view check-ins',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final dayCheckins = _getCheckinsForDate(_selectedDate!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddCheckInDialog(_selectedDate!),
                icon: const Icon(Icons.add),
                label: const Text('Add Check-In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        if (dayCheckins.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No check-ins for this date',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...dayCheckins.map((checkin) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: checkin['status'] == 'open' ? Colors.orange[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          checkin['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color: checkin['status'] == 'open' ? Colors.orange[800] : Colors.green[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('HH:mm').format(DateTime.parse(checkin['created_at'])),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checkin['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (checkin['coach_reply'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coach Reply:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            checkin['coach_reply'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ] else if (checkin['status'] == 'open')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Awaiting coach reply...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadMonthData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Month navigation
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    
                    // Calendar grid
                    _buildCalendarGrid(),
                    
                    const Divider(),
                    
                    // Selected date details
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildSelectedDateDetails(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
