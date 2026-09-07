import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/service_card.dart';
import '../../../models/category_model.dart';
import '../../../models/service_model.dart';
import '../../../services/category_service.dart';
import '../../../services/service_management_service.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';
import 'service_details_screen.dart';
import 'widgets/category_dialog.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0; // 0: Services, 1: Categories (Trades)
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive

  @override
  void initState() {
    super.initState();
    // Seed default starter categories if collection is currently empty
    _categoryService.seedDefaultCategoriesIfEmpty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar & Search
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedTab == 0
                              ? 'Services Catalog'
                              : 'Trades & Categories',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedTab == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddServiceScreen(),
                              ),
                            );
                          } else {
                            CategoryDialog.show(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenForest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          _selectedTab == 0 ? 'Add Service' : 'Add Category',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mode Switcher (Services vs Categories)
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 0;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab == 0
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x12064E3B),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Services',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? AppColors.greenForest
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab == 1
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x12064E3B),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Categories (Trades)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _selectedTab == 1
                                        ? AppColors.greenForest
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0
                          ? 'Search services by name or category...'
                          : 'Search categories / trades...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    const SizedBox(height: 10),
                    // Filter Chips (All, Active, Inactive)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Inactive'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Body (Services Stream or Categories Stream)
            Expanded(
              child: _selectedTab == 0
                  ? _buildServicesTab()
                  : _buildCategoriesTab(),
            ),
          ],
        ),
      ),
    );
  }

  // SERVICES TAB
  Widget _buildServicesTab() {
    return StreamBuilder<List<ServiceModel>>(
      stream: _serviceManagementService.streamAllServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(
              message: 'Loading master services catalog...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading services: ${snapshot.error}'),
          );
        }

        final allServices = snapshot.data ?? [];

        if (allServices.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greenMint.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_rounded,
                        size: 40, color: AppColors.greenForest),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No services in master catalog yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Click "Add Service" above to define platform services under categories.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddServiceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Platform Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenForest,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter services by search & status
        final filteredServices = allServices.where((s) {
          final matchesSearch = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery) ||
              s.category.toLowerCase().contains(_searchQuery) ||
              s.shortDescription.toLowerCase().contains(_searchQuery);

          bool matchesStatus = true;
          if (_statusFilter == 'Active') {
            matchesStatus = s.isActive;
          } else if (_statusFilter == 'Inactive') {
            matchesStatus = !s.isActive;
          }

          return matchesSearch && matchesStatus;
        }).toList();

        if (filteredServices.isEmpty) {
          return const Center(
            child: Text(
              'No services match your filter criteria.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredServices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final service = filteredServices[idx];

            return ServiceCard(
              service: service,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailsScreen(
                      serviceId: service.id,
                    ),
                  ),
                );
              },
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditServiceScreen(
                      service: service,
                    ),
                  ),
                );
              },
              onToggleStatus: () async {
                await _serviceManagementService.toggleServiceStatus(
                    service.id, service.status);
              },
            );
          },
        );
      },
    );
  }

  // CATEGORIES / TRADES TAB
  Widget _buildCategoriesTab() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryService.streamAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading categories & trades...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading categories: ${snapshot.error}'),
          );
        }

        final allCategories = snapshot.data ?? [];

        final filtered = allCategories.where((c) {
          if (_searchQuery.isEmpty) return true;
          final name = c.name.toLowerCase();
          final desc = (c.description ?? '').toLowerCase();
          return name.contains(_searchQuery) || desc.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greenMint.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        size: 40, color: AppColors.greenForest),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No categories found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create trades and categories to organize platform services.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => CategoryDialog.show(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Service Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenForest,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final category = filtered[idx];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE8E1), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C064E3B),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 40x40 Squircle Icon Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenMint.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.greenForest.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        category.iconData,
                        size: 20,
                        color: AppColors.greenForest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Name & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: category.isActive
                                    ? AppColors.greenMint.withValues(alpha: 0.35)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.isActive ? 'Active' : 'Hidden',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: category.isActive
                                      ? AppColors.greenDeep
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (category.description?.isNotEmpty == true) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  category.description!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Actions: Toggle Switch & Popup Actions Menu
                  Switch.adaptive(
                    value: category.isActive,
                    activeTrackColor: AppColors.greenForest,
                    activeThumbColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      await _categoryService.toggleCategoryStatus(
                          category.id, category.isActive);
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Category Actions',
                    onSelected: (action) {
                      if (action == 'edit') {
                        CategoryDialog.show(context, category: category);
                      } else if (action == 'delete') {
                        _confirmDeleteCategory(category);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 18, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.statusError),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.statusError)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? Services under this category will remain, but the category tag will be removed from trade listings.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _categoryService.deleteCategory(category.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _statusFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.greenMint.withValues(alpha: 0.4),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.greenDeep : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _statusFilter = label;
          });
        }
      },
    );
  }
}
