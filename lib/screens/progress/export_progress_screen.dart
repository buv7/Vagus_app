import 'package:flutter/material.dart';
import 'package:vagus_app/theme/design_tokens.dart';
import '../../services/config/feature_flags.dart';
import '../../services/admin/compliance_service.dart';
import '../../models/admin/admin_models.dart';

class ExportProgressScreen extends StatelessWidget {
  const ExportProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: DesignTokens.textPrimary,
        title: const Text('Export Progress Data'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.download, size: 22, color: DesignTokens.accentGreen),
                  SizedBox(width: 8),
                  Text(
                    'Export Progress Data',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryBlue,
                          foregroundColor: DesignTokens.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.table_view, color: DesignTokens.neutralWhite),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export CSV',
                                  style: TextStyle(
                                      color: DesignTokens.neutralWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('(Metrics)',
                                  style: TextStyle(
                                    color: DesignTokens.neutralWhite,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.accentPink,
                          foregroundColor: DesignTokens.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf, color: DesignTokens.neutralWhite),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export PDF',
                                  style: TextStyle(
                                      color: DesignTokens.neutralWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('(Progress)',
                                  style: TextStyle(
                                    color: DesignTokens.neutralWhite,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ VAGUS ADD: compliance-enhancements START
              FutureBuilder<bool>(
                future: FeatureFlags.instance.isEnabled(FeatureFlags.adminCompliance),
                builder: (context, flagSnapshot) {
                  if (!(flagSnapshot.data ?? false)) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description, color: DesignTokens.accentGreen),
                              SizedBox(width: 8),
                              Text(
                                'Compliance Reports',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textPrimary,
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
                                return const CircularProgressIndicator();
                              }

                              final reports = snapshot.data ?? [];
                              if (reports.isEmpty) {
                                return ElevatedButton.icon(
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
                                  icon: const Icon(Icons.add),
                                  label: const Text('Generate Data Export Report'),
                                );
                              }

                              return Column(
                                children: reports.map((report) {
                                  return ListTile(
                                    leading: const Icon(Icons.description),
                                    title: Text(report.reportType.label),
                                    subtitle: Text('Status: ${report.status.name}'),
                                    trailing: report.fileUrl != null
                                        ? IconButton(
                                            icon: const Icon(Icons.download),
                                            onPressed: () {
                                              // TODO: Open download URL
                                            },
                                          )
                                        : null,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // ✅ VAGUS ADD: compliance-enhancements END

              const SizedBox(height: 16),

              // Summary card
              Container(
                decoration: DesignTokens.glassmorphicDecoration(
                  borderRadius: DesignTokens.radius12,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textPrimary,
                          )),
                      SizedBox(height: 12),
                      _SummaryItem(text: '0 metric entries'),
                      _SummaryItem(text: '0 progress photos'),
                      _SummaryItem(text: '0 check-ins'),
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
}

class _SummaryItem extends StatelessWidget {
  final String text;
  const _SummaryItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text('• ',
              style: TextStyle(
                fontSize: 16,
                color: DesignTokens.accentGreen,
              )),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


