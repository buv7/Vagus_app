import 'package:flutter/material.dart';
import '../../services/health/health_service.dart';
import '../../services/ocr/ocr_cardio_service.dart';
import '../../theme/design_tokens.dart';

class HealthConnectionsScreen extends StatefulWidget {
  const HealthConnectionsScreen({super.key});

  @override
  State<HealthConnectionsScreen> createState() => _HealthConnectionsScreenState();
}

class _HealthConnectionsScreenState extends State<HealthConnectionsScreen> {
  final HealthService _healthService = HealthService();
  final OCRCardioService _ocrService = OCRCardioService();
  
  // List<HealthSource> _connectedSources = [];
  bool _isLoading = false;
  final Map<HealthProvider, bool> _connectionStatus = {};
  
  // Per-metric toggles (stored locally for now)
  final Map<HealthDataType, bool> _metricToggles = {
    HealthDataType.steps: true,
    HealthDataType.distance: true,
    HealthDataType.calories: true,
    HealthDataType.heartRate: true,
    HealthDataType.sleep: true,
    HealthDataType.weight: false,
    HealthDataType.bodyFat: false,
    HealthDataType.bloodPressure: false,
    HealthDataType.bloodGlucose: false,
  };

  @override
  void initState() {
    super.initState();
    _loadConnectedSources();
    _checkConnectionStatus();
  }

  Future<void> _loadConnectedSources() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement when health service is connected to database
      debugPrint('Loading connected sources - stubbed');
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading sources: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkConnectionStatus() async {
    for (final provider in HealthProvider.values) {
      final adapter = _healthService.getAdapter(provider);
      final isConnected = await adapter.isConnected();
      setState(() {
        _connectionStatus[provider] = isConnected;
      });
    }
  }

  Future<void> _connectToProvider(HealthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      final success = await _healthService.connect(provider);
      if (!mounted || !context.mounted) return;
      if (success) {
        setState(() {
          _connectionStatus[provider] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${provider.name}'),
            backgroundColor: DesignTokens.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${provider.name}'),
            backgroundColor: DesignTokens.warn,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error connecting to $provider: $e');
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to ${provider.name}'),
            backgroundColor: DesignTokens.warn,
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
  }

  Future<void> _disconnectFromProvider(HealthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await _healthService.disconnect(provider);
      if (!mounted || !context.mounted) return;
      setState(() {
        _connectionStatus[provider] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from ${provider.name}'),
          backgroundColor: DesignTokens.warn,
        ),
      );
    } catch (e) {
      debugPrint('Error disconnecting from $provider: $e');
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting from ${provider.name}'),
            backgroundColor: DesignTokens.warn,
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
  }

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);
    try {
      await _healthService.initialImport(days: 30);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health data synced successfully'),
          backgroundColor: DesignTokens.success,
        ),
      );
    } catch (e) {
      debugPrint('Error syncing health data: $e');
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing health data: $e'),
            backgroundColor: DesignTokens.warn,
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
  }

