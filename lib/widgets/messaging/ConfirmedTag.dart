import 'package:flutter/material.dart';

class ConfirmedTag extends StatelessWidget {
  const ConfirmedTag({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
      ),
      child: Text(
        'Confirmed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
