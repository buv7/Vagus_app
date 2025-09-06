import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition/money.dart';
import '../../theme/design_tokens.dart';
import '../../services/nutrition/locale_helper.dart';

class PriceEditorScreen extends StatefulWidget {
  const PriceEditorScreen({super.key});

  @override
  State<PriceEditorScreen> createState() => _PriceEditorScreenState();
}

class _PriceEditorScreenState extends State<PriceEditorScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _prices = [];
  List<Map<String, dynamic>> _filteredPrices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await supabase
          .from('nutrition_prices')
          .select('*')
          .order('key');

      setState(() {
        _prices = List<Map<String, dynamic>>.from(response);
        _filteredPrices = _prices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrices = _prices.where((price) {
        return price['key']?.toString().toLowerCase().contains(query) ?? false;
      }).toList();
    });
  }

  Future<void> _addPrice() async {
    final result = await _showPriceDialog();
    if (result != null) {
      try {
        await supabase
            .from('nutrition_prices')
            .insert(result);

        await _loadPrices();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Price added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add price: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editPrice(Map<String, dynamic> price) async {
    final result = await _showPriceDialog(price: price);
    if (result != null) {
      try {
        await supabase
            .from('nutrition_prices')
            .update(result)
            .eq('key', price['key']);

        await _loadPrices();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Price updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update price: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePrice(Map<String, dynamic> price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Price'),
        content: Text('Are you sure you want to delete the price for "${price['key']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase
            .from('nutrition_prices')
            .delete()
            .eq('key', price['key']);

        await _loadPrices();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Price deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete price: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showPriceDialog({Map<String, dynamic>? price}) async {
    final keyController = TextEditingController(text: price?['key'] ?? '');
    final costController = TextEditingController(text: price?['cost_per_unit']?.toString() ?? '');
    final currencyController = TextEditingController(text: price?['currency'] ?? 'USD');
    
    final isEdit = price != null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Price' : 'Add Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                hintText: 'e.g., chicken_breast_1kg',
                border: OutlineInputBorder(),
              ),
              enabled: !isEdit, // Can't edit key for existing prices
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Cost per Unit',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currencyController,
              decoration: const InputDecoration(
                labelText: 'Currency',
                hintText: 'USD',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final key = keyController.text.trim();
              final cost = double.tryParse(costController.text.trim());
              final currency = currencyController.text.trim();

              if (key.isEmpty || cost == null || currency.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'key': key,
                'cost_per_unit': cost,
                'currency': currency,
              });
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final isRTL = LocaleHelper.isRTL(language);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleHelper.t('prices', language)),
          actions: [
            IconButton(
              onPressed: _addPrice,
              icon: const Icon(Icons.add),
              tooltip: LocaleHelper.t('add', language),
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
                  hintText: LocaleHelper.t('search', language),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _filteredPrices.isEmpty
                          ? _buildEmptyState()
                          : _buildPricesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading prices',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPrices,
              child: Text(LocaleHelper.t('retry', language)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.price_check_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No prices found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first price to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addPrice,
              icon: const Icon(Icons.add),
              label: Text(LocaleHelper.t('add', language)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPrices.length,
      itemBuilder: (context, index) {
        final price = _filteredPrices[index];
        final money = Money(
          (price['cost_per_unit'] ?? 0.0).toDouble(),
          price['currency'] ?? 'USD',
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              price['key'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              money.toStringDisplay(locale: Localizations.localeOf(context).languageCode),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editPrice(price),
                  icon: const Icon(Icons.edit),
                  tooltip: LocaleHelper.t('edit', Localizations.localeOf(context).languageCode),
                ),
                IconButton(
                  onPressed: () => _deletePrice(price),
                  icon: const Icon(Icons.delete),
                  tooltip: LocaleHelper.t('delete', Localizations.localeOf(context).languageCode),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
