import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:vagus_app/models/nutrition/meal.dart';
import 'package:vagus_app/models/nutrition/food_item.dart';
import 'package:vagus_app/widgets/nutrition/food_item_card.dart';
import 'package:vagus_app/widgets/nutrition/animated/food_item_edit_modal.dart';
import 'package:vagus_app/services/haptics.dart';
import 'package:vagus_app/theme/nutrition_text_styles.dart';
import 'package:vagus_app/theme/nutrition_spacing.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

class MealTemplate {
  final String id;
  final String name;
  final String description;
  final MealType mealType;
  final List<FoodItem> items;
  final String? photoUrl;

  const MealTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.mealType,
    required this.items,
    this.photoUrl,
  });
}

class DraggableModal extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const DraggableModal({
    Key? key,
    required this.child,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<DraggableModal> createState() => _DraggableModalState();
}

class _DraggableModalState extends State<DraggableModal> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
          if (_dragOffset < 0) _dragOffset = 0;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > 100) {
          widget.onDismiss();
        } else {
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: widget.child,
      ),
    );
  }
}

class MealEditorModal extends StatefulWidget {
  final Meal? existingMeal;
  final Function(Meal) onSave;
  final String? clientId;
  final bool isCoachMode;

  const MealEditorModal({
    Key? key,
    this.existingMeal,
    required this.onSave,
    this.clientId,
    this.isCoachMode = true,
  }) : super(key: key);

  @override
  State<MealEditorModal> createState() => _MealEditorModalState();
}

