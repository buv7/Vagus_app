import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/calendar/event_service.dart';
import '../../widgets/anim/blocking_overlay.dart';

import '../../services/motion_service.dart';

class EventEditor extends StatefulWidget {
  final Event? event;
  final DateTime? initialDate;

  const EventEditor({
    super.key,
    this.event,
    this.initialDate,
  });

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  final EventService _eventService = EventService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _recurrenceController;
  
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;
  bool _isBookingSlot = false;
  int _capacity = 1;
  String _visibility = 'private';
  String _status = 'scheduled';
  List<String> _tags = [];
  String _userRole = 'client';
  String _userId = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _notesController = TextEditingController(text: widget.event?.notes ?? '');
    _recurrenceController = TextEditingController(text: widget.event?.recurrenceRule ?? '');
    
    _loadUserInfo();
    _initializeDates();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _userRole = profile['role'] ?? 'client';
          _userId = user.id;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  void _initializeDates() {
    if (widget.event != null) {
      // Editing existing event
      _startDate = widget.event!.startAt;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startAt);
      _endDate = widget.event!.endAt;
      _endTime = TimeOfDay.fromDateTime(widget.event!.endAt);
      _allDay = widget.event!.allDay;
      _isBookingSlot = widget.event!.isBookingSlot;
      _capacity = widget.event!.capacity;
      _visibility = widget.event!.visibility;
      _status = widget.event!.status;
      _tags = List.from(widget.event!.tags);
    } else {
      // Creating new event
      final now = DateTime.now();
      final initialDate = widget.initialDate ?? now;
      
      _startDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
      _startTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
      _endDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
      _endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 2)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _recurrenceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate! : _endDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime! : _endTime!,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tag',
            hintText: 'e.g., Workout, Nutrition, Check-in',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _tags.add(value.trim());
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // The onSubmitted callback already handles adding the tag
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveEvent() async {
    final contextRef = context;
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(contextRef).showSnackBar(
        const SnackBar(content: Text('Please set start and end times')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Create start and end DateTime objects
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _allDay ? 0 : _startTime!.hour,
        _allDay ? 0 : _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _allDay ? 23 : _endTime!.hour,
        _allDay ? 59 : _endTime!.minute,
      );

      // Validate times
      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(contextRef).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        setState(() => _saving = false);
        return;
      }

      // Check for conflicts
      final conflicts = await _eventService.findConflicts(
        userId: _userId,
        start: startDateTime,
        end: endDateTime,
      );

      if (conflicts.isNotEmpty && widget.event == null) {
        final hasConflict = conflicts.any((event) => event.id != widget.event?.id);
        if (hasConflict) {
          if (!mounted || !context.mounted) return;
          final shouldContinue = await showDialog<bool>(
            context: contextRef,
            builder: (context) => AlertDialog(
              title: const Text('Scheduling Conflict'),
              content: const Text('You have a scheduling conflict. Do you want to continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) {
            setState(() => _saving = false);
            return;
          }
        }
      }

      // Create or update event
      final event = Event(
        id: widget.event?.id ?? '',
        createdBy: widget.event?.createdBy ?? _userId,
        coachId: _userRole == 'coach' && _isBookingSlot ? _userId : widget.event?.coachId,
        clientId: _userRole == 'client' ? _userId : widget.event?.clientId,
        title: _titleController.text.trim(),
        startAt: startDateTime,
        endAt: endDateTime,
        allDay: _allDay,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: _tags,
        attachments: widget.event?.attachments ?? [],
        visibility: _visibility,
        status: _status,
        isBookingSlot: _isBookingSlot,
        capacity: _capacity,
        recurrenceRule: _recurrenceController.text.trim().isEmpty ? null : _recurrenceController.text.trim(),
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;
      final savedEvent = await runWithBlockingLoader(
        context,
        _eventService.createOrUpdate(event),
        showSuccess: true,
      );

      // Handle reminders based on event state
      try {
        if (widget.event == null) {
          // New event - schedule reminder
          final reminderStatus = await _eventService.scheduleReminder(
            eventId: savedEvent.id,
            eventTitle: savedEvent.title,
            eventTime: savedEvent.startAt,
            userId: _userId,
          );
          
          // Log reminder status for debugging
          if (reminderStatus == 'skipped_too_close') {
            debugPrint('⚠️ Reminder skipped for new event - too close to current time');
          } else if (reminderStatus == 'not_ready') {
            debugPrint('⚠️ Reminder not scheduled for new event - notifications not ready');
          } else if (reminderStatus != null) {
            debugPrint('✅ Reminder scheduled for new event');
          } else {
            debugPrint('❌ Failed to schedule reminder for new event');
          }
        } else {
          // Existing event - check if time changed and reschedule reminder
          final oldStartTime = widget.event!.startAt;
          final newStartTime = savedEvent.startAt;
          
          if (oldStartTime != newStartTime) {
            // Time changed - reschedule reminder
            await _eventService.rescheduleReminder(
              eventId: savedEvent.id,
              eventTitle: savedEvent.title,
              newEventTime: newStartTime,
              userId: _userId,
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to handle reminder: $e');
        // Don't block the save operation if reminder fails
      }

      // Haptic feedback
      MotionService.hapticFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null ? 'Event created!' : 'Event updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        // Cancel reminder before deleting event
        try {
          await _eventService.cancelReminder(
            eventId: widget.event!.id,
            userId: _userId,
          );
        } catch (e) {
          debugPrint('Failed to cancel reminder: $e');
          // Don't block deletion if reminder cancellation fails
        }
        
        await _eventService.deleteEvent(widget.event!.id);
        MotionService.hapticFeedback();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    final isCoach = _userRole == 'coach';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'New Event'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _saving ? null : _deleteEvent,
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
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date and Time Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // All Day Toggle
                    SwitchListTile(
                      title: const Text('All Day'),
                      value: _allDay,
                      onChanged: (value) => setState(() => _allDay = value),
                    ),

                    // Start Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start'),
                            subtitle: Text(
                              _startDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                  : 'Select date',
                            ),
                            onTap: () => _pickDate(context, true),
                          ),
                        ),
                        if (!_allDay)
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : 'Select time',
                              ),
                              onTap: () => _pickTime(context, true),
                            ),
                          ),
                      ],
                    ),

                    // End Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('End'),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : 'Select date',
                            ),
                            onTap: () => _pickDate(context, false),
                          ),
                        ),
                        if (!_allDay)
                          Expanded(
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : 'Select time',
                              ),
                              onTap: () => _pickTime(context, false),
                            ),
                          ),
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
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Tags
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tags',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addTag,
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _tags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Coach-specific options
            if (isCoach) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Booking Slot'),
                        subtitle: const Text('Allow clients to book this time'),
                        value: _isBookingSlot,
                        onChanged: (value) => setState(() => _isBookingSlot = value),
                      ),

                      if (_isBookingSlot) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _capacity.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                            border: OutlineInputBorder(),
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
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Visibility and Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recurrence (advanced)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurrence (Advanced)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter RRULE format (e.g., FREQ=WEEKLY;INTERVAL=1)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _recurrenceController,
                      decoration: const InputDecoration(
                        labelText: 'Recurrence Rule',
                        border: OutlineInputBorder(),
                        hintText: 'FREQ=WEEKLY;INTERVAL=1',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Event' : 'Create Event'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
