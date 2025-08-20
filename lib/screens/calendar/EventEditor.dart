import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/calendar/calendar_service.dart';
import '../../widgets/files/inline_file_picker.dart';
import '../../widgets/files/file_previewer.dart';

class EventEditor extends StatefulWidget {
  final CalendarEvent? event;
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(minute: TimeOfDay.now().minute + 30);
  
  String? _timezone;
  String? _recurrenceRule;
  String _status = 'scheduled';
  String? _selectedCoachId;
  String? _selectedClientId;
  
  List<Map<String, dynamic>> _attachments = [];
  bool _isSaving = false;
  bool _isDeleting = false;
  
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.event != null) {
      // Editing existing event
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _startDate = event.startAt;
      _startTime = TimeOfDay.fromDateTime(event.startAt);
      _endDate = event.endAt;
      _endTime = TimeOfDay.fromDateTime(event.endAt);
      _timezone = event.timezone;
      _recurrenceRule = event.recurrenceRule;
      _status = event.status;
      _selectedCoachId = event.coachId;
      _selectedClientId = event.clientId;
      _attachments = List.from(event.attachments);
    } else if (widget.initialDate != null) {
      // Creating new event with initial date
      _startDate = widget.initialDate!;
      _endDate = widget.initialDate!;
      _startTime = TimeOfDay.fromDateTime(widget.initialDate!);
      _endTime = TimeOfDay.fromDateTime(
        widget.initialDate!.add(const Duration(minutes: 30)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
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
    }
  }

  void _onFileSelected(Map<String, dynamic> fileData) {
    setState(() {
      _attachments.add({
        'file_name': fileData['file_name'],
        'file_path': fileData['file_path'],
        'file_size': fileData['file_size'],
        'mime_type': fileData['mime_type'],
        'uploaded_at': DateTime.now().toIso8601String(),
      });
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  String _buildRecurrenceRule() {
    if (_recurrenceRule == null || _recurrenceRule!.isEmpty) {
      return '';
    }
    
    switch (_recurrenceRule) {
      case 'daily':
        return 'FREQ=DAILY';
      case 'weekly':
        return 'FREQ=WEEKLY';
      case 'monthly':
        return 'FREQ=MONTHLY';
      default:
        return _recurrenceRule!;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Check for conflicts
      final hasConflict = await _calendarService.hasConflict(
        start: startDateTime,
        end: endDateTime,
        coachId: _selectedCoachId,
        clientId: _selectedClientId,
        ignoreEventId: widget.event?.id,
      );

      if (hasConflict) {
        final shouldOverride = await _showConflictDialog();
        if (!shouldOverride) return;
      }

      final draft = CalendarEventDraft(
        coachId: _selectedCoachId,
        clientId: _selectedClientId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        startAt: startDateTime,
        endAt: endDateTime,
        timezone: _timezone,
        recurrenceRule: _buildRecurrenceRule(),
      );

      if (widget.event != null) {
        // Update existing event
        final updatedEvent = CalendarEvent(
          id: widget.event!.id,
          coachId: _selectedCoachId,
          clientId: _selectedClientId,
          title: draft.title,
          description: draft.description,
          location: draft.location,
          startAt: draft.startAt,
          endAt: draft.endAt,
          timezone: draft.timezone,
          recurrenceRule: draft.recurrenceRule,
          status: _status,
          attachments: _attachments,
          createdBy: widget.event!.createdBy,
          createdAt: widget.event!.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _calendarService.updateEvent(updatedEvent);
      } else {
        // Create new event
        await _calendarService.createEvent(draft);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null 
                  ? '✅ Event updated successfully'
                  : '✅ Event created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save event: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _showConflictDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Conflict'),
        content: const Text(
          'There is already an event scheduled during this time. '
          'Do you want to schedule anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Pick Another Time'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule Anyway'),
          ),
        ],
      ),
    ) ?? false;
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

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _calendarService.deleteEvent(widget.event!.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete event: $e')),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'Edit Event' : 'New Event'),
        actions: [
          if (widget.event != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteEvent,
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
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
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

            // Start Date & Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () => _selectTime(context, true),
                  ),
                ),
              ],
            ),

            // End Date & Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('End Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recurrence
            DropdownButtonFormField<String>(
              value: _recurrenceRule,
              decoration: const InputDecoration(
                labelText: 'Recurrence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                setState(() => _recurrenceRule = value);
              },
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _status = value!);
              },
            ),
            const SizedBox(height: 16),

            // Attachments
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            InlineFilePicker(
              onFileSelected: _onFileSelected,
              showPreview: false,
              hint: 'Add attachment to event',
              allowMultiple: true,
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              },
            ),
            
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...(_attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(attachment['file_name']),
                    subtitle: Text('${attachment['file_size']} bytes'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeAttachment(index),
                    ),
                  ),
                );
              })),
            ],
            
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : Text(widget.event != null ? 'Update Event' : 'Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
