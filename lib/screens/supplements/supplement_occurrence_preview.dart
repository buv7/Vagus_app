import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplements/supplement_models.dart';
import '../../services/supplements/supplement_service.dart';
import '../../theme/design_tokens.dart';

class SupplementOccurrencePreview extends StatefulWidget {
  final Supplement supplement;

  const SupplementOccurrencePreview({
    super.key,
    required this.supplement,
  });

  @override
  State<SupplementOccurrencePreview> createState() => _SupplementOccurrencePreviewState();
}

class _SupplementOccurrencePreviewState extends State<SupplementOccurrencePreview> {
  List<SupplementSchedule> _schedules = [];
  List<DateTime> _occurrences = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedulesAndOccurrences();
  }

  Future<void> _loadSchedulesAndOccurrences() async {
    try {
      final schedules = await SupplementService.instance.getSchedulesForSupplement(widget.supplement.id);
      setState(() {
        _schedules = schedules;
        _loading = false;
      });
      
      if (schedules.isNotEmpty) {
        _generateOccurrences(schedules.first);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _generateOccurrences(SupplementSchedule schedule) {
    final occurrences = SupplementService.instance.generateOccurrences(
      schedule: schedule,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    setState(() {
      _occurrences = occurrences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DesignTokens.space16),
            decoration: const BoxDecoration(
              color: DesignTokens.ink50,
              border: Border(
                bottom: BorderSide(color: DesignTokens.ink100),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Schedule Preview',
                  style: DesignTokens.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                    ? _buildNoScheduleState()
                    : _buildOccurrencesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 64,
              color: DesignTokens.ink500,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'No Schedule Configured',
              style: DesignTokens.titleMedium.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'This supplement doesn\'t have a schedule yet.\nConfigure a schedule to see upcoming occurrences.',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccurrencesList() {
    final schedule = _schedules.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule Info Header
        Container(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.supplement.name,
                style: DesignTokens.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                widget.supplement.dosage,
                style: DesignTokens.bodyMedium.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              
              // Schedule Summary
              _buildScheduleSummary(schedule),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Occurrences List
        Expanded(
          child: _occurrences.isEmpty
              ? _buildNoOccurrencesState()
              : ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  itemCount: _occurrences.length,
                  itemBuilder: (context, index) {
                    final occurrence = _occurrences[index];
                    final isToday = _isSameDay(occurrence, DateTime.now());
                    final isTomorrow = _isSameDay(occurrence, DateTime.now().add(const Duration(days: 1)));
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getOccurrenceColor(occurrence),
                            borderRadius: BorderRadius.circular(DesignTokens.radius20),
                          ),
                          child: Icon(
                            _getOccurrenceIcon(occurrence),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _getOccurrenceTitle(occurrence),
                          style: DesignTokens.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(occurrence),
                              style: DesignTokens.bodyMedium.copyWith(
                                color: DesignTokens.ink500,
                              ),
                            ),
                            Text(
                              'at ${DateFormat('h:mm a').format(occurrence)}',
                              style: DesignTokens.bodySmall.copyWith(
                                color: DesignTokens.ink500,
                              ),
                            ),
                          ],
                        ),
                        trailing: _buildOccurrenceBadge(isToday, isTomorrow),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleSummary(SupplementSchedule schedule) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: DesignTokens.ink50,
        borderRadius: BorderRadius.circular(DesignTokens.radius8),
        border: Border.all(color: DesignTokens.ink100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Type: ${_getScheduleTypeDisplay(schedule)}',
            style: DesignTokens.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          
          if (schedule.scheduleType == 'fixed_times') ...[
            if (schedule.daysOfWeek != null && schedule.daysOfWeek!.isNotEmpty)
              Text(
                'Days: ${_getDaysOfWeekDisplay(schedule.daysOfWeek!)}',
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
            if (schedule.specificTimes != null && schedule.specificTimes!.isNotEmpty)
              Text(
                'Times: ${_getTimesDisplay(schedule.specificTimes!)}',
                style: DesignTokens.bodySmall.copyWith(
                  color: DesignTokens.ink500,
                ),
              ),
          ] else if (schedule.scheduleType == 'interval' && schedule.intervalHours != null) ...[
            Text(
              'Every ${schedule.intervalHours} hours',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
          ],
          
          const SizedBox(height: DesignTokens.space4),
          
          Text(
            'Start: ${DateFormat('MMM dd, yyyy').format(schedule.startDate)}',
            style: DesignTokens.bodySmall.copyWith(
              color: DesignTokens.ink500,
            ),
          ),
          
          if (schedule.endDate != null)
            Text(
              'End: ${DateFormat('MMM dd, yyyy').format(schedule.endDate!)}',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoOccurrencesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: DesignTokens.ink500,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              'No Upcoming Occurrences',
              style: DesignTokens.titleMedium.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'This schedule doesn\'t have any upcoming occurrences.\nCheck the schedule configuration.',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.ink500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccurrenceBadge(bool isToday, bool isTomorrow) {
    if (isToday) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
          vertical: DesignTokens.space4,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.success,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Text(
          'TODAY',
          style: DesignTokens.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    } else if (isTomorrow) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
          vertical: DesignTokens.space4,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.blue600,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Text(
          'TOMORROW',
          style: DesignTokens.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  String _getScheduleTypeDisplay(SupplementSchedule schedule) {
    switch (schedule.scheduleType) {
      case 'fixed_times':
        return 'Fixed Times';
      case 'interval':
        return 'Every N Hours';
      default:
        return schedule.frequency;
    }
  }

  String _getDaysOfWeekDisplay(List<int> days) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  String _getTimesDisplay(List<DateTime> times) {
    return times.map((time) => 
      DateFormat('h:mm a').format(time)
    ).join(', ');
  }

  String _getOccurrenceTitle(DateTime occurrence) {
    final now = DateTime.now();
    if (_isSameDay(occurrence, now)) {
      return 'Today';
    } else if (_isSameDay(occurrence, now.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE').format(occurrence);
    }
  }

  Color _getOccurrenceColor(DateTime occurrence) {
    final now = DateTime.now();
    if (_isSameDay(occurrence, now)) {
      return DesignTokens.success;
    } else if (_isSameDay(occurrence, now.add(const Duration(days: 1)))) {
      return DesignTokens.blue600;
    } else {
      return DesignTokens.ink500;
    }
  }

  IconData _getOccurrenceIcon(DateTime occurrence) {
    final now = DateTime.now();
    if (_isSameDay(occurrence, now)) {
      return Icons.today;
    } else if (_isSameDay(occurrence, now.add(const Duration(days: 1)))) {
      return Icons.event;
    } else {
      return Icons.schedule;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
