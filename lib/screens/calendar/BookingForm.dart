import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/calendar/calendar_service.dart';
import '../../services/account_switcher.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final CalendarService _calendarService = CalendarService();
  final AccountSwitcher _accountSwitcher = AccountSwitcher.instance;
  
  bool _isCoach = false;
  List<BookingRequest> _bookingRequests = [];
  bool _loading = true;
  String? _error;

  // Client booking form
  String? _selectedCoachId;
  DateTime _requestedStartDate = DateTime.now();
  TimeOfDay _requestedStartTime = TimeOfDay.now();
  DateTime _requestedEndDate = DateTime.now();
  TimeOfDay _requestedEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _error = 'No authenticated user');
        return;
      }

      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final userRole = response['role'] as String? ?? 'client';
      setState(() => _isCoach = userRole == 'coach');
      
      if (_isCoach) {
        _loadBookingRequests();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadBookingRequests() async {
    try {
      setState(() => _loading = true);

      final range = CalendarDateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now().add(const Duration(days: 90)),
      );

      final requests = await _calendarService.fetchBookingsForCoach(range);

      setState(() {
        _bookingRequests = requests;
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _requestedStartDate : _requestedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _requestedStartDate = picked;
          if (_requestedEndDate.isBefore(_requestedStartDate)) {
            _requestedEndDate = picked;
          }
        } else {
          _requestedEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _requestedStartTime : _requestedEndTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _requestedStartTime = picked;
        } else {
          _requestedEndTime = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedCoachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a coach')),
      );
      return;
    }

    final startDateTime = DateTime(
      _requestedStartDate.year,
      _requestedStartDate.month,
      _requestedStartDate.day,
      _requestedStartTime.hour,
      _requestedStartTime.minute,
    );
    
    final endDateTime = DateTime(
      _requestedEndDate.year,
      _requestedEndDate.month,
      _requestedEndDate.day,
      _requestedEndTime.hour,
      _requestedEndTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final draft = BookingDraft(
        coachId: _selectedCoachId!,
        requestedStartAt: startDateTime,
        requestedEndAt: endDateTime,
        message: _messageController.text.trim().isEmpty 
            ? null 
            : _messageController.text.trim(),
      );

      await _calendarService.submitBooking(draft);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Booking request submitted successfully')),
        );
        
        // Reset form
        _messageController.clear();
        setState(() {
          _requestedStartDate = DateTime.now();
          _requestedStartTime = TimeOfDay.now();
          _requestedEndDate = DateTime.now();
          _requestedEndTime = TimeOfDay(
            hour: (_requestedStartTime.hour + 1) % 24,
            minute: _requestedStartTime.minute,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to submit booking: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _respondToBooking(BookingRequest request, String status) async {
    try {
      await _calendarService.respondBooking(
        requestId: request.id,
        status: status,
      );

      if (status == 'approved') {
        // Create an event from the approved booking
        final draft = CalendarEventDraft(
          coachId: request.coachId,
          clientId: request.clientId,
          title: 'Session with ${request.clientId}', // You might want to fetch client name
          description: request.message,
          startAt: request.requestedStartAt,
          endAt: request.requestedEndAt,
        );

        await _calendarService.createEvent(draft);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Booking ${status} successfully')),
        );
        _loadBookingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to respond to booking: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCoach ? 'Booking Requests' : 'Book a Session'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkUserRole,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _isCoach
                  ? _buildCoachView()
                  : _buildClientView(),
    );
  }

  Widget _buildClientView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request a Session',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Coach selection (simplified - you might want to fetch available coaches)
          DropdownButtonFormField<String>(
            value: _selectedCoachId,
            decoration: const InputDecoration(
              labelText: 'Select Coach *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: const [
              // This would be populated with actual coach data
              DropdownMenuItem(value: 'coach1', child: Text('Coach 1')),
              DropdownMenuItem(value: 'coach2', child: Text('Coach 2')),
            ],
            onChanged: (value) {
              setState(() => _selectedCoachId = value);
            },
          ),
          const SizedBox(height: 16),

          // Start Date & Time
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_requestedStartDate)),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  subtitle: Text(_requestedStartTime.format(context)),
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
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_requestedEndDate)),
                  onTap: () => _selectDate(context, false),
                ),
              ),
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('End Time'),
                  subtitle: Text(_requestedEndTime.format(context)),
                  onTap: () => _selectTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Submitting...'),
                      ],
                    )
                  : const Text('Submit Booking Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachView() {
    return _bookingRequests.isEmpty
        ? const Center(
            child: Text(
              'No booking requests yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bookingRequests.length,
            itemBuilder: (context, index) {
              final request = _bookingRequests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session Request',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Client ID: ${request.clientId}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(request.requestedStartAt),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${TimeOfDay.fromDateTime(request.requestedStartAt).format(context)} - ${TimeOfDay.fromDateTime(request.requestedEndAt).format(context)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      
                      if (request.message != null && request.message!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.message, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.message!,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (request.status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToBooking(request, 'approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToBooking(request, 'declined'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }
}
