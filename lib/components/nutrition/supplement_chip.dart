import 'package:flutter/material.dart';
import '../../widgets/supplements/pill_icon.dart';

/// Supplement chip for displaying supplement information
class SupplementChip extends StatelessWidget {
  final String name;
  final String? timing;
  final VoidCallback? onTap;
  
  const SupplementChip({
    super.key,
    required this.name,
    this.timing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = timing == null || timing!.isEmpty 
        ? name 
        : '$name • $timing';
    
    return InputChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: const PillIcon(size: 16),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
