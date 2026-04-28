enum FlowLevel {
  none,
  light,
  medium,
  heavy;

  static FlowLevel fromKey(String key) {
    return FlowLevel.values.firstWhere(
      (f) => f.name == key,
      orElse: () => FlowLevel.none,
    );
  }

  String get displayName {
    switch (this) {
      case FlowLevel.none:   return 'None';
      case FlowLevel.light:  return 'Light';
      case FlowLevel.medium: return 'Medium';
      case FlowLevel.heavy:  return 'Heavy';
    }
  }
}
