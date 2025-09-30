
/// Text normalization utilities for Arabic, Kurdish, and English food names
/// Handles diacritics, letter variants, and transliteration
class TextNormalizer {
  // Arabic diacritics and marks to remove
  static const String _arabicDiacritics = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656\u0657\u0658\u0659\u065A\u065B\u065C\u065D\u065E\u065F\u0670';
  
  // Arabic letter variants mapping to canonical forms
  static const Map<String, String> _arabicVariants = {
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ء': 'ا',
    'ة': 'ه', 'ى': 'ي', 'ؤ': 'و',
    'ك': 'ک', 'ي': 'ی',
  };
  
  // Kurdish-specific variants
  static const Map<String, String> _kurdishVariants = {
    'گ': 'گ', 'چ': 'چ', 'پ': 'پ', 'ژ': 'ژ',
    'ڕ': 'ر', 'ڵ': 'ل', 'ڤ': 'ڤ',
  };
  
  // Common Latin-Arabic transliteration map for food terms
  static const Map<String, String> _latinArabicTransliteration = {
    // Common food terms
    'chicken': 'دجاج', 'meat': 'لحم', 'fish': 'سمك', 'bread': 'خبز',
    'rice': 'أرز', 'salad': 'سلطة', 'soup': 'شوربة', 'cheese': 'جبن',
    'milk': 'حليب', 'yogurt': 'لبن', 'dates': 'تمر', 'nuts': 'مكسرات',
    'oil': 'زيت', 'salt': 'ملح', 'sugar': 'سكر', 'flour': 'دقيق',
    'tomato': 'طماطم', 'onion': 'بصل', 'garlic': 'ثوم', 'lemon': 'ليمون',
    'egg': 'بيض', 'butter': 'زبدة', 'honey': 'عسل', 'tea': 'شاي',
    'coffee': 'قهوة', 'water': 'ماء', 'juice': 'عصير', 'fruit': 'فاكهة',
    'vegetable': 'خضار', 'spice': 'توابل', 'herb': 'أعشاب',
    
    // Cooking methods
    'grilled': 'مشوي', 'fried': 'مقلي', 'boiled': 'مسلوق', 'baked': 'مخبوز',
    'roasted': 'محمر', 'steamed': 'مبخر', 'raw': 'نيء', 'cooked': 'مطبوخ',
    
    // Cuisine terms
    'iraqi': 'عراقي', 'arabic': 'عربي', 'kurdish': 'كردي', 'middle eastern': 'شرق أوسطي',
    'mediterranean': 'متوسطي', 'traditional': 'تقليدي', 'homemade': 'منزلي',
  };
  
  // Arabic-Latin reverse transliteration
  static const Map<String, String> _arabicLatinTransliteration = {
    'دجاج': 'chicken', 'لحم': 'meat', 'سمك': 'fish', 'خبز': 'bread',
    'أرز': 'rice', 'سلطة': 'salad', 'شوربة': 'soup', 'جبن': 'cheese',
    'حليب': 'milk', 'لبن': 'yogurt', 'تمر': 'dates', 'مكسرات': 'nuts',
    'زيت': 'oil', 'ملح': 'salt', 'سكر': 'sugar', 'دقيق': 'flour',
    'طماطم': 'tomato', 'بصل': 'onion', 'ثوم': 'garlic', 'ليمون': 'lemon',
    'بيض': 'egg', 'زبدة': 'butter', 'عسل': 'honey', 'شاي': 'tea',
    'قهوة': 'coffee', 'ماء': 'water', 'عصير': 'juice', 'فاكهة': 'fruit',
    'خضار': 'vegetable', 'توابل': 'spice', 'أعشاب': 'herb',
    'عراقي': 'iraqi', 'عربي': 'arabic', 'كردي': 'kurdish', 'شرق أوسطي': 'middle eastern',
    'متوسطي': 'mediterranean', 'تقليدي': 'traditional', 'منزلي': 'homemade',
  };