  Future<void> _processOCRCardio() async {
    setState(() => _isLoading = true);
    try {
      final result = await _ocrService.processWorkoutImage();
      if (!mounted || !context.mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR processed: ${result.sport ?? 'Unknown'} workout'),
            backgroundColor: DesignTokens.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR processing failed'),
            backgroundColor: DesignTokens.warn,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing OCR: $e');
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing OCR: $e'),
            backgroundColor: DesignTokens.warn,
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
  }

  Widget _buildProviderCard(HealthProvider provider) {
    final adapter = _healthService.getAdapter(provider);
    final isConnected = _connectionStatus[provider] ?? false;
    final isSupported = adapter.isSupported;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getProviderIcon(provider),
                  color: isConnected ? DesignTokens.success : DesignTokens.ink500,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adapter.platformName,
                        style: DesignTokens.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isSupported ? 'Available' : 'Not supported on this platform',
                        style: DesignTokens.bodySmall.copyWith(
                          color: DesignTokens.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSupported)
                  Switch(
                    value: isConnected,
                    onChanged: (value) {
                      if (value) {
                        _connectToProvider(provider);
                      } else {
                        _disconnectFromProvider(provider);
                      }
                    },
                    activeColor: DesignTokens.success,
                  ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: DesignTokens.space12),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: DesignTokens.success,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.space8),
                  Text(
                    'Connected',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.success,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last sync: ${_getLastSyncText(provider)}',
                    style: DesignTokens.bodySmall.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                ],
              ),
            ],
            if (isSupported && !isConnected) ...[
              const SizedBox(height: DesignTokens.space12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _connectToProvider(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.blue600,
                    foregroundColor: DesignTokens.neutralWhite,
                  ),
                  child: const Text('Connect'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(HealthProvider provider) {
    switch (provider) {
      case HealthProvider.healthkit:
        return Icons.apple;
      case HealthProvider.healthconnect:
        return Icons.health_and_safety;
      case HealthProvider.googlefit:
        return Icons.fitness_center;
      case HealthProvider.hms:
        return Icons.phone_android;
    }
  }

  String _getLastSyncText(HealthProvider provider) {
    // TODO: Get actual last sync time from database
    return 'Never';
  }

  String _getMetricDisplayName(HealthDataType type) {
    switch (type) {
      case HealthDataType.steps:
        return 'Steps';
      case HealthDataType.distance:
        return 'Distance';
      case HealthDataType.calories:
        return 'Calories';
      case HealthDataType.heartRate:
        return 'Heart Rate';
      case HealthDataType.sleep:
        return 'Sleep';
      case HealthDataType.weight:
        return 'Weight';
      case HealthDataType.bodyFat:
        return 'Body Fat';
      case HealthDataType.bloodPressure:
        return 'Blood Pressure';
      case HealthDataType.bloodGlucose:
        return 'Blood Glucose';
    }
  }

  String _getMetricDescription(HealthDataType type) {
    switch (type) {
      case HealthDataType.steps:
        return 'Daily step count and activity';
      case HealthDataType.distance:
        return 'Walking, running, and workout distances';
      case HealthDataType.calories:
        return 'Active and total calorie burn';
      case HealthDataType.heartRate:
        return 'Heart rate during workouts and rest';
      case HealthDataType.sleep:
        return 'Sleep duration and quality metrics';
      case HealthDataType.weight:
        return 'Body weight tracking';
      case HealthDataType.bodyFat:
        return 'Body fat percentage';
      case HealthDataType.bloodPressure:
        return 'Systolic and diastolic readings';
      case HealthDataType.bloodGlucose:
        return 'Blood sugar levels';
    }
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connections'),
        backgroundColor: DesignTokens.ink50,
        foregroundColor: DesignTokens.ink900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DesignTokens.accentGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Platforms Section
                  Text(
                    'Health Platforms',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'Connect your health platforms to automatically sync workout data, steps, and sleep information.',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  
                  // Provider Cards
                  ...HealthProvider.values.map(_buildProviderCard),
                  
                  const SizedBox(height: DesignTokens.space24),
                  
                  // Per-Metric Toggles Section
                  Text(
                    'Data Types',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'Choose which health metrics to sync from your connected platforms.',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        children: _metricToggles.entries.map((entry) {
                          return SwitchListTile(
                            title: Text(_getMetricDisplayName(entry.key)),
                            subtitle: Text(_getMetricDescription(entry.key)),
                            value: entry.value,
                            onChanged: (value) {
                              setState(() {
                                _metricToggles[entry.key] = value;
                              });
                            },
                            activeColor: DesignTokens.success,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space24),
                  
                  // Sync Section
                  Text(
                    'Data Sync',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'Manually sync your health data or set up automatic syncing.',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sync,
                                color: DesignTokens.blue600,
                                size: 24,
                              ),
                              const SizedBox(width: DesignTokens.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manual Sync',
                                      style: DesignTokens.titleMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Sync the last 30 days of health data',
                                      style: DesignTokens.bodySmall.copyWith(
                                        color: DesignTokens.ink500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.space16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _syncNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.blue600,
                                foregroundColor: DesignTokens.neutralWhite,
                              ),
                              child: const Text('Sync Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space24),
                  
                  // OCR Cardio Section
                  Text(
                    'OCR Cardio',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'Take a photo of your workout summary to automatically extract workout data.',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                color: DesignTokens.success,
                                size: 24,
                              ),
                              const SizedBox(width: DesignTokens.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Process Workout Image',
                                      style: DesignTokens.titleMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Extract workout data from photos',
                                      style: DesignTokens.bodySmall.copyWith(
                                        color: DesignTokens.ink500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.space16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _processOCRCardio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.success,
                                foregroundColor: DesignTokens.neutralWhite,
                              ),
                              child: const Text('📸 Process Image'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DesignTokens.space24),
                  
                  // Package Proposals Section
                  Text(
                    'Package Proposals',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    'The following packages are proposed for approval to enable full health integration:',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.ink500,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPackageProposal(
                            'health',
                            'iOS/Android Health Integration',
                            'Provides cross-platform health data access for HealthKit, Health Connect, Google Fit, and HMS.',
                          ),
                          const SizedBox(height: DesignTokens.space12),
                          _buildPackageProposal(
                            'health_connect',
                            'Android Health Connect',
                            'Native Android Health Connect integration for Android 14+ devices.',
                          ),
                          const SizedBox(height: DesignTokens.space12),
                          _buildPackageProposal(
                            'google_mlkit_text_recognition',
                            'OCR Text Recognition',
                            'Google ML Kit for on-device text recognition from workout images.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageProposal(String package, String title, String description) {
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
          Row(
            children: [
              const Icon(
                Icons.inventory,
                color: DesignTokens.blue600,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                package,
                style: DesignTokens.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: DesignTokens.ink100,
                  color: DesignTokens.ink700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space8),
          Text(
            title,
            style: DesignTokens.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
                      Text(
              description,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500,
              ),
            ),
        ],
      ),
    );
  }
}
