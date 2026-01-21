import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/branding/vagus_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : DesignTokens.primaryDark,
          ),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: isDark ? Colors.white : DesignTokens.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Glassmorphism background matching FAB/side menu style
          gradient: isDark
              ? RadialGradient(
                  center: Alignment.topCenter,
                  radius: 2.0,
                  colors: [
                    DesignTokens.accentBlue.withValues(alpha: 0.15),
                    DesignTokens.accentBlue.withValues(alpha: 0.05),
                    DesignTokens.primaryDark,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF0F4FF),
                    Color(0xFFFAFBFF),
                  ],
                ),
        ),
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignTokens.accentBlue,
                  ),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignTokens.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: DesignTokens.space20),
                      
                      // App Logo and Name
                      _buildAppHeader(isDark),
                      
                      const SizedBox(height: DesignTokens.space32),
                      
                      // Version Info
                      _buildInfoCard(
                        context: context,
                        title: 'Version',
                        content: _packageInfo != null
                            ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                            : 'Unknown',
                        icon: Icons.info_outline,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: DesignTokens.space12),
                      
                      // Developer Info
                      _buildInfoCard(
                        context: context,
                        title: 'Developed by',
                        content: 'VAGUS Team',
                        icon: Icons.code,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: DesignTokens.space32),
                      
                      // Links Section
                      _buildSectionTitle('Links', isDark),
                      const SizedBox(height: DesignTokens.space12),
                      
                      _buildLinkTile(
                        context: context,
                        title: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () => _launchUrl('https://vagus.app/privacy'),
                        isDark: isDark,
                      ),
                      
                      _buildLinkTile(
                        context: context,
                        title: 'Terms of Service',
                        icon: Icons.description_outlined,
                        onTap: () => _launchUrl('https://vagus.app/terms'),
                        isDark: isDark,
                      ),
                      
                      _buildLinkTile(
                        context: context,
                        title: 'Visit Website',
                        icon: Icons.language,
                        onTap: () => _launchUrl('https://vagus.app'),
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: DesignTokens.space32),
                      
                      // Acknowledgments Section
                      _buildSectionTitle('Acknowledgments', isDark),
                      const SizedBox(height: DesignTokens.space12),
                      
                      _buildLinkTile(
                        context: context,
                        title: 'Open Source Licenses',
                        icon: Icons.article_outlined,
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'VAGUS',
                            applicationVersion: _packageInfo?.version ?? '',
                            applicationLegalese: '\u00a9 ${DateTime.now().year} VAGUS Team',
                          );
                        },
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: DesignTokens.space32),
                      
                      // Copyright
                      Text(
                        '\u00a9 ${DateTime.now().year} VAGUS. All rights reserved.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : DesignTokens.mediumGrey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: DesignTokens.space20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAppHeader(bool isDark) {
    return Column(
      children: [
        // App Icon Container with glassmorphic style
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.accentBlue,
                DesignTokens.accentBlue.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: VagusLogo(size: 48, white: true),
          ),
        ),
        
        const SizedBox(height: DesignTokens.space16),
        
        // Tagline
        Text(
          'Your Personal Fitness Companion',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : DesignTokens.mediumGrey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: DesignTokens.space4),
        child: Text(
          title,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : DesignTokens.mediumGrey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.space16),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: isDark
                  ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                  : DesignTokens.accentBlue.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: DesignTokens.accentBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: DesignTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : DesignTokens.mediumGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        color: isDark ? Colors.white : DesignTokens.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space16,
                  vertical: DesignTokens.space14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.accentBlue.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  border: Border.all(
                    color: isDark
                        ? DesignTokens.accentBlue.withValues(alpha: 0.3)
                        : DesignTokens.accentBlue.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignTokens.accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DesignTokens.accentBlue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: DesignTokens.accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : DesignTokens.primaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : DesignTokens.mediumGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