  /// Strip Arabic diacritics from text
  static String stripDiacritics(String text) {
    String result = text;
    for (int i = 0; i < _arabicDiacritics.length; i++) {
      result = result.replaceAll(_arabicDiacritics[i], '');
    }
    return result;
  }

  /// Unify Arabic letter variants to canonical forms
  static String unifyArabicVariants(String text) {
    String result = text;
    _arabicVariants.forEach((variant, canonical) {
      result = result.replaceAll(variant, canonical);
    });
    return result;
  }

  /// Unify Kurdish letter variants
  static String unifyKurdishVariants(String text) {
    String result = text;
    _kurdishVariants.forEach((variant, canonical) {
      result = result.replaceAll(variant, canonical);
    });
    return result;
  }

  /// Normalize text for search - removes diacritics, unifies variants, case-folds
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // Strip diacritics
    result = stripDiacritics(result);
    
    // Unify Arabic variants
    result = unifyArabicVariants(result);
    
    // Unify Kurdish variants
    result = unifyKurdishVariants(result);
    
    // Case fold
    result = result.toLowerCase();
    
    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return result;
  }

  /// Transliterate between Latin and Arabic (auto-detect direction)
  static String latinArabicTransliterate(String text, {String to = 'auto'}) {
    if (text.isEmpty) return text;
    
    // Auto-detect direction based on script
    final bool isArabic = _containsArabic(text);
    final bool isLatin = _containsLatin(text);
    
    if (to == 'auto') {
      if (isArabic && !isLatin) {
        // Arabic to Latin
        return _transliterate(_arabicLatinTransliteration, text);
      } else if (isLatin && !isArabic) {
        // Latin to Arabic
        return _transliterate(_latinArabicTransliteration, text);
      }
      return text; // Mixed or unknown, return as-is
    } else if (to == 'arabic') {
      return _transliterate(_latinArabicTransliteration, text);
    } else if (to == 'latin') {
      return _transliterate(_arabicLatinTransliteration, text);
    }
    
    return text;
  }

  /// Generate a canonical key for seed data
  static String canonicalKey(String text) {
    String normalized = normalizeForSearch(text);
    
    // Remove common words that don't add meaning
    final stopWords = ['the', 'a', 'an', 'of', 'and', 'or', 'with', 'in', 'on', 'at'];
    for (String stopWord in stopWords) {
      normalized = normalized.replaceAll(RegExp(r'\b' + stopWord + r'\b'), '');
    }
    
    // Replace spaces and special chars with underscores
    normalized = normalized.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    
    // Remove multiple underscores
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    
    // Remove leading/trailing underscores
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    
    return normalized;
  }

  /// Check if text contains Arabic script
  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Check if text contains Latin script
  static bool _containsLatin(String text) {
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  /// Perform transliteration using a mapping
  static String _transliterate(Map<String, String> mapping, String text) {
    String result = text.toLowerCase();
    
    // Sort by length (longest first) to avoid partial replacements
    final List<String> keys = mapping.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String key in keys) {
      result = result.replaceAll(key, mapping[key]!);
    }
    
    return result;
  }

  /// Normalize a search query for better matching
  static String normalizeQuery(String query) {
    return normalizeForSearch(query);
  }

  /// Normalize a label for consistent storage/comparison
  static String normalizeLabel(String label) {
    return normalizeForSearch(label);
  }

  /// Check if two texts are equivalent after normalization
  static bool areEquivalent(String text1, String text2) {
    return normalizeForSearch(text1) == normalizeForSearch(text2);
  }

  /// Get all possible search variations for a text (including transliterations)
  static List<String> getSearchVariations(String text) {
    final Set<String> variations = {};
    
    // Original normalized
    variations.add(normalizeForSearch(text));
    
    // Transliterated versions
    final String arabic = latinArabicTransliterate(text, to: 'arabic');
    if (arabic != text) {
      variations.add(normalizeForSearch(arabic));
    }
    
    final String latin = latinArabicTransliterate(text, to: 'latin');
    if (latin != text) {
      variations.add(normalizeForSearch(latin));
    }
    
    return variations.toList();
  }
}
