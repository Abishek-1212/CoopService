import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/category_model.dart';
import '../../../models/service_model.dart';
import '../../../services/category_service.dart';
import '../../../services/service_management_service.dart';
import 'widgets/category_dialog.dart';

class EditServiceScreen extends StatefulWidget {
  final ServiceModel service;

  const EditServiceScreen({
    super.key,
    required this.service,
  });

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _detailedDescController;
  late TextEditingController _priceRangeController;
  late TextEditingController _skillsController;

  late String _selectedCategory;
  late String _status;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _shortDescController =
        TextEditingController(text: widget.service.shortDescription);
    _detailedDescController =
        TextEditingController(text: widget.service.description ?? '');
    _priceRangeController =
        TextEditingController(text: widget.service.priceRange ?? '');
    _skillsController =
        TextEditingController(text: widget.service.requiredSkills.join(', '));

    _selectedCategory = widget.service.category;
    _status = widget.service.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _detailedDescController.dispose();
    _priceRangeController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final exists = await _serviceManagementService.checkServiceNameExists(
        name,
        excludeId: widget.service.id,
      );

      if (exists) {
        setState(() {
          _errorMessage =
              'A service with the name "$name" already exists in the master catalog.';
          _isLoading = false;
        });
        return;
      }

      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedService = widget.service.copyWith(
        name: name,
        shortDescription: _shortDescController.text.trim(),
        description: _detailedDescController.text.trim().isNotEmpty
            ? _detailedDescController.text.trim()
            : null,
        category: _selectedCategory,
        requiredSkills: skillsList,
        priceRange: _priceRangeController.text.trim().isNotEmpty
            ? _priceRangeController.text.trim()
            : null,
        status: _status,
        updatedAt: DateTime.now(),
      );

      await _serviceManagementService.updateService(updatedService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Service "$name" successfully updated!'),
            backgroundColor: AppColors.statusVerified,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update service: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit ${widget.service.name}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.statusError),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.statusError),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.statusError, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Service Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Service Name *',
                  hint: 'e.g., Electrician, AC Technician, Plumber',
                  controller: _nameController,
                  prefixIcon: Icons.handyman_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Service name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Short Description *',
                  hint: 'Brief 1-line summary of service offered',
                  controller: _shortDescController,
                  prefixIcon: Icons.subtitles_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Short description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category Dropdown with Quick-Add Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service Category (Trade) *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final created = await CategoryDialog.show(context);
                        if (created != null && mounted) {
                          setState(() {
                            _selectedCategory = created.name;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded,
                                size: 16, color: AppColors.greenForest),
                            SizedBox(width: 2),
                            Text(
                              'New Category',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StreamBuilder<List<CategoryModel>>(
                  stream: _categoryService.streamActiveCategories(),
                  builder: (context, catSnap) {
                    final categories = catSnap.data ?? [];
                    final names = categories.map((c) => c.name).toList();

                    // Ensure existing category is selectable even if newly created or legacy
                    if (!names.contains(_selectedCategory) && _selectedCategory.isNotEmpty) {
                      names.insert(0, _selectedCategory);
                    }

                    if (names.isEmpty) {
                      return OutlinedButton.icon(
                        onPressed: () async {
                          final created = await CategoryDialog.show(context);
                          if (created != null && mounted) {
                            setState(() {
                              _selectedCategory = created.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.add_rounded,
                            color: AppColors.greenForest),
                        label: const Text(
                          'No categories yet. Click to create one',
                          style: TextStyle(color: AppColors.greenForest),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFDCE8E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_rounded,
                            color: AppColors.textSecondary),
                      ),
                      items: names.map((catName) {
                        final catObj = categories.cast<CategoryModel?>().firstWhere(
                              (c) => c?.name == catName,
                              orElse: () => null,
                            );
                        final icon = catObj?.iconData ?? CategoryModel.getIconForName(catName);

                        return DropdownMenuItem(
                          value: catName,
                          child: Row(
                            children: [
                              Icon(icon, size: 18, color: AppColors.greenForest),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  catName,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'Additional Service Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Detailed Description',
                  hint: 'Provide complete details about scope, terms, and tools',
                  controller: _detailedDescController,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Required Skills / Certifications',
                  hint:
                      'Comma-separated skills e.g., Wiring, Circuit Repair, Safety License',
                  controller: _skillsController,
                  prefixIcon: Icons.psychology_outlined,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Estimated Price Range',
                  hint: 'e.g., ₹300 - ₹800 / visit or Flat ₹500',
                  controller: _priceRangeController,
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: 20),

                // Status Switch
                const Text(
                  'Service Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Active'),
                      selected: _status == AppConstants.statusActive,
                      selectedColor: AppColors.statusVerifiedBg,
                      labelStyle: TextStyle(
                        color: _status == AppConstants.statusActive
                            ? AppColors.statusVerified
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _status = AppConstants.statusActive;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Inactive'),
                      selected: _status == AppConstants.statusInactive,
                      selectedColor: AppColors.statusErrorBg,
                      labelStyle: TextStyle(
                        color: _status == AppConstants.statusInactive
                            ? AppColors.statusError
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _status = AppConstants.statusInactive;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Update Service',
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
