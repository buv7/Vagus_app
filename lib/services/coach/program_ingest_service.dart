import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/program_ingest/program_ingest_job.dart';

class ProgramIngestService {
  static final ProgramIngestService _instance = ProgramIngestService._internal();
  factory ProgramIngestService() => _instance;
  ProgramIngestService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a job from pasted text
  Future<String> createJobFromText({
    required String clientId,
    required String coachId,
    required String text,
  }) async {
    try {
      final response = await _supabase.from('program_ingest_jobs').insert({
        'client_id': clientId,
        'coach_id': coachId,
        'source': 'text',
        'raw_text': text,
        'status': 'queued',
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating text job: $e');
      rethrow;
    }
  }

  /// Create a job from uploaded file
  Future<String> createJobFromFile({
    required String clientId,
    required String coachId,
    required XFile file,
  }) async {
    try {
      // Upload file to storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final fileBytes = await file.readAsBytes();
      
      await _supabase.storage.from('program_ingest').uploadBinary(fileName, fileBytes);
      
      // Create job record
      final response = await _supabase.from('program_ingest_jobs').insert({
        'client_id': clientId,
        'coach_id': coachId,
        'source': 'file',
        'storage_path': fileName,
        'status': 'queued',
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating file job: $e');
      rethrow;
    }
  }

  /// Get a job by ID
  Future<ProgramIngestJob> getJob(String id) async {
    try {
      final response = await _supabase
          .from('program_ingest_jobs')
          .select('*')
          .eq('id', id)
          .single();

      return ProgramIngestJob.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching job: $e');
      rethrow;
    }
  }

  /// Get result for a job
  Future<ProgramIngestResult?> getResult(String jobId) async {
    try {
      final response = await _supabase
          .from('program_ingest_results')
          .select('*')
          .eq('job_id', jobId)
          .maybeSingle();

      if (response == null) return null;
      return ProgramIngestResult.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching result: $e');
      return null;
    }
  }

  /// Trigger the Edge Function to process the job
  Future<void> triggerEdge(String jobId) async {
    try {
      // Call the Edge Function
      final response = await _supabase.functions.invoke(
        'program_ingest',
        body: {'jobId': jobId},
      );

      print('Edge function response: $response');
    } catch (e) {
      print('Error triggering edge function: $e');
      rethrow;
    }
  }

  /// Stream job status updates
  Stream<ProgramIngestJob> streamJob(String jobId) {
    return _supabase
        .from('program_ingest_jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((data) => ProgramIngestJob.fromJson(data.first as Map<String, dynamic>));
  }

  /// Get all jobs for a coach
  Future<List<ProgramIngestJob>> getCoachJobs(String coachId) async {
    try {
      final response = await _supabase
          .from('program_ingest_jobs')
          .select('*')
          .eq('coach_id', coachId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProgramIngestJob.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching coach jobs: $e');
      return [];
    }
  }

  /// Get all jobs for a client
  Future<List<ProgramIngestJob>> getClientJobs(String clientId) async {
    try {
      final response = await _supabase
          .from('program_ingest_jobs')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProgramIngestJob.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching client jobs: $e');
      return [];
    }
  }

  /// Delete a job and its associated data
  Future<void> deleteJob(String jobId) async {
    try {
      // Get the job to find storage path
      final job = await getJob(jobId);
      
      // Delete from storage if it's a file job
      if (job.source == 'file' && job.storagePath != null) {
        try {
          await _supabase.storage.from('program_ingest').remove([job.storagePath!]);
        } catch (e) {
          print('Error deleting file from storage: $e');
          // Continue with database deletion even if storage deletion fails
        }
      }
      
      // Delete from database (cascade will handle results)
      await _supabase.from('program_ingest_jobs').delete().eq('id', jobId);
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }
}
