import 'package:flutter/material.dart';
import '../../models/live_session.dart';

class ScheduleCallDialog extends StatefulWidget {
  const ScheduleCallDialog({Key? key}) : super(key: key);

  @override
  State<ScheduleCallDialog> createState() => _ScheduleCallDialogState();
}

class _ScheduleCallDialogState extends State<ScheduleCallDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  SessionType _selectedType = SessionType.videoCall;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  int _maxParticipants = 2;
  bool _isRecordingEnabled = false;
  String? _selectedClientId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Schedule Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Call type selection
                      _buildSectionTitle('Call Type'),
                      _buildCallTypeSelector(),
                      
                      const SizedBox(height: 16),
                      
                      // Title
                      _buildSectionTitle('Title'),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter call title (optional)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 100) {
                            return 'Title must be less than 100 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      _buildSectionTitle('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter call description (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'Description must be less than 500 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date and time
                      _buildSectionTitle('Schedule'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateSelector(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeSelector(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Max participants
                      _buildSectionTitle('Max Participants'),
                      Slider(
                        value: _maxParticipants.toDouble(),
                        min: 2,
                        max: 10,
                        divisions: 8,
                        label: _maxParticipants.toString(),
                        onChanged: (value) {
                          setState(() {
                            _maxParticipants = value.round();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recording option
                      _buildSectionTitle('Recording'),
                      SwitchListTile(
                        title: const Text('Enable recording'),
                        subtitle: const Text('This call will be recorded'),
                        value: _isRecordingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isRecordingEnabled = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _scheduleCall,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Schedule'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCallTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildCallTypeOption(
            SessionType.audioCall,
            Icons.call,
            'Audio Call',
            'Voice-only call',
          ),
          _buildCallTypeOption(
            SessionType.videoCall,
            Icons.videocam,
            'Video Call',
            'Video call with camera',
          ),
          _buildCallTypeOption(
            SessionType.groupCall,
            Icons.group,
            'Group Call',
            'Multi-participant call',
          ),
          _buildCallTypeOption(
            SessionType.coachingSession,
            Icons.sports_handball,
            'Coaching Session',
            'Health coaching session',
          ),
        ],
      ),
    );
  }

  Widget _buildCallTypeOption(
    SessionType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedType == type;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: 8),
            Text(
              _selectedTime.format(context),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _scheduleCall() {
    if (!_formKey.currentState!.validate()) return;
    
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final session = LiveSession(
      id: '', // Will be generated by the service
      sessionType: _selectedType,
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      scheduledAt: scheduledDateTime,
      maxParticipants: _maxParticipants,
      isRecordingEnabled: _isRecordingEnabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    Navigator.pop(context, session);
  }
}
