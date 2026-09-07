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

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _detailedDescController = TextEditingController();
  final TextEditingController _priceRangeController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  String? _selectedCategory;
  String _status = AppConstants.statusActive;
  bool _isLoading = false;
  String? _errorMessage;

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
      final exists = await _serviceManagementService.checkServiceNameExists(name);

      if (exists) {
        setState(() {
          _errorMessage = 'A service with the name "$name" already exists in the master catalog.';
          _isLoading = false;
        });
        return;
      }

      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final newService = ServiceModel(
        id: '',
        name: name,
        shortDescription: _shortDescController.text.trim(),
        description: _detailedDescController.text.trim().isNotEmpty
            ? _detailedDescController.text.trim()
            : null,
        category: _selectedCategory ?? 'General',
        priceRange: _priceRangeController.text.trim().isNotEmpty
            ? _priceRangeController.text.trim()
            : null,
        requiredSkills: skillsList,
        status: _status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _serviceManagementService.createService(newService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service "$name" successfully added to Master Catalog!'),
            backgroundColor: AppColors.statusVerified,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create service: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Platform Service'),
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
                        const Icon(Icons.error_outline, color: AppColors.statusError),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.statusError, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Service Overview (Required)',
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

                    if (_selectedCategory == null ||
                        (!names.contains(_selectedCategory) && names.isNotEmpty)) {
                      if (names.isNotEmpty) {
                        _selectedCategory = names.first;
                      }
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

                    final currentValue = names.contains(_selectedCategory)
                        ? _selectedCategory
                        : names.first;

                    return DropdownButtonFormField<String>(
                      initialValue: currentValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_rounded,
                            color: AppColors.textSecondary),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.name,
                          child: Row(
                            children: [
                              Icon(cat.iconData,
                                  size: 18, color: AppColors.greenForest),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
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
                  'Additional Service Details (Optional)',
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
                  hint: 'Comma-separated skills e.g., Wiring, Circuit Repair, Safety License',
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
                  text: 'Save & Publish Service',
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
