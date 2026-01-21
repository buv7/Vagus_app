import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/calendar/event_service.dart';
import '../../widgets/anim/blocking_overlay.dart';
import '../../theme/design_tokens.dart';
import '../../theme/theme_colors.dart';

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
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.bg,
      appBar: _buildGlassmorphicAppBar(context, isEditing, tc),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Input with glassmorphic style
            _buildGlassmorphicTextField(
              controller: _titleController,
              label: 'Title *',
              tc: tc,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Date and Time Section
            _buildGlassmorphicCard(
              tc: tc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Date & Time', tc),
                  const SizedBox(height: 16),

                  // All Day Toggle
                  _buildGlassmorphicSwitch(
                    title: 'All Day',
                    value: _allDay,
                    onChanged: (value) => setState(() => _allDay = value),
                    tc: tc,
                  ),

                  const SizedBox(height: 16),

                  // Start Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeTile(
                          title: 'Start',
                          value: _startDate != null
                              ? DateFormat('MMM dd, yyyy').format(_startDate!)
                              : 'Select date',
                          onTap: () => _pickDate(context, true),
                          tc: tc,
                        ),
                      ),
                      if (!_allDay) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeTile(
                            title: 'Time',
                            value: _startTime != null
                                ? _startTime!.format(context)
                                : 'Select time',
                            onTap: () => _pickTime(context, true),
                            tc: tc,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // End Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeTile(
                          title: 'End',
                          value: _endDate != null
                              ? DateFormat('MMM dd, yyyy').format(_endDate!)
                              : 'Select date',
                          onTap: () => _pickDate(context, false),
                          tc: tc,
                        ),
                      ),
                      if (!_allDay) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeTile(
                            title: 'Time',
                            value: _endTime != null
                                ? _endTime!.format(context)
                                : 'Select time',
                            onTap: () => _pickTime(context, false),
                            tc: tc,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Location
            _buildGlassmorphicTextField(
              controller: _locationController,
              label: 'Location',
              tc: tc,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // Notes
            _buildGlassmorphicTextField(
              controller: _notesController,
              label: 'Notes',
              tc: tc,
              prefixIcon: Icons.sticky_note_2_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Tags
            _buildGlassmorphicCard(
              tc: tc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Tags', tc),
                      _buildGlassmorphicIconButton(
                        icon: Icons.add,
                        onTap: _addTag,
                        tc: tc,
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => _buildGlassmorphicChip(
                        label: tag,
                        onDeleted: () => _removeTag(tag),
                        tc: tc,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Coach-specific options
            if (isCoach) ...[
              _buildGlassmorphicCard(
                tc: tc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Booking Options', tc),
                    const SizedBox(height: 16),

                    _buildGlassmorphicSwitch(
                      title: 'Booking Slot',
                      subtitle: 'Allow clients to book this time',
                      value: _isBookingSlot,
                      onChanged: (value) => setState(() => _isBookingSlot = value),
                      tc: tc,
                    ),

                    if (_isBookingSlot) ...[
                      const SizedBox(height: 16),
                      _buildGlassmorphicTextField(
                        initialValue: _capacity.toString(),
                        label: 'Capacity',
                        tc: tc,
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
              const SizedBox(height: 20),
            ],

            // Visibility and Status
            _buildGlassmorphicCard(
              tc: tc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Settings', tc),
                  const SizedBox(height: 16),

                  _buildGlassmorphicDropdown(
                    value: _visibility,
                    label: 'Visibility',
                    items: const [
                      DropdownMenuItem(value: 'private', child: Text('Private')),
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                    ],
                    onChanged: (value) => setState(() => _visibility = value!),
                    tc: tc,
                  ),
                  const SizedBox(height: 16),

                  _buildGlassmorphicDropdown(
                    value: _status,
                    label: 'Status',
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) => setState(() => _status = value!),
                    tc: tc,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recurrence (advanced)
            _buildGlassmorphicCard(
              tc: tc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Recurrence (Advanced)', tc),
                  const SizedBox(height: 8),
                  Text(
                    'Enter RRULE format (e.g., FREQ=WEEKLY;INTERVAL=1)',
                    style: TextStyle(fontSize: 12, color: tc.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassmorphicTextField(
                    controller: _recurrenceController,
                    label: 'Recurrence Rule',
                    tc: tc,
                    hintText: 'FREQ=WEEKLY;INTERVAL=1',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button - Glassmorphic accent style
            _buildGlassmorphicButton(
              label: isEditing ? 'Update Event' : 'Create Event',
              onPressed: _saving ? null : _saveEvent,
              isLoading: _saving,
              tc: tc,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===== GLASSMORPHIC HELPER WIDGETS =====

  PreferredSizeWidget _buildGlassmorphicAppBar(BuildContext context, bool isEditing, ThemeColors tc) {
    return AppBar(
      backgroundColor: tc.bg.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: tc.icon),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        isEditing ? 'Edit Event' : 'New Event',
        style: TextStyle(
          color: tc.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildGlassmorphicIconButton(
              icon: Icons.delete_outline,
              onTap: _saving ? null : _deleteEvent,
              tc: tc,
              isDanger: true,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeColors tc) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.accentBlue,
      ),
    );
  }

  Widget _buildGlassmorphicCard({
    required Widget child,
    required ThemeColors tc,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tc.isDark
                  ? [
                      DesignTokens.accentBlue.withValues(alpha: 0.08),
                      DesignTokens.accentBlue.withValues(alpha: 0.03),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tc.isDark
                  ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                  : tc.border,
              width: 1,
            ),
            boxShadow: tc.isDark
                ? [
                    BoxShadow(
                      color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : tc.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required ThemeColors tc,
    IconData? prefixIcon,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: tc.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: TextStyle(color: tc.textSecondary),
            hintStyle: TextStyle(color: tc.textTertiary),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: DesignTokens.accentBlue, size: 20)
                : null,
            filled: true,
            fillColor: tc.isDark
                ? DesignTokens.accentBlue.withValues(alpha: 0.05)
                : tc.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: tc.isDark
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : tc.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: tc.isDark
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : tc.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.accentBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tc.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tc.danger, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicSwitch({
    required String title,
    String? subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required ThemeColors tc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tc.isDark
            ? DesignTokens.accentBlue.withValues(alpha: 0.05)
            : tc.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tc.isDark
              ? DesignTokens.accentBlue.withValues(alpha: 0.15)
              : tc.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tc.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.accentBlue,
            activeTrackColor: DesignTokens.accentBlue.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String title,
    required String value,
    required VoidCallback onTap,
    required ThemeColors tc,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tc.isDark
              ? DesignTokens.accentBlue.withValues(alpha: 0.05)
              : tc.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tc.isDark
                ? DesignTokens.accentBlue.withValues(alpha: 0.15)
                : tc.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: tc.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: DesignTokens.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicIconButton({
    required IconData icon,
    VoidCallback? onTap,
    required ThemeColors tc,
    bool isDanger = false,
  }) {
    final color = isDanger ? tc.danger : DesignTokens.accentBlue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicChip({
    required String label,
    required VoidCallback onDeleted,
    required ThemeColors tc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.15),
            DesignTokens.accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tc.isDark ? Colors.white : DesignTokens.accentBlue,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 16,
              color: tc.isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : DesignTokens.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicDropdown({
    required String value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required ThemeColors tc,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: tc.textPrimary),
          dropdownColor: tc.isDark ? const Color(0xFF1A1A2E) : tc.surface,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: tc.textSecondary),
            filled: true,
            fillColor: tc.isDark
                ? DesignTokens.accentBlue.withValues(alpha: 0.05)
                : tc.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: tc.isDark
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : tc.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: tc.isDark
                    ? DesignTokens.accentBlue.withValues(alpha: 0.2)
                    : tc.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.accentBlue,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    required ThemeColors tc,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DesignTokens.accentBlue.withValues(alpha: 0.3),
                  DesignTokens.accentBlue.withValues(alpha: 0.1),
                ],
                center: Alignment.center,
                radius: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
