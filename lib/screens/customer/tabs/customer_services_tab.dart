import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/category_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/category_service.dart';
import '../../../services/service_management_service.dart';
import '../widgets/service_booking_dialog.dart';

/// Customer "Service Directory" Tab - Unique modern design with mild green aesthetic,
/// tactile animated buttons, trade category pills, and cooperative-assured service cards.
class CustomerServicesTab extends StatefulWidget {
  final AppUser customer;
  final String? initialCategory;
  final Function(int targetTab) onNavigateTab;

  const CustomerServicesTab({
    super.key,
    required this.customer,
    this.initialCategory,
    required this.onNavigateTab,
  });

  @override
  State<CustomerServicesTab> createState() => _CustomerServicesTabState();
}

class _CustomerServicesTabState extends State<CustomerServicesTab> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search Bar with Mild Green styling
            _buildHeaderAndSearch(),

            // Dynamic Category Switcher Bar with Icons and Tactile Bounce
            _buildCategorySelector(),

            // Services Stream List
            Expanded(
              child: StreamBuilder<List<ServiceModel>>(
                stream: _serviceService.streamActiveServices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Loading verified services...');
                  }

                  final allServices = snapshot.data ?? [];
                  final filtered = allServices.where((s) {
                    final query = _searchQuery.trim().toLowerCase();
                    final matchesQuery = query.isEmpty ||
                        s.name.toLowerCase().contains(query) ||
                        s.shortDescription.toLowerCase().contains(query) ||
                        s.category.toLowerCase().contains(query) ||
                        s.requiredSkills.any((k) => k.toLowerCase().contains(query));

                    final matchesCat = _selectedCategory == 'All' ||
                        s.category.toLowerCase() == _selectedCategory.toLowerCase() ||
                        s.name.toLowerCase().contains(_selectedCategory.toLowerCase());

                    return matchesQuery && matchesCat;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(allServices.isEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final service = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildServiceCard(service),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundMildGreen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'Service Directory',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDeep,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7EFE1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: AppColors.greenForest),
                    SizedBox(width: 4),
                    Text(
                      'Fair Rates',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenForest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Explore certified cooperative trade services with protected pricing',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Modern Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4E6DC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C064E3B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search service, plumber, electrician, repair...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.greenForest),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: StreamBuilder<List<CategoryModel>>(
        stream: _categoryService.streamActiveCategories(),
        builder: (context, catSnap) {
          final categories = catSnap.data ?? [];
          final categoryNames = ['All', ...categories.map((c) => c.name)];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categoryNames.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categoryNames[index];
              final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
              final iconData = cat == 'All'
                  ? Icons.layers_rounded
                  : CategoryModel.getIconForName(cat);

              return _BounceButton(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFE4EFE8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFBCE0CC) : const Color(0xFFD4E6DC),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x180F766E),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        size: 15,
                        color: isSelected ? AppColors.greenForest : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.greenDeep : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDDECE3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10064E3B),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6F5ED), Color(0xFFCEECDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBCE0CC), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18047857),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isCompletelyEmpty ? Icons.handyman_outlined : Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.greenForest,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCompletelyEmpty ? 'No Services Available' : 'No Services Found',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCompletelyEmpty
                    ? 'Certified cooperative trade services will appear here once registered by your cooperative administrator.'
                    : 'No service matches "$_searchQuery" in category "$_selectedCategory". Try resetting your filter.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (!isCompletelyEmpty) ...[
                const SizedBox(height: 20),
                _BounceButton(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = 'All';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.greenForest],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330F766E),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Reset Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E064E3B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x06064E3B),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Trade Icon Squircle + Service Name + Category Tag + Price Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Trade Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBCE0CC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10047857),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CategoryModel.getIconForName(service.category),
                    color: AppColors.greenForest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Category Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8F3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDCEFE3)),
                        ),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenForest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Price Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF3E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBEE5CD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'FAIR RATE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenDeep,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        service.priceRange ?? '₹250 - ₹500',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Short Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              service.shortDescription.isNotEmpty
                  ? service.shortDescription
                  : 'Professional household service delivered by verified cooperative members.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Skill Badges
          if (service.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: service.requiredSkills.take(4).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2EDE6)),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Bottom Action Bar: Cooperative Guarantee + Tactile "Book Now" Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FCFA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFFE8F1EC), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: AppColors.greenEmerald),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Cooperative Quality Assured',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.greenForest,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _BounceButton(
                  onTap: () async {
                    final result = await ServiceBookingDialog.show(
                      context,
                      service: service,
                      customer: widget.customer,
                    );
                    if (result == true) {
                      widget.onNavigateTab(1); // navigate to Bookings tab
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.greenForest],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2A0F766E),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile bounce button with physical press micro-interaction
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BounceButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
