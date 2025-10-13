#!/bin/bash
# Fix DesignTokens references in remaining component files

FILES=(
  "lib/components/messaging/attachment_preview.dart"
  "lib/components/messaging/typing_indicator.dart"
  "lib/components/messaging/translation_toggle.dart"
  "lib/components/billing/coupon_input.dart"
  "lib/components/billing/free_trial_countdown_card.dart"
  "lib/components/settings/export_my_data_button.dart"
  "lib/components/settings/account_deletion_dialog.dart"
)

for file in "${FILES[@]}"; do
  echo "Fixing $file..."
  
  # Replace DesignTokens.* with compat constants
  sed -i 's/DesignTokens\.mintAqua/mintAqua/g' "$file"
  sed -i 's/DesignTokens\.errorRed/errorRed/g' "$file"
  sed -i 's/DesignTokens\.softYellow/softYellow/g' "$file"
  sed -i 's/DesignTokens\.steelGrey/steelGrey/g' "$file"
  sed -i 's/DesignTokens\.lightGrey/lightGrey/g' "$file"
  sed -i 's/DesignTokens\.textPrimary/textPrimary/g' "$file"
  sed -i 's/DesignTokens\.primaryAccent/primaryAccent/g' "$file"
  sed -i 's/DesignTokens\.spacing1/spacing1/g' "$file"
  sed -i 's/DesignTokens\.spacing2/spacing2/g' "$file"
  sed -i 's/DesignTokens\.spacing3/spacing3/g' "$file"
  sed -i 's/DesignTokens\.spacing4/spacing4/g' "$file"
  sed -i 's/DesignTokens\.radiusS/radiusS/g' "$file"
  sed -i 's/DesignTokens\.radiusM/radiusM/g' "$file"
  sed -i 's/DesignTokens\.radiusL/radiusL/g' "$file"
  
  # Fix deprecated withOpacity calls
  sed -i 's/\.withOpacity(\([^)]*\))/\.withValues(alpha: \1)/g' "$file"
  
done

echo "✅ All files fixed!"
echo "Run: flutter analyze"

