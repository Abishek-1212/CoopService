import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../models/category_model.dart';
import '../../../../services/category_service.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryModel? initialCategory;

  const CategoryDialog({super.key, this.initialCategory});

  static Future<CategoryModel?> show(BuildContext context, {CategoryModel? category}) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDialog(initialCategory: category),
    );
  }

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryService = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedIconKey;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialCategory?.description ?? '');
    _selectedIconKey = widget.initialCategory?.iconKey ?? 'handyman';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exists = await _categoryService.checkCategoryNameExists(
        name,
        excludeId: widget.initialCategory?.id,
      );

      if (exists) {
        setState(() {
          _errorMessage = 'A category named "$name" already exists.';
          _isLoading = false;
        });
        return;
      }

      if (widget.initialCategory != null) {
        final updated = widget.initialCategory!.copyWith(
          name: name,
          description: description.isNotEmpty ? description : null,
          iconKey: _selectedIconKey,
          updatedAt: DateTime.now(),
        );
        await _categoryService.updateCategory(updated);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final newCategory = CategoryModel(
          id: '',
          name: name,
          description: description.isNotEmpty ? description : null,
          iconKey: _selectedIconKey,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final newId = await _categoryService.createCategory(newCategory);
        if (mounted) Navigator.pop(context, newCategory.copyWith(id: newId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save category: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCategory != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundMildGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.neuBorder, width: 1.2),
            left: BorderSide(color: AppColors.neuBorder, width: 1.2),
            right: BorderSide(color: AppColors.neuBorder, width: 1.2),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Grab Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neuBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.greenMint.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neuBorder, width: 1),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: AppColors.greenForest,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Service Category' : 'Create Service Category',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Define a trade under which services can be grouped',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.neuBorder, width: 1),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.statusError.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 18, color: AppColors.statusError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.statusError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Category Name
                CustomTextField(
                  label: 'Category / Trade Name',
                  hint: 'e.g. Electrician, Carpentry, HVAC Services',
                  controller: _nameController,
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Description (Optional)
                CustomTextField(
                  label: 'Description (Optional)',
                  hint: 'Brief scope or trade summary',
                  controller: _descriptionController,
                  maxLines: 2,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 16),

                // Icon Selector Label
                const Text(
                  'Select Trade Icon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDeep,
                  ),
                ),
                const SizedBox(height: 8),

                // Icon Selector Grid / Horizontal List
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: CategoryModel.availableIcons.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = CategoryModel.availableIcons[index];
                      final key = item['key'] as String;
                      final label = item['label'] as String;
                      final icon = item['icon'] as IconData;
                      final isSelected = _selectedIconKey == key;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIconKey = key;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.greenMint.withValues(alpha: 0.35)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.greenForest
                                  : AppColors.neuBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.greenForest.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-1, -1),
                                      blurRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: Color(0x0A064E3B),
                                      offset: Offset(1, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.greenForest
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight:
                                      isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.greenForest
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: AppColors.neuBorder, width: 1.2),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: isEditing ? 'Update Category' : 'Create Category',
                        isLoading: _isLoading,
                        onPressed: _saveCategory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