class _MealEditorModalState extends State<MealEditorModal>
    with TickerProviderStateMixin {

  late TextEditingController _mealNameController;
  late TextEditingController _notesController;

  late Meal _currentMeal;

  // Animation controllers
  late AnimationController _contentAnimationController;
  late AnimationController _macroUpdateController;
  late TabController _tabController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _macroScaleAnimation;

  // State
  bool _isModified = false;
  bool _isSaving = false;
  MealType _selectedMealType = MealType.breakfast;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _mealPhotoUrl;

  // Template state
  List<MealTemplate> _templates = [];
  bool _showTemplates = false;

  @override
  void initState() {
    super.initState();

    // Initialize meal
    _currentMeal = widget.existingMeal ?? Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
      items: [],
      timestamp: DateTime.now(),
    );

    _mealNameController = TextEditingController(
      text: _currentMeal.name.isEmpty ? _getDefaultMealName() : _currentMeal.name,
    );
    _notesController = TextEditingController();

    // Initialize animation controllers
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _macroUpdateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _tabController = TabController(length: 3, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _macroScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _macroUpdateController,
      curve: Curves.easeOut,
    ));

    // Start animations
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });

    // Load templates
    _loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DraggableModal(
          onDismiss: _handleDismiss,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D2626),
                  Color(0xFF1A3A3A),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildMealMetadataSection(),
                      _buildStickyMacroSummary(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFoodsTab(),
                            _buildNotesTab(),
                            _buildTemplatesTab(),
                          ],
                        ),
                      ),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDefaultMealName() {
    switch (_selectedMealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  TimeOfDay _getDefaultTimeForMealType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return TimeOfDay(hour: 7, minute: 0);
      case MealType.lunch:
        return TimeOfDay(hour: 12, minute: 0);
      case MealType.dinner:
        return TimeOfDay(hour: 18, minute: 0);
      case MealType.snack:
        return TimeOfDay(hour: 15, minute: 0);
      default:
        return TimeOfDay.now();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART 2: HEADER & MEAL METADATA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.white70),
                onPressed: _handleDismiss,
              ),
              Expanded(
                child: Text(
                  widget.existingMeal == null ? 'New Meal' : 'Edit Meal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white70),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealMetadataSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMealPhotoSection(),
              SizedBox(height: 16),
              _buildMealNameField(),
              SizedBox(height: 12),
              _buildMealTypeAndTimeRow(),
              SizedBox(height: 12),
              _buildQuickActionsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealPhotoSection() {
    return GestureDetector(
      onTap: _selectMealPhoto,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _mealPhotoUrl == null
              ? LinearGradient(
                  colors: [
                    Color(0xFF00D9A3).withOpacity(0.2),
                    Color(0xFF00B4D8).withOpacity(0.2),
                  ],
                )
              : null,
          image: _mealPhotoUrl != null
              ? DecorationImage(
                  image: NetworkImage(_mealPhotoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _mealPhotoUrl == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white70,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add meal photo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMealNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _mealNameController,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Meal name',
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.restaurant, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) => _markAsModified(),
      ),
    );
  }

  Widget _buildMealTypeAndTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMealTypeSelector(),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildTimeSelector(),
        ),
      ],
    );
  }

  Widget _buildMealTypeSelector() {
    return GestureDetector(
      onTap: _showMealTypePicker,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(_getMealTypeIcon(), color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _getMealTypeName(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.content_copy,
            label: 'Duplicate',
            onTap: _duplicateMeal,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.delete_outline,
            label: 'Clear All',
            color: Colors.red,
            onTap: _clearAllFoods,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.bookmark_border,
            label: 'Save Template',
            onTap: _saveAsTemplate,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART 3: STICKY MACRO SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStickyMacroSummary() {
    final macros = _calculateTotalMacros();

    return AnimatedBuilder(
      animation: _macroUpdateController,
      builder: (context, child) {
        return Transform.scale(
          scale: _macroScaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00D9A3).withOpacity(0.2),
                  Color(0xFF00B4D8).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF00D9A3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Calories', '${macros['calories']?.toStringAsFixed(0) ?? "0"}'),
                _buildMacroDivider(),
                _buildMacroItem('Protein', '${macros['protein']?.toStringAsFixed(1) ?? "0"}g'),
                _buildMacroDivider(),
                _buildMacroItem('Carbs', '${macros['carbs']?.toStringAsFixed(1) ?? "0"}g'),
                _buildMacroDivider(),
                _buildMacroItem('Fat', '${macros['fat']?.toStringAsFixed(1) ?? "0"}g'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART 4: TAB BAR & TABS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00D9A3),
              Color(0xFF00B4D8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 18),
                SizedBox(width: 4),
                Text('Foods'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 18),
                SizedBox(width: 4),
                Text('Notes'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline, size: 18),
                SizedBox(width: 4),
                Text('Templates'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodsTab() {
    if (_currentMeal.items.isEmpty) {
      return _buildEmptyFoodsState();
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _currentMeal.items.length,
      onReorder: _handleFoodReorder,
      itemBuilder: (context, index) {
        final food = _currentMeal.items[index];
        return Dismissible(
          key: Key(food.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) => _removeFood(index),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: FoodItemCard(
              foodItem: food,
              onTap: () => _editFood(index),
              onLongPress: () => _showFoodOptions(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyFoodsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 64,
            color: Colors.white30,
          ),
          SizedBox(height: 16),
          Text(
            'No foods added yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add foods to build your meal',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEmptyStateAction(
                icon: Icons.add_circle_outline,
                label: 'Add Food',
                onTap: _addFoodFromDatabase,
              ),
              SizedBox(width: 12),
              _buildEmptyStateAction(
                icon: Icons.auto_awesome,
                label: 'AI Generate',
                onTap: _generateMealWithAI,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00D9A3).withOpacity(0.2),
              Color(0xFF00B4D8).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF00D9A3).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coach Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _notesController,
              style: TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Add notes about this meal...\n\n• Meal prep instructions\n• Timing recommendations\n• Substitution options',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (_) => _markAsModified(),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Quick Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickNoteChip('Pre-workout'),
              _buildQuickNoteChip('Post-workout'),
              _buildQuickNoteChip('Low sodium'),
              _buildQuickNoteChip('High protein'),
              _buildQuickNoteChip('Quick prep'),
              _buildQuickNoteChip('Meal prep friendly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteChip(String label) {
    return InkWell(
      onTap: () {
        final currentText = _notesController.text;
        _notesController.text = currentText.isEmpty
            ? label
            : '$currentText\n• $label';
        _markAsModified();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.white30,
            ),
            SizedBox(height: 16),
            Text(
              'No saved templates',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Save this meal as a template to reuse later',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(MealTemplate template) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _applyTemplate(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00D9A3).withOpacity(0.3),
                          Color(0xFF00B4D8).withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Icon(
                      _getMealTypeIconForType(template.mealType),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${template.items.length} items',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white70),
                    onPressed: () => _showTemplateOptions(template),
                  ),
                ],
              ),
              if (template.description.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  template.description,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART 5: FOOTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: _addFoodFromDatabase,
              icon: Icon(Icons.add, size: 18),
              label: Text('Add Food'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildAnimatedSaveButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ).copyWith(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isModified
                ? [Color(0xFF00D9A3), Color(0xFF00B4D8)]
                : [Colors.white24, Colors.white24],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          alignment: Alignment.center,
          constraints: BoxConstraints(minHeight: 48),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  'Save Meal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART 6: ACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _selectMealPhoto() async {
    HapticFeedback.lightImpact();
    // TODO: Implement photo selection
    setState(() {
      _mealPhotoUrl = 'https://via.placeholder.com/400x300';
      _markAsModified();
    });
  }

  void _showMealTypePicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A3A3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: MealType.values.map((type) {
            return ListTile(
              leading: Icon(_getMealTypeIconForType(type), color: Colors.white70),
              title: Text(
                _getMealTypeNameForType(type),
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  _selectedMealType = type;
                  _selectedTime = _getDefaultTimeForMealType(type);
                  if (_mealNameController.text.isEmpty ||
                      _mealNameController.text == _getDefaultMealName()) {
                    _mealNameController.text = _getMealTypeNameForType(type);
                  }
                  _markAsModified();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    HapticFeedback.lightImpact();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF00D9A3),
              surface: Color(0xFF1A3A3A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _markAsModified();
      });
    }
  }

  void _duplicateMeal() {
    HapticFeedback.mediumImpact();
    // TODO: Implement meal duplication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meal duplicated')),
    );
  }

  void _clearAllFoods() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A3A3A),
        title: Text('Clear all foods?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will remove all foods from this meal.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentMeal = Meal(
                  id: _currentMeal.id,
                  name: _currentMeal.name,
                  items: [],
                  timestamp: _currentMeal.timestamp,
                );
                _markAsModified();
              });
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveAsTemplate() {
    HapticFeedback.mediumImpact();
    // TODO: Implement save as template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved as template')),
    );
  }

  void _addFoodFromDatabase() {
    HapticFeedback.lightImpact();
    // TODO: Show food database picker
    // For now, add a sample food
    setState(() {
      _currentMeal = Meal(
        id: _currentMeal.id,
        name: _currentMeal.name,
        items: [
          ..._currentMeal.items,
          FoodItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Sample Food',
            calories: 200,
            protein: 20,
            carbs: 30,
            fat: 5,
            servingSize: '100g',
          ),
        ],
        timestamp: _currentMeal.timestamp,
      );
      _markAsModified();
      _animateMacroUpdate();
    });
  }

  void _generateMealWithAI() {
    HapticFeedback.mediumImpact();
    // TODO: Implement AI meal generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI meal generation coming soon')),
    );
  }

  void _editFood(int index) {
    HapticFeedback.lightImpact();
    // TODO: Show food edit modal
  }

  void _showFoodOptions(int index) {
    HapticFeedback.mediumImpact();
    // TODO: Show food options bottom sheet
  }

  void _removeFood(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      final items = List<FoodItem>.from(_currentMeal.items);
      items.removeAt(index);
      _currentMeal = Meal(
        id: _currentMeal.id,
        name: _currentMeal.name,
        items: items,
        timestamp: _currentMeal.timestamp,
      );
      _markAsModified();
      _animateMacroUpdate();
    });
  }

  void _handleFoodReorder(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = List<FoodItem>.from(_currentMeal.items);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      _currentMeal = Meal(
        id: _currentMeal.id,
        name: _currentMeal.name,
        items: items,
        timestamp: _currentMeal.timestamp,
      );
      _markAsModified();
    });
  }

  void _applyTemplate(MealTemplate template) {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentMeal = Meal(
        id: _currentMeal.id,
        name: template.name,
        items: template.items,
        timestamp: _currentMeal.timestamp,
      );
      _mealNameController.text = template.name;
      _selectedMealType = template.mealType;
      _markAsModified();
      _animateMacroUpdate();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template applied')),
    );
  }

  void _showTemplateOptions(MealTemplate template) {
    HapticFeedback.lightImpact();
    // TODO: Show template options (edit, delete, etc.)
  }

  void _showMoreOptions() {
    HapticFeedback.lightImpact();
    // TODO: Show more options menu
  }

  Future<void> _handleSave() async {
    HapticFeedback.heavyImpact();

    if (_mealNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a meal name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(Duration(milliseconds: 500));

    final meal = Meal(
      id: _currentMeal.id,
      name: _mealNameController.text,
      items: _currentMeal.items,
      timestamp: _currentMeal.timestamp,
    );

    widget.onSave(meal);

    Navigator.of(context).pop();
  }

  Future<bool> _handleBackPress() async {
    if (_isModified) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A3A3A),
          title: Text('Discard changes?', style: TextStyle(color: Colors.white)),
          content: Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  void _handleDismiss() {
    HapticFeedback.lightImpact();
    _handleBackPress().then((shouldPop) {
      if (shouldPop) {
        Navigator.of(context).pop();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _markAsModified() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  void _animateMacroUpdate() {
    _macroUpdateController.forward().then((_) {
      _macroUpdateController.reverse();
    });
  }

  Map<String, double> _calculateTotalMacros() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final item in _currentMeal.items) {
      totalCalories += item.calories;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  IconData _getMealTypeIcon() {
    return _getMealTypeIconForType(_selectedMealType);
  }

  IconData _getMealTypeIconForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  String _getMealTypeName() {
    return _getMealTypeNameForType(_selectedMealType);
  }

  String _getMealTypeNameForType(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  Future<void> _loadTemplates() async {
    // TODO: Load templates from database
    setState(() {
      _templates = [];
    });
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _notesController.dispose();
    _contentAnimationController.dispose();
    _macroUpdateController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODAL ROUTE FOR SMOOTH PRESENTATION
// ═══════════════════════════════════════════════════════════════════════════

class MealEditorModalRoute extends PageRoute {
  final WidgetBuilder builder;

  MealEditorModalRoute({required this.builder});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}