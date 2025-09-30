import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coach/coach_profile.dart';
import '../../services/coach_portfolio_service.dart';
import '../../services/coaches/coach_repository.dart';
import '../../services/qr_service.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../theme/app_theme.dart';

class CoachProfilePublicScreen extends StatefulWidget {
  final String? coachId;
  final String? username;
  final Map<String, dynamic>? coachData;

  const CoachProfilePublicScreen({
    super.key,
    this.coachId,
    this.username,
    this.coachData,
  }) : assert(coachId != null || username != null, 'Either coachId or username must be provided');

  @override
  State<CoachProfilePublicScreen> createState() => _CoachProfilePublicScreenState();
}

class _CoachProfilePublicScreenState extends State<CoachProfilePublicScreen> {
  final CoachPortfolioService _portfolioService = CoachPortfolioService();
  final CoachRepository _coachRepository = CoachRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  CoachProfile? _profile;
  List<CoachMedia> _media = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;
      final clientId = user?.id;

      // Resolve coachId if we only have username
      String? coachId = widget.coachId;
      if (coachId == null && widget.username != null) {
        final coachVm = await _coachRepository.byUsername(widget.username!);
        if (coachVm == null) {
          throw Exception('Coach not found');
        }
        coachId = coachVm.coachId;
      }

      if (coachId == null) {
        throw Exception('Coach ID not found');
      }

      // Load profile
      final profile = await _portfolioService.getCoachProfile(coachId);

      // Load approved media (including clients_only if current user is a connected client)
      final media = await _portfolioService.getApprovedMedia(
        coachId,
        clientId: clientId,
      );

      setState(() {
        _profile = profile;
        _media = media;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showQrShareSheet() {
    if (_profile?.username == null) return;
    
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    
    QRService().showQRBottomSheet(
      context,
      coachId: currentUser.id,
      coachName: _profile!.displayName ?? 'Coach',
      username: _profile!.username!,
    );
  }

  bool _isOwnProfile() {
    final currentUser = _supabase.auth.currentUser;
    return currentUser != null &&
           (currentUser.id == widget.coachId ||
            (widget.coachId == null && _profile?.coachId == currentUser.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VagusAppBar(
        title: const Text('Coach Profile'),
        actions: _isOwnProfile() && _profile != null
            ? [
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _showQrShareSheet,
                  tooltip: 'Share QR Code',
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(
                      child: Text(
                        'Coach profile not found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          _buildProfileHeader(),
                          
                          const SizedBox(height: 24),
                          
                          // Intro Video
                          if (_profile!.introVideoUrl != null) ...[
                            _buildIntroVideo(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Bio
                          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
                            _buildBioSection(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Specialties
                          if (_profile!.specialties.isNotEmpty) ...[
                            _buildSpecialtiesSection(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Media
                          if (_media.isNotEmpty) ...[
                            _buildMediaSection(),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
      ),
      child: Column(
        children: [
          // Profile Picture Placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppTheme.primaryDark,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            _profile!.displayName ?? 'Coach',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Headline
          if (_profile!.headline != null && _profile!.headline!.isNotEmpty)
            Text(
              _profile!.headline!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildIntroVideo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Choose Me?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Video placeholder or actual video player
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: AppTheme.primaryDark,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Intro Video',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Video URL overlay (for debugging)
                  if (_profile!.introVideoUrl != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Video Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Text(
              _profile!.bio!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specialties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile!.specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  specialty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media & Resources',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          
          // Group media by type
          ..._groupMediaByType().entries.map((entry) {
            final type = entry.key;
            final media = entry.value;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'video' ? 'Videos' : 'Courses',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...media.map((item) => _buildMediaCard(item)),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Map<String, List<CoachMedia>> _groupMediaByType() {
    final grouped = <String, List<CoachMedia>>{};
    for (final media in _media) {
      if (!grouped.containsKey(media.mediaType)) {
        grouped[media.mediaType] = [];
      }
      grouped[media.mediaType]!.add(media);
    }
    return grouped;
  }

  Widget _buildMediaCard(CoachMedia media) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Media icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                media.mediaType == 'video' ? Icons.play_circle_outline : Icons.school,
                color: AppTheme.primaryDark,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Media info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  if (media.description != null && media.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      media.description!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: media.visibility == 'public' 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          media.visibility == 'public' ? 'Public' : 'Clients Only',
                          style: TextStyle(
                            color: media.visibility == 'public' 
                                ? Colors.green[700]
                                : Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
