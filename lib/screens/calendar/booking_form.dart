import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/calendar/event_service.dart';
import '../../services/motion_service.dart';

class BookingForm extends StatefulWidget {
  final String? coachId;
  final Event? event;

  const BookingForm({
    super.key,
    this.coachId,
    this.event,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final EventService _eventService = EventService();
  
  List<Event> _availableSlots = [];
  List<Event> _myBookings = [];
  bool _loading = true;
  String _userRole = 'client';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      if (_userRole == 'client') {
        // Load available booking slots from coaches
        await _loadAvailableSlots();
        // Load my current bookings
        await _loadMyBookings();
      } else if (_userRole == 'coach') {
        // Load my booking slots
        await _loadMyBookingSlots();
        // Load bookings for my slots
        await _loadBookingsForMySlots();
      }
    } catch (e) {
      debugPrint('Error loading booking data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailableSlots() async {
    try {
      // Get all coaches' booking slots
      final coaches = await Supabase.instance.client
          .from('profiles')
          .select('id, name')
          .eq('role', 'coach');

      final allSlots = <Event>[];
      for (final coach in coaches) {
        final slots = await _eventService.getBookingSlots(coach['id']);
        allSlots.addAll(slots);
      }

      setState(() {
        _availableSlots = allSlots
            .where((slot) => slot.startAt.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      });
    } catch (e) {
      debugPrint('Error loading available slots: $e');
    }
  }

  Future<void> _loadMyBookings() async {
    try {
      final bookings = await _eventService.listUpcomingForUser(
        userId: _userId,
        role: 'client',
        limit: 50,
      );

      setState(() {
        _myBookings = bookings
            .where((event) => event.isBookingSlot)
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      });
    } catch (e) {
      debugPrint('Error loading my bookings: $e');
    }
  }

  Future<void> _loadMyBookingSlots() async {
    try {
      final slots = await _eventService.getBookingSlots(_userId);
      setState(() {
        _availableSlots = slots
            .where((slot) => slot.startAt.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      });
    } catch (e) {
      debugPrint('Error loading my booking slots: $e');
    }
  }

  Future<void> _loadBookingsForMySlots() async {
    try {
      final bookings = await _eventService.listUpcomingForUser(
        userId: _userId,
        role: 'coach',
        limit: 50,
      );

      setState(() {
        _myBookings = bookings
            .where((event) => event.isBookingSlot)
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      });
    } catch (e) {
      debugPrint('Error loading bookings for my slots: $e');
    }
  }

  Future<void> _bookSlot(Event slot) async {
    try {
      await _eventService.bookSlot(
        eventId: slot.id,
        userId: _userId,
      );

      MotionService.hapticFeedback();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Booked "${slot.title}" successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        unawaited(_loadData()); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(Event booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel "${booking.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _eventService.cancelBooking(
          eventId: booking.id,
          userId: _userId,
        );

        MotionService.hapticFeedback();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Booking cancelled'),
              backgroundColor: Colors.green,
            ),
          );
          unawaited(_loadData()); // Refresh the data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to cancel: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showParticipants(Event slot) async {
    try {
      final participants = await _eventService.getEventParticipants(slot.id);
      
      if (mounted) {
        // ignore: unawaited_futures
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Participants - ${slot.title}'),
            content: SizedBox(
              width: double.maxFinite,
              child: participants.isEmpty
                  ? const Text('No participants yet')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        final profile = participant['profiles'] as Map<String, dynamic>?;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (profile?['name'] as String? ?? 'U')[0].toUpperCase(),
                            ),
                          ),
                          title: Text(profile?['name'] ?? 'Unknown'),
                          subtitle: Text(profile?['email'] ?? ''),
                          trailing: Chip(
                            label: Text(participant['status'] ?? 'confirmed'),
                            backgroundColor: participant['status'] == 'confirmed'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading participants: $e')),
        );
      }
    }
  }

  Widget _buildSlotCard(Event slot, {bool isMySlot = false}) {
    final isBooked = _myBookings.any((booking) => booking.id == slot.id);
    final isPast = slot.startAt.isBefore(DateTime.now());
    final canBook = !isBooked && !isPast;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBooked ? Colors.green : Colors.blue,
          child: Icon(
            isBooked ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          slot.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPast ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(slot.startAt),
              style: TextStyle(
                color: isPast ? Colors.grey : null,
              ),
            ),
            if (slot.location != null)
              Text(
                '📍 ${slot.location}',
                style: TextStyle(
                  color: isPast ? Colors.grey : null,
                ),
              ),
            if (slot.capacity > 1)
              Text(
                '👥 ${slot.capacity} spots available',
                style: TextStyle(
                  color: isPast ? Colors.grey : null,
                ),
              ),
          ],
        ),
        trailing: _userRole == 'coach' && isMySlot
            ? IconButton(
                icon: const Icon(Icons.people),
                onPressed: () => _showParticipants(slot),
                tooltip: 'View participants',
              )
            : null,
        onTap: canBook ? () => _bookSlot(slot) : null,
      ),
    );
  }

  Widget _buildBookingCard(Event booking) {
    final isPast = booking.startAt.isBefore(DateTime.now());
    final canCancel = !isPast;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : Colors.green,
          child: Icon(
            isPast ? Icons.check_circle : Icons.event,
            color: Colors.white,
          ),
        ),
        title: Text(
          booking.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPast ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(booking.startAt),
              style: TextStyle(
                color: isPast ? Colors.grey : null,
              ),
            ),
            if (booking.location != null)
              Text(
                '📍 ${booking.location}',
                style: TextStyle(
                  color: isPast ? Colors.grey : null,
                ),
              ),
            if (_userRole == 'coach')
              Text(
                '👤 ${booking.clientId ?? 'Unknown client'}',
                style: TextStyle(
                  color: isPast ? Colors.grey : null,
                ),
              ),
          ],
        ),
        trailing: canCancel
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _cancelBooking(booking),
                tooltip: 'Cancel booking',
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_userRole == 'coach' ? 'My Booking Slots' : 'Book Sessions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'My Bookings'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Available Slots Tab
                  _availableSlots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _userRole == 'coach'
                                    ? 'No booking slots available'
                                    : 'No available sessions',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_userRole == 'coach')
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/calendar/event-editor');
                                  },
                                  child: const Text('Create Booking Slot'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _availableSlots[index];
                              return _buildSlotCard(
                                slot,
                                isMySlot: _userRole == 'coach',
                              );
                            },
                          ),
                        ),

                  // My Bookings Tab
                  _myBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No bookings yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _myBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _myBookings[index];
                              return _buildBookingCard(booking);
                            },
                          ),
                        ),
                ],
              ),
        floatingActionButton: _userRole == 'coach'
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/calendar/event-editor',
                    arguments: {'isBookingSlot': true},
                  ).then((_) => unawaited(_loadData()));
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
