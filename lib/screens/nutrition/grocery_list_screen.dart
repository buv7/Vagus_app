import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/nutrition/grocery_list.dart';
import '../../models/nutrition/grocery_item.dart';
import '../../models/nutrition/money.dart';
import '../../services/nutrition/grocery_service.dart';
import '../../services/nutrition/costing_service.dart';
import '../../services/nutrition/integrations/pantry_integration_helper.dart';
import '../../services/nutrition/integrations/pantry_grocery_adapter.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../widgets/branding/vagus_appbar.dart';

class GroceryListScreen extends StatefulWidget {
  final GroceryList groceryList;
  final PantrySummary? pantrySummary;

  const GroceryListScreen({
    super.key,
    required this.groceryList,
    this.pantrySummary,
  });

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final GroceryService _groceryService = GroceryService();
  final CostingService _costing = CostingService();
  
  List<GroceryItem> _items = [];
  bool _loading = true;
  String? _error;
  Money? _estimatedTotalCost;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final items = await _groceryService.getItems(widget.groceryList.id);
      
      setState(() {
        _items = items;
        _loading = false;
      });
      
      // Calculate estimated total cost
      await _calculateTotalCost();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleItemChecked(GroceryItem item) async {
    try {
      await _groceryService.toggleChecked(
        itemId: item.id,
        value: !item.isChecked,
      );
      
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(isChecked: !item.isChecked);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final filePath = await _groceryService.exportCsv(widget.groceryList.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
        
        // Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'Grocery List - Week ${widget.groceryList.weekIndex}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final filePath = await _groceryService.exportPdf(widget.groceryList.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
        
        // Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'Grocery List - Week ${widget.groceryList.weekIndex}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  Future<void> _calculateTotalCost() async {
    try {
      final cost = await _costing.estimateGroceryListCost(widget.groceryList);
      setState(() {
        _estimatedTotalCost = cost;
      });
    } catch (e) {
      // Silently ignore cost calculation errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final isRTL = LocaleHelper.isRTL(language);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: VagusAppBar(
          title: Text('${LocaleHelper.t('grocery_list', language)} - ${LocaleHelper.t('week', language)} ${widget.groceryList.weekIndex}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            if (!_loading && _items.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: LocaleHelper.t('export_csv', language),
                onPressed: _exportCsv,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: LocaleHelper.t('export_pdf', language),
                onPressed: _exportPdf,
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Pantry coverage banner
            if (widget.pantrySummary != null)
              PantryIntegrationHelper.buildCoverageBanner(
                summary: widget.pantrySummary!,
                language: language,
              ),
            
            // Estimated total cost banner
            if (_estimatedTotalCost != null && _estimatedTotalCost!.amount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleHelper.t('estimated_total_cost', language),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            _estimatedTotalCost!.toStringDisplay(locale: language),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _items.isEmpty
                          ? _buildEmptyState()
                          : _buildItemsList(),
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
              LocaleHelper.t('error_loading_grocery_list', language),
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
              onPressed: _loadItems,
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
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              LocaleHelper.t('no_grocery_items', language),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              LocaleHelper.t('generate_from_plan', language),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;

    // Group items by aisle
    final itemsByAisle = <String, List<GroceryItem>>{};
    for (final item in _items) {
      final aisle = item.aisle ?? 'other';
      itemsByAisle.putIfAbsent(aisle, () => []).add(item);
    }

    // Calculate progress
    final totalItems = _items.length;
    final checkedItems = _items.where((item) => item.isChecked).length;
    final progress = totalItems > 0 ? checkedItems / totalItems : 0.0;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleHelper.t('progress', language),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$checkedItems / $totalItems',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Items by aisle
        Expanded(
          child: ListView.builder(
            itemCount: itemsByAisle.length,
            itemBuilder: (context, index) {
              final aisle = itemsByAisle.keys.toList()[index];
              final aisleItems = itemsByAisle[aisle]!;
              final aisleChecked = aisleItems.where((item) => item.isChecked).length;
              
              return _buildAisleSection(aisle, aisleItems, aisleChecked, language);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAisleSection(String aisle, List<GroceryItem> items, int checkedCount, String language) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Aisle header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getAisleIcon(aisle),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAisleDisplayName(aisle, language),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '$checkedCount / ${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Items
          ...items.map((item) => _buildItemTile(item, language)),
        ],
      ),
    );
  }

  Widget _buildItemTile(GroceryItem item, String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleItemChecked(item),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: item.isChecked 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                color: item.isChecked 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              child: item.isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked ? Colors.grey.shade600 : null,
                  ),
                ),
                ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.amount.toStringAsFixed(1)} ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAisleIcon(String aisle) {
    switch (aisle) {
      case 'produce':
        return Icons.eco;
      case 'meat':
        return Icons.restaurant;
      case 'dairy':
        return Icons.local_drink;
      case 'bakery':
        return Icons.cake;
      case 'frozen':
        return Icons.ac_unit;
      case 'canned':
        return Icons.inventory;
      case 'grains':
        return Icons.grain;
      case 'spices':
        return Icons.spa;
      case 'beverages':
        return Icons.local_bar;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.shopping_basket;
    }
  }

  String _getAisleDisplayName(String aisle, String language) {
    switch (aisle) {
      case 'produce':
        return LocaleHelper.t('produce', language);
      case 'meat':
        return LocaleHelper.t('meat', language);
      case 'dairy':
        return LocaleHelper.t('dairy', language);
      case 'bakery':
        return LocaleHelper.t('bakery', language);
      case 'frozen':
        return LocaleHelper.t('frozen', language);
      case 'canned':
        return LocaleHelper.t('canned', language);
      case 'grains':
        return LocaleHelper.t('grains', language);
      case 'spices':
        return LocaleHelper.t('spices', language);
      case 'beverages':
        return LocaleHelper.t('beverages', language);
      case 'snacks':
        return LocaleHelper.t('snacks', language);
      default:
        return LocaleHelper.t('other', language);
    }
  }
}
