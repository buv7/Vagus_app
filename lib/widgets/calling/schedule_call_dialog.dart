import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/live_session.dart';
import '../../theme/design_tokens.dart';

class ScheduleCallDialog extends StatefulWidget {
  const ScheduleCallDialog({super.key});

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkBackground : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with glassmorphism
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: DesignTokens.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Schedule Call',
                        style: TextStyle(
                          color: isDark ? Colors.white : DesignTokens.textColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context),
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
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(
                                color: isDark 
                                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                  : DesignTokens.borderColor(context),
                              ),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                              decoration: InputDecoration(
                                hintText: 'Enter call title (optional)',
                                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              validator: (value) {
                                if (value != null && value.length > 100) {
                                  return 'Title must be less than 100 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description
                          _buildSectionTitle('Description'),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(
                                color: isDark 
                                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                  : DesignTokens.borderColor(context),
                              ),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                              decoration: InputDecoration(
                                hintText: 'Enter call description (optional)',
                                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value != null && value.length > 500) {
                                  return 'Description must be less than 500 characters';
                                }
                                return null;
                              },
                            ),
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
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: DesignTokens.accentBlue,
                              inactiveTrackColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
                              thumbColor: DesignTokens.accentBlue,
                              overlayColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
                              valueIndicatorColor: DesignTokens.accentBlue,
                            ),
                            child: Slider(
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
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Recording option
                          _buildSectionTitle('Recording'),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(
                                color: isDark 
                                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                                  : DesignTokens.borderColor(context),
                              ),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Enable recording',
                                style: TextStyle(color: isDark ? Colors.white : DesignTokens.textColor(context)),
                              ),
                              subtitle: Text(
                                'This call will be recorded',
                                style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context)),
                              ),
                              value: _isRecordingEnabled,
                              activeColor: DesignTokens.accentBlue,
                              onChanged: (value) {
                                setState(() {
                                  _isRecordingEnabled = value;
                                });
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.2) : Colors.white,
                                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                    border: Border.all(
                                      color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Center(
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: isDark ? Colors.white : DesignTokens.accentBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: DesignTokens.accentBlue,
                                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _scheduleCall,
                                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        child: Center(
                                          child: Text(
                                            'Schedule',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCallTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
        border: Border.all(
          color: isDark 
            ? DesignTokens.accentBlue.withValues(alpha: 0.3)
            : DesignTokens.borderColor(context),
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
            ? DesignTokens.accentBlue.withValues(alpha: 0.2)
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? DesignTokens.accentBlue : (isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context)),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected 
            ? DesignTokens.accentBlue 
            : (isDark ? Colors.white : DesignTokens.textColor(context)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isSelected 
            ? DesignTokens.accentBlue.withValues(alpha: 0.7)
            : (isDark ? Colors.white.withValues(alpha: 0.6) : DesignTokens.textColorSecondary(context)),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: DesignTokens.accentBlue)
          : null,
      hoverColor: DesignTokens.accentBlue.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isDark 
              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
              : DesignTokens.borderColor(context),
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.accentBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isDark 
              ? DesignTokens.accentBlue.withValues(alpha: 0.3)
              : DesignTokens.borderColor(context),
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : DesignTokens.iconColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedTime.format(context),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : DesignTokens.textColor(context),
              ),
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
