import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/calendar/event_service.dart';
import '../../services/motion_service.dart';

class AvailabilityPublisher extends StatefulWidget {
  const AvailabilityPublisher({super.key});

  @override
  State<AvailabilityPublisher> createState() => _AvailabilityPublisherState();
}

class _AvailabilityPublisherState extends State<AvailabilityPublisher> {
  final EventService _eventService = EventService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  
  // Time settings
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 60; // minutes
  
  // Date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 28));
  
  // Weekday selection
  final Set<int> _selectedWeekdays = {1, 3, 5}; // Mon, Wed, Fri
  
  // Event settings
  int _capacity = 1;
  final List<String> _tags = ['session'];
  String _visibility = 'public';
  
  // UI state
  bool _publishing = false;
  int _estimatedSlots = 0;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Consultation Session');
    _locationController = TextEditingController();
    _notesController = TextEditingController();
    _calculateEstimatedSlots();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _calculateEstimatedSlots() {
    int slots = 0;
    final current = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (_selectedWeekdays.contains(current.weekday)) {
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        final availableMinutes = endMinutes - startMinutes;
        slots += (availableMinutes / _slotDuration).floor();
      }
      current.add(const Duration(days: 1));
    }
    
    setState(() {
      _estimatedSlots = slots;
    });
  }
  
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _calculateEstimatedSlots();
    }
  }
  
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _calculateEstimatedSlots();
    }
  }
  
  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
    _calculateEstimatedSlots();
  }
  
  Future<void> _publishAvailability() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one weekday')),
      );
      return;
    }
    
    setState(() => _publishing = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      int createdSlots = 0;
      final current = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      
      // Generate slots for each selected weekday in the date range
      DateTime slotDate = current;
      while (slotDate.isBefore(end) || slotDate.isAtSameMomentAs(end)) {
        if (_selectedWeekdays.contains(slotDate.weekday)) {
          // Create slots for this day
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          
          for (int minute = startMinutes; minute < endMinutes; minute += _slotDuration) {
            final slotStart = DateTime(
              slotDate.year,
              slotDate.month,
              slotDate.day,
              minute ~/ 60,
              minute % 60,
            );
            
            final slotEnd = slotStart.add(Duration(minutes: _slotDuration));
            
            // Create the booking slot
            final event = Event(
              id: '',
              createdBy: user.id,
              coachId: user.id,
              title: _titleController.text.trim(),
              startAt: slotStart,
              endAt: slotEnd,
              location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              tags: _tags,
              visibility: _visibility,
              isBookingSlot: true,
              capacity: _capacity,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            final savedEvent = await _eventService.createOrUpdate(event);
            
            // Schedule reminder for this event
            final reminderStatus = await _eventService.scheduleReminder(
              eventId: savedEvent.id,
              eventTitle: savedEvent.title,
              eventTime: savedEvent.startAt,
              userId: user.id,
            );
            
            // Log reminder status for debugging
            if (reminderStatus == 'skipped_too_close') {
              debugPrint('⚠️ Reminder skipped for event ${savedEvent.id} - too close to current time');
            } else if (reminderStatus == 'not_ready') {
              debugPrint('⚠️ Reminder not scheduled for event ${savedEvent.id} - notifications not ready');
            } else if (reminderStatus != null) {
              debugPrint('✅ Reminder scheduled for event ${savedEvent.id}');
            } else {
              debugPrint('❌ Failed to schedule reminder for event ${savedEvent.id}');
            }
            
            createdSlots++;
          }
        }
        slotDate = slotDate.add(const Duration(days: 1));
      }
      
      MotionService.hapticFeedback();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Published $createdSlots availability slots!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View in Calendar',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
                // Navigate to calendar tab
                Navigator.pushNamed(context, '/calendar');
              },
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to publish availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _publishing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Availability'),
        actions: [
          if (_estimatedSlots > 0)
            Chip(
              label: Text('$_estimatedSlots slots'),
              backgroundColor: Colors.blue.shade100,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Session Title *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Consultation Session',
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Time Range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Range',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(_startTime.format(context)),
                            onTap: () => _pickTime(context, true),
                            trailing: const Icon(Icons.access_time),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(_endTime.format(context)),
                            onTap: () => _pickTime(context, false),
                            trailing: const Icon(Icons.access_time),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Slot Duration
                    DropdownButtonFormField<int>(
                      value: _slotDuration,
                      decoration: const InputDecoration(
                        labelText: 'Slot Duration',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 minutes')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 45, child: Text('45 minutes')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                        DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                        DropdownMenuItem(value: 120, child: Text('2 hours')),
                      ],
                      onChanged: (value) {
                        setState(() => _slotDuration = value!);
                        _calculateEstimatedSlots();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Date'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                            onTap: () => _pickDate(context, true),
                            trailing: const Icon(Icons.calendar_today),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Date'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                            onTap: () => _pickDate(context, false),
                            trailing: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Weekday Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Days',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildWeekdayChip(1, 'Mon'),
                        _buildWeekdayChip(2, 'Tue'),
                        _buildWeekdayChip(3, 'Wed'),
                        _buildWeekdayChip(4, 'Thu'),
                        _buildWeekdayChip(5, 'Fri'),
                        _buildWeekdayChip(6, 'Sat'),
                        _buildWeekdayChip(7, 'Sun'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., Zoom, Office, Gym',
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Additional information for clients',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Capacity
            TextFormField(
              initialValue: _capacity.toString(),
              decoration: const InputDecoration(
                labelText: 'Capacity per Slot',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final capacity = int.tryParse(value);
                if (capacity != null && capacity > 0) {
                  setState(() => _capacity = capacity);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Visibility
            DropdownButtonFormField<String>(
              value: _visibility,
              decoration: const InputDecoration(
                labelText: 'Visibility',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'public', child: Text('Public')),
              ],
              onChanged: (value) => setState(() => _visibility = value!),
            ),
            const SizedBox(height: 32),
            
            // Publish Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _publishing ? null : _publishAvailability,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _publishing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish Availability'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeekdayChip(int weekday, String label) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleWeekday(weekday),
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }
}
