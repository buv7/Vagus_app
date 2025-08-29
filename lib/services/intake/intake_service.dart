import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class IntakeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Form Management
  Future<Map<String, dynamic>?> getDefaultFormForCoach(String coachId) async {
    try {
      // First try to get coach-specific form
      final coachForm = await _supabase
          .from('intake_forms')
          .select('*, intake_form_versions(*)')
          .eq('coach_id', coachId)
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (coachForm != null) {
        return coachForm;
      }

      // Fall back to system default form (coach_id IS NULL)
      final systemForm = await _supabase
                  .from('intake_forms')
        .select('*, intake_form_versions(*)')
        .filter('coach_id', 'is', null)
        .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return systemForm;
    } catch (e) {
      debugPrint('Error getting default form: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createOrCloneForm({
    required String coachId,
    required String title,
    String? sourceFormId,
    Map<String, dynamic>? configJson,
  }) async {
    try {
      final Map<String, dynamic> formData = {
        'coach_id': coachId,
        'title': title,
        'status': 'draft',
        'config_json': configJson ?? {},
      };

      if (sourceFormId != null) {
        // Clone existing form
        final sourceForm = await _supabase
            .from('intake_forms')
            .select('*, intake_form_versions(*)')
            .eq('id', sourceFormId)
            .single();

        formData['config_json'] = sourceForm['config_json'];
        
        final newForm = await _supabase
            .from('intake_forms')
            .insert(formData)
            .select()
            .single();

        // Clone the latest version
        final latestVersion = (sourceForm['intake_form_versions'] as List)
            .where((v) => v['active'] == true)
            .first;

        await _supabase.from('intake_form_versions').insert({
          'form_id': newForm['id'],
          'version': 1,
          'schema_json': latestVersion['schema_json'],
          'waiver_md': latestVersion['waiver_md'],
          'active': true,
        });

        return newForm;
      } else {
        // Create new form
        return await _supabase
            .from('intake_forms')
            .insert(formData)
            .select()
            .single();
      }
    } catch (e) {
      debugPrint('Error creating/cloning form: $e');
      return null;
    }
  }

  Future<bool> publishVersion({
    required String formId,
    required Map<String, dynamic> schemaJson,
    String? waiverMd,
  }) async {
    try {
      // Get current version number
      final currentVersions = await _supabase
          .from('intake_form_versions')
          .select('version')
          .eq('form_id', formId)
          .order('version', ascending: false)
          .limit(1);

      final newVersion = currentVersions.isNotEmpty 
          ? (currentVersions.first['version'] as int) + 1 
          : 1;

      // Deactivate current active version
      await _supabase
          .from('intake_form_versions')
          .update({'active': false})
          .eq('form_id', formId)
          .eq('active', true);

      // Create new version
      await _supabase.from('intake_form_versions').insert({
        'form_id': formId,
        'version': newVersion,
        'schema_json': schemaJson,
        'waiver_md': waiverMd,
        'active': true,
      });

      // Update form status to published
      await _supabase
          .from('intake_forms')
          .update({'status': 'published'})
          .eq('id', formId);

      return true;
    } catch (e) {
      debugPrint('Error publishing version: $e');
      return false;
    }
  }

  // Response Management
  Future<Map<String, dynamic>?> startOrResumeResponse({
    required String formId,
    required String clientId,
  }) async {
    try {
      // Check if response already exists
      final existingResponse = await _supabase
          .from('intake_responses')
          .select()
          .eq('form_id', formId)
          .eq('client_id', clientId)
          .maybeSingle();

      if (existingResponse != null) {
        return existingResponse;
      }

      // Create new response
      return await _supabase
          .from('intake_responses')
          .insert({
            'form_id': formId,
            'client_id': clientId,
            'status': 'draft',
            'answers_json': {},
          })
          .select()
          .single();
    } catch (e) {
      debugPrint('Error starting/resuming response: $e');
      return null;
    }
  }

  Future<bool> saveDraft({
    required String responseId,
    required Map<String, dynamic> answersPatch,
  }) async {
    try {
      // Get current answers
      final currentResponse = await _supabase
          .from('intake_responses')
          .select('answers_json')
          .eq('id', responseId)
          .single();

      final Map<String, dynamic> currentAnswers = 
          Map<String, dynamic>.from(currentResponse['answers_json'] ?? {});
      
      // Merge with patch
      currentAnswers.addAll(answersPatch);

      await _supabase
          .from('intake_responses')
          .update({'answers_json': currentAnswers})
          .eq('id', responseId);

      return true;
    } catch (e) {
      debugPrint('Error saving draft: $e');
      return false;
    }
  }

  Future<bool> submitResponse({
    required String responseId,
    required String signatureSvg,
    required String waiverHash,
  }) async {
    try {
      // Update response status
      await _supabase
          .from('intake_responses')
          .update({'status': 'submitted'})
          .eq('id', responseId);

      // Create signature record
      await _supabase.from('intake_signatures').insert({
        'response_id': responseId,
        'signed_by': _supabase.auth.currentUser!.id,
        'signature_svg': signatureSvg,
        'waiver_hash': waiverHash,
      });

      return true;
    } catch (e) {
      debugPrint('Error submitting response: $e');
      return false;
    }
  }

  Future<bool> approveResponse(String responseId) async {
    try {
      await _supabase
          .from('intake_responses')
          .update({'status': 'approved'})
          .eq('id', responseId);

      return true;
    } catch (e) {
      debugPrint('Error approving response: $e');
      return false;
    }
  }

  Future<bool> rejectResponse({
    required String responseId,
    required String reason,
  }) async {
    try {
      // For now, just update status. In future, we could add a rejection_reason field
      await _supabase
          .from('intake_responses')
          .update({'status': 'rejected'})
          .eq('id', responseId);

      return true;
    } catch (e) {
      debugPrint('Error rejecting response: $e');
      return false;
    }
  }

  Future<String?> getResponseStatus(String clientId) async {
    try {
      final response = await _supabase
          .from('intake_responses')
          .select('status')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['status'];
    } catch (e) {
      debugPrint('Error getting response status: $e');
      return null;
    }
  }

  // Form Management for Coaches
  Future<List<Map<String, dynamic>>> getCoachForms(String coachId) async {
    try {
      final response = await _supabase
          .from('intake_forms')
          .select('*, intake_form_versions(*)')
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting coach forms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFormResponses({
    required String formId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('intake_responses')
          .select('*, profiles(full_name, email)')
          .eq('form_id', formId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting form responses: $e');
      return [];
    }
  }

  Future<bool> setDefaultForm(String formId) async {
    try {
      // For now, we'll just mark it as published
      // In a more complex system, we might have a separate default_form_id field
      await _supabase
          .from('intake_forms')
          .update({'status': 'published'})
          .eq('id', formId);

      return true;
    } catch (e) {
      debugPrint('Error setting default form: $e');
      return false;
    }
  }

  // Google Forms Integration (stubs for future)
  Future<bool> linkGoogleForm({
    required String formId,
    required String externalId,
    Map<String, dynamic>? mapJson,
  }) async {
    // TODO: Implement Google Forms integration
    debugPrint('Google Forms integration not yet implemented');
    return false;
  }

  Future<bool> setupWebhook({
    required String formId,
    required String url,
    required String secret,
  }) async {
    // TODO: Implement webhook setup
    debugPrint('Webhook setup not yet implemented');
    return false;
  }

  // Helper methods
  Map<String, dynamic> calculateRiskScore(Map<String, dynamic> answers) {
    int score = 0;
    
    // PAR-Q scoring
    final parqFields = [
      'heart_condition', 'chest_pain', 'dizziness', 
      'bone_problem', 'blood_pressure', 'physical_activity'
    ];
    
    for (String field in parqFields) {
      if (answers[field] == 'Yes') {
        score += 1;
      }
    }
    
    // Additional risk factors
    if (answers['age'] != null) {
      final int age = int.tryParse(answers['age'].toString()) ?? 0;
      if (age > 65) score += 1;
    }
    
    if (answers['medical_conditions'] != null && 
        answers['medical_conditions'].toString().isNotEmpty) {
      score += 1;
    }
    
    return {
      'score': score,
      'risk_level': score == 0 ? 'low' : score <= 2 ? 'moderate' : 'high',
      'requires_clearance': score > 0,
    };
  }
}
