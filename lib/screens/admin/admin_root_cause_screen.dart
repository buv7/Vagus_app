// ignore_for_file: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin/admin_support_service.dart';

class AdminRootCauseScreen extends StatefulWidget {
  const AdminRootCauseScreen({super.key});
  @override
  State<AdminRootCauseScreen> createState() => _AdminRootCauseScreenState();
}

class _AdminRootCauseScreenState extends State<AdminRootCauseScreen> {
  final _svc = AdminSupportService.instance;
  List<TagTrendPoint> _series = const [];
  List<String> _tags = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final s = await _svc.getRootCauseTrends();
    if (!mounted) return;
    final tagSet = <String>{};
    for (final p in s) { tagSet.addAll(p.countsByTag.keys); }
    setState(() { _series = s; _tags = tagSet.toList()..sort(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Root-Cause Trends')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _Legend(tags: _tags),
            const SizedBox(height: 8),
            Expanded(child: _StackedBars(data: _series, tags: _tags)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<String> tags;
  const _Legend({required this.tags});
  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    return Wrap(
      spacing: 8, runSpacing: 4,
      children: List.generate(tags.length, (i){
        final c = palette[i % palette.length];
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c.withValues(alpha:.9), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(tags[i]),
        ]);
      }),
    );
  }
}

class _StackedBars extends StatelessWidget {
  final List<TagTrendPoint> data;
  final List<String> tags;
  const _StackedBars({required this.data, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Text('No data');
    final palette = _palette();
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (_, i) {
        final p = data[i];
        final total = tags.fold<int>(0, (sum, t)=> sum + (p.countsByTag[t] ?? 0));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.day.month}/${p.day.day}', style: TextStyle(color: Colors.black.withValues(alpha:.6))),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Row(children: [
                  for (var ti=0; ti<tags.length; ti++)
                    Flexible(
                      flex: (p.countsByTag[tags[ti]] ?? 0).clamp(0, 1<<30),
                      child: Container(height: 14, color: palette[ti % palette.length].withValues(alpha:.9)),
                    ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('$total'),
            ]),
          ]),
        );
      },
    );
  }
}

List<Color> _palette() => const [
  Colors.indigo, Colors.teal, Colors.orange, Colors.purple, Colors.blueGrey, Colors.pink, Colors.blue, Colors.green
];
