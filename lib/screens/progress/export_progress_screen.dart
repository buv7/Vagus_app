import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../services/config/feature_flags.dart';
import '../../services/admin/compliance_service.dart';
import '../../models/admin/admin_models.dart';

class ExportProgressScreen extends StatelessWidget {
  const ExportProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0B1220),
        elevation: 0,
        title: Text(
          'Export Progress Data',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0B1220),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download, size: 22, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  const Text(
                    'Export Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildExportButton(
                      icon: Icons.table_view,
                      title: 'Export CSV',
                      subtitle: '(Metrics)',
                      color: DesignTokens.accentBlue,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildExportButton(
                      icon: Icons.picture_as_pdf,
                      title: 'Export PDF',
                      subtitle: '(Progress)',
                      color: const Color(0xFF00D4AA),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Compliance Reports Section
              FutureBuilder<bool>(
                future: FeatureFlags.instance.isEnabled(FeatureFlags.adminCompliance),
                builder: (context, flagSnapshot) {
                  if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();

                  return _buildGlassmorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            const Text(
                              'Compliance Reports',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<ComplianceReport>>(
                          future: ComplianceService.I.listReports(
                            reportType: ReportType.dataExport,
                            limit: 5,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(color: DesignTokens.accentBlue),
                              );
                            }

                            final reports = snapshot.data ?? [];
                            if (reports.isEmpty) {
                              return _buildGlassmorphicButton(
                                onPressed: () async {
                                  try {
                                    await ComplianceService.I.generateReport(
                                      reportType: ReportType.dataExport,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Compliance report generated ✅'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.white.withValues(alpha: 0.9)),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Generate Data Export Report',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: reports.map((report) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.accentBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: DesignTokens.accentBlue.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.description, color: Colors.white.withValues(alpha: 0.8), size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report.reportType.label,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              'Status: ${report.status.name}',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (report.fileUrl != null)
                                        IconButton(
                                          icon: Icon(Icons.download, color: Colors.white.withValues(alpha: 0.8)),
                                          onPressed: () {},
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Summary Card
              _buildGlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryItem('0 metric entries'),
                    _buildSummaryItem('0 progress photos'),
                    _buildSummaryItem('0 check-ins'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSummaryItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.25),
                DesignTokens.accentBlue.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentBlue.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton({required VoidCallback onPressed, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                DesignTokens.accentBlue.withValues(alpha: 0.35),
                DesignTokens.accentBlue.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.accentBlue.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
