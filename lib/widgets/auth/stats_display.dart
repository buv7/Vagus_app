import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsDisplay extends StatefulWidget {
  const StatsDisplay({super.key});

  @override
  State<StatsDisplay> createState() => _StatsDisplayState();
}

class _StatsDisplayState extends State<StatsDisplay> {
  int _coachCount = 120; // Default fallback value
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoachCount();
  }

  Future<void> _fetchCoachCount() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'coach');

      if (mounted) {
        setState(() {
          _coachCount = response.length;
          _loading = false;
        });
      }
    } catch (e) {
      // If fetch fails, keep default value
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      debugPrint('Failed to fetch coach count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StatItem(
            value: 100,
            suffix: '%',
            label: 'CUSTOMISED PLANS',
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _StatItem(
            value: _coachCount,
            suffix: '+',
            label: 'ELITE COACHES',
            isLoading: _loading,
          ),
        ),
        const SizedBox(width: 32),
        const Expanded(
          child: _StatItem(
            value: 24,
            suffix: '/7',
            label: 'ADAPTIVE AI',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String suffix;
  final String label;
  final bool isLoading;

  const _StatItem({
    required this.value,
    required this.suffix,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          tween: Tween(begin: 0, end: value.toDouble()),
          builder: (context, animatedValue, child) {
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: isLoading ? '...' : animatedValue.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C8FF),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isLoading)
                    TextSpan(
                      text: suffix,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF00C8FF).withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
