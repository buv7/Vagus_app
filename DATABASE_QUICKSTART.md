# Database Quick Start Guide

## Overview

This guide helps you quickly integrate the new database tables into your Vagus app.

## What Was Added

1. **calendar_events.event_type** - Categorize calendar events
2. **client_feedback** - Collect and manage client feedback
3. **payments** - Track payments and revenue

## Flutter/Dart Integration

### 1. Add to Your Models

Create or update these model files:

**lib/models/calendar_event.dart**:
```dart
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final String coachId;
  final String? clientId;
  final String status;
  final String eventType; // NEW FIELD
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    required this.coachId,
    this.clientId,
    required this.status,
    this.eventType = 'session', // Default value
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startAt: DateTime.parse(json['start_at']),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      coachId: json['coach_id'],
      clientId: json['client_id'],
      status: json['status'],
      eventType: json['event_type'] ?? 'session',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'coach_id': coachId,
      'client_id': clientId,
      'status': status,
      'event_type': eventType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Event type constants
class EventType {
  static const String session = 'session';
  static const String workout = 'workout';
  static const String consultation = 'consultation';
  static const String checkIn = 'check_in';
  static const String appointment = 'appointment';
  static const String other = 'other';

  static List<String> get all => [
        session,
        workout,
        consultation,
        checkIn,
        appointment,
        other,
      ];
}
```

**lib/models/client_feedback.dart**:
```dart
class ClientFeedback {
  final String id;
  final String clientId;
  final String coachId;
  final String? feedbackText;
  final int rating;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientFeedback({
    required this.id,
    required this.clientId,
    required this.coachId,
    this.feedbackText,
    required this.rating,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientFeedback.fromJson(Map<String, dynamic> json) {
    return ClientFeedback(
      id: json['id'],
      clientId: json['client_id'],
      coachId: json['coach_id'],
      feedbackText: json['feedback_text'],
      rating: json['rating'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'coach_id': coachId,
      'feedback_text': feedbackText,
      'rating': rating,
      'category': category,
    };
  }
}

// Feedback category constants
class FeedbackCategory {
  static const String workout = 'workout';
  static const String nutrition = 'nutrition';
  static const String support = 'support';
  static const String communication = 'communication';
  static const String results = 'results';
  static const String general = 'general';

  static List<String> get all => [
        workout,
        nutrition,
        support,
        communication,
        results,
        general,
      ];
}
```

**lib/models/payment.dart**:
```dart
class Payment {
  final String id;
  final String clientId;
  final String coachId;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final String? stripePaymentId;
  final String? stripePaymentIntentId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.paymentMethod,
    this.stripePaymentId,
    this.stripePaymentIntentId,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      clientId: json['client_id'],
      coachId: json['coach_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'],
      paymentMethod: json['payment_method'],
      stripePaymentId: json['stripe_payment_id'],
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      description: json['description'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'coach_id': coachId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'stripe_payment_id': stripePaymentId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'description': description,
      'metadata': metadata,
    };
  }
}

// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
  static const String cancelled = 'cancelled';
}
```

### 2. Create Service Methods

**lib/services/feedback_service.dart**:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_feedback.dart';

class FeedbackService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Submit feedback as a client
  Future<ClientFeedback> submitFeedback({
    required String coachId,
    required int rating,
    required String category,
    String? feedbackText,
  }) async {
    final response = await _supabase.from('client_feedback').insert({
      'coach_id': coachId,
      'rating': rating,
      'category': category,
      'feedback_text': feedbackText,
    }).select().single();

    return ClientFeedback.fromJson(response);
  }

  // Get feedback for a coach
  Future<List<ClientFeedback>> getCoachFeedback(String coachId) async {
    final response = await _supabase
        .from('client_feedback')
        .select()
        .eq('coach_id', coachId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ClientFeedback.fromJson(json))
        .toList();
  }

  // Get client's own feedback
  Future<List<ClientFeedback>> getMyFeedback() async {
    final response = await _supabase
        .from('client_feedback')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ClientFeedback.fromJson(json))
        .toList();
  }

  // Update feedback
  Future<ClientFeedback> updateFeedback({
    required String feedbackId,
    int? rating,
    String? feedbackText,
  }) async {
    final updates = <String, dynamic>{};
    if (rating != null) updates['rating'] = rating;
    if (feedbackText != null) updates['feedback_text'] = feedbackText;

    final response = await _supabase
        .from('client_feedback')
        .update(updates)
        .eq('id', feedbackId)
        .select()
        .single();

    return ClientFeedback.fromJson(response);
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    await _supabase.from('client_feedback').delete().eq('id', feedbackId);
  }

  // Get coach rating summary
  Future<Map<String, dynamic>> getCoachRatingSummary(String coachId) async {
    final response = await _supabase
        .from('coach_feedback_summary')
        .select()
        .eq('coach_id', coachId)
        .maybeSingle();

    return response ?? {
      'total_feedback': 0,
      'average_rating': 0.0,
      'five_star_count': 0,
      'four_star_count': 0,
      'three_star_count': 0,
      'two_star_count': 0,
      'one_star_count': 0,
    };
  }
}
```

**lib/services/payment_service.dart**:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get payments for a coach
  Future<List<Payment>> getCoachPayments(String coachId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('coach_id', coachId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  // Get client's payments
  Future<List<Payment>> getMyPayments() async {
    final response = await _supabase
        .from('payments')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  // Get coach payment summary
  Future<Map<String, dynamic>> getCoachPaymentSummary(String coachId) async {
    final response = await _supabase
        .from('coach_payment_summary')
        .select()
        .eq('coach_id', coachId)
        .maybeSingle();

    return response ?? {
      'total_payments': 0,
      'completed_payments': 0,
      'total_revenue': 0.0,
      'average_payment': 0.0,
    };
  }

  // Get monthly revenue (custom query)
  Future<List<Map<String, dynamic>>> getMonthlyRevenue(String coachId) async {
    final response = await _supabase.rpc('get_monthly_revenue', params: {
      'p_coach_id': coachId,
    });

    return List<Map<String, dynamic>>.from(response);
  }
}
```

