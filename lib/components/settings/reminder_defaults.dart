import 'package:flutter/material.dart';
import '../../services/settings/settings_controller.dart';

class ReminderDefaults extends StatefulWidget {
  final SettingsController settingsController;

  const ReminderDefaults({
    super.key,
    required this.settingsController,
  });

  @override
  State<ReminderDefaults> createState() => _ReminderDefaultsState();
}

class _ReminderDefaultsState extends State<ReminderDefaults> {
  String? _selectedDay;
  TimeOfDay? _selectedTime;
  bool _notificationsEnabled = true;

  final Map<String, String> _days = {
    'sun': 'Sunday',
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final defaults = widget.settingsController.reminderDefaults;
    _selectedDay = defaults['checkin_day'] ?? 'sun';
    _notificationsEnabled = defaults['notifications'] ?? true;
    
    final timeString = defaults['reminder_time'] ?? '08:30';
    final parts = timeString.split(':');
    if (parts.length == 2) {
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 30,
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 30);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 30),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _saveSettings();
    }
  }

  void _saveSettings() {
    final settings = <String, dynamic>{
      'checkin_day': _selectedDay,
      'reminder_time': '${_selectedTime?.hour.toString().padLeft(2, '0')}:${_selectedTime?.minute.toString().padLeft(2, '0')}',
      'notifications': _notificationsEnabled,
    };
    widget.settingsController.setReminderDefaults(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default check-in day
        Text(
          'Default check-in day:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDay,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _days.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDay = value;
            });
            _saveSettings();
          },
        ),
        const SizedBox(height: 16),

        // Reminder time
        Text(
          'Reminder time:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime?.format(context) ?? '8:30 AM',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notifications toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enable notifications:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ],
    );
  }
}
