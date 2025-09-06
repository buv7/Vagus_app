import 'package:flutter/material.dart';

class ExportProgressScreen extends StatelessWidget {
  const ExportProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Progress Data'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.download, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Export Progress Data',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.table_view, color: Colors.white),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export CSV',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('(Metrics)',
                                  style: TextStyle(
                                    color: Colors.white,
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
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export PDF',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('(Progress)',
                                  style: TextStyle(
                                    color: Colors.white,
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
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Summary:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}


