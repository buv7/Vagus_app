import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin/admin_support_service.dart';

typedef ViewChanged = void Function(SavedView view);

class SavedViewsBar extends StatefulWidget {
  final Map<String, dynamic> currentFilters;   // the inbox/tickets' filters
  final ViewChanged onSelect;                  // call when a view is chosen
  const SavedViewsBar({super.key, required this.currentFilters, required this.onSelect});

  @override
  State<SavedViewsBar> createState() => _SavedViewsBarState();
}

class _SavedViewsBarState extends State<SavedViewsBar> {
  final _svc = AdminSupportService.instance;
  List<SavedView> _views = const [];
  String _activeId = 'all';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final v = await _svc.listSavedViews();
    if (!mounted) return;
    setState(() => _views = v..sort((a,b)=>a.order.compareTo(b.order)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              ..._views.map((v) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(v.name),
                  selected: v.id == _activeId,
                  onSelected: (_) {
                    setState(()=>_activeId = v.id);
                    widget.onSelect(v);
                  },
                ),
              )),
            ]),
          ),
        ),
        IconButton(
          tooltip: 'Save current view',
          icon: const Icon(Icons.bookmark_add_outlined),
          onPressed: () async {
            final name = await _askName(context);
            if (name == null || name.trim().isEmpty) return;
            final v = await _svc.createSavedView(name.trim(), widget.currentFilters);
            if (!mounted) return;
            setState(() {
              _views = [..._views, v]..sort((a,b)=>a.order.compareTo(b.order));
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View saved')));
          },
        ),
        IconButton(
          tooltip: 'Manage views',
          icon: const Icon(Icons.tune),
          onPressed: () => _manageViews(context),
        ),
      ],
    );
  }

  Future<String?> _askName(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save current view'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'View name')),
        actions: [
          TextButton(onPressed: ()=> Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: ()=> Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _manageViews(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder(
              future: _svc.listSavedViews(),
              builder: (_, snap) {
                final vs = (snap.data as List<SavedView>?) ?? _views;
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: true,
                  itemCount: vs.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final items = [...vs];
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    await _svc.reorderSavedViews(items.map((e)=>e.id).toList());
                    if (!context.mounted) return;
                    setState(()=> _views = items);
                  },
                  itemBuilder: (_, i) {
                    final v = vs[i];
                    final locked = v.id=='all' || v.id=='open';
                    return ListTile(
                      key: ValueKey(v.id),
                      title: Text(v.name),
                      subtitle: Text(v.filters.toString()),
                      trailing: locked ? const SizedBox(width: 20) : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await _svc.deleteSavedView(v.id);
                          if (!context.mounted) return;
                          if (ok) setState(()=> _views = _views.where((x)=>x.id != v.id).toList());
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(()=>{});
  }
}
