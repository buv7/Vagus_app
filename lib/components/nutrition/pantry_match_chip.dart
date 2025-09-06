import 'package:flutter/material.dart';
import '../../services/nutrition/locale_helper.dart';

/// Reusable chip for displaying pantry match percentage
class PantryMatchChip extends StatelessWidget {
  final double ratio; // 0..1
  final bool isCompact;
  final VoidCallback? onTap;
  
  const PantryMatchChip({
    super.key,
    required this.ratio,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final pct = (ratio * 100).round();
    
    // Determine color based on coverage percentage
    Color chipColor;
    Color textColor;
    
    if (pct >= 80) {
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
    } else if (pct >= 50) {
      chipColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
    } else {
      chipColor = Colors.grey.shade100;
      textColor = Colors.grey.shade600;
    }
    
    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 12,
                color: textColor,
              ),
              const SizedBox(width: 2),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          '${LocaleHelper.t('pantry_match', language)} $pct%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        avatar: Icon(
          Icons.inventory_2_outlined,
          size: 16,
          color: textColor,
        ),
        backgroundColor: chipColor,
        side: BorderSide(color: textColor.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Compact version for tight spaces
class PantryMatchBadge extends StatelessWidget {
  final double ratio;
  final VoidCallback? onTap;
  
  const PantryMatchBadge({
    super.key,
    required this.ratio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    
    Color badgeColor;
    if (pct >= 80) {
      badgeColor = Colors.green;
    } else if (pct >= 50) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.grey;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$pct',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator version
class PantryMatchProgress extends StatelessWidget {
  final double ratio;
  final double size;
  final VoidCallback? onTap;
  
  const PantryMatchProgress({
    super.key,
    required this.ratio,
    this.size = 32.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();
    
    Color progressColor;
    if (pct >= 80) {
      progressColor = Colors.green;
    } else if (pct >= 50) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.grey;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            CircularProgressIndicator(
              value: ratio,
              strokeWidth: 3,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            Center(
              child: Text(
                '$pct',
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
