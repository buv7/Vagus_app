import 'package:flutter/material.dart';
import '../../models/nutrition/pantry_item.dart';
import '../../services/nutrition/pantry_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/branding/vagus_appbar.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PantryItem> _allItems = [];
  List<PantryItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentUserId = ''; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPantryItems() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Get current user ID from auth service
      _currentUserId = 'current_user_id'; // Replace with actual user ID
      
      final items = await _pantryService.list(_currentUserId);
      setState(() {
        _allItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pantry items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (_searchQuery.isNotEmpty) {
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        return true;
      }).toList();
    });
  }

  List<PantryItem> get _expiringSoonItems {
    return _filteredItems.where((item) => item.isExpiringSoon).toList();
  }

  List<PantryItem> get _allOtherItems {
    return _filteredItems.where((item) => !item.isExpiringSoon).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    
    return Scaffold(
      appBar: VagusAppBar(
        title: Text(LocaleHelper.t('pantry', language)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            tooltip: LocaleHelper.t('add_pantry_item', language),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: LocaleHelper.t('search_pantry', language),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState(language)
                    : _buildPantryList(language),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String language) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            LocaleHelper.t('no_pantry_items', language),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleHelper.t('add_pantry_item', language),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: Text(LocaleHelper.t('add_pantry_item', language)),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryList(String language) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Expiring soon section
        if (_expiringSoonItems.isNotEmpty) ...[
          _buildSectionHeader(
            LocaleHelper.t('expiring_soon', language),
            _expiringSoonItems.length,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          ..._expiringSoonItems.map((item) => _buildPantryItemTile(item, language)),
          const SizedBox(height: 24),
        ],
        
        // All items section
        _buildSectionHeader(
          LocaleHelper.t('pantry', language),
          _allOtherItems.length,
          Colors.grey.shade600,
        ),
        const SizedBox(height: 8),
        ..._allOtherItems.map((item) => _buildPantryItemTile(item, language)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPantryItemTile(PantryItem item, String language) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.displayQuantity),
            if (item.expiresAt != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: item.isExpiringSoon 
                        ? Colors.orange 
                        : item.isExpired 
                            ? Colors.red 
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${LocaleHelper.t('expires', language)}: ${_formatDate(item.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isExpiringSoon 
                          ? Colors.orange 
                          : item.isExpired 
                              ? Colors.red 
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditItemDialog(item);
                break;
              case 'delete':
                _showDeleteConfirmation(item, language);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  Text(LocaleHelper.t('edit', language)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    LocaleHelper.t('delete', language),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(PantryItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({PantryItem? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final qtyController = TextEditingController(text: item?.qty.toString() ?? '');
    String selectedUnit = item?.unit ?? 'g';
    DateTime? selectedDate = item?.expiresAt;
    
    final units = ['g', 'kg', 'ml', 'l', 'pcs'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing 
                ? LocaleHelper.t('edit', Localizations.localeOf(context).languageCode)
                : LocaleHelper.t('add_pantry_item', Localizations.localeOf(context).languageCode),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: LocaleHelper.t('pantry', Localizations.localeOf(context).languageCode),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        decoration: InputDecoration(
                          labelText: LocaleHelper.t('qty', Localizations.localeOf(context).languageCode),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: LocaleHelper.t('unit', Localizations.localeOf(context).languageCode),
                          border: const OutlineInputBorder(),
                        ),
                        items: units.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedUnit = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate != null 
                            ? '${LocaleHelper.t('expires', Localizations.localeOf(context).languageCode)}: ${_formatDate(selectedDate ?? DateTime.now())}'
                            : LocaleHelper.t('expires', Localizations.localeOf(context).languageCode),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                      child: Text(selectedDate != null ? LocaleHelper.t('edit', Localizations.localeOf(context).languageCode) : LocaleHelper.t('add_pantry_item', Localizations.localeOf(context).languageCode)),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        onPressed: () => setDialogState(() => selectedDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleHelper.t('cancel', Localizations.localeOf(context).languageCode)),
            ),
            ElevatedButton(
              onPressed: () => _saveItem(
                nameController.text,
                qtyController.text,
                selectedUnit,
                selectedDate,
                item,
              ),
              child: Text(LocaleHelper.t('save', Localizations.localeOf(context).languageCode)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem(
    String name,
    String qtyText,
    String unit,
    DateTime? expiresAt,
    PantryItem? existingItem,
  ) async {
    if (name.isEmpty || qtyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final qty = double.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    try {
      // final now = DateTime.now();
      final pantryItem = PantryItem(
        id: existingItem?.id ?? _generateKey(name),
        userId: _currentUserId,
        name: name,
        amount: qty,
        unit: unit,
        expiresAt: expiresAt,
        createdAt: existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _pantryService.upsert(pantryItem);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadPantryItems();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingItem != null ? 'Item updated' : 'Item added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(PantryItem item, String language) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleHelper.t('delete', language)),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleHelper.t('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () => _deleteItem(item),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(LocaleHelper.t('delete', language)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(PantryItem item) async {
    try {
      await _pantryService.delete(userId: item.userId, key: item.key);
      if (!mounted) return;
      Navigator.pop(context); // Close confirmation dialog
      await _loadPantryItems();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateKey(String name) {
    // Simple key generation - could be enhanced with better normalization
    return name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
