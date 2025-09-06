import 'package:flutter/material.dart';
import '../../services/nutrition/food_catalog_service.dart';
import '../../services/nutrition/locale_helper.dart';
import '../../services/ai/nutrition_ai.dart';

class RegionalFoodPicker extends StatefulWidget {
  final String lang;
  final void Function(CatalogFoodItem item, double grams) onPicked;

  const RegionalFoodPicker({
    super.key,
    required this.lang,
    required this.onPicked,
  });

  @override
  State<RegionalFoodPicker> createState() => _RegionalFoodPickerState();
}

class _RegionalFoodPickerState extends State<RegionalFoodPicker> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();
  final FoodCatalogService _catalogService = FoodCatalogService();
  
  List<CatalogFoodItem> _searchResults = [];
  List<CatalogFoodItem> _aiSuggestions = [];
  bool _isLoading = false;
  bool _showAiSuggestions = false;
  bool _isSearchingAi = false;

  @override
  void initState() {
    super.initState();
    _portionController.text = '100';
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _aiSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Search catalog first
      final results = await _catalogService.search(query, lang: widget.lang);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // If AI suggestions are enabled, search AI as well
      if (_showAiSuggestions) {
        _searchAiSuggestions(query);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchAiSuggestions(String query) async {
    setState(() {
      _isSearchingAi = true;
    });

    try {
      final suggestions = await NutritionAI().autoFillFromText(
        query,
        locale: widget.lang,
      );

      setState(() {
        _aiSuggestions = suggestions.map((item) {
          if (item is String) {
            return CatalogFoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nameEn: item,
              portionGrams: 100.0,
              kcal: 0.0,
              proteinG: 0.0,
              carbsG: 0.0,
              fatG: 0.0,
              sodiumMg: 0,
              potassiumMg: 0,
              tags: ['ai_suggestion'],
              source: 'ai',
            );
          } else {
            // Treat as FoodItem-like object
            return CatalogFoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nameEn: (item as dynamic).name ?? item.toString(),
              portionGrams: (item as dynamic).amount ?? 100.0,
              kcal: (item as dynamic).kcal ?? 0.0,
              proteinG: (item as dynamic).protein ?? 0.0,
              carbsG: (item as dynamic).carbs ?? 0.0,
              fatG: (item as dynamic).fat ?? 0.0,
              sodiumMg: ((item as dynamic).sodium ?? 0.0).toInt(),
              potassiumMg: ((item as dynamic).potassium ?? 0.0).toInt(),
              tags: ['ai_suggestion'],
              source: 'ai',
            );
          }
        }).toList();
        _isSearchingAi = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingAi = false;
      });
    }
  }

  void _onFoodPicked(CatalogFoodItem item) {
    final grams = double.tryParse(_portionController.text) ?? item.portionGrams;
    final scaledItem = item.scaleToGrams(grams);
    widget.onPicked(scaledItem, grams);
    Navigator.pop(context);
  }

  void _onAiSuggestionPicked(CatalogFoodItem suggestion) {
    final grams = double.tryParse(_portionController.text) ?? suggestion.portionGrams;
    final scaledItem = suggestion.scaleToGrams(grams);
    widget.onPicked(scaledItem, grams);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocaleHelper.isRTL(widget.lang);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleHelper.t('regional_foods', widget.lang),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: LocaleHelper.t('search_foods', widget.lang),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Portion input
                TextField(
                  controller: _portionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocaleHelper.t('portion_g', widget.lang),
                    border: const OutlineInputBorder(),
                    suffixText: LocaleHelper.t('grams', widget.lang),
                  ),
                ),
                const SizedBox(height: 16),

                // AI suggestions toggle
                SwitchListTile(
                  title: Text(LocaleHelper.t('auto_fill_ai', widget.lang)),
                  value: _showAiSuggestions,
                  onChanged: (value) {
                    setState(() {
                      _showAiSuggestions = value;
                      if (value && _searchController.text.isNotEmpty) {
                        _searchAiSuggestions(_searchController.text.trim());
                      } else {
                        _aiSuggestions = [];
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Results
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildResultsList(scrollController),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsList(ScrollController scrollController) {
    if (_searchResults.isEmpty && _aiSuggestions.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty 
              ? LocaleHelper.t('search_foods', widget.lang)
              : LocaleHelper.t('no_results', widget.lang),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      children: [
        // Catalog results
        if (_searchResults.isNotEmpty) ...[
          Text(
            LocaleHelper.t('suggestions', widget.lang),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._searchResults.map((item) => _buildFoodItemTile(item)),
          const SizedBox(height: 16),
        ],

        // AI suggestions
        if (_showAiSuggestions && _aiSuggestions.isNotEmpty) ...[
          Text(
            '${LocaleHelper.t('auto_fill_ai', widget.lang)} ${LocaleHelper.t('suggestions', widget.lang)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearchingAi)
            const Center(child: CircularProgressIndicator())
          else
            ..._aiSuggestions.map((suggestion) => _buildAiSuggestionTile(suggestion)),
        ],
      ],
    );
  }

  Widget _buildFoodItemTile(CatalogFoodItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.getName(widget.lang),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (item.source == 'database')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  LocaleHelper.t('from_catalog', widget.lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${LocaleHelper.formatNumber(item.kcal)} ${LocaleHelper.t('kcal', widget.lang)}'),
            Row(
              children: [
                Text('${LocaleHelper.t('protein', widget.lang)}: ${LocaleHelper.formatNumber(item.proteinG)}${LocaleHelper.t('grams', widget.lang)}'),
                const SizedBox(width: 16),
                Text('${LocaleHelper.t('carbs', widget.lang)}: ${LocaleHelper.formatNumber(item.carbsG)}${LocaleHelper.t('grams', widget.lang)}'),
                const SizedBox(width: 16),
                Text('${LocaleHelper.t('fat', widget.lang)}: ${LocaleHelper.formatNumber(item.fatG)}${LocaleHelper.t('grams', widget.lang)}'),
              ],
            ),
            if (item.sodiumMg != null || item.potassiumMg != null)
              Row(
                children: [
                  if (item.sodiumMg != null)
                    Text('${LocaleHelper.t('sodium', widget.lang)}: ${item.sodiumMg}${LocaleHelper.t('mg', widget.lang)}'),
                  if (item.sodiumMg != null && item.potassiumMg != null)
                    const SizedBox(width: 16),
                  if (item.potassiumMg != null)
                    Text('${LocaleHelper.t('potassium', widget.lang)}: ${item.potassiumMg}${LocaleHelper.t('mg', widget.lang)}'),
                ],
              ),
          ],
        ),
        onTap: () => _onFoodPicked(item),
      ),
    );
  }

  Widget _buildAiSuggestionTile(CatalogFoodItem suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          suggestion.nameEn,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${LocaleHelper.formatNumber(suggestion.kcal)} ${LocaleHelper.t('kcal', widget.lang)}'),
            Row(
              children: [
                Text('${LocaleHelper.t('protein', widget.lang)}: ${LocaleHelper.formatNumber(suggestion.proteinG)}${LocaleHelper.t('grams', widget.lang)}'),
                const SizedBox(width: 16),
                Text('${LocaleHelper.t('carbs', widget.lang)}: ${LocaleHelper.formatNumber(suggestion.carbsG)}${LocaleHelper.t('grams', widget.lang)}'),
                const SizedBox(width: 16),
                Text('${LocaleHelper.t('fat', widget.lang)}: ${LocaleHelper.formatNumber(suggestion.fatG)}${LocaleHelper.t('grams', widget.lang)}'),
              ],
            ),
          ],
        ),
        onTap: () => _onAiSuggestionPicked(suggestion),
      ),
    );
  }
}
