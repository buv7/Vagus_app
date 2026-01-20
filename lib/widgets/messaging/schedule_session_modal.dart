import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ScheduleSessionModal extends StatefulWidget {
  final String clientName;
  final VoidCallback? onSchedule;
  final VoidCallback? onCancel;

  const ScheduleSessionModal({
    super.key,
    required this.clientName,
    this.onSchedule,
    this.onCancel,
  });

  @override
  State<ScheduleSessionModal> createState() => _ScheduleSessionModalState();
}

class _ScheduleSessionModalState extends State<ScheduleSessionModal> {
  final TextEditingController _sessionTypeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '60');
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _sessionTypeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Schedule Session with ${widget.clientName}',
                    style: const TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.lightGrey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Session Type
            _buildInputField(
              controller: _sessionTypeController,
              label: 'Session Type',
              hint: 'e.g., Form Check, Progress Review',
              icon: Icons.fitness_center,
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Date
            _buildInputField(
              controller: _dateController,
              label: 'Date',
              hint: 'mm/dd/yyyy',
              icon: Icons.calendar_today,
              onTap: () => _selectDate(),
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Time
            _buildInputField(
              controller: _timeController,
              label: 'Time',
              hint: '--:--',
              icon: Icons.access_time,
              onTap: () => _selectTime(),
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Duration
            _buildInputField(
              controller: _durationController,
              label: 'Duration (minutes)',
              hint: '60',
              icon: Icons.timer,
            ),
            
            const SizedBox(height: DesignTokens.space16),
            
            // Location
            _buildInputField(
              controller: _locationController,
              label: 'Location',
              hint: 'Gym, Virtual, etc.',
              icon: Icons.location_on,
            ),
            
            const SizedBox(height: DesignTokens.space24),
            
            // Schedule Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _scheduleSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.space16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  ),
                ),
                child: const Text(
                  'Schedule Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.neutralWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            border: Border.all(
              color: AppTheme.accentGreen,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.neutralWhite),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.lightGrey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(DesignTokens.space12),
              suffixIcon: Icon(
                icon,
                color: AppTheme.lightGrey,
                size: 20,
              ),
            ),
            onTap: onTap,
            readOnly: onTap != null,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Use current app theme instead of forcing dark
    );
    
    if (date != null) {
      _dateController.text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      // Use current app theme instead of forcing dark
    );
    
    if (time != null) {
      _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _scheduleSession() {
    // Validate inputs
    if (_sessionTypeController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }
    
    // Schedule the session
    widget.onSchedule?.call();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session scheduled with ${widget.clientName}'),
        backgroundColor: DesignTokens.success,
      ),
    );
    
    Navigator.of(context).pop();
  }
}