### 3. Update Calendar Service

Add event type support to existing calendar methods:

```dart
// In lib/services/calendar_service.dart

Future<CalendarEvent> createEvent({
  required String title,
  required DateTime startAt,
  DateTime? endAt,
  String? clientId,
  String? description,
  String eventType = 'session', // NEW PARAMETER
}) async {
  final response = await _supabase.from('calendar_events').insert({
    'title': title,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt?.toIso8601String(),
    'client_id': clientId,
    'description': description,
    'event_type': eventType, // NEW FIELD
    'status': 'scheduled',
  }).select().single();

  return CalendarEvent.fromJson(response);
}

// Get events by type
Future<List<CalendarEvent>> getEventsByType(String eventType) async {
  final response = await _supabase
      .from('calendar_events')
      .select()
      .eq('event_type', eventType)
      .order('start_at', ascending: true);

  return (response as List)
      .map((json) => CalendarEvent.fromJson(json))
      .toList();
}
```

### 4. UI Examples

**Feedback Form Widget**:
```dart
class FeedbackForm extends StatefulWidget {
  final String coachId;
  const FeedbackForm({required this.coachId, Key? key}) : super(key: key);

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _feedbackService = FeedbackService();
  int _rating = 5;
  String _category = FeedbackCategory.general;
  final _textController = TextEditingController();

  Future<void> _submitFeedback() async {
    try {
      await _feedbackService.submitFeedback(
        coachId: widget.coachId,
        rating: _rating,
        category: _category,
        feedbackText: _textController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rating stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => _rating = index + 1),
            );
          }),
        ),

        // Category dropdown
        DropdownButton<String>(
          value: _category,
          items: FeedbackCategory.all.map((cat) {
            return DropdownMenuItem(value: cat, child: Text(cat));
          }).toList(),
          onChanged: (val) => setState(() => _category = val!),
        ),

        // Feedback text
        TextField(
          controller: _textController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Your feedback',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        // Submit button
        ElevatedButton(
          onPressed: _submitFeedback,
          child: const Text('Submit Feedback'),
        ),
      ],
    );
  }
}
```

**Coach Dashboard Stats**:
```dart
class CoachDashboardStats extends StatefulWidget {
  final String coachId;
  const CoachDashboardStats({required this.coachId, Key? key}) : super(key: key);

  @override
  State<CoachDashboardStats> createState() => _CoachDashboardStatsState();
}

class _CoachDashboardStatsState extends State<CoachDashboardStats> {
  final _feedbackService = FeedbackService();
  final _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _feedbackService.getCoachRatingSummary(widget.coachId),
        _paymentService.getCoachPaymentSummary(widget.coachId),
      ]),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final feedbackSummary = snapshot.data![0];
        final paymentSummary = snapshot.data![1];

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCard(
              title: 'Average Rating',
              value: feedbackSummary['average_rating']?.toStringAsFixed(1) ?? '0.0',
              icon: Icons.star,
              color: Colors.amber,
            ),
            _StatCard(
              title: 'Total Feedback',
              value: feedbackSummary['total_feedback'].toString(),
              icon: Icons.message,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Total Revenue',
              value: '\$${paymentSummary['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
```

## Testing

Run the verification script to ensure everything is set up:

```bash
node verify_migration.js
```

## Common Queries Reference

See `supabase/queries/common_queries.sql` for SQL examples.

## Next Steps

1. Create the Dart models (copy from above)
2. Create the service classes
3. Update existing UI to use event types
4. Add feedback collection UI
5. Add payment viewing UI
6. Implement Stripe integration (for payments)

## Support

- Migration file: `supabase/migrations/20251002140000_add_missing_tables_and_columns.sql`
- Full documentation: `MIGRATION_SUMMARY.md`
- SQL examples: `supabase/queries/common_queries.sql`

## Security Notes

- RLS is enabled on all tables
- Clients can only manage their own feedback
- Payment mutations require service_role (Stripe webhooks)
- All foreign keys cascade on delete
