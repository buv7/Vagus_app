import 'package:flutter/material.dart';
import '../../services/ai/ai_usage_service.dart';
import '../../services/notifications/notification_test_helper.dart';
import 'ai_usage_meter.dart';

/// Test widget for AI usage tracking system
/// Allows manual testing of usage updates and displays current data
class AIUsageTestWidget extends StatefulWidget {
  const AIUsageTestWidget({super.key});

  @override
  State<AIUsageTestWidget> createState() => _AIUsageTestWidgetState();
}

class _AIUsageTestWidgetState extends State<AIUsageTestWidget> {
  bool _isRecording = false;
  String? _lastResult;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 AI Usage Test Panel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : () => _testBasicUsage(50),
                    icon: const Icon(Icons.add),
                    label: const Text('Test 50 Tokens'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : () => _testBasicUsage(150),
                    icon: const Icon(Icons.add),
                    label: const Text('Test 150 Tokens'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : () => _testDetailedUsage(75),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Test Detailed (75)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? null : () => _refreshUsage(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // OneSignal Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRecording ? null : _testOneSignal,
                icon: const Icon(Icons.notifications),
                label: const Text('Test OneSignal Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status and results
            if (_isRecording)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Recording usage...'),
                ],
              ),
            
            if (_lastResult != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastResult!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            const SizedBox(height: 16),
            
            // AI Usage Meter (compact mode)
            const AIUsageMeter(isCompact: true),
          ],
        ),
      ),
    );
  }

  Future<void> _testBasicUsage(int tokens) async {
    _setRecording(true);
    _clearMessages();
    
    try {
      final success = await AIUsageService.instance.recordUsage(tokensUsed: tokens);
      
      if (success) {
        setState(() {
          _lastResult = '✅ Successfully recorded $tokens tokens';
        });
        
        // Refresh the usage meter
        await _refreshUsage();
      } else {
        setState(() {
          _error = '❌ Failed to record $tokens tokens';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Error: $e';
      });
    } finally {
      _setRecording(false);
    }
  }

  Future<void> _testDetailedUsage(int tokens) async {
    _setRecording(true);
    _clearMessages();
    
    try {
      final success = await AIUsageService.instance.recordUsageWithMetadata(
        tokensUsed: tokens,
        requestType: 'test_nutrition_plan',
        requestId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        additionalData: {
          'test_type': 'detailed_tracking',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        setState(() {
          _lastResult = '✅ Successfully recorded $tokens tokens with metadata';
        });
        
        // Refresh the usage meter
        await _refreshUsage();
      } else {
        setState(() {
          _error = '❌ Failed to record $tokens tokens with metadata';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Error: $e';
      });
    } finally {
      _setRecording(false);
    }
  }

  Future<void> _refreshUsage() async {
    try {
      final usage = await AIUsageService.instance.getCurrentUsage();
      if (usage != null) {
        setState(() {
          _lastResult = '📊 Usage refreshed: ${usage['requests_this_month'] ?? 0} requests, ${usage['tokens_this_month'] ?? 0} tokens this month';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Failed to refresh usage: $e';
      });
    }
  }

  Future<void> _testOneSignal() async {
    _setRecording(true);
    _clearMessages();
    
    try {
      final success = await NotificationTestHelper.instance.sendTestNotification(
        title: '🧪 VAGUS Test',
        message: 'OneSignal is working correctly!',
        additionalData: {
          'test_type': 'onesignal_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        setState(() {
          _lastResult = '✅ OneSignal test notification sent successfully!';
        });
      } else {
        setState(() {
          _error = '❌ Failed to send OneSignal test notification';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Error testing OneSignal: $e';
      });
    } finally {
      _setRecording(false);
    }
  }

  void _setRecording(bool recording) {
    setState(() {
      _isRecording = recording;
    });
  }

  void _clearMessages() {
    setState(() {
      _lastResult = null;
      _error = null;
    });
  }
}
