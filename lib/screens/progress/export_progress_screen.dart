import 'package:flutter/material.dart';
import 'package:vagus_app/theme/design_tokens.dart';

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


