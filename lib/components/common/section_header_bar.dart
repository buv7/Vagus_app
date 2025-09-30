import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';

class SectionHeaderBar extends StatelessWidget {
  final String title;
  final Widget? leadingIcon;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? actionIcon;
  final bool dense;

  const SectionHeaderBar({
    super.key,
    required this.title,
    this.leadingIcon,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
        final useColumnLayout = constraints.maxWidth < 380 || textScaleFactor > 1.2;

        if (useColumnLayout) {
          return _buildColumnLayout(context);
        } else {
          return _buildRowLayout(context);
        }
      },
    );
  }

  Widget _buildRowLayout(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          leadingIcon!,
          const SizedBox(width: DesignTokens.space8),
        ],
        Expanded(
          child: Text(
            title,
            style: DesignTokens.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: DesignTokens.space8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildActionButton(context),
        ),
      ],
    );
  }

  Widget _buildColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: DesignTokens.space8),
            ],
            Expanded(
              child: Text(
                title,
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: dense ? DesignTokens.space8 : DesignTokens.space12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _buildActionButton(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 44.0, // Minimum tap target
        minWidth: 44.0,
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onAction();
        },
        icon: Icon(actionIcon ?? Icons.add),
        label: Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: DesignTokens.space12,
            vertical: dense ? DesignTokens.space8 : DesignTokens.space12,
          ),
          backgroundColor: DesignTokens.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
        ),
      ),
    );
  }
}
