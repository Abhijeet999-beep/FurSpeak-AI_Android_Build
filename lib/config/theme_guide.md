# FurSpeak AI Theme Guide

This guide provides comprehensive instructions for maintaining consistent styling across the FurSpeak AI app.

## Colors

Use the predefined colors from `AppTheme`:

```dart
// Primary Colors
AppTheme.primaryColor    // Soft Periwinkle - Main brand color
AppTheme.accentColor     // Gentle Orange - Secondary actions
AppTheme.tertiaryColor   // Pastel Yellow - Accents and highlights
AppTheme.successColor    // Mint Green - Success states
AppTheme.errorColor      // Coral Red - Error states

// Background Colors
AppTheme.bgColor         // Vanilla Cream - App background
Colors.white            // Card backgrounds

// Text Colors
AppTheme.textColor      // Dark Gray - Primary text
AppTheme.textLightColor // Stone Gray - Secondary text
```

## Typography

Use the predefined text styles:

```dart
// Headings
AppTheme.headingStyle    // Main headings (32px)
AppTheme.subheadingStyle // Section headings (24px)
AppTheme.titleStyle      // Card titles (18px)

// Body Text
AppTheme.bodyStyle      // Regular text (16px)
AppTheme.captionStyle   // Small text (14px)
```

## Components

### Buttons

```dart
// Primary Button
ElevatedButton(
  style: AppTheme.primaryButtonStyle,
  child: Text('Primary Action'),
)

// Accent Button
ElevatedButton(
  style: AppTheme.accentButtonStyle,
  child: Text('Secondary Action'),
)

// Success Button
ElevatedButton(
  style: AppTheme.successButtonStyle,
  child: Text('Success Action'),
)
```

### Cards

```dart
Container(
  decoration: AppTheme.cardDecoration,
  child: YourContent(),
)
```

### Input Fields

```dart
TextField(
  decoration: AppTheme.inputDecoration(
    label: 'Your Label',
    hint: 'Your Hint',
    prefixIcon: Icons.your_icon,
  ),
)
```

## Layout

### Spacing

Use consistent spacing throughout the app:

```dart
// Padding
const EdgeInsets.all(24.0)      // Card padding
const EdgeInsets.all(16.0)      // Component padding
const EdgeInsets.all(8.0)       // Small spacing

// Margins
const SizedBox(height: 24)      // Vertical spacing
const SizedBox(width: 16)       // Horizontal spacing
```

### Border Radius

```dart
BorderRadius.circular(24)  // Cards
BorderRadius.circular(18)  // Buttons
BorderRadius.circular(16)  // Inputs
```

## Best Practices

1. **Never use hardcoded colors** - Always use `AppTheme` colors
2. **Maintain consistent spacing** - Use the predefined spacing values
3. **Follow the typography hierarchy** - Use appropriate text styles
4. **Use predefined components** - Leverage existing button and card styles
5. **Keep accessibility in mind** - Ensure sufficient color contrast
6. **Be consistent with animations** - Use standard durations and curves

## Adding New Styles

If you need to add new styles:

1. Add them to `AppTheme` class in `app_theme.dart`
2. Document them in this guide
3. Use them consistently across the app

## Example Implementation

```dart
import 'package:furspeak_ai/config/app_theme.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('Your Title', style: AppTheme.titleStyle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('Heading', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Content', style: AppTheme.bodyStyle),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () {},
                    child: Text('Action', style: AppTheme.titleStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
``` 