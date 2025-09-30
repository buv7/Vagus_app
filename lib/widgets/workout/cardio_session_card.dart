import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/workout/cardio_session.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../theme/design_tokens.dart';

/// Cardio session card widget
///
/// Shows:
/// - Machine type icon
/// - Settings display (speed, incline, resistance, etc.)
/// - Duration display
/// - Quick timer access
///
/// Example:
/// ```dart
/// CardioSessionCard(
///   session: cardioSession,
///   onEdit: () => editSession(),
///   onDelete: () => deleteSession(),
///   onStartTimer: () => startTimer(),
/// )
/// ```
class CardioSessionCard extends StatelessWidget {
  final CardioSession session;
  final bool isEditable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStartTimer;

  const CardioSessionCard({
    Key? key,
    required this.session,
    this.isEditable = true,
    this.onEdit,
    this.onDelete,
    this.onStartTimer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getMachineColor().withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMachineColor().withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Machine icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getMachineColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMachineIcon(),
                        color: _getMachineColor(),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space12),

                    // Machine type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMachineLabel(language),
                            style: DesignTokens.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (session.duration != null)
                            Text(
                              '${session.duration} ${LocaleHelper.t('minutes', language)}',
                              style: DesignTokens.labelMedium.copyWith(
                                color: DesignTokens.ink500.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Quick actions
                    if (isEditable) _buildQuickActions(),
                  ],
                ),

                const SizedBox(height: DesignTokens.space12),

                // Machine settings
                _buildMachineSettings(language),

                // Notes
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space12),
                  _buildNotes(language),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start timer
        if (onStartTimer != null)
          IconButton(
            icon: const Icon(Icons.timer),
            iconSize: 20,
            onPressed: onStartTimer,
            color: _getMachineColor(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // Edit
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit),
            iconSize: 20,
            onPressed: onEdit,
            color: DesignTokens.ink500,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // Delete
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete),
            iconSize: 20,
            onPressed: onDelete,
            color: DesignTokens.danger,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildMachineSettings(String language) {
    final settings = <Widget>[];

    switch (session.machine) {
      case CardioMachine.treadmill:
        if (session.speed != null) {
          settings.add(_buildSettingChip(
            Icons.speed,
            '${session.speed} km/h',
            Colors.blue.shade600,
          ));
        }
        if (session.incline != null) {
          settings.add(_buildSettingChip(
            Icons.trending_up,
            '${session.incline}% ${LocaleHelper.t('incline', language)}',
            Colors.orange.shade600,
          ));
        }
        break;

      case CardioMachine.bike:
        if (session.resistance != null) {
          settings.add(_buildSettingChip(
            Icons.settings,
            '${LocaleHelper.t('resistance', language)} ${session.resistance}',
            Colors.purple.shade600,
          ));
        }
        if (session.rpm != null) {
          settings.add(_buildSettingChip(
            Icons.refresh,
            '${session.rpm} RPM',
            Colors.green.shade600,
          ));
        }
        break;

      case CardioMachine.rower:
        if (session.resistance != null) {
          settings.add(_buildSettingChip(
            Icons.settings,
            '${LocaleHelper.t('resistance', language)} ${session.resistance}',
            Colors.purple.shade600,
          ));
        }
        if (session.strokeRate != null) {
          settings.add(_buildSettingChip(
            Icons.rowing,
            '${session.strokeRate} SPM',
            Colors.teal.shade600,
          ));
        }
        if (session.distance != null) {
          settings.add(_buildSettingChip(
            Icons.straighten,
            '${session.distance} m',
            Colors.blue.shade600,
          ));
        }
        break;

      case CardioMachine.elliptical:
        if (session.resistance != null) {
          settings.add(_buildSettingChip(
            Icons.settings,
            '${LocaleHelper.t('resistance', language)} ${session.resistance}',
            Colors.purple.shade600,
          ));
        }
        if (session.incline != null) {
          settings.add(_buildSettingChip(
            Icons.trending_up,
            '${session.incline}% ${LocaleHelper.t('incline', language)}',
            Colors.orange.shade600,
          ));
        }
        break;

      case CardioMachine.stairmaster:
        if (session.level != null) {
          settings.add(_buildSettingChip(
            Icons.stairs,
            '${LocaleHelper.t('level', language)} ${session.level}',
            Colors.red.shade600,
          ));
        }
        break;

      case CardioMachine.other:
        // Show generic settings
        break;
    }

    // Add duration if available
    if (session.duration != null) {
      settings.add(_buildSettingChip(
        Icons.timer,
        '${session.duration} min',
        Colors.green.shade600,
      ));
    }

    return Wrap(
      spacing: DesignTokens.space8,
      runSpacing: DesignTokens.space8,
      children: settings,
    );
  }

  Widget _buildSettingChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(String language) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space8),
      decoration: BoxDecoration(
        color: DesignTokens.ink500.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note,
            size: 16,
            color: DesignTokens.ink500.withValues(alpha: 0.6),
          ),
          const SizedBox(width: DesignTokens.space8),
          Expanded(
            child: Text(
              session.notes!,
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.ink500.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMachineLabel(String language) {
    switch (session.machine) {
      case CardioMachine.treadmill:
        return LocaleHelper.t('treadmill', language);
      case CardioMachine.bike:
        return LocaleHelper.t('bike', language);
      case CardioMachine.rower:
        return LocaleHelper.t('rower', language);
      case CardioMachine.elliptical:
        return LocaleHelper.t('elliptical', language);
      case CardioMachine.stairmaster:
        return LocaleHelper.t('stairmaster', language);
      case CardioMachine.other:
        return LocaleHelper.t('cardio', language);
    }
  }

  IconData _getMachineIcon() {
    switch (session.machine) {
      case CardioMachine.treadmill:
        return Icons.directions_run;
      case CardioMachine.bike:
        return Icons.directions_bike;
      case CardioMachine.rower:
        return Icons.rowing;
      case CardioMachine.elliptical:
        return Icons.fitness_center;
      case CardioMachine.stairmaster:
        return Icons.stairs;
      case CardioMachine.other:
        return Icons.favorite;
    }
  }

  Color _getMachineColor() {
    switch (session.machine) {
      case CardioMachine.treadmill:
        return Colors.blue.shade600;
      case CardioMachine.bike:
        return Colors.green.shade600;
      case CardioMachine.rower:
        return Colors.teal.shade600;
      case CardioMachine.elliptical:
        return Colors.purple.shade600;
      case CardioMachine.stairmaster:
        return Colors.red.shade600;
      case CardioMachine.other:
        return Colors.grey.shade600;
    }
  }
}