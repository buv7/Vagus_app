import 'package:flutter/material.dart';
import 'package:vagus_app/theme/design_tokens.dart';
import 'package:vagus_app/services/coaches/coach_repository.dart';
import 'package:vagus_app/screens/coach_profile/coach_profile_screen.dart';

class CoachGlassCard extends StatelessWidget {
  final CoachCardVm coach;

  const CoachGlassCard({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(
              coachId: coach.coachId,
              isPublicView: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: DesignTokens.glassmorphicDecoration(
          borderRadius: DesignTokens.radius24,
          boxShadow: DesignTokens.cardShadow,
        ),
        child: DesignTokens.createBackdropFilter(
          sigmaX: DesignTokens.blurMd,
          sigmaY: DesignTokens.blurMd,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: DesignTokens.lightGrey,
                      backgroundImage: coach.avatarUrl != null
                          ? NetworkImage(coach.avatarUrl!)
                          : null,
                      child: coach.avatarUrl == null
                          ? Text(
                              coach.displayName.isNotEmpty
                                  ? coach.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: DesignTokens.neutralWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coach.displayName,
                            style: DesignTokens.bodyLarge.copyWith(
                              color: DesignTokens.neutralWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (coach.username != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${coach.username}',
                              style: DesignTokens.bodySmall.copyWith(
                                color: DesignTokens.accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space12),
                if (coach.headline != null) ...[
                  Text(
                    coach.headline!,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.space12),
                ],
                if (coach.specialties.isNotEmpty) ...[
                  Wrap(
                    spacing: DesignTokens.space6,
                    runSpacing: DesignTokens.space6,
                    children: coach.specialties.take(3).map((specialty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space8,
                          vertical: DesignTokens.space4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          border: Border.all(
                            color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          specialty,
                          style: DesignTokens.labelSmall.copyWith(
                            color: DesignTokens.accentBlue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: DesignTokens.space16),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoachProfileScreen(
                            coachId: coach.coachId,
                            isPublicView: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.accentGreen,
                      foregroundColor: DesignTokens.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Profile',
                      style: DesignTokens.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}