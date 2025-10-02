import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rest timer widget with notifications and audio cues
class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final String? nextExerciseName;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final bool showNotifications;

  const RestTimerWidget({
    super.key,
    required this.initialSeconds,
    this.nextExerciseName,
    required this.onComplete,
    this.onSkip,
    this.showNotifications = true,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;

    // Pulse animation for last 10 seconds
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.initialSeconds),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _isRunning = true;
    _progressController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      // Vibrate at milestones
      if (_remainingSeconds == 10 || _remainingSeconds == 5 || _remainingSeconds == 3) {
        _vibrate();
      }

      // Pulse animation for last 10 seconds
      if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
        _pulseController.repeat(reverse: true);
      }

      // Play sound at 3, 2, 1
      if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
        _playBeep();
      }

      // Complete
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _pulseController.stop();
        _playCompletionSound();
        _vibrate(duration: 500);
        widget.onComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    _progressController.stop();
    _pulseController.stop();
  }

  void _resumeTimer() {
    _startTimer();
    _progressController.forward(from: _progressController.value);
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
    });
  }

  void _skipTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();
    if (widget.onSkip != null) {
      widget.onSkip!();
    }
  }

  void _vibrate({int duration = 100}) {
    HapticFeedback.mediumImpact();
  }

  void _playBeep() {
    // In production, use audioplayers package
    // AudioPlayer().play(AssetSource('sounds/beep.mp3'));
    HapticFeedback.lightImpact();
  }

  void _playCompletionSound() {
    // In production, use audioplayers package
    // AudioPlayer().play(AssetSource('sounds/complete.mp3'));
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Rest Timer',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Next exercise
            if (widget.nextExerciseName != null)
              Text(
                'Next: ${widget.nextExerciseName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Circular progress timer
            AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _progressController]),
              builder: (context, child) {
                final pulseScale = _remainingSeconds <= 10
                    ? 1.0 + (_pulseController.value * 0.1)
                    : 1.0;

                return Transform.scale(
                  scale: pulseScale,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),

                        // Progress circle
                        CircularProgressIndicator(
                          value: _remainingSeconds / widget.initialSeconds,
                          strokeWidth: 12,
                          color: _getTimerColor(theme),
                        ),

                        // Time display
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(theme),
                              ),
                            ),
                            Text(
                              'seconds',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Add 15s
                _buildControlButton(
                  icon: Icons.add,
                  label: '+15s',
                  onPressed: () => _addTime(15),
                  theme: theme,
                ),

                // Add 30s
                _buildControlButton(
                  icon: Icons.add,
                  label: '+30s',
                  onPressed: () => _addTime(30),
                  theme: theme,
                ),

                // Pause/Resume
                _buildControlButton(
                  icon: _isRunning ? Icons.pause : Icons.play_arrow,
                  label: _isRunning ? 'Pause' : 'Resume',
                  onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Skip button
            TextButton(
              onPressed: _skipTimer,
              child: const Text('Skip Rest'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$remainingSeconds';
    }
  }

  Color _getTimerColor(ThemeData theme) {
    if (_remainingSeconds <= 5) {
      return theme.colorScheme.error;
    } else if (_remainingSeconds <= 10) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }
}

/// Compact rest timer banner for display at top of screen
class RestTimerBanner extends StatefulWidget {
  final int initialSeconds;
  final String? nextExerciseName;
  final VoidCallback onComplete;
  final VoidCallback? onExpand;
  final VoidCallback? onSkip;

  const RestTimerBanner({
    super.key,
    required this.initialSeconds,
    this.nextExerciseName,
    required this.onComplete,
    this.onExpand,
    this.onSkip,
  });

  @override
  State<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends State<RestTimerBanner> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _remainingSeconds / widget.initialSeconds;

    return Material(
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: widget.onExpand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  // Timer icon
                  Icon(
                    Icons.timer,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),

                  // Time and next exercise
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resting: ${_formatTime(_remainingSeconds)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (widget.nextExerciseName != null)
                          Text(
                            'Next: ${widget.nextExerciseName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Skip button
                  if (widget.onSkip != null)
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: theme.colorScheme.onPrimaryContainer,
                      onPressed: widget.onSkip,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Progress bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${remainingSeconds}s';
    }
  }
}