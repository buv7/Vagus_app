# Pill Icon Usage

## PillIcon Widget

The `PillIcon` widget uses the AI-generated SVG icon (`assets/icons/icon_pill.svg`) and automatically adapts to light and dark themes.

### Features
- ✅ Theme-aware (automatically uses appropriate colors for light/dark mode)
- ✅ Scalable SVG (crisp at any size)
- ✅ Customizable size and color

### Usage

```dart
import 'package:vagus_app/widgets/supplements/pill_icon.dart';

// Basic usage (theme-aware)
PillIcon(size: 24)

// Custom size
PillIcon(size: 48)

// Custom color (overrides theme)
PillIcon(
  size: 24,
  color: Colors.blue,
)
```

### Migration from HalfPillIcon

You can replace `HalfPillIcon` with `PillIcon` in your code:

```dart
// Old
const HalfPillIcon(size: 24)

// New
const PillIcon(size: 24)
```

Both widgets are available, so you can migrate gradually or use both as needed.
