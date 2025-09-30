import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/design_tokens.dart';
import '../../../../models/nutrition/nutrition_plan.dart';
import '../../../../services/nutrition/locale_helper.dart';
import '../../../../services/haptics.dart';
import '../../widgets/shared/nutrition_card.dart';
import '../../widgets/shared/empty_state_widget.dart';

/// Gallery for meal photo attachments with upload and management capabilities
class AttachmentsGallery extends StatefulWidget {
  final Meal meal;
  final String userRole;
  final bool isReadOnly;
  final Function(Meal)? onMealUpdated;
  final Function()? onAddAttachment;

  const AttachmentsGallery({
    super.key,
    required this.meal,
    required this.userRole,
    this.isReadOnly = false,
    this.onMealUpdated,
    this.onAddAttachment,
  });

  @override
  State<AttachmentsGallery> createState() => _AttachmentsGalleryState();
}

class _AttachmentsGalleryState extends State<AttachmentsGallery>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _gridAnimationController;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeItemAnimations();
    _gridAnimationController.forward();
  }

  @override
  void didUpdateWidget(AttachmentsGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.attachments.length != widget.meal.attachments.length) {
      _initializeItemAnimations();
    }
  }

  void _initializeItemAnimations() {
    // Dispose old controllers
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    _itemAnimations.clear();

    // Create new controllers for each attachment
    for (int i = 0; i < widget.meal.attachments.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 100)),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );

      _itemControllers.add(controller);
      _itemAnimations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (widget.isReadOnly) return;

    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // For now, we'll just add the local path
        // In a real app, you'd upload to storage first
        final updatedAttachments = List<String>.from(widget.meal.attachments);
        updatedAttachments.add(image.path);

        final updatedMeal = widget.meal.copyWith(
          attachments: updatedAttachments,
        );

        widget.onMealUpdated?.call(updatedMeal);
        Haptics.success();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radius20),
            topRight: Radius.circular(DesignTokens.radius20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.all(DesignTokens.space16),
              child: Text(
                'Add Photo',
                style: TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Options
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.accentGreen),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: AppTheme.neutralWhite),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),

            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.accentOrange),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppTheme.neutralWhite),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),

            const SizedBox(height: DesignTokens.space16),
          ],
        ),
      ),
    );
  }

  void _removeAttachment(int index) {
    if (widget.isReadOnly) return;

    Haptics.impact();

    // Animate out the item being removed
    _itemControllers[index].reverse().then((_) {
      if (!mounted) return;

      final updatedAttachments = List<String>.from(widget.meal.attachments);
      updatedAttachments.removeAt(index);

      final updatedMeal = widget.meal.copyWith(
        attachments: updatedAttachments,
      );

      widget.onMealUpdated?.call(updatedMeal);
    });
  }

  void _viewAttachment(String attachmentPath, int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close photo',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _PhotoViewModal(
          attachmentPath: attachmentPath,
          index: index,
          totalCount: widget.meal.attachments.length,
          canDelete: !widget.isReadOnly,
          onDelete: () {
            Navigator.pop(context);
            _removeAttachment(index);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (widget.meal.attachments.isEmpty) {
      return EmptyStateWidget(
        type: EmptyStateType.noFoodItems,
        customTitle: 'No Photos Added',
        customSubtitle: 'Add photos to document your meal',
        actionLabel: 'Add Photo',
        onActionPressed: widget.isReadOnly ? null : _addPhoto,
      );
    }

    return Column(
      children: [
        // Add photo button
        if (!widget.isReadOnly)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(DesignTokens.space16),
            child: ElevatedButton.icon(
              onPressed: _addPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: Text(LocaleHelper.t('add_photo', locale)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
              ),
            ),
          ),

        // Photos grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.space16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: DesignTokens.space12,
              mainAxisSpacing: DesignTokens.space12,
              childAspectRatio: 1.0,
            ),
            itemCount: widget.meal.attachments.length,
            itemBuilder: (context, index) {
              if (index >= _itemAnimations.length) return const SizedBox.shrink();

              final attachmentPath = widget.meal.attachments[index];
              return AnimatedBuilder(
                animation: _itemAnimations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _itemAnimations[index].value,
                    child: Opacity(
                      opacity: _itemAnimations[index].value,
                      child: _PhotoThumbnail(
                        attachmentPath: attachmentPath,
                        index: index,
                        canDelete: !widget.isReadOnly,
                        onTap: () => _viewAttachment(attachmentPath, index),
                        onDelete: () => _removeAttachment(index),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String attachmentPath;
  final int index;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoThumbnail({
    required this.attachmentPath,
    required this.index,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              child: _buildImage(),
            ),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Delete button
            if (canDelete)
              Positioned(
                top: DesignTokens.space8,
                right: DesignTokens.space8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ),

            // Photo index
            Positioned(
              bottom: DesignTokens.space8,
              left: DesignTokens.space8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if it's a network URL or local file
    if (attachmentPath.startsWith('http')) {
      return Image.network(
        attachmentPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    } else {
      return Image.file(
        File(attachmentPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.mediumGrey.withOpacity(0.2),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accentGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.mediumGrey.withOpacity(0.2),
      child: const Icon(
        Icons.broken_image,
        color: AppTheme.lightGrey,
        size: 32,
      ),
    );
  }
}

class _PhotoViewModal extends StatelessWidget {
  final String attachmentPath;
  final int index;
  final int totalCount;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _PhotoViewModal({
    required this.attachmentPath,
    required this.index,
    required this.totalCount,
    required this.canDelete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Photo
          Center(
            child: InteractiveViewer(
              child: _buildFullImage(),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.space16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${index + 1} of $totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    if (canDelete && onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullImage() {
    if (attachmentPath.startsWith('http')) {
      return Image.network(
        attachmentPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
      );
    } else {
      return Image.file(
        File(attachmentPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentGreen,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.white70,
            size: 64,
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}