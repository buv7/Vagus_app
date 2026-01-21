// Create lib/screens/coach_profile/widgets/profile_header.dart
import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';
import '../../../theme/theme_colors.dart';

class ProfileHeader extends StatelessWidget {
  final CoachProfile? profile;
  final bool isEditMode;
  final Function(Map<String, dynamic>)? onEdit;

  const ProfileHeader({
    super.key,
    this.profile,
    this.isEditMode = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40, // Reduced from 50
              backgroundColor: ThemeColors.of(context).avatarBg,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Icon(Icons.person, size: 40, color: ThemeColors.of(context).avatarIcon) // Reduced from 50
                  : null,
            ),
            const SizedBox(height: 12), // Reduced from 16

            // Name and Username
            if (isEditMode) ...[
              TextField(
                controller: TextEditingController(text: profile?.displayName),
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  isDense: true, // Makes field more compact
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => onEdit?.call({'display_name': value}),
              ),
              const SizedBox(height: 6), // Reduced from 8
              TextField(
                controller: TextEditingController(text: profile?.username),
                decoration: const InputDecoration(
                  labelText: '@username',
                  border: OutlineInputBorder(),
                  isDense: true, // Makes field more compact
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => onEdit?.call({'username': value}),
              ),
            ] else ...[
              Text(
                profile?.displayName ?? 'Coach Name',
                style: const TextStyle(
                  fontSize: 20, // Reduced from 24
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (profile?.username != null) ...[
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  '@${profile!.username}',
                  style: const TextStyle(
                    fontSize: 14, // Reduced from 16
                    color: Colors.white70,
                  ),
                ),
              ],
            ],

            // Headline
            if (profile?.headline != null || isEditMode) ...[
              const SizedBox(height: 8), // Reduced from 12
              if (isEditMode)
                TextField(
                  controller: TextEditingController(text: profile?.headline),
                  decoration: const InputDecoration(
                    labelText: 'Headline',
                    border: OutlineInputBorder(),
                    isDense: true, // Makes field more compact
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => onEdit?.call({'headline': value}),
                )
              else
                Text(
                  profile!.headline!,
                  style: const TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Limit to 2 lines
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
