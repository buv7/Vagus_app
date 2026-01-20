import 'package:flutter/material.dart';
import '../../models/admin/admin_models.dart';
import '../../services/admin/meta_admin_service.dart';

class MetaAdminScreen extends StatefulWidget {
  const MetaAdminScreen({super.key});

  @override
  State<MetaAdminScreen> createState() => _MetaAdminScreenState();
}

class _MetaAdminScreenState extends State<MetaAdminScreen> {
  List<AdminHierarchy> _hierarchy = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    setState(() => _loading = true);
    try {
      final hierarchy = await MetaAdminService.I.listAdminHierarchy();
      setState(() {
        _hierarchy = hierarchy;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _assignLevel(String adminId, int level) async {
    try {
      await MetaAdminService.I.assignAdminLevel(
        adminId: adminId,
        level: level,
      );
      await _loadHierarchy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin level assigned ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meta Admin Hierarchy')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_hierarchy.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No admin hierarchy entries found.'),
                    ),
                  )
                else
                  ..._hierarchy.map((entry) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('L${entry.level}'),
                          ),
                          title: Text('Admin ID: ${entry.adminId.substring(0, 8)}...'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level: ${entry.level}'),
                              if (entry.parentAdminId != null)
                                Text('Parent: ${entry.parentAdminId!.substring(0, 8)}...'),
                              Text('Permissions: ${entry.permissions.keys.join(", ")}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              for (int i = 1; i <= 5; i++)
                                PopupMenuItem(
                                  child: Text('Set Level $i'),
                                  onTap: () => _assignLevel(entry.adminId, i),
                                ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
