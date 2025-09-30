import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachMarketplaceCard extends StatefulWidget {
  final Map<String, dynamic> coach;
  final VoidCallback onTap;

  const CoachMarketplaceCard({
    super.key,
    required this.coach,
    required this.onTap,
  });

  @override
  State<CoachMarketplaceCard> createState() => _CoachMarketplaceCardState();
}

class _CoachMarketplaceCardState extends State<CoachMarketplaceCard> {
  bool _isConnecting = false;

  String get _displayName => 
      widget.coach['display_name'] ?? widget.coach['profile_name'] ?? 'Coach';
  
  String get _username => widget.coach['username'] ?? '';
  
  String get _headline => widget.coach['headline'] ?? '';
  
  List<String> get _specialties => 
      List<String>.from(widget.coach['specialties'] ?? []);

  Future<void> _connectWithCoach() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Send coach connection request
      await Supabase.instance.client
          .from('coach_requests')
          .insert({
        'client_id': currentUser.id,
        'coach_id': widget.coach['coach_id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connection request sent!'),
            backgroundColor: DesignTokens.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to connect: $e'),
            backgroundColor: DesignTokens.accentPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: DesignTokens.glassmorphicDecoration(
          borderRadius: DesignTokens.radius20,
          boxShadow: DesignTokens.glowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and username
              _buildHeader(),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display name
                      Text(
                        _displayName,
                        style: DesignTokens.titleSmall.copyWith(
                          color: DesignTokens.neutralWhite,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (_headline.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.space4),
                        Text(
                          _headline,
                          style: DesignTokens.bodySmall.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Specialties
                      if (_specialties.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.space6),
                        _buildSpecialties(),
                      ],
                      
                      const Spacer(),
                      
                      // Rating placeholder
                      const SizedBox(height: DesignTokens.space6),
                      _buildRating(),
                      
                      // Connect button
                      const SizedBox(height: DesignTokens.space8),
                      _buildConnectButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentBlue.withValues(alpha: 0.2),
            DesignTokens.accentPurple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: DesignTokens.accentGreen.withValues(alpha: 0.2),
            child: Text(
              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
              style: DesignTokens.titleSmall.copyWith(
                color: DesignTokens.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          
          const SizedBox(width: DesignTokens.space8),
          
          // Username
          Expanded(
            child: Text(
              '@$_username',
              style: DesignTokens.bodySmall.copyWith(
                color: DesignTokens.accentGreen,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialties() {
    return Wrap(
      spacing: DesignTokens.space4,
      runSpacing: DesignTokens.space4,
      children: _specialties.take(3).map((specialty) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space2,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRating() {
    // Placeholder rating - would be replaced with actual rating data
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < 4 ? Icons.star : Icons.star_border,
            size: 12,
            color: DesignTokens.accentOrange,
          );
        }),
        const SizedBox(width: DesignTokens.space4),
        Text(
          '4.0 (12)',
          style: DesignTokens.labelSmall.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isConnecting ? null : _connectWithCoach,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.accentGreen,
          foregroundColor: DesignTokens.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          elevation: 0,
        ),
        child: _isConnecting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.primaryDark,
                ),
              )
            : Text(
                'Connect',
                style: DesignTokens.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
