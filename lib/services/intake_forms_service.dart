import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/intake/intake_form.dart';

class IntakeFormsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get intake form for a coach
  Future<IntakeForm?> getCoachForm(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_intake_forms')
          .select()
          .eq('coach_id', coachId)
          .maybeSingle();

      if (response == null) return null;

      return IntakeForm.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch coach intake form: $e');
    }
  }

  /// Create or update intake form
  Future<String> createOrUpdateForm(IntakeForm form) async {
    try {
      final data = form.toMap();
      data.remove('id'); // Remove id for insert
      data.remove('updated_at'); // Let the database handle this

      final response = await _supabase
          .from('coach_intake_forms')
          .upsert(data)
          .select()
          .single();

      return response['id']?.toString() ?? '';
    } catch (e) {
      throw Exception('Failed to save intake form: $e');
    }
  }

  /// Get default form for a coach (with mandatory allergy questions)
  Future<IntakeForm> getDefaultFormForCoach(String coachId) async {
    try {
      // Try to get existing form
      final existingForm = await getCoachForm(coachId);
      if (existingForm != null) {
        return existingForm;
      }

      // Create default form with mandatory allergy questions
      final defaultForm = _createDefaultForm(coachId);
      final formId = await createOrUpdateForm(defaultForm);
      
      return defaultForm.copyWith(id: formId);
    } catch (e) {
      throw Exception('Failed to get default form: $e');
    }
  }

  IntakeForm _createDefaultForm(String coachId) {
    final questions = [
      // Mandatory allergy questions
      FormQuestion(
        id: 'food_allergies',
        type: 'textarea',
        title: 'Do you have any food allergies? List them.',
        description: 'Please list all food allergies you have. If none, write "None".',
        required: true,
        options: {},
        order: 1,
      ),
      FormQuestion(
        id: 'substance_allergies',
        type: 'textarea',
        title: 'Do you have any drug or supplement allergies? List them.',
        description: 'Please list all drug or supplement allergies you have. If none, write "None".',
        required: true,
        options: {},
        order: 2,
      ),
      // Basic health questions
      FormQuestion(
        id: 'medical_conditions',
        type: 'textarea',
        title: 'Do you have any medical conditions?',
        description: 'Please list any medical conditions that might affect your training.',
        required: false,
        options: {},
        order: 3,
      ),
      FormQuestion(
        id: 'medications',
        type: 'textarea',
        title: 'Are you currently taking any medications?',
        description: 'Please list any medications you are currently taking.',
        required: false,
        options: {},
        order: 4,
      ),
      FormQuestion(
        id: 'fitness_goals',
        type: 'textarea',
        title: 'What are your fitness goals?',
        description: 'Describe what you want to achieve with your training.',
        required: true,
        options: {},
        order: 5,
      ),
      FormQuestion(
        id: 'experience_level',
        type: 'select',
        title: 'What is your fitness experience level?',
        description: 'Select the option that best describes your experience.',
        required: true,
        options: {
          'choices': ['Beginner', 'Intermediate', 'Advanced', 'Expert']
        },
        order: 6,
      ),
      FormQuestion(
        id: 'workout_frequency',
        type: 'select',
        title: 'How often do you want to work out?',
        description: 'Select your preferred workout frequency.',
        required: true,
        options: {
          'choices': ['2-3 times per week', '4-5 times per week', '6-7 times per week', 'Daily']
        },
        order: 7,
      ),
      FormQuestion(
        id: 'available_equipment',
        type: 'checkbox',
        title: 'What equipment do you have access to?',
        description: 'Select all equipment you have available.',
        required: false,
        options: {
          'choices': [
            'Gym membership',
            'Home gym',
            'Dumbbells',
            'Barbell',
            'Resistance bands',
            'Cardio equipment',
            'Bodyweight only',
            'Other'
          ]
        },
        order: 8,
      ),
      FormQuestion(
        id: 'dietary_preferences',
        type: 'select',
        title: 'Do you follow any specific dietary preferences?',
        description: 'Select your dietary approach.',
        required: false,
        options: {
          'choices': [
            'No specific diet',
            'Vegetarian',
            'Vegan',
            'Keto',
            'Paleo',
            'Mediterranean',
            'Low-carb',
            'Other'
          ]
        },
        order: 9,
      ),
      FormQuestion(
        id: 'additional_info',
        type: 'textarea',
        title: 'Any additional information?',
        description: 'Share any other information that might be helpful for your coach.',
        required: false,
        options: {},
        order: 10,
      ),
    ];

    return IntakeForm(
      id: '',
      coachId: coachId,
      schema: {
        'title': 'Client Intake Form',
        'description': 'Please fill out this form to help your coach create a personalized program for you.',
        'questions': questions.map((q) => q.toMap()).toList(),
      },
      updatedAt: DateTime.now(),
    );
  }

  /// Submit intake response
  Future<String> submitResponse(IntakeResponse response) async {
    try {
      final data = response.toMap();
      data.remove('id'); // Let the database generate this
      data.remove('created_at'); // Let the database handle this

      final responseId = await _supabase
          .from('intake_responses')
          .insert(data)
          .select()
          .single();

      final responseIdStr = responseId['id']?.toString() ?? '';
      
      // Update client allergies based on response
      await _updateClientAllergies(response);
      
      return responseIdStr;
    } catch (e) {
      throw Exception('Failed to submit intake response: $e');
    }
  }

  /// Update client allergies from intake response
  Future<void> _updateClientAllergies(IntakeResponse response) async {
    try {
      final foodAllergies = response.getFoodAllergies();
      final substanceAllergies = response.getSubstanceAllergies();

      await _supabase
          .from('client_allergies')
          .upsert({
            'client_id': response.clientId,
            'foods': foodAllergies,
            'substances': substanceAllergies,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Don't throw - allergy update is not critical
      print('Failed to update client allergies: $e');
    }
  }

  /// Get client allergies
  Future<ClientAllergies?> getClientAllergies(String clientId) async {
    try {
      final response = await _supabase
          .from('client_allergies')
          .select()
          .eq('client_id', clientId)
          .maybeSingle();

      if (response == null) return null;

      return ClientAllergies.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch client allergies: $e');
    }
  }

  /// Update client allergies manually
  Future<void> updateClientAllergies(ClientAllergies allergies) async {
    try {
      final data = allergies.toMap();
      data.remove('updated_at'); // Let the database handle this

      await _supabase
          .from('client_allergies')
          .upsert(data);
    } catch (e) {
      throw Exception('Failed to update client allergies: $e');
    }
  }

  /// Get intake responses for a coach
  Future<List<IntakeResponse>> getResponsesForCoach(String coachId) async {
    try {
      final response = await _supabase
          .from('intake_responses')
          .select('''
            *,
            coach_intake_forms!inner(coach_id)
          ''')
          .eq('coach_intake_forms.coach_id', coachId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((resp) => IntakeResponse.fromMap(resp as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch intake responses: $e');
    }
  }

  /// Get intake response for a client
  Future<IntakeResponse?> getResponseForClient(String clientId, String formId) async {
    try {
      final response = await _supabase
          .from('intake_responses')
          .select()
          .eq('client_id', clientId)
          .eq('form_id', formId)
          .maybeSingle();

      if (response == null) return null;

      return IntakeResponse.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch client intake response: $e');
    }
  }

  /// Check for allergy violations in nutrition plan
  Future<List<String>> checkAllergyViolations(String clientId, List<String> foodItems) async {
    try {
      final allergies = await getClientAllergies(clientId);
      if (allergies == null) return [];

      final violations = <String>[];
      for (final food in foodItems) {
        if (allergies.hasFoodAllergy(food)) {
          violations.add(food);
        }
      }
      return violations;
    } catch (e) {
      // Return empty list if there's an error
      return [];
    }
  }

  /// Record allergy violation
  Future<void> recordAllergyViolation(String coachId, String clientId, String foodItem) async {
    try {
      // Get current violation count
      final response = await _supabase
          .from('plan_violation_counts')
          .select()
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .maybeSingle();

      final currentCount = response?['violation_count'] as int? ?? 0;
      final newCount = currentCount + 1;

      await _supabase
          .from('plan_violation_counts')
          .upsert({
            'coach_id': coachId,
            'client_id': clientId,
            'violation_count': newCount,
            'last_violation_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Don't throw - violation recording is not critical
      print('Failed to record allergy violation: $e');
    }
  }

  /// Get violation count for coach-client pair
  Future<int> getViolationCount(String coachId, String clientId) async {
    try {
      final response = await _supabase
          .from('plan_violation_counts')
          .select()
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .maybeSingle();

      return response?['violation_count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

// Extension to add copyWith method to IntakeForm
extension IntakeFormExtension on IntakeForm {
  IntakeForm copyWith({
    String? id,
    String? coachId,
    Map<String, dynamic>? schema,
    DateTime? updatedAt,
  }) {
    return IntakeForm(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      schema: schema ?? this.schema,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
